import Foundation
import AppKit
import CoreGraphics
import IOKit
import IOKit.hid
import Combine
import os

class KeyboardManager: ObservableObject {
    private static let osLogger = Logger(subsystem: "devplaceholder.Inca-Empousa", category: "Hardware")

    static func log(_ message: String) {
        print(message)
        fflush(stdout)
        NSLog("%@", message)
        osLogger.notice("\(message, privacy: .public)")
    }

    private var hidManager: IOHIDManager?
    private var keyboardDevice: IOHIDDevice?
    private let bleBatteryDiscovery = BLEBatteryDiscovery()
    
    // Inca Klavye Donanım Tanımlayıcıları (KB.ini ve OemDrv.exe)
    // 1. Kablosuz Alıcı (2.4G): VID: 13652 (0x3554), PID: 64009 (0xFA09), UsagePage: 0xFF02
    // 2. Kablolu (USB-C): VID: 9610 (0x258A), PID: 268 (0x010C), UsagePage: 0xFF00
    static let wirelessVID: Int = 13652
    static let wirelessPID: Int = 64009
    static let wirelessUsagePage: Int = 0xFF02
    
    static let wiredVID: Int = 0x258A
    static let wiredPID: Int = 0x010C
    static let wiredUsagePage: Int = 0xFF00
    
    enum ConnectionType: String {
        case disconnected = "Bağlantı Yok"
        case wireless24G = "2.4G Kablosuz"
        case wiredUSB = "USB-C"
        case bluetooth = "Bluetooth"

        var icon: String {
            switch self {
            case .disconnected: return "bolt.slash.fill"
            case .wireless24G: return "antenna.radiowaves.left.and.right"
            case .wiredUSB: return "cable.connector.horizontal"
            case .bluetooth: return "dot.radiowaves.left.and.right"
            }
        }
    }

    @Published var isConnected: Bool = false
    @Published var statusMessage: String = "Empousa klavye aranıyor..."
    @Published var lastHardwareConfig: String = "-"
    @Published var hidDescriptorSummary: String = "Henüz bir HID arayüzü seçilmedi."
    @Published var configLoadStatus: String = "Config Load henüz çalıştırılmadı."
    @Published var bleBatteryStatus: String = "BLE batarya endpoint'i henüz taranmadı."
    @Published var bleBatteryEndpoint: String = "-"
    @Published var lastBLEValue: String = "-"
    @Published var batteryLevel: Int = 85
    @Published var isCharging: Bool = false
    @Published var isMacMode: Bool = true
    @Published var connectionType: ConnectionType = .disconnected
    @Published var activeEffectId: UInt8 = 2
    @Published var activeSpeed: UInt8 = 0
    @Published var activeBrightness: UInt8 = 4
    @Published var hasInputMonitoringPermission: Bool = false
    @Published var isLightsOff: Bool = false

    // Yan LED (Side LED) Durumu
    @Published var sideLedEffect: SideLEDEffect = .streaming
    @Published var sideLedSpeed: UInt8 = 2
    @Published var sideLedBrightness: UInt8 = 3
    @Published var sideLedRed: UInt8 = 0
    @Published var sideLedGreen: UInt8 = 217
    @Published var sideLedBlue: UInt8 = 255

    // Dinamik Ada (Dynamic Island) Durumu
    enum IslandStatus: Equatable {
        case idle                                // Normal: "Empousa IKG-455 Magnetic"
        case unsavedChanges(description: String) // "Kaydedilmemiş Değişiklikler Var"
        case saving(message: String)             // "Değişiklikler Kaydediliyor..."
        case saved(message: String)              // "Başarıyla Kaydedildi!"
    }

    @Published var islandStatus: IslandStatus = .idle
    var isDeviceOpened: Bool = false
    var onCommitChangesRequested: (() -> Void)? = nil
    var onDiscardChangesRequested: (() -> Void)? = nil

    func triggerUnsavedStatus(description: String, onCommit: (() -> Void)? = nil, onDiscard: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.onCommitChangesRequested = onCommit
            self.onDiscardChangesRequested = onDiscard
            self.islandStatus = .unsavedChanges(description: description)
        }
    }

    func triggerSavingStatus(message: String = "Cihaza Gönderiliyor...") {
        DispatchQueue.main.async {
            self.islandStatus = .saving(message: message)
        }
    }

    func triggerSavedSuccess(message: String = "Başarıyla Kaydedildi!") {
        DispatchQueue.main.async {
            self.islandStatus = .saved(message: message)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                if case .saved = self.islandStatus {
                    self.islandStatus = .idle
                }
            }
        }
    }

    func triggerIdleStatus() {
        DispatchQueue.main.async {
            self.islandStatus = .idle
        }
    }

    // Müzik Ritmi Modu
    @Published var activeMusicMode: MusicSyncMode? = nil

    // Donanım Ayarları
    @Published var sleepTimeoutSeconds: Int = 180
    @Published var debounceTimeMs: Int = 8

    // Döner Tekerlek (Knob / Wheel) Modu (OemDrv 0x49BE42 nWheelMode)
    enum WheelMode: UInt8, CaseIterable, Identifiable {
        case volume = 0
        case backlight = 1
        
        var id: UInt8 { self.rawValue }
        var name: String {
            switch self {
            case .volume: return "Ses & Medya"
            case .backlight: return "RGB Parlaklık"
            }
        }
        var icon: String {
            switch self {
            case .volume: return "speaker.wave.3.fill"
            case .backlight: return "sun.max.fill"
            }
        }
    }

    @Published var wheelMode: WheelMode = .volume

    // 128-baytlık kalıcı donanım LED profil tamponu (USB Sniff Paket 595/545 doğrulamalı)
    private var cachedLedProfile: [UInt8] = KeyboardCommand.defaultLedProfileTemplate()

    private var lastQueryTime: Date = Date.distantPast
    private var musicStreamTimer: DispatchSourceTimer?
    private var musicPhase: Double = 0.0

    /// Donanım HID iletişimi için seri arka plan kuyruğu.
    /// usleep kullanıldığından ASLA main thread'de çalıştırılmamalı — UI donması yaratır!
    private let hidQueue = DispatchQueue(label: "empousa.hid.serial", qos: .userInitiated)
    /// Hızlı ardışık gönderimler için debounce — son isteği önceliklendirir, öncekini iptal eder
    private var pendingLightingItem: DispatchWorkItem?
    /// TCC sistem penceresi bir uygulama çalıştırmasında yalnızca bir kez
    /// istenebilir. İzin durumu sonraki açılışlarda sadece kontrol edilir.
    private var didRequestInputMonitoringPermissionThisLaunch = false
    private var inputMonitoringEventTap: CFMachPort?
    // v2 intentionally retries once after adding the required usage string to
    // the shipped Info.plist. Subsequent launches remain quiet.
    private let inputMonitoringPromptRequestedKey = "inputMonitoringPromptRequested.v2"

    init() {
        Self.log("🚀 [Inca Empousa] KeyboardManager başlatıldı!")
        // Kaydedilmiş son durumu yükle (önceki bugdan kalan 0 değerini varsayılan Full (4) yap)
        if let savedB = UserDefaults.standard.object(forKey: "savedBrightness") as? UInt8, savedB > 0 {
            let savedOff = UserDefaults.standard.bool(forKey: "savedIsLightsOff")
            self.isLightsOff = savedOff
            self.activeBrightness = savedOff ? 0 : min(UInt8(4), savedB)
        } else {
            self.activeBrightness = 4 // Varsayılan Full Parlaklık
            self.isLightsOff = false
        }
        // Kaydedilmiş efekt hızını yükle
        if let savedSpeed = UserDefaults.standard.object(forKey: "savedSpeed") as? UInt8 {
            self.activeSpeed = min(4, savedSpeed)
        }
        let inputMonitoringGranted = checkInputMonitoringPermission()
        setupHIDManager()
        configureBLEBatteryDiscovery()
        if inputMonitoringGranted {
            startPassiveInputMonitoringProbe()
        } else if !UserDefaults.standard.bool(forKey: inputMonitoringPromptRequestedKey) {
            // Register with TCC exactly once for this installed application
            // identity. Future launches only check the existing decision.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.requestInputMonitoringPermission()
            }
        }
    }

    private func configureBLEBatteryDiscovery() {
        bleBatteryDiscovery.onStatus = { [weak self] status in
            Self.log("📡 [BLE] \(status)")
            DispatchQueue.main.async { self?.bleBatteryStatus = status }
        }
        bleBatteryDiscovery.onValue = { [weak self] endpoint, hex in
            Self.log("📥 [BLE] \(endpoint): \(hex)")
            DispatchQueue.main.async { self?.lastBLEValue = "\(endpoint): \(hex)" }
        }
        bleBatteryDiscovery.onBattery = { [weak self] percent, endpoint in
            Self.log("🔋 [BLE Batarya] %\(percent) — \(endpoint)")
            DispatchQueue.main.async {
                self?.batteryLevel = percent
                self?.bleBatteryEndpoint = endpoint
            }
        }
        bleBatteryDiscovery.start()
    }

    /// Restarts the read-only BLE scan when the keyboard is switched to its
    /// Bluetooth profile or when a new endpoint capture is needed.
    func scanBLEBatteryEndpoint() {
        bleBatteryDiscovery.start()
    }

    @discardableResult
    func checkInputMonitoringPermission() -> Bool {
        guard #available(macOS 10.15, *) else { return true }
        // CGPreflightListenEventAccess is the authoritative public API for the
        // Input Monitoring privacy control. The IOKit result is retained as a
        // compatibility fallback for HID listening.
        let cgAccess = CGPreflightListenEventAccess()
        let hidAccess = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
        let isPermitted = cgAccess || hidAccess
        if hasInputMonitoringPermission != isPermitted {
            if Thread.isMainThread {
                hasInputMonitoringPermission = isPermitted
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.hasInputMonitoringPermission = isPermitted
                }
            }
        }
        return isPermitted
    }

    func requestInputMonitoringPermission() {
        if #available(macOS 10.15, *) {
            // IOKit sistem API'si: macOS'un sistemi uyararak 'Inca Empousa' uygulamasını Giriş İzleme (Input Monitoring) listesine kaydetmesini sağlar
            let hidAccess = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
            Self.log("🔐 [TCC] IOHIDRequestAccess çağrıldı (Sistem Listesine Ekleme): \(hidAccess)")
            _ = CGRequestListenEventAccess()
        }

        // TCC veritabanında uygulamanın kesinlikle görünmesi için dinleme tap'i dene
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        if let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        ) {
            CFMachPortInvalidate(tap)
        }

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            if self.checkInputMonitoringPermission() {
                self.startPassiveInputMonitoringProbe()
                if let dev = self.keyboardDevice {
                    _ = self.ensureDeviceOpen(dev)
                }
            }
        }
    }

    /// Uygulama paketini (.app) Finder'da seçili olarak açar (Sistem Ayarları'nda '+' ile kolayca ekleyebilmek için)
    func revealAppInFinder() {
        let bundleURL = Bundle.main.bundleURL
        NSWorkspace.shared.activateFileViewerSelecting([bundleURL])
    }

    /// Cihazın açık olduğundan emin olur; açık değilse açmayı dener
    @discardableResult
    func ensureDeviceOpen(_ device: IOHIDDevice) -> Bool {
        let openRes = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        if openRes == kIOReturnSuccess || openRes == -536870207 /* kIOReturnExclusiveAccess */ {
            self.isDeviceOpened = true
            return true
        }
        Self.log("⚠️ [IOKit] ensureDeviceOpen: \(Self.describeIOReturn(openRes))")
        return false
    }

    /// Creates a listen-only event tap after approval. The callback returns the
    /// event unchanged and records nothing; it exists solely to verify that
    /// macOS granted the permission this app actually requests.
    private func startPassiveInputMonitoringProbe() {
        guard inputMonitoringEventTap == nil, CGPreflightListenEventAccess() else { return }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        ) else {
            hasInputMonitoringPermission = false
            return
        }
        inputMonitoringEventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func setupHIDManager() {
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = hidManager else {
            return
        }
        
        // Empousa donanım kontrol arabirimleri
        let matchingCriteria: [[String: Any]] = [
            // 2.4G Kablosuz Dongle: Vendor Interface (Page 0xFF02, Usage 2)
            [
                kIOHIDVendorIDKey: Self.wirelessVID,
                kIOHIDPrimaryUsagePageKey: 0xFF02,
                kIOHIDPrimaryUsageKey: 2
            ],
            // Kablolu USB: Kontrol Arayüzü (Page 1, Usage 128 — MaxFeat 520)
            [
                kIOHIDVendorIDKey: Self.wiredVID,
                kIOHIDPrimaryUsagePageKey: 1,
                kIOHIDPrimaryUsageKey: 128
            ]
        ]
        
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingCriteria as CFArray)
        
        let context = Unmanaged.passUnretained(self).toOpaque()
        
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { (context, result, sender, device) in
            guard let context = context else { return }
            let manager = Unmanaged<KeyboardManager>.fromOpaque(context).takeUnretainedValue()
            manager.handleDeviceConnected(device)
        }, context)
        
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { (context, result, sender, device) in
            guard let context = context else { return }
            let manager = Unmanaged<KeyboardManager>.fromOpaque(context).takeUnretainedValue()
            manager.handleDeviceRemoved(device)
        }, context)
        
        // CANLI TELEMETRİ / BATARYA RAPOR DİNLEYİCİSİ (OemDrv.exe OnDeviceBehavior / ReadFile 0x14)
        IOHIDManagerRegisterInputReportCallback(manager, { context, result, sender, type, reportID, report, length in
            guard let context = context, result == kIOReturnSuccess, length > 0 else { return }
            let manager = Unmanaged<KeyboardManager>.fromOpaque(context).takeUnretainedValue()
            manager.handleInputReport(reportID: reportID, report: report, length: length)
        }, context)

        // HID Yöneticisini standart (paylaşımlı) modda aç
        _ = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        
        // İlk açılışta takılı cihazları tara ve periyodik olarak bağlantı sağlığını kontrol et
        scanConnectedDevices()
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.scanConnectedDevices()
        }
    }

    func scanConnectedDevices() {
        guard let manager = hidManager else { return }
        guard let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>, !deviceSet.isEmpty else {
            if isConnected {
                DispatchQueue.main.async {
                    self.isConnected = false
                    self.connectionType = .disconnected
                    self.statusMessage = "Klavye Bağlantısı Kesildi"
                }
                self.keyboardDevice = nil
            }
            return
        }

        var foundWired: IOHIDDevice? = nil
        var foundWireless: IOHIDDevice? = nil

        // LocationID bazında deterministik sırala (rastgele seçim önleme)
        let sortedDevices = deviceSet.sorted { dev1, dev2 in
            let loc1 = (IOHIDDeviceGetProperty(dev1, kIOHIDLocationIDKey as CFString) as? NSNumber)?.intValue ?? 0
            let loc2 = (IOHIDDeviceGetProperty(dev2, kIOHIDLocationIDKey as CFString) as? NSNumber)?.intValue ?? 0
            return loc1 < loc2
        }

        for dev in sortedDevices {
            let vid = (IOHIDDeviceGetProperty(dev, kIOHIDVendorIDKey as CFString) as? NSNumber)?.intValue ?? 0
            let page = (IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsagePageKey as CFString) as? Int) ?? 0
            let usage = (IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsageKey as CFString) as? Int) ?? 0
            let maxFeat = (IOHIDDeviceGetProperty(dev, kIOHIDMaxFeatureReportSizeKey as CFString) as? Int) ?? 0

            // Kablolu kontrol arayüzü: VID 0x258A, Usage 128 (MaxFeat >= 136)
            if vid == Self.wiredVID && usage == 128 {
                foundWired = dev
            }

            // 2.4G Kablosuz Dongle kontrol arayüzü: VID 0x3554, Page 0xFF02, Usage 2
            if vid == Self.wirelessVID && (page == 0xFF02 || page == 65282 || usage == 2) {
                if foundWireless == nil {
                    foundWireless = dev
                }
            }
        }

        // DOĞRU KANAL VE ÖNCELİK EŞLEMESİ:
        // Eğer kablolu USB (0x258A) takılıysa, klavye doğrudan kabloya bağlıdır -> activeDev = foundWired!
        // Eğer kablo takılı değilse, klavye kablosuz moddadır -> activeDev = foundWireless!
        let activeDev: IOHIDDevice?
        let activeType: ConnectionType

        if let wired = foundWired {
            activeDev = wired
            activeType = .wiredUSB
            if self.connectionType != .wiredUSB {
                Self.log("🔌 [HID] Kablolu USB bağlantısı algılandı (0x258A aktif)")
            }
        } else if let wireless = foundWireless {
            activeDev = wireless
            activeType = .wireless24G
            if self.connectionType != .wireless24G {
                Self.log("📡 [HID] Kablosuz 2.4G modu aktif (0x3554 aktif)")
            }
        } else {
            activeDev = nil
            activeType = .disconnected
        }

        // CİHAZ STABİLİTESİ: Eğer zaten doğru cihaza bağlı ve açıksa gereksiz işlem yapma!
        if let currentDev = self.keyboardDevice,
           currentDev == activeDev,
           self.connectionType == activeType,
           self.isConnected,
           self.isDeviceOpened {
            return
        }


        if let dev = activeDev {
            let isNewDevice = (self.keyboardDevice != dev)
            self.keyboardDevice = dev
            
            // Yeni cihaz veya henüz başarıyla açılamamışsa açmayı dene
            if isNewDevice || !self.isDeviceOpened {
                let openRes = IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone))
                if openRes == kIOReturnSuccess || openRes == -536870207 /* kIOReturnExclusiveAccess */ {
                    self.isDeviceOpened = true
                    Self.log("🔌 [IOKit] Empousa Vendor Endpoint başarıyla açıldı (0x0)")
                    checkInputMonitoringPermission()
                } else {
                    self.isDeviceOpened = false
                    Self.log("⚠️ [IOKit] IOHIDDeviceOpen sonucu: \(Self.describeIOReturn(openRes))")
                    checkInputMonitoringPermission()
                }

                // Descriptor bilgisi yalnızca teşhis içindir.
                let descriptor = HIDDeviceDescriptor.inspect(dev)
                DispatchQueue.main.async {
                    self.hidDescriptorSummary = descriptor.diagnosticSummary
                }
                Self.log("🔎 [HID Descriptor] \(descriptor.diagnosticSummary)")
            }

            if !self.isConnected || self.connectionType != activeType {
                DispatchQueue.main.async {
                    self.isConnected = true
                    self.connectionType = activeType
                    self.statusMessage = "Empousa Bağlandı (\(activeType.rawValue))"
                    if activeType == .wiredUSB {
                        self.isCharging = true
                    }
                }
            }
        } else if self.isConnected {
            self.keyboardDevice = nil
            self.isDeviceOpened = false
            DispatchQueue.main.async {
                self.isConnected = false
                self.connectionType = .disconnected
                self.statusMessage = "Klavye Bağlantısı Kesildi"
            }
        }
    }

    private func handleDeviceConnected(_ device: IOHIDDevice) {
        scanConnectedDevices()
    }

    private func handleDeviceRemoved(_ device: IOHIDDevice) {
        scanConnectedDevices()
    }

    /// OemDrv.exe tersine mühendislik analizinden çıkarılan canlı telemetri ve sniffer dinleyicisi:
    /// - Komut 0x05 (OnDeviceBehavior VA 0x0045B7C0): Batarya Yüzdesi (Byte 1) & Şarj Durumu (Byte 2)
    /// - Şarj bayrağı: ((Byte 2 & 0xF0) != 0 && (Byte 2 & 0x0F) == 0) -> Şarj oluyor
    /// - Komut 0x0A (ReadFile Loop VA 0x00497850): Kablosuz bağlantı & uyku durumu
    /// - Canlı Donanım Dinleyicisi (Sniffer): Klavyeden gelen tüm donanım tuş/mod/aydınlatma paketlerini yakalar
    private func handleInputReport(reportID: UInt32, report: UnsafeMutablePointer<UInt8>, length: CFIndex) {
        guard length > 0 else { return }
        let buffer = [UInt8](UnsafeBufferPointer(start: report, count: length))
        let hexStr = buffer.map { String(format: "%02X", $0) }.joined(separator: " ")
        Self.log("📥 [Donanım Telemetrisi] ReportID: 0x\(String(format: "%02X", reportID)), Len: \(length), Baytlar: [\(hexStr)]")

        DispatchQueue.main.async {
            self.lastHardwareConfig = "ID: 0x\(String(format: "%02X", reportID)) | [\(hexStr)]"
        }

        var batteryPercent: Int? = nil
        var chargingStatus: Bool? = nil

        // 1. Batarya & Şarj Telemetrisi (Komut 0x05)
        if reportID == 0x05 && buffer.count >= 2 {
            let power = buffer[0]
            let chargeByte = buffer[1]
            batteryPercent = min(100, max(0, Int(power)))
            chargingStatus = ((chargeByte & 0xF0) != 0) && ((chargeByte & 0x0F) == 0)
        } else if buffer.count >= 3 && buffer[0] == 0x05 {
            let power = buffer[1]
            let chargeByte = buffer[2]
            batteryPercent = min(100, max(0, Int(power)))
            chargingStatus = ((chargeByte & 0xF0) != 0) && ((chargeByte & 0x0F) == 0)
        }

        if let percent = batteryPercent, let isCharging = chargingStatus {
            DispatchQueue.main.async {
                self.batteryLevel = percent
                self.isCharging = isCharging
                Self.log("🔋 [Canlı Donanım] Batarya: %\(percent), Şarj Durumu: \(isCharging ? "Şarj Oluyor ⚡️" : "Pilde")")
            }
            return
        }

        // 2. Döner Tekerlek (Knob) Mod Değişimi: Ses ⟷ Işık (Sniff Paket 665 / 683 doğrulaması)
        // Gerçek Donanım Paketi: [06 0A 07 00 11 00 00 00]
        // Byte 0: 0x06, Byte 1: 0x0A, Byte 2: 0x07 (Grup 0x07), Byte 3: 0x00, Byte 4: 0x11 (Tekerlek Toggle)
        if (buffer.count >= 5 && buffer[1] == 0x0A && buffer[2] == 0x07 && buffer[4] == 0x11) ||
           (buffer.count >= 8 && buffer[0] == 0x06 && buffer[1] == 0x0A && buffer[2] == 0x07 && buffer[4] == 0x11) ||
           (reportID == 0x06 && buffer.count >= 5 && buffer[0] == 0x0A && buffer[1] == 0x07 && buffer[3] == 0x11) {
            let nextMode: WheelMode = (self.wheelMode == .volume) ? .backlight : .volume
            DispatchQueue.main.async {
                self.wheelMode = nextMode
                Self.log("🎛️ [Döner Tekerlek] Donanımdan Mod Değiştirildi (Toggle): \(nextMode.name)")
            }
            return
        }

        // 3. Kablosuz bağlantı / Uyku durumu (OemDrv 0x497850)
        if (buffer.count >= 7 && buffer[1] == 0x0A && buffer[5] == 0x02) ||
           (reportID == 0x0A && buffer.count >= 6 && buffer[4] == 0x02) {
            let isOnline = (buffer[1] == 0x0A) ? (buffer[6] != 0) : (buffer[5] != 0)
            DispatchQueue.main.async {
                if !isOnline && self.connectionType == .wireless24G {
                    self.statusMessage = "Empousa Uyku Modunda (2.4G)"
                } else if isOnline && self.connectionType == .wireless24G {
                    self.statusMessage = "Empousa Aktif (2.4G)"
                }
            }
            return
        }

        // 4. Donanımsal FN Tuş Kısayolları — KB.ini [FN1] Tam Tablosu
        // Format: ReportID=0x03 + payload=[Group, Sub, Action, Param]
        // KB.ini 0xGGSSAABB decode: GG=Group, SS=Sub, AA=Action
        //
        // Grup 0x07 (Sistem): Fn+LWin(0x01), Fn+Esc(0x04), Fn+1-4(0x05-08),
        //   Fn+G(0x0A), Fn+Space(0x0B), Fn+W(0x0E), Fn+A(0x0F), Fn+RAlt(0x11), Fn+CapsLk(0x12)
        // Grup 0x08 (LED):  Fn+Insert(sub=0x00), Fn+Enter(sub=0x02),
        //   Fn+Up/Down(sub=0x03,act=0x01/02), Fn+Right/Left(sub=0x04,act=0x01/02), Fn+Bksp(sub=0x07)
        // Tek-Bayt: Fn+'(0x46), Fn+;(0x47), Fn+/(0x48), Fn+[(0x4A), Fn+](0x4D)
        if reportID == 0x03 || (!buffer.isEmpty && buffer[0] == 0x03) {
            let offset = (buffer[0] == 0x03) ? 1 : 0
            guard buffer.count > offset else { return }

            let group  = buffer[offset]
            let sub    = buffer.count > offset + 1 ? buffer[offset + 1] : 0
            let action = buffer.count > offset + 2 ? buffer[offset + 2] : 0

            Self.log("🎹 [FN] Grup:0x\(String(format:"%02X",group)) Sub:0x\(String(format:"%02X",sub)) Action:0x\(String(format:"%02X",action))")

            // ── GRUP 0x07: Sistem & Profil Kısayolları ──
            if group == 0x07 {
                switch action {
                case 0x01: // Fn+LWin: Win Tuşu Kilidi
                    Self.log("🔒 [FN] Fn+LWin → Win Kilidi Toggle")
                    return

                case 0x04: // Fn+Esc: Fabrika Sıfırlama
                    Self.log("♻️ [FN] Fn+Esc → Efekt Sıfırla")
                    applyLighting(effect: 2, speed: 2, brightness: 4, red: 250, green: 45, blue: 97)
                    return

                case 0x05, 0x06, 0x07, 0x08: // Fn+1..4: Donanım Profili
                    let profileNum = action - 0x04
                    Self.log("📋 [FN] Fn+\(profileNum) → Profil \(profileNum)")
                    return

                case 0x0A: // Fn+G: Gaming Modu
                    Self.log("🎮 [FN] Fn+G → Gaming Modu")
                    return

                case 0x0B: // Fn+Space: Işık Aç/Kapat
                    // Klavye hardware'ı zaten toggle yaptı — sadece UI'ı senkronize et
                    let newB: UInt8 = (isLightsOff || activeBrightness == 0) ? 3 : 0
                    DispatchQueue.main.async {
                        self.activeBrightness = newB
                        self.isLightsOff = (newB == 0)
                        self.cachedLedProfile[2] = newB
                        UserDefaults.standard.set(newB == 0, forKey: "savedIsLightsOff")
                        UserDefaults.standard.set(newB, forKey: "savedBrightness")
                        Self.log("💡 [FN→UI] Fn+Space → \(newB == 0 ? "KAPALI" : "AÇIK") (donanım zaten güncelledi)")
                    }
                    return

                case 0x0E: // Fn+W: Windows Modu
                    DispatchQueue.main.async { self.isMacMode = false }
                    Self.log("⌨️ [FN] Fn+W → Windows")
                    return

                case 0x0F: // Fn+A: macOS Modu
                    DispatchQueue.main.async { self.isMacMode = true }
                    Self.log("⌨️ [FN] Fn+A → macOS")
                    return

                case 0x11: // Döner Tekerlek (Knob) Mod Değişimi: Ses ⟷ Işık
                    let nextMode: WheelMode = (self.wheelMode == .volume) ? .backlight : .volume
                    DispatchQueue.main.async {
                        self.wheelMode = nextMode
                        Self.log("🎛️ [FN/Knob] Tekerlek Modu Değiştirildi (Toggle): \(nextMode.name)")
                    }
                    return

                case 0x12: // Fn+CapsLock
                    Self.log("🔡 [FN] Fn+CapsLock")
                    return

                case 0x14: // Mute
                    Self.log("🔇 [FN] Mute")
                    return

                default:
                    Self.log("❓ [FN] Grup=0x07 action=0x\(String(format:"%02X",action)) bilinmiyor")
                    return
                }
            }

            // ── GRUP 0x08: LED Parlaklık & Hız Kısayolları ──
            if group == 0x08 {
                switch sub {
                case 0x02: // Fn+Enter: Işıkları Sıfırla
                    Self.log("🔄 [FN] Fn+Enter → Sıfırla")
                    applyLighting(effect: 2, speed: 2, brightness: 4, red: 250, green: 45, blue: 97)
                    return

                case 0x03: // Fn+Up/Down: Parlaklık
                    // Klavye hardware'ı zaten brightness'ı değiştirdi — sadece UI'ı senkronize et, RESEND ETME!
                    if action == 0x01 {
                        let newB = min(UInt8(4), activeBrightness &+ 1)
                        DispatchQueue.main.async {
                            self.activeBrightness = newB
                            self.isLightsOff = false
                            UserDefaults.standard.set(newB, forKey: "savedBrightness")
                            UserDefaults.standard.set(false, forKey: "savedIsLightsOff")
                            Self.log("☀️ [FN→UI] Fn+↑ → Parlaklık: \(newB)/4 (donanım zaten güncelledi)")
                        }
                        let eff = (self.activeEffectId == 0 || self.activeEffectId == 0xFF) ? 3 : self.activeEffectId
                        let entryOffset = 58 + Int(eff - 1) * 2
                        if entryOffset < 98 {
                            self.cachedLedProfile[entryOffset] = newB
                        }
                    } else if action == 0x02 {
                        let newB: UInt8 = activeBrightness > 0 ? activeBrightness - 1 : 0
                        DispatchQueue.main.async {
                            self.activeBrightness = newB
                            self.isLightsOff = (newB == 0)
                            UserDefaults.standard.set(newB, forKey: "savedBrightness")
                            UserDefaults.standard.set(newB == 0, forKey: "savedIsLightsOff")
                            Self.log("🔅 [FN→UI] Fn+↓ → Parlaklık: \(newB)/4 (donanım zaten güncelledi)")
                        }
                        let eff = (self.activeEffectId == 0 || self.activeEffectId == 0xFF) ? 3 : self.activeEffectId
                        let entryOffset = 58 + Int(eff - 1) * 2
                        if entryOffset < 98 {
                            self.cachedLedProfile[entryOffset] = newB
                        }
                    }
                    return

                case 0x04: // Fn+Right/Left: Hız
                    // Klavye hardware'ı zaten hızı değiştirdi — sadece UI'ı senkronize et
                    if action == 0x01 {
                        let newS = min(UInt8(4), activeSpeed &+ 1)
                        DispatchQueue.main.async {
                            self.activeSpeed = newS
                            UserDefaults.standard.set(newS, forKey: "savedSpeed")
                            Self.log("⚡️ [FN→UI] Fn+→ → Hız: \(newS)/4 (donanım zaten güncelledi)")
                        }
                        let eff = (self.activeEffectId == 0 || self.activeEffectId == 0xFF) ? 3 : self.activeEffectId
                        let entryOffset = 58 + Int(eff - 1) * 2
                        if entryOffset + 1 < 98 {
                            let currentColor = self.cachedLedProfile[entryOffset + 1] & 0x0F
                            self.cachedLedProfile[entryOffset + 1] = (newS << 4) | currentColor
                        }
                    } else if action == 0x02 {
                        let newS: UInt8 = activeSpeed > 0 ? activeSpeed - 1 : 0
                        DispatchQueue.main.async {
                            self.activeSpeed = newS
                            UserDefaults.standard.set(newS, forKey: "savedSpeed")
                            Self.log("🐢 [FN→UI] Fn+← → Hız: \(newS)/4 (donanım zaten güncelledi)")
                        }
                        let eff = (self.activeEffectId == 0 || self.activeEffectId == 0xFF) ? 3 : self.activeEffectId
                        let entryOffset = 58 + Int(eff - 1) * 2
                        if entryOffset + 1 < 98 {
                            let currentColor = self.cachedLedProfile[entryOffset + 1] & 0x0F
                            self.cachedLedProfile[entryOffset + 1] = (newS << 4) | currentColor
                        }
                    }
                    return

                case 0x07: // Fn+Backspace: Efekt Döngüsü
                    let effectList: [UInt8] = Array(1...19)
                    let cur = effectList.firstIndex(of: activeEffectId) ?? 0
                    let next = effectList[(cur + 1) % effectList.count]
                    applyLighting(effect: next, speed: activeSpeed, brightness: activeBrightness,
                                  red: 250, green: 45, blue: 97)
                    Self.log("🔄 [FN] Fn+Backspace → Efekt: \(next)")
                    return

                default:
                    Self.log("❓ [FN] Grup=0x08 sub=0x\(String(format:"%02X",sub)) bilinmiyor")
                    return
                }
            }

            // ── Tek-Bayt LED Kısayolları ──
            let effectList: [UInt8] = [1, 3, 2, 19, 15, 13, 20, 16, 18, 5, 7, 14, 12, 8, 28, 30, 17, 29]
            switch group {
            case 0x46: // Fn+': Renk Önceki
                Self.log("🎨 [FN] Fn+\' → Renk Önceki")
                return
            case 0x47: // Fn+;: Renk Sonraki
                Self.log("🎨 [FN] Fn+; → Renk Sonraki")
                return
            case 0x48: // Fn+/: Renk Seçici
                Self.log("🎨 [FN] Fn+/ → Renk Seçici")
                return
            case 0x4A: // Fn+[: Efekt Önceki
                let cur = effectList.firstIndex(of: activeEffectId) ?? 0
                let prev = effectList[(cur + effectList.count - 1) % effectList.count]
                applyLighting(effect: prev, speed: activeSpeed, brightness: activeBrightness,
                              red: 250, green: 45, blue: 97)
                Self.log("⏮️ [FN] Fn+[ → Efekt Önceki → \(prev)")
                return
            case 0x4D: // Fn+]: Efekt Sonraki
                let cur2 = effectList.firstIndex(of: activeEffectId) ?? 0
                let next2 = effectList[(cur2 + 1) % effectList.count]
                applyLighting(effect: next2, speed: activeSpeed, brightness: activeBrightness,
                              red: 250, green: 45, blue: 97)
                Self.log("⏭️ [FN] Fn+] → Efekt Sonraki → \(next2)")
                return
            default:
                Self.log("❓ [FN] Bilinmeyen kısayol byte: 0x\(String(format:"%02X",group))")
                return
            }
        }

        // 5. Donanım Aydınlatma Telemetrisi (Fn+\ veya Knob ile ışık/efekt değiştiğinde)
        if reportID == 0x04 || (buffer.count >= 4 && buffer[0] == 0x04) {
            let offset = (buffer[0] == 0x04) ? 1 : 0
            guard buffer.count >= offset + 3 else { return }
            let effect = buffer[offset]
            let speed = buffer[offset + 1]
            let brightness = buffer[offset + 2]

            // Tüm baytlar 0x00 ise bu bir tuş bırakma (release/idle) paketidir; GERÇEK IŞIK AYARINI EZME!
            if effect == 0 && speed == 0 && brightness == 0 {
                return
            }

            // Yalnızca geçerli donanım telemetrisi geldiğinde UI'ı güncelle
            // NOT: isLightsOff sadece brightness==0 ise true olmalı; effect==0 tek başına ışık kapalı anlamına gelmez.
            DispatchQueue.main.async {
                if effect > 0 { self.activeEffectId = effect } // Geçerli effect varsa güncelle
                self.activeSpeed = speed
                self.activeBrightness = min(4, brightness)
                self.isLightsOff = (brightness == 0)
                UserDefaults.standard.set(self.isLightsOff, forKey: "savedIsLightsOff")
                UserDefaults.standard.set(self.activeBrightness, forKey: "savedBrightness")
                UserDefaults.standard.set(self.activeSpeed, forKey: "savedSpeed")
                Self.log("💡 [Canlı Donanım Aydınlatması] Efekt: \(effect), Hız: \(speed), Parlaklık: \(brightness)")
            }
            return
        }
    }

    // Cihaza Feature Report fırlatan fonksiyon (Report ID 0x06)
    @discardableResult
    func sendFeatureReport(reportID: UInt8 = 0x06, data: [UInt8]) -> IOReturn {
        guard let device = keyboardDevice else {
            print("❌ Bağlı klavye bulunamadı!")
            return kIOReturnNotOpen
        }

        var reportBytes = data
        reportBytes.insert(reportID, at: 0)
        let reportCount = reportBytes.count

        var result = reportBytes.withUnsafeMutableBytes { pointer in
            guard let baseAddress = pointer.baseAddress else { return kIOReturnBadArgument }
            return IOHIDDeviceSetReport(
                device,
                kIOHIDReportTypeFeature,
                CFIndex(reportID),
                baseAddress,
                reportCount
            )
        }

        if result == -536870195 /* kIOReturnNotOpen */ {
            Self.log("⚠️ [IOKit] Cihaz açık değil (kIOReturnNotOpen), IOHIDDeviceOpen deneniyor...")
            if ensureDeviceOpen(device) {
                result = reportBytes.withUnsafeMutableBytes { pointer in
                    guard let baseAddress = pointer.baseAddress else { return kIOReturnBadArgument }
                    return IOHIDDeviceSetReport(
                        device,
                        kIOHIDReportTypeFeature,
                        CFIndex(reportID),
                        baseAddress,
                        reportCount
                    )
                }
            }
        }

        if result == kIOReturnSuccess {
            print("✅ Feature [0x\(String(format: "%02X", reportID))] başarıyla gönderildi: \(reportBytes.map { String(format: "%02X", $0) }.joined(separator: " "))")
        } else {
            print("❌ Feature Report gönderilemedi: \(Self.describeIOReturn(result))")
        }
        return result
    }

    // Cihaza Output Report fırlatan fonksiyon (Report ID 0x13)
    @discardableResult
    func sendOutputReport(reportID: UInt8 = 0x13, data: [UInt8]) -> IOReturn {
        guard let device = keyboardDevice else {
            print("❌ Bağlı klavye bulunamadı!")
            return kIOReturnNotOpen
        }

        var reportBytes = data
        reportBytes.insert(reportID, at: 0)
        let reportCount = reportBytes.count

        var result = reportBytes.withUnsafeMutableBytes { pointer in
            guard let baseAddress = pointer.baseAddress else { return kIOReturnBadArgument }
            return IOHIDDeviceSetReport(
                device,
                kIOHIDReportTypeOutput,
                CFIndex(reportID),
                baseAddress,
                reportCount
            )
        }

        if result == -536870195 /* kIOReturnNotOpen */ {
            Self.log("⚠️ [IOKit] Cihaz açık değil (kIOReturnNotOpen), IOHIDDeviceOpen deneniyor...")
            if ensureDeviceOpen(device) {
                result = reportBytes.withUnsafeMutableBytes { pointer in
                    guard let baseAddress = pointer.baseAddress else { return kIOReturnBadArgument }
                    return IOHIDDeviceSetReport(
                        device,
                        kIOHIDReportTypeOutput,
                        CFIndex(reportID),
                        baseAddress,
                        reportCount
                    )
                }
            }
        }

        if result == kIOReturnSuccess {
            Self.log("✅ Output [0x\(String(format: "%02X", reportID))] başarıyla gönderildi: \(reportBytes.map { String(format: "%02X", $0) }.joined(separator: " "))")
        } else {
            Self.log("❌ Output Report gönderilemedi: \(Self.describeIOReturn(result))")
        }
        return result
    }

    /// Safe, read-only protocol probe. It mirrors the confirmed Windows flow:
    /// SetFeature report 0x05 (83 B6 00 00 00 00), then GetFeature report 0x06.
    /// No response fields are interpreted until their layout has been decoded.
    func readCurrentConfig() {
        guard let device = keyboardDevice else {
            configLoadStatus = "Config Load için bağlı cihaz yok."
            return
        }

        hidQueue.async { [weak self] in
            guard let self else { return }
            do {
                let snapshot = try KeyboardProtocol(transport: HIDFeatureTransport(device: device)).loadConfig()
                let preview = snapshot.rawResponse.prefix(32).map { String(format: "%02X", $0) }.joined(separator: " ")
                Self.log("📋 [Config Load] \(snapshot.rawResponse.count) byte alındı: \(preview)…")
                DispatchQueue.main.async {
                    self.lastHardwareConfig = preview
                    self.configLoadStatus = "Başarılı — \(snapshot.rawResponse.count) byte ham config alındı."
                }
            } catch {
                Self.log("❌ [Config Load] \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.configLoadStatus = "Başarısız — \(error.localizedDescription)"
                }
            }
        }
    }

    // Klavyeye mevcut aydınlatma durumunu sorar (Güvenli Read/Query)
    func queryCurrentLighting() {
        guard isConnected, let device = keyboardDevice else { return }
        let now = Date()
        guard now.timeIntervalSince(lastQueryTime) > 2.0 else {
            Self.log("⏳ [Aydınlatma Sorgusu] Çok sık sorgu engellendi (spam koruması).")
            return
        }
        lastQueryTime = now

        Self.log("🔍 [Aydınlatma Sorgusu] Klavyeye aydınlatma durumu sorgusu gönderiliyor...")
        if connectionType == .wireless24G {
            let pkt = KeyboardCommand.createGetLEDPacket()
            sendOutputReport(reportID: 0x13, data: Array(pkt.dropFirst()))
        } else if connectionType == .wiredUSB {
            // Sniff Paket 405 doğrulaması: 06 84 00 00 01 00 80 00 (GetLED)
            var getReq = KeyboardCommand.createWiredGetLEDPacket()
            let res = getReq.withUnsafeMutableBytes { ptr in
                IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
            }
            if res == kIOReturnSuccess {
                Self.log("🔍 [Aydınlatma Sorgusu] Kablolu GetLED (0x06 0x84) talebi iletildi")
            } else {
                Self.log("⚠️ [Aydınlatma Sorgusu] Kablolu GetLED başarısız: \(Self.describeIOReturn(res))")
            }
        }
    }

    /// 128-Baytlık tam profili bağlantı türüne göre güvenle donanıma ileten yardımcı fonksiyon
    private func sendLedProfileToDevice(_ profile: [UInt8], capturedDev: IOHIDDevice?, connType: ConnectionType) {
        guard let device = capturedDev, connType != .disconnected else {
            Self.log("⚠️ [SendProfile] Gönderim atlandı — bağlantı yok veya cihaz geçersiz")
            return
        }
        
        if connType == .wiredUSB {
            // Sniff Paket 409 doğrulaması: Kablolu USB modunda Feature Report 0x06 (136 bayt)
            var wiredPacket = KeyboardCommand.createWiredSetLEDPacket(payload: profile)
            var res = wiredPacket.withUnsafeMutableBytes { ptr in
                IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
            }
            if res == -536870195 /* kIOReturnNotOpen */ {
                Self.log("⚠️ [SendProfile-Wired] Cihaz açık değil, IOHIDDeviceOpen deneniyor...")
                if ensureDeviceOpen(device) {
                    res = wiredPacket.withUnsafeMutableBytes { ptr in
                        IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
                    }
                }
            }
            if res == kIOReturnSuccess {
                Self.log("✅ [SendProfile-Wired] Feature Report 0x06 iletildi (\(wiredPacket.count) bayt)")
            } else {
                Self.log("❌ [SendProfile-Wired] Feature Report 0x06 başarısız: \(Self.describeIOReturn(res))")
            }
        } else {
            // Kablosuz (2.4G) modda: Output Report 0x13 ile 10 adet dilim paket (her biri 14B)
            let packets = KeyboardCommand.createSlicedPackets(cmd: KeyboardCommand.cmdSetLED, payload: profile)
            Self.log("📤 [SendProfile-Wireless] \(packets.count) dilim paket gönderiliyor...")
            for pkt in packets {
                var reportBytes = Array(pkt.dropFirst())
                reportBytes.insert(0x13, at: 0)
                var res = reportBytes.withUnsafeMutableBytes { ptr in
                    IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, CFIndex(0x13), ptr.baseAddress!, ptr.count)
                }
                if res == -536870195 /* kIOReturnNotOpen */ {
                    if ensureDeviceOpen(device) {
                        res = reportBytes.withUnsafeMutableBytes { ptr in
                            IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, CFIndex(0x13), ptr.baseAddress!, ptr.count)
                        }
                    }
                }
                if res != kIOReturnSuccess {
                    Self.log("❌ [SendProfile-Wireless] Dilim paket gönderilemedi: \(KeyboardManager.describeIOReturn(res))")
                    break
                }
                usleep(12000)
            }
        }
    }

    /// Kablolu USB modunda tek renk seçiminde Feature Report 0x06 (520 bayt) özel renk paketini iletir
    private func sendColorPacketToDevice(r: UInt8, g: UInt8, b: UInt8, capturedDev: IOHIDDevice?) {
        guard let device = capturedDev, connectionType == .wiredUSB else { return }
        var colorPkt = KeyboardCommand.createWiredColorPacket(r: r, g: g, b: b)
        var res = colorPkt.withUnsafeMutableBytes { ptr in
            IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
        }
        if res == -536870195 /* kIOReturnNotOpen */ {
            Self.log("⚠️ [ColorPacket-Wired] Cihaz açık değil, IOHIDDeviceOpen deneniyor...")
            if ensureDeviceOpen(device) {
                res = colorPkt.withUnsafeMutableBytes { ptr in
                    IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
                }
            }
        }
        if res == kIOReturnSuccess {
            Self.log("🎨 [ColorPacket-Wired] Özel RGB (\(r),\(g),\(b)) iletildi (520 bayt)")
        } else {
            Self.log("⚠️ [ColorPacket-Wired] Özel RGB gönderimi: \(Self.describeIOReturn(res))")
        }
    }

    // Aydınlatmayı donanıma uygulayan ana metod
    func applyLighting(effect: UInt8, speed: UInt8, brightness: UInt8, red: UInt8, green: UInt8, blue: UInt8, isMulticolor: Bool = false) {
        Self.log("💡 Aydınlatma uygulanıyor -> Efekt: \(effect), Hız: \(speed), Parlaklık: \(brightness), RGB: (\(red), \(green), \(blue)), Çok Renkli: \(isMulticolor)")

        // 1. Kapalı kontrolü (LedOpt20 standardı)
        if effect == LightingEffect.off.rawValue || brightness == 0 || effect == 0 {
            turnOffLights()
            return
        }

        // Sıfırlanmış tamponu şablondan yeniden yükle
        if cachedLedProfile[56] == 0 && cachedLedProfile[57] == 0 {
            cachedLedProfile = KeyboardCommand.defaultLedProfileTemplate()
        }

        let safeEffect = max(UInt8(1), min(UInt8(19), effect))
        let safeSpeed = min(UInt8(4), speed)
        let safeBrightness = min(UInt8(4), brightness)

        // 2. Sniff doğrulamalı donanım güncellemesi:
        // Byte 1: Aktif Efekt İndeksi (1..19)
        cachedLedProfile[1] = safeEffect
        // Byte 2: Hız (0..4)
        cachedLedProfile[2] = safeSpeed
        // Byte 3: Parlaklık (0..4)
        cachedLedProfile[3] = safeBrightness
        // Byte 4: Yön (0)
        cachedLedProfile[4] = 0x00
        
        // Çok renkli / spektrum tabanlı efekt kontrolü
        let isRainbow = isMulticolor ||
                        (safeEffect == LightingEffect.rainbow.rawValue) ||
                        (safeEffect == LightingEffect.rainbowWheel.rawValue) ||
                        (safeEffect == LightingEffect.neonStream.rawValue) ||
                        (safeEffect == LightingEffect.waterfall.rawValue)
        
        // Donanımsal Renk Modu İndeksi (Vision/EVision MCU dahili renk donanım eşleşmesi):
        // 0: Kırmızı, 1: Yeşil, 2: Mavi, 3: Sarı/Turuncu, 4: Mor, 5: Cyan, 6: Beyaz, 7: Gökkuşağı / Çok Renkli
        let colorNibble: UInt8 = isRainbow ? 0x07 : Self.paletteIndex(r: red, g: green, b: blue, isRainbow: false)
        
        // Byte 8: Donanımsal Renk Kontrol İndeksi (Sniff 635/645'te her zaman 0x07)
        cachedLedProfile[8] = 0x07
        // Byte 10: Aktif Efekt İndeksi
        cachedLedProfile[10] = safeEffect

        // Efekt Tablosu Ofseti: 58 + (AktifEfekt - 1) * 2
        let entryOffset = 58 + Int(safeEffect - 1) * 2

        if entryOffset + 1 < 98 {
            cachedLedProfile[entryOffset] = safeBrightness
            cachedLedProfile[entryOffset + 1] = (safeSpeed << 4) | (colorNibble & 0x0F)
        }

        // Donanım onay imzası
        cachedLedProfile[126] = 0x5A
        cachedLedProfile[127] = 0xA5

        // 3. UI durumunu hemen güncelle (bloklamadan)
        DispatchQueue.main.async {
            self.activeEffectId = safeEffect
            self.activeSpeed = safeSpeed
            self.activeBrightness = safeBrightness
            self.isLightsOff = false
            self.activeMusicMode = nil
            UserDefaults.standard.set(false, forKey: "savedIsLightsOff")
            UserDefaults.standard.set(safeBrightness, forKey: "savedBrightness")
            UserDefaults.standard.set(safeSpeed, forKey: "savedSpeed")
        }

        // 4. HID gönderimi — ARKA PLAN kuyruğunda
        let profileSnapshot = cachedLedProfile
        let connType = connectionType
        let capturedDev = keyboardDevice
        let isSingleColor = !isRainbow && (connType == .wiredUSB)

        hidQueue.async { [weak self, capturedDev, profileSnapshot] in
            guard let self = self else { return }
            if isSingleColor {
                self.sendColorPacketToDevice(r: red, g: green, b: blue, capturedDev: capturedDev)
                usleep(60000) // 60ms MCU Flash yazma güvenliği
            }
            self.sendLedProfileToDevice(profileSnapshot, capturedDev: capturedDev, connType: connType)
        }
    }

    /// Donanım dahili renk paleti eşleme fonksiyonu (Vision MCU Donanımsal Renk Kodları):
    /// 0: Kırmızı, 1: Yeşil, 2: Mavi, 3: Sarı/Turuncu, 4: Mor/Pembe, 5: Cyan/Açık Mavi, 6: Beyaz, 7: Gökkuşağı
    static func paletteIndex(r: UInt8, g: UInt8, b: UInt8, isRainbow: Bool) -> UInt8 {
        if isRainbow { return 0x07 }
        
        let rf = Double(r) / 255.0
        let gf = Double(g) / 255.0
        let bf = Double(b) / 255.0
        
        let maxV = max(rf, gf, bf)
        let minV = min(rf, gf, bf)
        let delta = maxV - minV
        
        // Nötr / Beyaz / Düşük doygunluk -> Beyaz (Index 6)
        if delta < 0.15 {
            return 0x06
        }
        
        var hue: Double = 0
        if maxV == rf {
            hue = (gf - bf) / delta
            if hue < 0 { hue += 6 }
        } else if maxV == gf {
            hue = ((bf - rf) / delta) + 2
        } else {
            hue = ((rf - gf) / delta) + 4
        }
        hue *= 60.0
        
        switch hue {
        case 15..<75:
            return 0x03 // Sarı & Turuncu (Donanım Preset 3 = Sarı)
        case 75..<165:
            return 0x01 // Yeşil (Donanım Preset 1 = Yeşil)
        case 165..<205:
            return 0x05 // Cyan / Açık Mavi (Donanım Preset 5 = Cyan)
        case 205..<260:
            return 0x02 // Mavi (Donanım Preset 2 = Mavi)
        case 260..<345:
            return 0x04 // Mor / Pembe (Donanım Preset 4 = Mor)
        default:
            return 0x00 // Kırmızı (Donanım Preset 0 = Kırmızı)
        }
    }

    // Yan Şerit Aydınlatmasını (Side LED) uygulayan metod (Ghidra FUN_0049bc50 analizi)
    func applySideLED(effect: UInt8, speed: UInt8, brightness: UInt8, red: UInt8, green: UInt8, blue: UInt8) {
        Self.log("🌈 Yan Şerit LED uygulanıyor -> Efekt: \(effect), Hız: \(speed), Parlaklık: \(brightness)")
        
        // Ghidra FUN_0049bc50 donanım profil ofsetleri:
        // 0x12 = Mode, 0x13 = Color, 0x14 = nLight (Parlaklık: 0..4), 0x15 = nSpeed (0..4)
        cachedLedProfile[0x12] = effect
        cachedLedProfile[0x13] = 7 // Gökkuşağı/Varsayılan renk
        cachedLedProfile[0x14] = brightness
        cachedLedProfile[0x15] = speed
        cachedLedProfile[126] = 0x5A
        cachedLedProfile[127] = 0xA5
        
        let sideProfileSnapshot = cachedLedProfile
        let sideConnType = connectionType
        let capturedDev = keyboardDevice
        hidQueue.async { [weak self, capturedDev, sideProfileSnapshot] in
            guard let self = self else { return }
            self.sendLedProfileToDevice(sideProfileSnapshot, capturedDev: capturedDev, connType: sideConnType)
        }
        
        DispatchQueue.main.async {
            self.sideLedEffect = SideLEDEffect(rawValue: effect) ?? .streaming
            self.sideLedSpeed = speed
            self.sideLedBrightness = brightness
            self.sideLedRed = red
            self.sideLedGreen = green
            self.sideLedBlue = blue
        }
    }

    // Işıkları tamamen kapatma veya açma (Toggle Lights)
    func toggleLights() {
        if isLightsOff || activeBrightness == 0 {
            // Aç: 2. kademede aç
            turnOnLights(level: 2)
        } else {
            turnOffLights()
        }
    }

    // Işıkları tamamen kapat (OFF - Sniff Paket 403 / LedOpt20: 0,0,0,0,0,0,0)
    func turnOffLights() {
        Self.log("🌑 Işıklar tamamen kapatılıyor (LedOpt20 standardı)...")
        
        // Sniff Paket 403 ve 287 teyidi:
        // 0..125 arası TÜMÜ 0x00, 126..127 donanım onay imzası 0x5A, 0xA5
        cachedLedProfile = [UInt8](repeating: 0, count: 128)
        cachedLedProfile[126] = 0x5A
        cachedLedProfile[127] = 0xA5
        
        DispatchQueue.main.async {
            self.activeBrightness = 0
            self.isLightsOff = true
            UserDefaults.standard.set(true, forKey: "savedIsLightsOff")
            UserDefaults.standard.set(UInt8(0), forKey: "savedBrightness")
        }
        
        pendingLightingItem?.cancel()
        let offSnapshot = cachedLedProfile
        let connType = connectionType
        let capturedDev = keyboardDevice
        let item = DispatchWorkItem { [weak self, offSnapshot, capturedDev] in
            guard let self = self else { return }
            self.sendLedProfileToDevice(offSnapshot, capturedDev: capturedDev, connType: connType)
        }
        pendingLightingItem = item
        hidQueue.async(execute: item)
    }

    // Işıkları aç
    func turnOnLights(level: UInt8 = 2) {
        let safeLevel = max(1, min(4, level))
        let eff = (activeEffectId == 0 || activeEffectId == 0xFF) ? 3 : activeEffectId
        Self.log("💡 Işıklar açılıyor (Efekt: \(eff), Kademe: \(safeLevel)/4)...")
        applyLighting(effect: eff, speed: activeSpeed, brightness: safeLevel, red: 250, green: 45, blue: 97)
    }

    // Doğrudan donanımsal kademe ayarlama (0..4)
    func setBrightnessLevel(_ level: UInt8) {
        let safeLevel = min(UInt8(4), max(UInt8(0), level))
        Self.log("☀️ Parlaklık kademesi: \(safeLevel)/4")
        if safeLevel == 0 {
            turnOffLights()
        } else {
            applyLightingQuick(brightness: safeLevel)
        }
    }

    /// Hızlı Işık Güncelleme: UI'ı anında günceller, tam profili arka planda gönderir.
    func applyLightingQuick(brightness: UInt8? = nil, speed: UInt8? = nil) {
        let newB = brightness ?? activeBrightness
        let newS = speed ?? activeSpeed
        if newB == 0 {
            turnOffLights()
            return
        }
        
        if cachedLedProfile[56] == 0 && cachedLedProfile[57] == 0 {
            cachedLedProfile = KeyboardCommand.defaultLedProfileTemplate()
        }

        let eff = (activeEffectId == 0 || activeEffectId == 0xFF) ? 3 : activeEffectId
        cachedLedProfile[10] = eff

        let entryOffset = 58 + Int(eff - 1) * 2
        if entryOffset + 1 < 98 {
            cachedLedProfile[entryOffset] = newB
            let currentColor = cachedLedProfile[entryOffset + 1] & 0x0F
            cachedLedProfile[entryOffset + 1] = (newS << 4) | currentColor
        }
        cachedLedProfile[126] = 0x5A
        cachedLedProfile[127] = 0xA5

        DispatchQueue.main.async {
            self.activeBrightness = newB
            self.activeSpeed = newS
            self.isLightsOff = false
            self.activeEffectId = eff
            UserDefaults.standard.set(false, forKey: "savedIsLightsOff")
            UserDefaults.standard.set(newB, forKey: "savedBrightness")
            UserDefaults.standard.set(newS, forKey: "savedSpeed")
        }

        pendingLightingItem?.cancel()
        let quickSnapshot = cachedLedProfile
        let qConnType = connectionType
        let capturedDevice = keyboardDevice
        let item = DispatchWorkItem { [weak self, quickSnapshot, capturedDevice] in
            guard let self = self else { return }
            self.sendLedProfileToDevice(quickSnapshot, capturedDev: capturedDevice, connType: qConnType)
        }
        pendingLightingItem = item
        hidQueue.asyncAfter(deadline: .now() + 0.05, execute: item) // 50ms debounce
    }

    // Müzik Senkronizasyonunu başlatan/uygulayan metod (Sniff Paket 781 / 827 doğrulaması)
    func applyMusicSync(mode: MusicSyncMode) {
        Self.log("🎵 Müzik Senkronizasyon modu seçildi: \(mode.name) (ID: \(mode.rawValue))")
        
        musicStreamTimer?.cancel()
        musicStreamTimer = nil
        
        DispatchQueue.main.async {
            self.activeMusicMode = mode
        }
        
        guard connectionType == .wiredUSB, let device = keyboardDevice else {
            Self.log("ℹ️ Müzik matrisi canlı akışı kablolu USB bağlantısında aktiftir.")
            return
        }
        
        let timer = DispatchSource.makeTimerSource(queue: hidQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(50)) // 20 FPS canlı akış
        timer.setEventHandler { [weak self, weak device] in
            guard let self = self, let dev = device else { return }
            self.musicPhase += 0.2
            
            // 126 tuş için canlı RGB matris verisi üret (378 bayt = 126 tuş * 3B)
            var rgb = [UInt8](repeating: 0, count: 378)
            let phase = self.musicPhase
            let modeId = mode.rawValue
            
            for key in 0..<126 {
                let norm = Double(key) / 126.0
                var r: Double = 0
                var g: Double = 0
                var b: Double = 0
                
                switch modeId {
                case 2: // Parlak - Rock (Kırmızı/Turuncu ritmik vuruşlar)
                    let beat = max(0, sin(phase * 3.0 + norm * 4.0))
                    r = beat * 255.0
                    g = beat * 60.0
                    b = 0
                case 3: // Bulutlar & Kar (Mavi/Beyaz dalgalanma)
                    let wave = 0.5 + 0.5 * sin(phase * 2.0 + norm * 6.0)
                    r = wave * 180.0
                    g = wave * 220.0
                    b = 255.0
                default: // Spektrum / Gökkuşağı ritim dalgası
                    let angle = phase + norm * 2.0 * .pi
                    r = (sin(angle) * 0.5 + 0.5) * 255.0
                    g = (sin(angle + 2.0 * .pi / 3.0) * 0.5 + 0.5) * 255.0
                    b = (sin(angle + 4.0 * .pi / 3.0) * 0.5 + 0.5) * 255.0
                }
                
                rgb[key * 3] = UInt8(max(0, min(255, r)))
                rgb[key * 3 + 1] = UInt8(max(0, min(255, g)))
                rgb[key * 3 + 2] = UInt8(max(0, min(255, b)))
            }
            
            // Sniff Paket 781/827 formatı: Feature Report 0x06, Cmd 0x08, Len 378
            var framePkt = KeyboardCommand.createMusicFramePacket(rgbData: rgb)
            framePkt.withUnsafeMutableBytes { ptr in
                IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
            }
        }
        
        self.musicStreamTimer = timer
        timer.resume()
    }

    // Müzik Senkronizasyonunu durduran metod (Sniff Paket 823/841 doğrulaması: normal profile dönüş)
    func stopMusicSync() {
        Self.log("⏹️ Müzik Senkronizasyonu durduruluyor, normal donanım profiline dönülüyor...")
        musicStreamTimer?.cancel()
        musicStreamTimer = nil
        
        DispatchQueue.main.async {
            self.activeMusicMode = nil
        }
        
        // Sniff Paket 841: Müzik akışı durduğunda 06 04 SetLED ile normal aydınlatmayı geri yükle
        let eff = (activeEffectId == 0 || activeEffectId == 0xFF) ? 3 : activeEffectId
        applyLighting(effect: eff, speed: activeSpeed, brightness: activeBrightness, red: 250, green: 45, blue: 97)
    }

    /// Kullanıcı Tanımlı Özel Tuş Renklerini Uygulayan Metod (Sniff Paket 851/861/867 doğrulaması)
    func applyCustomKeyColors(rgbData: [UInt8]) {
        Self.log("🎨 Özel tuş renkleri uygulanıyor (126 tuş matrisi)...")
        
        musicStreamTimer?.cancel()
        musicStreamTimer = nil
        
        guard connectionType == .wiredUSB, let device = keyboardDevice else {
            Self.log("ℹ️ Özel tuş renk matrisi kablolu USB modunda uygulanabilir.")
            return
        }
        
        // 1. 06 06 paketi ile 126 tuşun RGB haritasını klavyeye gönder (Sniff 851/861)
        var matrixPkt = KeyboardCommand.createCustomColorMatrixPacket(rgbData: rgbData)
        let res = matrixPkt.withUnsafeMutableBytes { ptr in
            IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
        }
        if res == kIOReturnSuccess {
            Self.log("✅ [CustomMatrix] 126 tuş RGB renk haritası iletildi (520 bayt)")
        } else {
            Self.log("⚠️ [CustomMatrix] Gönderim sonucu: \(Self.describeIOReturn(res))")
        }
        
        usleep(15000)
        
        // 2. Sniff Paket 857/867: Profilde Byte 9 = 0x01, Byte 10 = 0x15 (21) yaparak LedOpt19 Özel Modu aktif et
        if cachedLedProfile[56] == 0 && cachedLedProfile[57] == 0 {
            cachedLedProfile = KeyboardCommand.defaultLedProfileTemplate()
        }
        cachedLedProfile[9] = 0x01
        cachedLedProfile[10] = 0x15 // 21 (LedOpt19)
        cachedLedProfile[126] = 0x5A
        cachedLedProfile[127] = 0xA5
        
        let profileSnapshot = cachedLedProfile
        let connType = connectionType
        let capturedDev = keyboardDevice
        hidQueue.async { [weak self, capturedDev, profileSnapshot] in
            guard let self = self else { return }
            self.sendLedProfileToDevice(profileSnapshot, capturedDev: capturedDev, connType: connType)
        }
        
        DispatchQueue.main.async {
            self.activeEffectId = 21
            self.isLightsOff = false
        }
    }

    // Uyku Süresi Ayarlama (Sniff Paket 689/697 doğrulaması: 24. bayt, 30 saniyelik adımlar)
    func setSleepTimeout(seconds: Int) {
        Self.log("⏱️ Uyku süresi ayarlanıyor: \(seconds) saniye")
        
        let safeSeconds = max(0, min(1200, seconds))
        let sleepUnits = UInt8(safeSeconds / 30) // 0=Asla, 1=30sn, 2=1dk, 6=3dk, 40=20dk
        
        // 1. Kalıcı 128 baytlık profil tamponunun 24. baytına yaz
        if cachedLedProfile[56] == 0 && cachedLedProfile[57] == 0 {
            cachedLedProfile = KeyboardCommand.defaultLedProfileTemplate()
        }
        cachedLedProfile[24] = sleepUnits
        cachedLedProfile[126] = 0x5A
        cachedLedProfile[127] = 0xA5
        
        DispatchQueue.main.async {
            self.sleepTimeoutSeconds = safeSeconds
            UserDefaults.standard.set(safeSeconds, forKey: "savedSleepTimeout")
        }
        
        // 2. Donanıma hem USB Feature Report hem de 2.4G üzerinden tam profili ilet
        let profileSnapshot = cachedLedProfile
        let capturedDev = keyboardDevice
        let connType = connectionType
        hidQueue.async { [weak self, capturedDev, profileSnapshot] in
            guard let self = self else { return }
            self.sendLedProfileToDevice(profileSnapshot, capturedDev: capturedDev, connType: connType)
        }
    }

    // Tuş Çakışma Önleme (Debounce) Ayarlama
    func setDebounceTime(ms: Int) {
        print("🛡️ Tuş gecikme filtresi (Debounce): \(ms) ms")
        let pkt = KeyboardCommand.createDebouncePacket(debounceMs: UInt8(ms))
        sendOutputReport(reportID: 0x13, data: Array(pkt.dropFirst()))
        
        DispatchQueue.main.async {
            self.debounceTimeMs = ms
        }
    }

    // Döner Tekerlek (Knob / Wheel) Modu
    func setWheelMode(_ mode: WheelMode) {
        DispatchQueue.main.async {
            self.wheelMode = mode
        }
        let pkt = KeyboardCommand.createWheelModePacket(mode: mode.rawValue)
        sendOutputReport(reportID: 0x13, data: Array(pkt.dropFirst()))
        Self.log("🎛️ [Döner Tekerlek] Donanıma Mod Paketi Gönderildi: \(mode.name) (0x\(String(format: "%02X", mode.rawValue)))")
    }

    func toggleWheelMode() {
        let nextMode: WheelMode = (self.wheelMode == .volume) ? .backlight : .volume
        setWheelMode(nextMode)
    }

    // İşletim Sistemi Modu (Donanım Fn+S / Fn+A ile değiştirilir, burada UI güncellenir)
    func setPlatformMode(macMode: Bool) {
        DispatchQueue.main.async {
            self.isMacMode = macMode
        }
    }

    // Fabrika Ayarlarına Sıfırla (Sniff Paket 881, 883, 885, 887, 897 doğrulaması)
    func resetToFactoryDefaults() {
        Self.log("🔄 [FactoryReset] Klavye orijinal donanım fabrika ayarlarına sıfırlanıyor...")

        guard let dev = keyboardDevice else {
            Self.log("❌ [FactoryReset] Bağlı klavye bulunamadı!")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // 1. Layer 0 (Base) Orijinal Fabrika Tuş Matrisi (Sniff 881)
            var p0 = KeyboardCommand.createFactoryLayer0Packet()
            p0.withUnsafeMutableBytes { ptr in
                IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
            }
            usleep(15000)

            // 2. Layer 1 (FN1) Orijinal Fonksiyon Matrisi (Sniff 883)
            var p1 = KeyboardCommand.createFactoryLayer1Packet()
            p1.withUnsafeMutableBytes { ptr in
                IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
            }
            usleep(15000)

            // 3. Layer 2 (FN2) Sıfırlama Matrisi (Sniff 885)
            var p2 = KeyboardCommand.createFactoryLayer2Packet()
            p2.withUnsafeMutableBytes { ptr in
                IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
            }
            usleep(15000)

            // 4. Layer 3 (Tap) Sıfırlama Matrisi (Sniff 887)
            var p3 = KeyboardCommand.createFactoryLayer3Packet()
            p3.withUnsafeMutableBytes { ptr in
                IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
            }
            usleep(15000)

            // 5. Orijinal Fabrika LED & Uyku Profili (Sniff 897: NeonStream 11, Uyku 180s)
            var ledPkt = KeyboardCommand.createFactoryLedPacket()
            ledPkt.withUnsafeMutableBytes { ptr in
                IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
            }

            DispatchQueue.main.async {
                self.activeEffectId = 11 // NeonStream
                self.activeBrightness = 4
                self.activeSpeed = 4
                self.sleepTimeoutSeconds = 180
                self.debounceTimeMs = 8
                self.wheelMode = .volume
                self.activeMusicMode = nil
                self.statusMessage = "Klavyeniz fabrika çıkış ayarlarına döndürüldü"
                Self.log("✅ [FactoryReset] Tüm katmanlar ve donanım LED profili başarıyla sıfırlandı.")
            }
        }
    }

    // MARK: - Donanımsal Makro Yönetimi (Sniff Paket 871, 873, 875, 877, 879)

    /// Klavyenin dahili çipine makro tanımını (eylemler, süreler, isim) yazar (0x06 Cmd 0x05)
    @discardableResult
    func saveMacroToKeyboard(
        macroIndex: UInt8,
        name: String,
        actions: [KeyboardCommand.HardwareMacroAction]
    ) -> Bool {
        guard let dev = keyboardDevice else {
            Self.log("❌ [Macro] Makro gönderilemedi: Bağlı cihaz yok.")
            return false
        }
        
        var packet = KeyboardCommand.createMacroDefinitionPacket(
            macroIndex: macroIndex,
            name: name,
            actions: actions
        )
        
        let res = packet.withUnsafeMutableBytes { ptr in
            IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
        }
        
        if res == kIOReturnSuccess {
            Self.log("💾 [Macro] Makro #\(macroIndex + 1) ('\(name)') donanım hafızasına kaydedildi (\(actions.count) eylem).")
            return true
        } else {
            Self.log("❌ [Macro] Makro kaydedilemedi: \(Self.describeIOReturn(res))")
            return false
        }
    }

    /// Bir tuşa donanımsal makroyu bağlar (Sniff Paket 871 / 877)
    /// layer: 0=Base, 1=FN1, 2=FN2, 3=Tap
    /// loopCount: 1..255 (döngü sayısı)
    @discardableResult
    func assignMacroToKey(
        layer: UInt8,
        keyIndex: Int,
        macroId: UInt8,
        loopCount: UInt8
    ) -> Bool {
        guard let dev = keyboardDevice else {
            Self.log("❌ [MacroAssign] Atama yapılamadı: Bağlı cihaz yok.")
            return false
        }
        
        var packet = KeyboardCommand.createAssignMacroKeyPacket(
            layerIndex: layer,
            keyIndex: keyIndex,
            macroId: macroId,
            loopCount: loopCount
        )
        
        let res = packet.withUnsafeMutableBytes { ptr in
            IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
        }
        
        if res == kIOReturnSuccess {
            Self.log("🔗 [MacroAssign] Katman \(layer), Tuş \(keyIndex) -> Makro #\(macroId) (Döngü: \(loopCount)) atandı.")
            return true
        } else {
            Self.log("❌ [MacroAssign] Tuşa makro atanamadı: \(Self.describeIOReturn(res))")
            return false
        }
    }

    /// Tuşun atamasını kaldırıp varsayılana çevirir (Sniff Paket 875)
    @discardableResult
    func clearKeyAssignment(layer: UInt8, keyIndex: Int) -> Bool {
        guard let dev = keyboardDevice else { return false }
        
        var matrix = [UInt8](repeating: 0, count: 506)
        let slotOffset = keyIndex * 4
        if slotOffset + 3 < matrix.count {
            matrix[slotOffset] = 0x00
            matrix[slotOffset + 1] = 0x00
            matrix[slotOffset + 2] = 0x00
            matrix[slotOffset + 3] = 0x00
        }
        
        var packet = KeyboardCommand.createSetLayerMatrixPacket(layerIndex: layer, matrixData: matrix)
        let res = packet.withUnsafeMutableBytes { ptr in
            IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, CFIndex(0x06), ptr.baseAddress!, ptr.count)
        }
        
        if res == kIOReturnSuccess {
            Self.log("🧹 [MacroAssign] Katman \(layer), Tuş \(keyIndex) varsayılana sıfırlandı.")
            return true
        } else {
            Self.log("❌ [MacroAssign] Tuş sıfırlanamadı: \(Self.describeIOReturn(res))")
            return false
        }
    }

    static func describeIOReturn(_ code: IOReturn) -> String {
        let uCode = UInt32(bitPattern: code)
        let hex = String(format: "0x%08X", uCode)
        
        switch code {
        case kIOReturnSuccess:
            return "Başarılı (0x0)"
        case -536870195: // 0xE00002CD
            return "Hata (\(code) / \(hex)): kIOReturnNotOpen (Cihaz henüz açık değil veya bağlantı açılamadı)"
        case -536870174: // 0xE00002E2
            return "Hata (\(code) / \(hex)): kIOReturnNotPermitted (Erişim engellendi - App Sandbox veya Giriş İzleme izni gerekli)"
        case -536870207: // 0xE00002C1
            return "Hata (\(code) / \(hex)): kIOReturnExclusiveAccess (Cihaz başka bir işlem tarafından kilitli)"
        case -536850432: // 0xE0005000
            return "Hata (\(code) / \(hex)): kUSBHostReturnPipeStalled (USB STALL - Yanlış Report ID veya geçersiz paket uzunluğu)"
        case kIOReturnBadArgument:
            return "Hata (\(code) / \(hex)): kIOReturnBadArgument (Geçersiz parametre veya bellek adresi)"
        case kIOReturnUnsupported:
            return "Hata (\(code) / \(hex)): kIOReturnUnsupported (Bu rapor türü cihaz tarafından desteklenmiyor)"
        default:
            return "Hata Kodu: \(code) (Hex: \(hex))"
        }
    }
}
