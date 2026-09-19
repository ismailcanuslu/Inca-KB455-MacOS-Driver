import Foundation

struct KeyboardCommand {
    // Ghidra analizinde gördüğümüz komut başlıkları (Header / Command IDs)
    static let headerByte1: UInt8 = 0x83
    static let headerByte2: UInt8 = 0xb6
    
    // Aydınlatma ve RGB komutlarını paketleyen statik fonksiyon
    static func createLightingPacket(effect: UInt8, red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) -> [UInt8] {
        var packet: [UInt8] = []
        
        // Protokol imza baytları
        packet.append(headerByte1)
        packet.append(headerByte2)
        
        // Efekt ve renk parametreleri
        packet.append(effect)
        packet.append(red)
        packet.append(green)
        packet.append(blue)
        packet.append(brightness)
        
        // Paket uzunluğunu veya eksik dolgu baytlarını Ghidra'daki yapıya göre tamamlayabiliriz
        // Şimdilik temel payload'u döndürüyoruz
        return packet
    }
}
