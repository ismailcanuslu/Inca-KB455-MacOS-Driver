import SwiftUI
import AppKit
import Combine

/// Bilgisayar diskinde (UserDefaults) saklanan tekil bir kişisel aydınlatma profili slotu.
struct CustomLightingSlot: Codable, Identifiable {
    var id: Int // 1...5
    var title: String
    var keyHexColors: [String: String] // ["W": "#FF0000", ...]
    var updatedAt: Date?

    var isEmpty: Bool {
        keyHexColors.isEmpty
    }

    var keyCount: Int {
        keyHexColors.count
    }

    /// Önizleme için slotta kullanılan ilk 4 farklı rengi döndürür
    var distinctPreviewColors: [Color] {
        var seen = Set<String>()
        var result: [Color] = []
        for hex in keyHexColors.values {
            if !seen.contains(hex) {
                seen.insert(hex)
                result.append(Color.fromHex(hex))
                if result.count >= 4 { break }
            }
        }
        return result
    }
}

/// Kişisel aydınlatma için 5 adet disk slotunu yöneten Observable servis.
final class CustomLightingSlotsManager: ObservableObject {
    static let shared = CustomLightingSlotsManager()
    private let storageKey = "custom_lighting_disk_slots_v1"

    @Published var slots: [CustomLightingSlot] = []
    @Published var activeSlotId: Int? = nil

    init() {
        loadFromDisk()
    }

    /// Diskten slotları oku; yoksa varsayılan 5 slot oluştur
    func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([CustomLightingSlot].self, from: data),
           decoded.count == 5 {
            self.slots = decoded
            return
        }

        // İlk açılış: 5 slot oluştur (Slot 1 gamer hazır şablonlu, diğerleri boş)
        var defaultSlots: [CustomLightingSlot] = []
        for i in 1...5 {
            if i == 1 {
                var wasdHexes: [String: String] = [:]
                let gamerKeys = ["W", "A", "S", "D", "UP", "DOWN", "LEFT", "RIGHT", "ESC", "SPACE"]
                for k in gamerKeys {
                    wasdHexes[k] = "#FA2E60" // Apple Red
                }
                defaultSlots.append(
                    CustomLightingSlot(
                        id: 1,
                        title: "Slot 1 (Gamer WASD)",
                        keyHexColors: wasdHexes,
                        updatedAt: Date()
                    )
                )
            } else {
                defaultSlots.append(
                    CustomLightingSlot(
                        id: i,
                        title: "Slot \(i)",
                        keyHexColors: [:],
                        updatedAt: nil
                    )
                )
            }
        }
        self.slots = defaultSlots
        saveToDisk()
    }

    /// Slotu mevcut klavye renk matrisiyle diske kaydet
    func saveSlot(id: Int, title: String? = nil, colors: [String: Color]) {
        guard let index = slots.firstIndex(where: { $0.id == id }) else { return }

        var hexMap: [String: String] = [:]
        for (key, color) in colors {
            hexMap[key] = color.toHex()
        }

        var currentSlot = slots[index]
        currentSlot.keyHexColors = hexMap
        currentSlot.updatedAt = Date()
        if let newTitle = title, !newTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            currentSlot.title = newTitle
        }

        slots[index] = currentSlot
        activeSlotId = id
        saveToDisk()
    }

    /// Slotun renklerini diskten oku ve Color haritası olarak döndür
    func loadColors(for id: Int) -> [String: Color] {
        guard let slot = slots.first(where: { $0.id == id }) else { return [:] }
        var result: [String: Color] = [:]
        for (key, hex) in slot.keyHexColors {
            result[key] = Color.fromHex(hex)
        }
        activeSlotId = id
        return result
    }

    /// Slotun adını güncelle
    func renameSlot(id: Int, newTitle: String) {
        guard let index = slots.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        slots[index].title = trimmed
        saveToDisk()
    }

    /// Slot içeriğini temizle
    func clearSlot(id: Int) {
        guard let index = slots.firstIndex(where: { $0.id == id }) else { return }
        slots[index].keyHexColors = [:]
        slots[index].updatedAt = nil
        if activeSlotId == id {
            activeSlotId = nil
        }
        saveToDisk()
    }

    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}

// MARK: - Color Hex Dönüşüm Yardımcıları
extension Color {
    func toHex() -> String {
        let nsColor = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = max(0, min(255, Int(round(nsColor.redComponent * 255.0))))
        let g = max(0, min(255, Int(round(nsColor.greenComponent * 255.0))))
        let b = max(0, min(255, Int(round(nsColor.blueComponent * 255.0))))
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    static func fromHex(_ hexString: String) -> Color {
        var clean = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if clean.hasPrefix("#") {
            clean.removeFirst()
        }
        guard clean.count == 6, let val = UInt64(clean, radix: 16) else {
            return .white
        }
        let r = Double((val & 0xFF0000) >> 16) / 255.0
        let g = Double((val & 0x00FF00) >> 8) / 255.0
        let b = Double(val & 0x0000FF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    var rgbComponents: (r: Int, g: Int, b: Int) {
        let nsColor = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = max(0, min(255, Int(round(nsColor.redComponent * 255.0))))
        let g = max(0, min(255, Int(round(nsColor.greenComponent * 255.0))))
        let b = max(0, min(255, Int(round(nsColor.blueComponent * 255.0))))
        return (r, g, b)
    }

    var rgbString: String {
        let (r, g, b) = rgbComponents
        return "RGB(\(r), \(g), \(b))"
    }
}
