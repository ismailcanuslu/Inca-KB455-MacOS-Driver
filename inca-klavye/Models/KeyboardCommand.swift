import Foundation

// OemDrv.exe ve KB.ini / USB Sniff kayıtlarından çıkarılan tam donanım LedOpt efekt listesi (1-20)
enum LightingEffect: UInt8, CaseIterable, Identifiable {
    case solid = 1          // Sabit Açık (LedOpt1)
    case breathing = 2      // Nefes Alma (LedOpt2)
    case rainbow = 3        // Gökkuşağı (LedOpt3)
    case zoomGlow = 4       // Uzaklaşan Parlama (LedOpt4)
    case raindrops = 5      // Yağmur Damlaları (LedOpt5)
    case rainbowWheel = 6   // Gökkuşağı Tekerleği (LedOpt6)
    case waveRipple = 7     // Dalgalı Parıltı (LedOpt7)
    case stars = 8          // Yıldızlar Parlar (LedOpt8)
    case shadowFade = 9     // Gölge Kaybolur (LedOpt9)
    case retroSnake = 10    // Retro Yılan (LedOpt10)
    case neonStream = 11    // Neon Akışı (LedOpt11)
    case blossom = 12       // Çiçek Açma (LedOpt12)
    case sineWave = 13      // Sinüs Dalga (LedOpt13)
    case reactive = 14      // Reaksiyon Efekti (LedOpt14)
    case rotatingVenus = 15 // Dönen Venüs (LedOpt15)
    case waterfall = 16     // Renkli Şelale (LedOpt16)
    case scan = 17          // Takip Eden Tarama (LedOpt17)
    case storm = 18         // Dönen Fırtına (LedOpt18)
    case custom = 19        // Özel Renk (LedOpt19)
    case off = 20           // KAPALI (LedOpt20: 0,0,0,0,0,0,0)
    
    var id: UInt8 { self.rawValue }
    
    var name: String {
        switch self {
        case .solid: return "Sabit Açık"
        case .breathing: return "Nefes Alma"
        case .rainbow: return "Gökkuşağı"
        case .zoomGlow: return "Uzaklaşan Parlama"
        case .raindrops: return "Yağmur Damlaları"
        case .rainbowWheel: return "Gökkuşağı Tekerleği"
        case .waveRipple: return "Dalgalı Parıltı"
        case .stars: return "Yıldızlar Parlar"
        case .shadowFade: return "Gölge Kaybolur"
        case .retroSnake: return "Retro Yılan"
        case .neonStream: return "Neon Akışı"
        case .reactive: return "Reaksiyon Efekti"
        case .sineWave: return "Sinüs Dalga"
        case .scan: return "Takip Eden Tarama"
        case .rotatingVenus: return "Dönen Venüs"
        case .waterfall: return "Renkli Şelale"
        case .blossom: return "Çiçek Açma"
        case .storm: return "Dönen Fırtına"
        case .custom: return "Özel Renk"
        case .off: return "Işıkları Kapat"
        }
    }

    var icon: String {
        switch self {
        case .solid: return "sun.max.fill"
        case .breathing: return "lungs.fill"
        case .rainbow: return "rainbow"
        case .zoomGlow: return "sparkles"
        case .raindrops: return "cloud.rain.fill"
        case .rainbowWheel: return "circle.hexagongrid.fill"
        case .waveRipple: return "waveform.path"
        case .stars: return "star.fill"
        case .shadowFade: return "shadow"
        case .retroSnake: return "point.filled.topleft.down.curvedto.point.bottomright.up"
        case .neonStream: return "wind"
        case .reactive: return "hand.tap.fill"
        case .sineWave: return "water.waves"
        case .scan: return "scanner.fill"
        case .rotatingVenus: return "atom"
        case .waterfall: return "arrow.down.to.line"
        case .blossom: return "camera.macro"
        case .storm: return "tornado"
        case .custom: return "paintpalette.fill"
        case .off: return "power"
        }
    }

    /// Efektin donanımsal çok renkli (gökkuşağı spektrumu) desteği var mı?
    /// True olan efektler zaten renk döngüsü yapar; kullanıcı tek renk seçmek yerine
    /// "Çok Renkli" modunu etkinleştirebilir.
    var supportsMulticolor: Bool {
        switch self {
        case .rainbow, .rainbowWheel, .waterfall, .neonStream, .retroSnake,
             .zoomGlow, .scan, .storm, .blossom, .sineWave, .raindrops, .waveRipple:
            return true
        case .solid, .breathing, .stars, .shadowFade, .reactive, .rotatingVenus, .custom, .off:
            return false
        }
    }

    var subtitle: String {
        switch self {
        case .solid: return "Sürekli Canlı Işık"
        case .breathing: return "Yumuşak Nefes Geçişi"
        case .rainbow: return "Kesintisiz Spektrum"
        case .zoomGlow: return "Merkezden Dışa Parıltı"
        case .raindrops: return "Işık Damlaları"
        case .rainbowWheel: return "Spektrum Dönüşü"
        case .waveRipple: return "Tuş Vuruş Dalgası"
        case .stars: return "Yanıp Sönen Yıldızlar"
        case .shadowFade: return "Hızlı Sönen İzler"
        case .retroSnake: return "Piksel Yılan Dansı"
        case .neonStream: return "Akıcı Neon Şeritleri"
        case .blossom: return "Dışa Açılan Çiçek"
        case .sineWave: return "Yumuşak Dalga Salınımı"
        case .reactive: return "Basılan Tuşa Duyarlı"
        case .rotatingVenus: return "Yörüngesel Dönüş"
        case .waterfall: return "Yukarıdan Aşağı Akış"
        case .scan: return "Sağa Sola Lazer Tarama"
        case .storm: return "Girdap Fırtına Hareketi"
        case .custom: return "Özel Tuş Matrisi"
        case .off: return "Aydınlatma Kapalı"
        }
    }
}

// OemDrv.exe ve text.xml kaynaklı Yan Şerit LED (Side LED) efektleri
enum SideLEDEffect: UInt8, CaseIterable, Identifiable {
    case streaming = 1       // Colorful Streaming
    case steady = 2          // Sabit Açık
    case breathing = 3       // Nefes Alma
    case tail = 4            // Renkli Kuyruk
    case neon = 5            // Neon
    case colorfulSteady = 6  // Renkli Sabit
    case flicker = 7         // Yanıp Sönme
    case stars = 8           // Yıldız Parıltısı
    case wave = 9            // Dalga
    case off = 0             // Kapalı
    
    var id: UInt8 { self.rawValue }
    
    var name: String {
        switch self {
        case .streaming: return "Renkli Akış"
        case .steady: return "Sabit Işık"
        case .breathing: return "Nefes Alma"
        case .tail: return "Kuyruklu Akış"
        case .neon: return "Neon Işıltı"
        case .colorfulSteady: return "Sabit Çok Renkli"
        case .flicker: return "Çakarlı / Titreşim"
        case .stars: return "Yıldız Işıltısı"
        case .wave: return "Işık Dalgası"
        case .off: return "Yan Işıkları Kapat"
        }
    }
    
    var icon: String {
        switch self {
        case .streaming: return "wind"
        case .steady: return "sun.max.fill"
        case .breathing: return "lungs.fill"
        case .tail: return "comet.fill"
        case .neon: return "sparkle"
        case .colorfulSteady: return "circle.hexagongrid.fill"
        case .flicker: return "bolt.fill"
        case .stars: return "star.fill"
        case .wave: return "water.waves"
        case .off: return "power"
        }
    }

    var subtitle: String {
        switch self {
        case .streaming: return "Dinamik Çevre Akışı"
        case .steady: return "Sürekli Sabit Işık"
        case .breathing: return "Yumuşak Nefes Alma"
        case .tail: return "Kuyruklu Işık İzi"
        case .neon: return "Neon Işıltı Efekti"
        case .colorfulSteady: return "Çok Renkli Masaya Yansıma"
        case .flicker: return "Canlı Titreşim"
        case .stars: return "Yıldız Işıltısı"
        case .wave: return "Akan Işık Dalgası"
        case .off: return "Yan Şerit Kapalı"
        }
    }
}

// Müzik Senkronizasyon Modları
enum MusicSyncMode: UInt8, CaseIterable, Identifiable {
    case softDance = 1
    case brightRock = 2
    case cloudSnow = 3
    case soundField = 4
    case stream = 5
    case bloom = 6
    case jadePlate = 7
    case moonChase = 8
    case mountainStream = 9
    case silkRain = 10
    
    var id: UInt8 { self.rawValue }
    
    var name: String {
        switch self {
        case .softDance: return "Ses Dansı - Yumuşak"
        case .brightRock: return "Parlak - Rock"
        case .cloudSnow: return "Bulutlar & Kar"
        case .soundField: return "Işık Alanı - Ses"
        case .stream: return "Çınlayan Akarsu"
        case .bloom: return "Çiçek Açma - Tutku"
        case .jadePlate: return "İnci Tabağı"
        case .moonChase: return "Bulutlar Ayı Takip Eder"
        case .mountainStream: return "Dağlar ve Akışkan Su"
        case .silkRain: return "İpek Gibi Yağmur"
        }
    }
    
    var icon: String {
        switch self {
        case .softDance: return "music.note"
        case .brightRock: return "guitars.fill"
        case .cloudSnow: return "cloud.snow.fill"
        case .soundField: return "waveform"
        case .stream: return "water.waves.and.arrow.down"
        case .bloom: return "camera.macro"
        case .jadePlate: return "circle.dashed"
        case .moonChase: return "moon.stars.fill"
        case .mountainStream: return "mountain.2.fill"
        case .silkRain: return "cloud.rain.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .softDance: return "Hafif Melodi Ritmi"
        case .brightRock: return "Yüksek Enerji Vuruşu"
        case .cloudSnow: return "Yumuşak Kar Tanesi Parıltısı"
        case .soundField: return "Genişletilmiş Ses Alanı"
        case .stream: return "Akıcı Ritim Dalgası"
        case .bloom: return "Dinamik Frekans Patlaması"
        case .jadePlate: return "Berrak Tizler & Vuruş"
        case .moonChase: return "Gece Temposu"
        case .mountainStream: return "Bas Ağırlıklı Dalgalanma"
        case .silkRain: return "Hassas Çevre Sesi Tepkisi"
        }
    }
}

struct KeyboardCommand {
    // OemDrv.exe CDev3632 / CDevComboFilm protokol komut kodları:
    // 0x04: SetLED (Kablolu mod veya temel LED komutu)
    // 0x14: SetLED Wireless (2.4G kablosuz alıcı üzerinden LED komutu)
    // 0x44: GetLED (LED durumu okuma)
    // 0x0A: SetOnBoard (Uyku süresi, ayarlar)
    // 0x4A: GetOnBoard (Dahili ayarları okuma)
    // 0x03: SetMatrix (Tuş atamaları / Makro - Işık için KULLANILMAZ)
    // 0x83: GetConfig / Telemetri
    static let cmdSetLED: UInt8 = 0x04
    static let cmdSetMacro: UInt8 = 0x05 // Donanımsal Makro Tanımı (Sniff Paket 873/879)
    static let cmdSetLEDWireless: UInt8 = 0x14
    static let cmdSetCustomMatrix: UInt8 = 0x06 // Özel Tuş Renk Matrisi (Sniff Paket 851/861)
    static let cmdSetRGBMatrix: UInt8 = 0x08 // Canlı RGB Matris / Müzik Akışı (Sniff Paket 781/827)
    static let cmdGetLED: UInt8 = 0x44
    static let cmdSetOnBoard: UInt8 = 0x0A
    static let cmdGetOnBoard: UInt8 = 0x4A
    static let cmdRead: UInt8 = 0x83
    static let headerB6: UInt8 = 0xB6
    
    /// 20-baytlık Output Report 0x13 paketi oluşturur.
    /// Format: [0x13, cmd, nPackages, pkgIdx, (block << 4)|len, payload(14B), checksum]
    static func createWirelessOutputPacket(
        cmd: UInt8 = cmdSetLED,
        effect: UInt8,
        speed: UInt8,
        brightness: UInt8,
        red: UInt8,
        green: UInt8,
        blue: UInt8
    ) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 20)
        packet[0] = 0x13                  // Report ID
        packet[1] = cmd                   // 0x04 (SetLED) veya 0x14
        packet[2] = 0x01                  // nPackageNum: 1 paket
        packet[3] = 0x00                  // package_idx: 0
        packet[4] = 0x06                  // block 0, chunk length = 6 bayt payload
        
        // Payload (byte 5..18)
        packet[5] = effect                // Efekt ID
        packet[6] = speed                 // Hız (0..4)
        packet[7] = brightness            // Parlaklık (0..4)
        packet[8] = red                   // R
        packet[9] = green                 // G
        packet[10] = blue                 // B
        
        // Byte 19: Checksum (0..18 toplamı)
        var sum: UInt32 = 0
        for i in 0..<19 {
            sum += UInt32(packet[i])
        }
        packet[19] = UInt8(sum & 0xFF)
        
        return packet
    }
    
    /// 128-baytlık tam profil paketi gönderimi için dilimlenmiş (sliced) paketler üretir.
    static func createSlicedPackets(cmd: UInt8, payload: [UInt8]) -> [[UInt8]] {
        let chunkSize = 14
        let totalPackages = UInt8((payload.count + chunkSize - 1) / chunkSize)
        var packets: [[UInt8]] = []
        
        for pkgIdx in 0..<totalPackages {
            var packet = [UInt8](repeating: 0, count: 20)
            packet[0] = 0x13
            packet[1] = cmd
            packet[2] = totalPackages
            packet[3] = pkgIdx
            
            let start = Int(pkgIdx) * chunkSize
            let end = min(start + chunkSize, payload.count)
            let len = UInt8(end - start)
            packet[4] = len // (block 0 << 4) | len
            
            for i in 0..<Int(len) {
                packet[5 + i] = payload[start + i]
            }
            
            var sum: UInt32 = 0
            for i in 0..<19 {
                sum += UInt32(packet[i])
            }
            packet[19] = UInt8(sum & 0xFF)
            packets.append(packet)
        }
        
        return packets
    }
    
    /// Kablolu (USB-C) bağlantı için 0x06 Feature Report paketi (Sniff Paket 409 doğrulaması)
    /// Format: [0x06 (ReportID), 0x04 (cmdSetLED), 0x00, 0x00, 0x01, 0x00, 0x80, 0x00] + 128B profil tamponu (toplam 136 bayt)
    static func createWiredSetLEDPacket(payload: [UInt8]) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 8 + 128)
        packet[0] = 0x06 // Feature Report ID
        packet[1] = cmdSetLED // 0x04
        packet[2] = 0x00
        packet[3] = 0x00
        packet[4] = 0x01
        packet[5] = 0x00
        packet[6] = 0x80 // 128 bayt (0x0080)
        packet[7] = 0x00
        for i in 0..<min(128, payload.count) {
            packet[8 + i] = payload[i]
        }
        return packet
    }
    
    /// Kablolu (USB-C) bağlantı için LED okuma talebi (Sniff Paket 405 doğrulaması)
    /// Format: [0x06, 0x84 (cmdGetLED), 0x00, 0x00, 0x01, 0x00, 0x80, 0x00]
    static func createWiredGetLEDPacket() -> [UInt8] {
        return [0x06, 0x84, 0x00, 0x00, 0x01, 0x00, 0x80, 0x00]
    }
    /// Sniff Paket 629 (Mavi) ve Paket 639 (Yeşil) doğrulamalı orijinal 520 baytlık donanım şablonu
    static let wiredColorPacketTemplate: [UInt8] = [
        0x06, 0x0A, 0x00, 0x00, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00,
        0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00,
        0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF,
        0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00,
        0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xFF,
        0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF,
        0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF,
        0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00,
        0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00,
        0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00,
        0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF,
        0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00,
        0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00,
        0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x5A, 0xA5, 0x00, 0x00, 0x00, 0x00
    ]

    /// Kablolu (USB-C) tek renk / özel RGB rengi Feature Report 0x06 paketi (520 bayt)
    /// Ofset 50: Red, 51: Green, 52: Blue, onay imzası: 5A A5
    static func createWiredColorPacket(r: UInt8, g: UInt8, b: UInt8) -> [UInt8] {
        var packet = wiredColorPacketTemplate
        packet[50] = r
        packet[51] = g
        packet[52] = b
        packet[514] = 0x5A
        packet[515] = 0xA5
        return packet
    }

    /// Canlı Müzik Ritmi / RGB Matris Kare Paketi (Sniff Paket 781 / 827 doğrulaması: 520 bayt)
    /// Header: [0x06, 0x08, 0x00, 0x00, 0x01, 0x00, 0x7A, 0x01] (0x017A = 378 bayt = 126 tuş x 3B RGB)
    static func createMusicFramePacket(rgbData: [UInt8]) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 520)
        packet[0] = 0x06
        packet[1] = cmdSetRGBMatrix // 0x08
        packet[2] = 0x00
        packet[3] = 0x00
        packet[4] = 0x01
        packet[5] = 0x00
        packet[6] = 0x7A // 378 bayt (0x017A)
        packet[7] = 0x01
        
        let count = min(378, rgbData.count)
        for i in 0..<count {
            packet[8 + i] = rgbData[i]
        }
        
        packet[514] = 0x5A
        packet[515] = 0xA5
        return packet
    }

    /// Özel Tuş Renk Haritası Paketi (Sniff Paket 851 / 861 doğrulaması: 520 bayt)
    /// Header: [0x06, 0x06, 0x00, 0x00, 0x01, 0x00, 0x7A, 0x01] (0x017A = 378 bayt = 126 tuş x 3B RGB)
    static func createCustomColorMatrixPacket(rgbData: [UInt8]) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 520)
        packet[0] = 0x06
        packet[1] = cmdSetCustomMatrix // 0x06
        packet[2] = 0x00
        packet[3] = 0x00
        packet[4] = 0x01
        packet[5] = 0x00
        packet[6] = 0x7A // 378 bayt (0x017A)
        packet[7] = 0x01
        
        let count = min(378, rgbData.count)
        for i in 0..<count {
            packet[8 + i] = rgbData[i]
        }
        
        packet[514] = 0x5A
        packet[515] = 0xA5
        return packet
    }

    /// 4 Katmanlı Tuş Atama Paketi (Sniff Paket 757, 761, 763, 845 doğrulaması: 520 bayt)
    /// Katmanlar: 0x00=Varsayılan (Base), 0x01=FN1, 0x02=FN2, 0x03=Dokun (Tap)
    /// Header: [0x06, 0x03, layerIndex, 0x00, 0x01, 0x00, 0x00, 0x02] + 512 bayt tuş matrisi
    static func createSetLayerMatrixPacket(layerIndex: UInt8, matrixData: [UInt8]) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 520)
        packet[0] = 0x06
        packet[1] = 0x03 // cmdSetMatrix
        packet[2] = layerIndex // 0=Base, 1=FN1, 2=FN2, 3=Tap
        packet[3] = 0x00
        packet[4] = 0x01
        packet[5] = 0x00
        packet[6] = 0x00
        packet[7] = 0x02
        
        let count = min(506, matrixData.count)
        for i in 0..<count {
            packet[8 + i] = matrixData[i]
        }
        
        packet[514] = 0x5A
        packet[515] = 0xA5
        return packet
    }

    /// USB Sniff kayıtlarından (Paket 595, 545 vb.) çıkarılan klavye donanım 128 baytlık fabrika şablonu
    static func defaultLedProfileTemplate() -> [UInt8] {
        var profile = [UInt8](repeating: 0, count: 128)
        // 0..7
        profile[0] = 0x00
        profile[1] = 0x03
        profile[2] = 0x03
        profile[3] = 0x02
        profile[4] = 0x00
        profile[5] = 0x00
        profile[6] = 0x04
        profile[7] = 0x04
        // 8..15 (Ofset 10: Aktif efekt indeksi, varsayılan LedOpt3 = 0x03)
        profile[8] = 0x07
        profile[9] = 0x00
        profile[10] = 0x03
        profile[11] = 0x20
        profile[12] = 0x01
        profile[13] = 0x00
        profile[14] = 0x00
        profile[15] = 0x00
        // 16..23
        profile[16] = 0x00
        profile[17] = 0x00
        profile[18] = 0x01
        profile[19] = 0x00
        profile[20] = 0x04
        profile[21] = 0x04
        profile[22] = 0x00
        profile[23] = 0xFF
        // 24: Uyku Süresi (30 saniyelik birimler: 0=Kapalı, 1=30sn, 2=1dk, 6=3dk, 40=20dk - KB.ini SleepTime=180)
        profile[24] = 0x06
        // 25..55 sıfır kalır
        // 56..57: Tablo başlangıcı (FF FF)
        profile[56] = 0xFF
        profile[57] = 0xFF
        // 58..97: 20 efekt tablosu (Varsayılan Parlaklık 4, Hız 4, Gökkuşağı 7 -> 04 47)
        for i in stride(from: 58, to: 98, by: 2) {
            profile[i] = 0x04     // Parlaklık: 4
            profile[i + 1] = 0x47 // Hız: 4, Renk: 7 (Rainbow)
        }
        // 98..115: Özel / Oyun profilleri
        let customTail: [UInt8] = [
            0x07, 0x47, 0x07, 0x47, 0x07, 0x44, 0x07, 0x44,
            0x07, 0x44, 0x07, 0x44, 0x07, 0x44, 0x07, 0x44,
            0x07, 0x44
        ]
        for (idx, byte) in customTail.enumerated() {
            profile[98 + idx] = byte
        }
        // 116..125
        for i in 116..<126 {
            profile[i] = 0x04
        }
        // 126..127: Donanım Onay İmzası
        profile[126] = 0x5A
        profile[127] = 0xA5
        return profile
    }
    
    // Geriye dönük uyumluluk için eski metod çağrıları
    static func createWiredLightingPacket(effect: UInt8, speed: UInt8, brightness: UInt8, red: UInt8, green: UInt8, blue: UInt8) -> [UInt8] {
        var profile = [UInt8](repeating: 0, count: 128)
        profile[1] = effect
        profile[2] = speed
        profile[3] = brightness
        profile[8] = 7 // Multi/Rainbow
        profile[126] = 0x5A
        profile[127] = 0xA5
        return createWiredSetLEDPacket(payload: profile)
    }
    
    // Durum / Yapılandırma Okuma Paketi (0x83 0xB6)
    static func createReadConfigPacket() -> [UInt8] {
        return [cmdRead, headerB6, 0x00, 0x00, 0x00, 0x00, 0x00]
    }

    /// LED aydınlatma durumunu sorgulama paketi (cmdGetLED = 0x44)
    static func createGetLEDPacket() -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 20)
        packet[0] = 0x13
        packet[1] = cmdGetLED // 0x44
        packet[2] = 0x01
        packet[3] = 0x00
        packet[4] = 0x00
        var sum: UInt32 = 0
        for i in 0..<19 {
            sum += UInt32(packet[i])
        }
        packet[19] = UInt8(sum & 0xFF)
        return packet
    }
    
    /// Uyku süresi ayarlama paketi (cmd 0x0A - SetOnBoard)
    /// seconds: 0 (Kapat/Asla), 60 (1dk), 180 (3dk), 300 (5dk), 600 (10dk)
    static func createSleepPacket(seconds: Int) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 20)
        packet[0] = 0x13
        packet[1] = cmdSetOnBoard
        packet[2] = 0x01
        packet[3] = 0x00
        packet[4] = 0x04 // 4 bayt payload
        
        let sec16 = UInt16(min(65535, max(0, seconds)))
        packet[5] = 0x01 // Alt komut: Sleep config
        packet[6] = UInt8(sec16 & 0xFF)
        packet[7] = UInt8((sec16 >> 8) & 0xFF)
        packet[8] = 0x00
        
        var sum: UInt32 = 0
        for i in 0..<19 {
            sum += UInt32(packet[i])
        }
        packet[19] = UInt8(sum & 0xFF)
        return packet
    }

    /// Çakışma önleme (Debounce) ayarlama paketi (cmd 0x0A)
    static func createDebouncePacket(debounceMs: UInt8) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 20)
        packet[0] = 0x13
        packet[1] = cmdSetOnBoard
        packet[2] = 0x01
        packet[3] = 0x00
        packet[4] = 0x03
        
        packet[5] = 0x02 // Alt komut: Debounce
        packet[6] = debounceMs
        packet[7] = 0x00
        
        var sum: UInt32 = 0
        for i in 0..<19 {
            sum += UInt32(packet[i])
        }
        packet[19] = UInt8(sum & 0xFF)
        return packet
    }

    /// Döner Tekerlek (Knob / Wheel) modu ayarlama paketi (0 = Ses/Medya, 1 = RGB Parlaklık)
    static func createWheelModePacket(mode: UInt8) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 20)
        packet[0] = 0x13
        packet[1] = cmdSetOnBoard
        packet[2] = 0x01
        packet[3] = 0x00
        packet[4] = 0x03
        packet[5] = 0x03 // Alt komut: Wheel Mode
        packet[6] = mode
        packet[7] = 0x00
        
        var sum: UInt32 = 0
        for i in 0..<19 {
            sum += UInt32(packet[i])
        }
        packet[19] = UInt8(sum & 0xFF)
        return packet
    }

    /// İşletim sistemi tuş dizilimi katmanı (0 = Windows, 2 = macOS)
    static func createModeSwitchPacket(mode: UInt8) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 20)
        packet[0] = 0x13
        packet[1] = cmdSetOnBoard
        packet[2] = 0x01
        packet[3] = 0x00
        packet[4] = 0x03
        packet[5] = 0x04 // Alt komut: Mode/Layer Switch (0 = Win, 2 = Mac)
        packet[6] = mode
        packet[7] = 0x00
        
        var sum: UInt32 = 0
        for i in 0..<19 {
            sum += UInt32(packet[i])
        }
        packet[19] = UInt8(sum & 0xFF)
        return packet
    }

    /// Donanımsal Makro Eylemi (4 Baytlık Yapı)
    /// [Delay_High, Delay_Low, HID_Code, State]
    /// Sniff Paket 873/879 doğrulaması:
    /// - Delay: 16-bit Big-Endian milisaniye
    /// - HID_Code: USB HID Klavye Kullanım Kodu (örn. 0x04='a', 0x05='b', 0x52=Yukarı Ok)
    /// - State: 0x80 (Basıldı/Down), 0x00 (Bırakıldı/Up)
    struct HardwareMacroAction: Identifiable, Codable, Equatable {
        var id = UUID()
        var hidCode: UInt8
        var isKeyDown: Bool
        var delayMs: UInt16

        init(hidCode: UInt8, isKeyDown: Bool, delayMs: UInt16) {
            self.hidCode = hidCode
            self.isKeyDown = isKeyDown
            self.delayMs = delayMs
        }
    }

    /// Donanımsal Makro Tanım Paketi (Sniff Paket 873 / 879 doğrulaması: 520 bayt)
    /// Header: [0x06, 0x05, macroIndex, 0x00, 0x01, 0x00, dataLen_Low, dataLen_High]
    /// Payload:
    ///   - Byte 8..9: 0x04, 0x00
    ///   - Byte 10..11: contentLen_Low, contentLen_High (dataLen - 4)
    ///   - Byte 12: NameByteCount (UTF-16LE, örn. 8 bayt)
    ///   - Byte 13 ..< 13 + NameByteCount: UTF-16LE Makro Adı
    ///   - Eylemler: Her biri 4 bayt [Delay_High, Delay_Low, HID_Code, State (0x80 = Down, 0x00 = Up)]
    ///   - Footer: 514: 0x5A, 515: 0xA5
    static func createMacroDefinitionPacket(
        macroIndex: UInt8,
        name: String,
        actions: [HardwareMacroAction]
    ) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 520)

        // 1. İsim UTF-16LE baytları
        var nameBytes: [UInt8] = []
        for utf16Unit in name.utf16 {
            nameBytes.append(UInt8(utf16Unit & 0xFF))
            nameBytes.append(UInt8((utf16Unit >> 8) & 0xFF))
        }
        if nameBytes.isEmpty {
            nameBytes = [0x4D, 0x00, 0x31, 0x00] // "M1"
        }

        // 2. Eylemler (her biri 4 bayt)
        var actionBytes: [UInt8] = []
        for action in actions {
            let delay = action.delayMs
            actionBytes.append(UInt8((delay >> 8) & 0xFF)) // Big-Endian delay High
            actionBytes.append(UInt8(delay & 0xFF))        // Big-Endian delay Low
            actionBytes.append(action.hidCode)             // HID Keycode (0x04='a', 0x05='b'...)
            actionBytes.append(action.isKeyDown ? 0x80 : 0x00) // 0x80=Down, 0x00=Up
        }

        // 3. Uzunluk hesapları
        // contentLen = 1 (nameLen byte) + nameBytes.count + actionBytes.count
        let contentLen = 1 + nameBytes.count + actionBytes.count
        // totalDataLen = 4 (magic 04 00 + contentLen 2B) + contentLen
        let totalDataLen = 4 + contentLen

        // Header (8 bayt)
        packet[0] = 0x06
        packet[1] = cmdSetMacro // 0x05
        packet[2] = macroIndex  // 0x00 = 1. Makro
        packet[3] = 0x00
        packet[4] = 0x01
        packet[5] = 0x00
        packet[6] = UInt8(totalDataLen & 0xFF)
        packet[7] = UInt8((totalDataLen >> 8) & 0xFF)

        // Payload
        packet[8] = 0x04
        packet[9] = 0x00
        packet[10] = UInt8(contentLen & 0xFF)
        packet[11] = UInt8((contentLen >> 8) & 0xFF)
        packet[12] = UInt8(nameBytes.count)

        var offset = 13
        for b in nameBytes {
            if offset < 514 {
                packet[offset] = b
                offset += 1
            }
        }

        for b in actionBytes {
            if offset < 514 {
                packet[offset] = b
                offset += 1
            }
        }

        // Donanım onay imzası
        packet[514] = 0x5A
        packet[515] = 0xA5

        return packet
    }

    /// Tuşa Makro Atama Paketi (Sniff Paket 871 / 877 doğrulaması)
    /// 4 Katmanlı tuş matrisinde ilgili tuşun 4-baytlık slotuna makro bilgisini yazar:
    /// Slot formatı: [0x03 (Macro Type), macroId (1..N), loopCount/mode, 0x00]
    static func createAssignMacroKeyPacket(
        layerIndex: UInt8,
        keyIndex: Int,
        macroId: UInt8,
        loopCount: UInt8,
        baseMatrix: [UInt8]? = nil
    ) -> [UInt8] {
        var matrix = baseMatrix ?? [UInt8](repeating: 0, count: 506)
        if matrix.count < 506 {
            matrix.append(contentsOf: [UInt8](repeating: 0, count: 506 - matrix.count))
        }

        // Her tuş 4 bayttan oluşur
        let slotOffset = keyIndex * 4
        if slotOffset + 3 < matrix.count {
            matrix[slotOffset] = 0x03       // Aksiyon: Makro
            matrix[slotOffset + 1] = macroId // Makro Numarası (1-based)
            matrix[slotOffset + 2] = loopCount // Döngü sayısı (1, 2..255)
            matrix[slotOffset + 3] = 0x00
        }

        return createSetLayerMatrixPacket(layerIndex: layerIndex, matrixData: matrix)
    }

    // MARK: - Fabrika Sıfırlama (Factory Reset) Paketleri (Sniff 881, 883, 885, 887, 897)

    /// Layer 0 (Base) Orijinal Fabrika Tuş Matrisi (Sniff Paket 881: 520 Bayt)
    static func createFactoryLayer0Packet() -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 520)
        packet[0] = 0x06
        packet[1] = 0x03
        packet[2] = 0x00 // Base Layer
        packet[3] = 0x00
        packet[4] = 0x01
        packet[5] = 0x00
        packet[6] = 0x00
        packet[7] = 0x02

        let matrix: [UInt8] = [
            0x00, 0x00, 0x00, 0x29, 0x00, 0x00, 0x00, 0x35, 0x00, 0x00, 0x00, 0x2b, 0x00, 0x00, 0x00, 0x39,
            0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1e,
            0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x08, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x3a, 0x00, 0x00, 0x00, 0x1f, 0x00, 0x00, 0x00, 0x1a, 0x00, 0x00, 0x00, 0x16,
            0x00, 0x00, 0x00, 0x1b, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3b, 0x00, 0x00, 0x00, 0x20,
            0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x3c, 0x00, 0x00, 0x00, 0x21, 0x00, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00, 0x09,
            0x00, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3d, 0x00, 0x00, 0x00, 0x22,
            0x00, 0x00, 0x00, 0x17, 0x00, 0x00, 0x00, 0x0a, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x2c,
            0x00, 0x00, 0x00, 0x3e, 0x00, 0x00, 0x00, 0x23, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x00, 0x00, 0x0b,
            0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3f, 0x00, 0x00, 0x00, 0x24,
            0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x25, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x0e,
            0x00, 0x00, 0x00, 0x36, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x26,
            0x00, 0x00, 0x00, 0x12, 0x00, 0x00, 0x00, 0x0f, 0x00, 0x00, 0x00, 0x37, 0x0d, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x42, 0x00, 0x00, 0x00, 0x27, 0x00, 0x00, 0x00, 0x13, 0x00, 0x00, 0x00, 0x33,
            0x00, 0x00, 0x00, 0x38, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x43, 0x00, 0x00, 0x00, 0x2d,
            0x00, 0x00, 0x00, 0x2f, 0x00, 0x00, 0x00, 0x34, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x44, 0x00, 0x00, 0x00, 0x2e, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00, 0x31,
            0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x45, 0x00, 0x00, 0x00, 0x2a,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x28, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x50,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x52, 0x00, 0x00, 0x00, 0x51, 0x07, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x49,
            0x00, 0x00, 0x00, 0x4c, 0x00, 0x00, 0x00, 0x4b, 0x00, 0x00, 0x00, 0x4e, 0x00, 0x00, 0x00, 0x4f
        ]
        for i in 0..<min(matrix.count, 506) {
            packet[8 + i] = matrix[i]
        }
        packet[514] = 0x5A
        packet[515] = 0xA5
        return packet
    }

    /// Layer 1 (FN1) Orijinal Fabrika Fonksiyon Matrisi (Sniff Paket 883: 520 Bayt)
    static func createFactoryLayer1Packet() -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 520)
        packet[0] = 0x06
        packet[1] = 0x03
        packet[2] = 0x01 // FN1 Layer
        packet[3] = 0x00
        packet[4] = 0x01
        packet[5] = 0x00
        packet[6] = 0x00
        packet[7] = 0x02

        let matrix: [UInt8] = [
            0x07, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x12,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x05,
            0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x01,
            0x02, 0x00, 0x00, 0x70, 0x07, 0x00, 0x00, 0x06, 0x07, 0x00, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x6f, 0x07, 0x00, 0x00, 0x07,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x04, 0x00, 0x2b, 0x07, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x0b, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x0a, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x0b,
            0x00, 0x08, 0x00, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x02, 0x21, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x02, 0x00, 0x00, 0xb6, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x11, 0x02, 0x00, 0x00, 0xcd, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x02, 0x00, 0x00, 0xb5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x47,
            0x00, 0x00, 0x00, 0x48, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0xe2, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x4a, 0x00, 0x00, 0x00, 0x46, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x02, 0x00, 0x00, 0xea, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4d, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0xe9, 0x08, 0x07, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x08, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x04, 0x02, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x08, 0x03, 0x01, 0x00, 0x08, 0x03, 0x02, 0x00, 0x08, 0x04, 0x01, 0x00, 0x08, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x04, 0x01, 0x00
        ]
        for i in 0..<min(matrix.count, 506) {
            packet[8 + i] = matrix[i]
        }
        packet[514] = 0x5A
        packet[515] = 0xA5
        return packet
    }

    /// Layer 2 (FN2) Sıfırlama Paketi (Sniff Paket 885: 520 Bayt)
    static func createFactoryLayer2Packet() -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 520)
        packet[0] = 0x06
        packet[1] = 0x03
        packet[2] = 0x02 // FN2 Layer
        packet[3] = 0x00
        packet[4] = 0x01
        packet[5] = 0x00
        packet[6] = 0x00
        packet[7] = 0x02
        packet[514] = 0x5A
        packet[515] = 0xA5
        return packet
    }

    /// Layer 3 (Tap) Sıfırlama Paketi (Sniff Paket 887: 520 Bayt)
    static func createFactoryLayer3Packet() -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 520)
        packet[0] = 0x06
        packet[1] = 0x03
        packet[2] = 0x03 // Tap Layer
        packet[3] = 0x00
        packet[4] = 0x01
        packet[5] = 0x00
        packet[6] = 0x00
        packet[7] = 0x02
        packet[514] = 0x5A
        packet[515] = 0xA5
        return packet
    }

    /// Orijinal Fabrika LED & Aydınlatma Profili (Sniff Paket 897: 136 Bayt)
    /// Efekt: 11 (NeonStream / Neon Akışı), Parlaklık: 4, Hız: 4, Uyku: 180s (3dk)
    static func createFactoryLedPacket() -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 136)
        packet[0] = 0x06
        packet[1] = cmdSetLED // 0x04
        packet[2] = 0x00
        packet[3] = 0x00
        packet[4] = 0x01
        packet[5] = 0x00
        packet[6] = 0x80
        packet[7] = 0x00

        let payload: [UInt8] = [
            0x00, 0x03, 0x03, 0x02, 0x00, 0x00, 0x04, 0x04, 0x07, 0x00, 0x0b, 0x20, 0x01, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x01, 0x00, 0x04, 0x04, 0x00, 0xff, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0x04, 0x47, 0x04, 0x47, 0x04, 0x47,
            0x04, 0x47, 0x04, 0x47, 0x04, 0x47, 0x04, 0x47, 0x04, 0x47, 0x04, 0x47, 0x04, 0x47, 0x04, 0x47,
            0x04, 0x47, 0x04, 0x47, 0x04, 0x47, 0x04, 0x47, 0x04, 0x47, 0x04, 0x47, 0x04, 0x47, 0x04, 0x47,
            0x04, 0x47, 0x07, 0x47, 0x07, 0x47, 0x07, 0x44, 0x07, 0x44, 0x07, 0x44, 0x07, 0x44, 0x07, 0x44,
            0x07, 0x44, 0x07, 0x44, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x5a, 0xa5
        ]
        for i in 0..<min(payload.count, 128) {
            packet[8 + i] = payload[i]
        }
        return packet
    }
}

