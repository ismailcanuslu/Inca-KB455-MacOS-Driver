import Foundation

enum KeyboardProtocolConstants {
    static let controlReportID: UInt8 = 0x05
    static let dataReportID: UInt8 = 0x06
    static let bulkDataSize = 0x400
    static let bulkPayloadSize = 0x407
}

enum KeyboardProtocolError: LocalizedError {
    case invalidBulkDataLength(actual: Int)
    case unexpectedConfigHeader(UInt8?)

    var errorDescription: String? {
        switch self {
        case let .invalidBulkDataLength(actual):
            return "Bulk veri tam olarak 1024 byte olmalı; gelen: \(actual)."
        case let .unexpectedConfigHeader(value):
            return "Config Load yanıtı 0x83 ile başlamıyor (gelen: \(value.map { String(format: "0x%02X", $0) } ?? "yok"))."
        }
    }
}

struct ConfigSnapshot {
    /// Complete 0x407-byte payload from report 0x06. Field boundaries are not
    /// inferred until the response layout has been independently confirmed.
    let rawResponse: [UInt8]
    let global: [UInt8]?
    let profile1: [UInt8]?
}

enum KeyboardPacketBuilder {
    static func matrix(data: [UInt8]) throws -> [UInt8] {
        try requireBulkData(data)
        return [0x04, 0xD4, 0x00, 0x40, 0x00, 0x00, 0x00] + data
    }

    static func macro(id: UInt8, data: [UInt8]) throws -> [UInt8] {
        try requireBulkData(data)
        return [0x05, id, 0x00, 0x40, 0x00, 0x00, 0x00] + data
    }

    static func unknown09(argument: UInt8, data: [UInt8]) throws -> [UInt8] {
        try requireBulkData(data)
        return [0x09, argument, 0x00, 0x40, 0x00, 0x00, 0x00] + data
    }

    private static func requireBulkData(_ data: [UInt8]) throws {
        guard data.count == KeyboardProtocolConstants.bulkDataSize else {
            throw KeyboardProtocolError.invalidBulkDataLength(actual: data.count)
        }
    }
}

struct KeyboardProtocol {
    let transport: HIDFeatureTransport

    func loadConfig() throws -> ConfigSnapshot {
        try transport.setFeature(
            reportID: KeyboardProtocolConstants.controlReportID,
            payload: [0x83, 0xB6, 0x00, 0x00, 0x00, 0x00]
        )
        let response = try transport.getFeature(
            reportID: KeyboardProtocolConstants.dataReportID,
            payloadLength: KeyboardProtocolConstants.bulkPayloadSize
        )
        guard response.first == 0x83 else {
            throw KeyboardProtocolError.unexpectedConfigHeader(response.first)
        }
        return ConfigSnapshot(rawResponse: response, global: nil, profile1: nil)
    }

    /// Raw upload APIs are intentionally not connected to the UI until matrix
    /// and macro serialization have been fully decoded.
    func setMatrix(_ data: [UInt8]) throws {
        try transport.setFeature(reportID: KeyboardProtocolConstants.dataReportID, payload: KeyboardPacketBuilder.matrix(data: data))
    }

    func setMacro(id: UInt8, data: [UInt8]) throws {
        try transport.setFeature(reportID: KeyboardProtocolConstants.dataReportID, payload: KeyboardPacketBuilder.macro(id: id, data: data))
    }
}
