import Foundation
import IOKit
import IOKit.hid
import Combine

class KeyboardManager: ObservableObject {
    private var hidManager: IOHIDManager?
    private var keyboardDevice: IOHIDDevice?
    
    @Published var isConnected: Bool = false

    init() {
        setupHIDManager()
    }

    private func setupHIDManager() {
        // HID yöneticisini başlatıyoruz
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = hidManager else { return }
        
        // Şimdilik tüm HID cihazlarını dinlemek için boş bırakıyoruz.
        // İleride belirli bir Vendor ID (VID) filtrelemesi de ekleyebiliriz.
        let matchingCriteria: [String: Any] = [:]
        
        IOHIDManagerSetDeviceMatching(manager, matchingCriteria as CFDictionary)
        
        // Cihaz bağlandığında tetiklenecek C-style callback köprüsü
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { (context, result, sender, device) in
            let manager = Unmanaged<KeyboardManager>.fromOpaque(context!).takeUnretainedValue()
            manager.handleDeviceConnected(device)
        }, context)
        
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        print("HID Manager başlatıldı, cihazlar dinleniyor...")
    }

    private func handleDeviceConnected(_ device: IOHIDDevice) {
        self.keyboardDevice = device
        
        // Arayüzün haberdar olması için ana thread üzerinde güncelliyoruz
        DispatchQueue.main.async {
            self.isConnected = true
            print("Klavye başarıyla algılandı ve bağlandı!")
        }
    }

    // Ghidra'da çözdüğümüz SetFeature komutunu cihaza fırlatan ana fonksiyon
    func sendFeatureReport(reportID: UInt8, data: [UInt8]) {
        guard let device = keyboardDevice else {
            print("Bağlı klavye bulunamadı!")
            return
        }

        var reportBytes = data
        reportBytes.insert(reportID, at: 0) // İlk bayt Report ID
        let reportCount = reportBytes.count

        let result = reportBytes.withUnsafeMutableBytes { pointer in
            guard let baseAddress = pointer.baseAddress else { return kIOReturnBadArgument }
            
            return IOHIDDeviceSetReport(
                device,
                kIOHIDReportTypeFeature,
                CFIndex(reportID),
                baseAddress,
                reportCount
            )
        }

        if result == kIOReturnSuccess {
            print("Komut başarıyla klavyeye gönderildi!")
        } else {
            print("Komut gönderilemedi, Hata Kodu: \(result)")
        }
    }
}
