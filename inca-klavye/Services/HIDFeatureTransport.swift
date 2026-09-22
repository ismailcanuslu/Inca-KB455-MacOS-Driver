import Foundation
import IOKit
import IOKit.hid

/// Read-only discovery surface. It deliberately returns metadata rather than
/// opening every HID device, so normal keyboards are never claimed by the app.
enum HIDDeviceDiscovery {
    static func enumerate() -> [HIDDeviceDescriptor] {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        defer { IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone)) }
        guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess,
              let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            return []
        }
        return devices.map(HIDDeviceDescriptor.inspect).sorted {
            ($0.vendorID, $0.productID, $0.locationID) < ($1.vendorID, $1.productID, $1.locationID)
        }
    }
}

/// The report-ID buffer convention must be confirmed against the device's HID
/// descriptor. This protocol starts with the convention observed in the Windows
/// driver: report ID in byte 0, then the feature payload.
enum HIDFeatureBufferConvention {
    case includesReportID
    case payloadOnly
}

enum HIDFeatureTransportError: LocalizedError {
    case invalidPayloadLength(expected: Int, actual: Int)
    case ioKit(operation: String, status: IOReturn)
    case malformedResponse(expectedReportID: UInt8)

    var errorDescription: String? {
        switch self {
        case let .invalidPayloadLength(expected, actual):
            return "Geçersiz paket uzunluğu: beklenen \(expected), gelen \(actual)."
        case let .ioKit(operation, status):
            return "HID \(operation) başarısız oldu (0x\(String(status, radix: 16)))."
        case let .malformedResponse(expectedReportID):
            return "HID yanıtı beklenen report ID 0x\(String(format: "%02X", expectedReportID)) ile başlamıyor."
        }
    }
}

struct HIDFeatureTransport {
    static let retryCount = 3
    static let retryDelay: TimeInterval = 0.2

    let device: IOHIDDevice
    let convention: HIDFeatureBufferConvention

    init(device: IOHIDDevice, convention: HIDFeatureBufferConvention = .includesReportID) {
        self.device = device
        self.convention = convention
    }

    func setFeature(reportID: UInt8, payload: [UInt8]) throws {
        var report = convention == .includesReportID ? [reportID] + payload : payload
        try retry(operation: "SetFeature") {
            report.withUnsafeMutableBytes { bytes in
                IOHIDDeviceSetReport(
                    device,
                    kIOHIDReportTypeFeature,
                    CFIndex(reportID),
                    bytes.baseAddress!,
                    bytes.count
                )
            }
        }
    }

    /// Returns application payload only; the report ID is removed when macOS
    /// returns it in byte 0.
    func getFeature(reportID: UInt8, payloadLength: Int) throws -> [UInt8] {
        let capacity = payloadLength + (convention == .includesReportID ? 1 : 0)
        var report = [UInt8](repeating: 0, count: capacity)
        if convention == .includesReportID { report[0] = reportID }
        var actualLength = CFIndex(report.count)

        try retry(operation: "GetFeature") {
            report.withUnsafeMutableBytes { bytes in
                IOHIDDeviceGetReport(
                    device,
                    kIOHIDReportTypeFeature,
                    CFIndex(reportID),
                    bytes.baseAddress!,
                    &actualLength
                )
            }
        }

        let received = Array(report.prefix(Int(actualLength)))
        if convention == .includesReportID, received.first == reportID {
            return Array(received.dropFirst())
        }
        if convention == .includesReportID, received.count == payloadLength {
            // Some HID descriptors exclude the ID from the returned buffer.
            return received
        }
        guard convention == .payloadOnly else {
            throw HIDFeatureTransportError.malformedResponse(expectedReportID: reportID)
        }
        return received
    }

    private func retry(operation: String, _ body: () -> IOReturn) throws {
        var lastStatus: IOReturn = kIOReturnError
        for attempt in 0..<Self.retryCount {
            let status = body()
            if status == kIOReturnSuccess { return }
            lastStatus = status
            if attempt + 1 < Self.retryCount {
                Thread.sleep(forTimeInterval: Self.retryDelay)
            }
        }
        throw HIDFeatureTransportError.ioKit(operation: operation, status: lastStatus)
    }
}

struct HIDDeviceDescriptor: Equatable {
    struct FeatureReport: Identifiable, Equatable {
        let id: UInt8
        let bitLength: Int
        var byteLength: Int { (bitLength + 7) / 8 }
    }

    let vendorID: Int
    let productID: Int
    let usagePage: Int
    let usage: Int
    let locationID: Int
    let reportDescriptorLength: Int
    let featureReports: [FeatureReport]

    static func inspect(_ device: IOHIDDevice) -> HIDDeviceDescriptor {
        func intProperty(_ key: CFString) -> Int {
            (IOHIDDeviceGetProperty(device, key) as? NSNumber)?.intValue ?? 0
        }

        var reports: [UInt8: Int] = [:]
        let elements = IOHIDDeviceCopyMatchingElements(device, nil, IOOptionBits(kIOHIDOptionsTypeNone)) as? [IOHIDElement] ?? []
        for element in elements where IOHIDElementGetType(element) == kIOHIDElementTypeFeature {
            let reportID = UInt8(truncatingIfNeeded: IOHIDElementGetReportID(element))
            // Public IOKit exposes the element's bit width/count but not a
            // Swift-imported report offset. Keep the largest declared feature
            // field as a descriptor diagnostic, not as a wire-size guarantee.
            let declaredBits = Int(IOHIDElementGetReportSize(element) * IOHIDElementGetReportCount(element))
            reports[reportID] = max(reports[reportID] ?? 0, declaredBits)
        }

        let rawDescriptor = IOHIDDeviceGetProperty(device, kIOHIDReportDescriptorKey as CFString) as? Data
        return HIDDeviceDescriptor(
            vendorID: intProperty(kIOHIDVendorIDKey as CFString),
            productID: intProperty(kIOHIDProductIDKey as CFString),
            usagePage: intProperty(kIOHIDPrimaryUsagePageKey as CFString),
            usage: intProperty(kIOHIDPrimaryUsageKey as CFString),
            locationID: intProperty(kIOHIDLocationIDKey as CFString),
            reportDescriptorLength: rawDescriptor?.count ?? 0,
            featureReports: reports.map { FeatureReport(id: $0.key, bitLength: $0.value) }.sorted { $0.id < $1.id }
        )
    }

    var diagnosticSummary: String {
        let reports = featureReports.map { String(format: "0x%02X: %d B", $0.id, $0.byteLength) }.joined(separator: ", ")
        return String(format: "VID:0x%04X PID:0x%04X Usage:0x%04X/0x%04X · Descriptor: %d B · Feature: %@", vendorID, productID, usagePage, usage, reportDescriptorLength, reports.isEmpty ? "bulunamadı" : reports)
    }
}
