import Foundation
import CoreBluetooth

/// Read-only BLE explorer used to identify the battery endpoint exposed by the
/// keyboard. It never writes a characteristic or changes device configuration.
final class BLEBatteryDiscovery: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    typealias StatusHandler = (String) -> Void
    typealias BatteryHandler = (_ percent: Int, _ endpoint: String) -> Void
    typealias ValueHandler = (_ endpoint: String, _ hex: String) -> Void

    var onStatus: StatusHandler?
    var onBattery: BatteryHandler?
    var onValue: ValueHandler?

    private let targetName = "IKG-455 BT 5.0"
    private lazy var central = CBCentralManager(delegate: self, queue: .main)
    private var target: CBPeripheral?
    private var wantsScan = false
    private var endpointForCharacteristic: [ObjectIdentifier: String] = [:]

    func start() {
        wantsScan = true
        _ = central
        if central.state == .poweredOn { findConnectedKeyboardOrScan() }
    }

    func stop() {
        wantsScan = false
        central.stopScan()
        if let target { central.cancelPeripheralConnection(target) }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            onStatus?("BLE kullanıma hazır değil (durum: \(central.state.rawValue)).")
            return
        }
        if wantsScan { findConnectedKeyboardOrScan() }
    }

    private func findConnectedKeyboardOrScan() {
        // Paired BLE HID peripherals often stop advertising while macOS is
        // already connected. Ask CoreBluetooth for those first.
        let services = [CBUUID(string: "1812"), CBUUID(string: "180F")]
        if let connected = central.retrieveConnectedPeripherals(withServices: services).first(where: { $0.name == targetName }) {
            connect(connected, existingConnection: true)
        } else {
            scan()
        }
    }

    private func scan() {
        onStatus?("BLE taranıyor: \(targetName)")
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        guard peripheral.name == targetName || advertisedName == targetName else { return }
        onStatus?("BLE cihazı bulundu (RSSI \(RSSI)); servisler okunuyor.")
        connect(peripheral, existingConnection: false)
    }

    private func connect(_ peripheral: CBPeripheral, existingConnection: Bool) {
        target = peripheral
        central.stopScan()
        peripheral.delegate = self
        if existingConnection || peripheral.state == .connected {
            onStatus?("Mevcut BLE HID bağlantısı kullanılıyor; servisler keşfediliyor.")
            peripheral.discoverServices(nil)
        } else {
            central.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        onStatus?("BLE bağlı; servisler keşfediliyor.")
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        onStatus?("BLE bağlantısı kurulamadı: \(error?.localizedDescription ?? "bilinmeyen hata")")
        if wantsScan { findConnectedKeyboardOrScan() }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        onStatus?("BLE bağlantısı kesildi. \(error?.localizedDescription ?? "")")
        if wantsScan { findConnectedKeyboardOrScan() }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            onStatus?("BLE servis keşfi başarısız: \(error?.localizedDescription ?? "bilinmeyen hata")")
            return
        }
        for service in services { peripheral.discoverCharacteristics(nil, for: service) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let characteristics = service.characteristics else {
            onStatus?("\(service.uuid) characteristic keşfi başarısız: \(error?.localizedDescription ?? "bilinmeyen hata")")
            return
        }

        for characteristic in characteristics {
            let endpoint = "\(service.uuid.uuidString) / \(characteristic.uuid.uuidString)"
            endpointForCharacteristic[ObjectIdentifier(characteristic)] = endpoint
            let access = propertiesDescription(characteristic.properties)
            onStatus?("BLE endpoint: \(endpoint) [\(access)]")

            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            // Subscribing is read-only and lets us identify values that change
            // with battery state. HID input reports may also appear here.
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let value = characteristic.value else {
            onStatus?("BLE değer okuma hatası (\(characteristic.uuid)): \(error?.localizedDescription ?? "boş değer")")
            return
        }
        let endpoint = endpointForCharacteristic[ObjectIdentifier(characteristic)] ?? characteristic.uuid.uuidString
        let hex = value.map { String(format: "%02X", $0) }.joined(separator: " ")
        onValue?(endpoint, hex)

        // Bluetooth SIG Battery Level characteristic. Its first byte is the
        // percentage; charging state requires a separate discovered endpoint.
        if characteristic.uuid == CBUUID(string: "2A19"), let level = value.first {
            onBattery?(min(100, Int(level)), endpoint)
            onStatus?("Batarya endpoint doğrulandı: \(endpoint) = %\(level)")
        }
    }

    private func propertiesDescription(_ properties: CBCharacteristicProperties) -> String {
        var values: [String] = []
        if properties.contains(.read) { values.append("read") }
        if properties.contains(.write) { values.append("write") }
        if properties.contains(.writeWithoutResponse) { values.append("writeWithoutResponse") }
        if properties.contains(.notify) { values.append("notify") }
        if properties.contains(.indicate) { values.append("indicate") }
        return values.joined(separator: ", ")
    }
}
