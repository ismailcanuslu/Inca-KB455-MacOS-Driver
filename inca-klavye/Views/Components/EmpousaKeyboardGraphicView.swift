import SwiftUI

// Tuş rengi tipi (Fotoğraftaki 3 ana renk grubu)
enum KeycapStyle {
    case white     // Beyaz tuşlar (Harfler, sayılar, F1-F4, F9-F12)
    case beige     // Vintage Bej/Açık Gri tuşlar (F5-F8, Tab, Caps, Shift, Ctrl, Alt, Ins, Del, PgUp, PgDn)
    case dark      // Koyu Antrasit tuşlar (ESC, Boşluk, Yön Okları)
}

// İnteraktif Klavye Tuş Modeli
struct KeyboardKeyDef: Identifiable, Hashable {
    let id: String           // Benzersiz anahtar (örn: "UP", "A", "ESC")
    let primaryLabel: String // Ana sembol (örn: "A", "W", "▲")
    let secondaryLabel: String? // Alt sembol (örn: "Mac", "Win", "Home", "BT1")
    let widthUnits: CGFloat  // 1.0 = standart kare tuş, 1.25, 1.5, 2.0, 6.25u vs.
    let style: KeycapStyle
    let hidCode: UInt8
    let matrixIndex: Int     // Donanım 06 03 matrisindeki ofset
}

struct EmpousaKeyboardGraphicView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @Binding var selectedKeyId: String?
    
    // Opsiyonel: Tuşlara atanan makro isimleri (KeyId -> Makro Adı)
    var assignedMacroNames: [String: String] = [:]
    
    // Opsiyonel: Tuşlara özel atanmış renkler (KeyId -> Renk)
    var perKeyColors: [String: Color] = [:]
    
    // Olay geri çağrıları
    var onKeySelected: ((KeyboardKeyDef) -> Void)? = nil
    var onKnobRotatedOrClicked: (() -> Void)? = nil

    // Fotoğraftaki tam Türkçe Q %75 Inca Empousa Tuş Dizilimi (Donanım Matris İndeksleri: KB.ini)
    static let row0: [KeyboardKeyDef] = [
        KeyboardKeyDef(id: "ESC", primaryLabel: "ESC", secondaryLabel: "⎋", widthUnits: 1.0, style: .dark, hidCode: 0x29, matrixIndex: 0),
        // F1-F4 Beyaz
        KeyboardKeyDef(id: "F1", primaryLabel: "F1", secondaryLabel: "☼-", widthUnits: 1.0, style: .white, hidCode: 0x3A, matrixIndex: 12),
        KeyboardKeyDef(id: "F2", primaryLabel: "F2", secondaryLabel: "☼+", widthUnits: 1.0, style: .white, hidCode: 0x3B, matrixIndex: 18),
        KeyboardKeyDef(id: "F3", primaryLabel: "F3", secondaryLabel: "⎘", widthUnits: 1.0, style: .white, hidCode: 0x3C, matrixIndex: 24),
        KeyboardKeyDef(id: "F4", primaryLabel: "F4", secondaryLabel: "🎙", widthUnits: 1.0, style: .white, hidCode: 0x3D, matrixIndex: 30),
        // F5-F8 Bej
        KeyboardKeyDef(id: "F5", primaryLabel: "F5", secondaryLabel: "🔒", widthUnits: 1.0, style: .beige, hidCode: 0x3E, matrixIndex: 36),
        KeyboardKeyDef(id: "F6", primaryLabel: "F6", secondaryLabel: "🔍", widthUnits: 1.0, style: .beige, hidCode: 0x3F, matrixIndex: 42),
        KeyboardKeyDef(id: "F7", primaryLabel: "F7", secondaryLabel: "⏮", widthUnits: 1.0, style: .beige, hidCode: 0x40, matrixIndex: 48),
        KeyboardKeyDef(id: "F8", primaryLabel: "F8", secondaryLabel: "⏯", widthUnits: 1.0, style: .beige, hidCode: 0x41, matrixIndex: 54),
        // F9-F12 Beyaz
        KeyboardKeyDef(id: "F9", primaryLabel: "F9", secondaryLabel: "⏭", widthUnits: 1.0, style: .white, hidCode: 0x42, matrixIndex: 60),
        KeyboardKeyDef(id: "F10", primaryLabel: "F10", secondaryLabel: "🔇", widthUnits: 1.0, style: .white, hidCode: 0x43, matrixIndex: 66),
        KeyboardKeyDef(id: "F11", primaryLabel: "F11", secondaryLabel: "🔉", widthUnits: 1.0, style: .white, hidCode: 0x44, matrixIndex: 72),
        KeyboardKeyDef(id: "F12", primaryLabel: "F12", secondaryLabel: "🔊", widthUnits: 1.0, style: .white, hidCode: 0x45, matrixIndex: 78)
    ]

    static let row1: [KeyboardKeyDef] = [
        KeyboardKeyDef(id: "TILDE", primaryLabel: "é", secondaryLabel: "\"", widthUnits: 1.0, style: .beige, hidCode: 0x35, matrixIndex: 1),
        KeyboardKeyDef(id: "1", primaryLabel: "1", secondaryLabel: "BT1", widthUnits: 1.0, style: .white, hidCode: 0x1E, matrixIndex: 7),
        KeyboardKeyDef(id: "2", primaryLabel: "2", secondaryLabel: "BT2", widthUnits: 1.0, style: .white, hidCode: 0x1F, matrixIndex: 13),
        KeyboardKeyDef(id: "3", primaryLabel: "3", secondaryLabel: "BT3", widthUnits: 1.0, style: .white, hidCode: 0x20, matrixIndex: 19),
        KeyboardKeyDef(id: "4", primaryLabel: "4", secondaryLabel: "2.4G", widthUnits: 1.0, style: .white, hidCode: 0x21, matrixIndex: 25),
        KeyboardKeyDef(id: "5", primaryLabel: "5", secondaryLabel: "%", widthUnits: 1.0, style: .white, hidCode: 0x22, matrixIndex: 31),
        KeyboardKeyDef(id: "6", primaryLabel: "6", secondaryLabel: "&", widthUnits: 1.0, style: .white, hidCode: 0x23, matrixIndex: 37),
        KeyboardKeyDef(id: "7", primaryLabel: "7", secondaryLabel: "{", widthUnits: 1.0, style: .white, hidCode: 0x24, matrixIndex: 43),
        KeyboardKeyDef(id: "8", primaryLabel: "8", secondaryLabel: "[", widthUnits: 1.0, style: .white, hidCode: 0x25, matrixIndex: 49),
        KeyboardKeyDef(id: "9", primaryLabel: "9", secondaryLabel: "]", widthUnits: 1.0, style: .white, hidCode: 0x26, matrixIndex: 55),
        KeyboardKeyDef(id: "0", primaryLabel: "0", secondaryLabel: "}", widthUnits: 1.0, style: .white, hidCode: 0x27, matrixIndex: 61),
        KeyboardKeyDef(id: "MINUS", primaryLabel: "*", secondaryLabel: "?", widthUnits: 1.0, style: .white, hidCode: 0x2D, matrixIndex: 67),
        KeyboardKeyDef(id: "EQUAL", primaryLabel: "-", secondaryLabel: "_", widthUnits: 1.0, style: .white, hidCode: 0x2E, matrixIndex: 73),
        KeyboardKeyDef(id: "BACKSPACE", primaryLabel: "BACKSPACE", secondaryLabel: "⌫", widthUnits: 2.0, style: .white, hidCode: 0x2A, matrixIndex: 79),
        KeyboardKeyDef(id: "INS", primaryLabel: "INS", secondaryLabel: "N", widthUnits: 1.0, style: .beige, hidCode: 0x49, matrixIndex: 91)
    ]

    static let row2: [KeyboardKeyDef] = [
        KeyboardKeyDef(id: "TAB", primaryLabel: "TAB", secondaryLabel: "⇥", widthUnits: 1.5, style: .beige, hidCode: 0x2B, matrixIndex: 2),
        KeyboardKeyDef(id: "Q", primaryLabel: "Q", secondaryLabel: "@", widthUnits: 1.0, style: .white, hidCode: 0x14, matrixIndex: 8),
        KeyboardKeyDef(id: "W", primaryLabel: "W", secondaryLabel: "Win", widthUnits: 1.0, style: .white, hidCode: 0x1A, matrixIndex: 14),
        KeyboardKeyDef(id: "E", primaryLabel: "E", secondaryLabel: "€", widthUnits: 1.0, style: .white, hidCode: 0x08, matrixIndex: 20),
        KeyboardKeyDef(id: "R", primaryLabel: "R", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x15, matrixIndex: 26),
        KeyboardKeyDef(id: "T", primaryLabel: "T", secondaryLabel: "₺", widthUnits: 1.0, style: .white, hidCode: 0x17, matrixIndex: 32),
        KeyboardKeyDef(id: "Y", primaryLabel: "Y", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x1C, matrixIndex: 38),
        KeyboardKeyDef(id: "U", primaryLabel: "U", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x18, matrixIndex: 44),
        KeyboardKeyDef(id: "I", primaryLabel: "I", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x0C, matrixIndex: 50),
        KeyboardKeyDef(id: "O", primaryLabel: "O", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x12, matrixIndex: 56),
        KeyboardKeyDef(id: "P", primaryLabel: "P", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x13, matrixIndex: 62),
        KeyboardKeyDef(id: "Ğ", primaryLabel: "Ğ", secondaryLabel: "Home", widthUnits: 1.0, style: .white, hidCode: 0x2F, matrixIndex: 68),
        KeyboardKeyDef(id: "Ü", primaryLabel: "Ü", secondaryLabel: "End", widthUnits: 1.0, style: .white, hidCode: 0x30, matrixIndex: 74),
        KeyboardKeyDef(id: "ENTER_TOP", primaryLabel: "ENTER", secondaryLabel: "↵", widthUnits: 1.5, style: .white, hidCode: 0x28, matrixIndex: 81),
        KeyboardKeyDef(id: "DEL", primaryLabel: "DEL", secondaryLabel: "⌦", widthUnits: 1.0, style: .beige, hidCode: 0x4C, matrixIndex: 92)
    ]

    static let row3: [KeyboardKeyDef] = [
        KeyboardKeyDef(id: "CAPS", primaryLabel: "CAPS LOCK", secondaryLabel: "⇪", widthUnits: 1.75, style: .beige, hidCode: 0x39, matrixIndex: 3),
        KeyboardKeyDef(id: "A", primaryLabel: "A", secondaryLabel: "Mac", widthUnits: 1.0, style: .white, hidCode: 0x04, matrixIndex: 9),
        KeyboardKeyDef(id: "S", primaryLabel: "S", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x16, matrixIndex: 15),
        KeyboardKeyDef(id: "D", primaryLabel: "D", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x07, matrixIndex: 21),
        KeyboardKeyDef(id: "F", primaryLabel: "F", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x09, matrixIndex: 27),
        KeyboardKeyDef(id: "G", primaryLabel: "G", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x0A, matrixIndex: 33),
        KeyboardKeyDef(id: "H", primaryLabel: "H", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x0B, matrixIndex: 39),
        KeyboardKeyDef(id: "J", primaryLabel: "J", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x0D, matrixIndex: 45),
        KeyboardKeyDef(id: "K", primaryLabel: "K", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x0E, matrixIndex: 51),
        KeyboardKeyDef(id: "L", primaryLabel: "L", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x0F, matrixIndex: 57),
        KeyboardKeyDef(id: "Ş", primaryLabel: "Ş", secondaryLabel: "ScrLk", widthUnits: 1.0, style: .white, hidCode: 0x33, matrixIndex: 63),
        KeyboardKeyDef(id: "İ", primaryLabel: "İ", secondaryLabel: "PrtSc", widthUnits: 1.0, style: .white, hidCode: 0x34, matrixIndex: 69),
        KeyboardKeyDef(id: "BACKSLASH", primaryLabel: ",", secondaryLabel: ";", widthUnits: 1.0, style: .white, hidCode: 0x31, matrixIndex: 75),
        KeyboardKeyDef(id: "ENTER_BOT", primaryLabel: "ENTER", secondaryLabel: "↵", widthUnits: 1.25, style: .white, hidCode: 0x28, matrixIndex: 81),
        KeyboardKeyDef(id: "PGUP", primaryLabel: "PGUP", secondaryLabel: "▲", widthUnits: 1.0, style: .beige, hidCode: 0x4B, matrixIndex: 93)
    ]

    static let row4: [KeyboardKeyDef] = [
        KeyboardKeyDef(id: "LSHIFT", primaryLabel: "SHIFT", secondaryLabel: "⇧", widthUnits: 1.25, style: .beige, hidCode: 0xE1, matrixIndex: 4),
        KeyboardKeyDef(id: "LESS", primaryLabel: "<", secondaryLabel: ">", widthUnits: 1.0, style: .white, hidCode: 0x64, matrixIndex: 76),
        KeyboardKeyDef(id: "Z", primaryLabel: "Z", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x1D, matrixIndex: 10),
        KeyboardKeyDef(id: "X", primaryLabel: "X", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x1B, matrixIndex: 16),
        KeyboardKeyDef(id: "C", primaryLabel: "C", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x06, matrixIndex: 22),
        KeyboardKeyDef(id: "V", primaryLabel: "V", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x19, matrixIndex: 28),
        KeyboardKeyDef(id: "B", primaryLabel: "B", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x05, matrixIndex: 34),
        KeyboardKeyDef(id: "N", primaryLabel: "N", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x11, matrixIndex: 40),
        KeyboardKeyDef(id: "M", primaryLabel: "M", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x10, matrixIndex: 46),
        KeyboardKeyDef(id: "Ö", primaryLabel: "Ö", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x36, matrixIndex: 52),
        KeyboardKeyDef(id: "Ç", primaryLabel: "Ç", secondaryLabel: nil, widthUnits: 1.0, style: .white, hidCode: 0x37, matrixIndex: 58),
        KeyboardKeyDef(id: "DOT", primaryLabel: ":", secondaryLabel: "Pause", widthUnits: 1.0, style: .white, hidCode: 0x38, matrixIndex: 64),
        KeyboardKeyDef(id: "RSHIFT", primaryLabel: "SHIFT", secondaryLabel: "⇧", widthUnits: 1.75, style: .beige, hidCode: 0xE5, matrixIndex: 82),
        KeyboardKeyDef(id: "UP", primaryLabel: "▲", secondaryLabel: "⚙", widthUnits: 1.0, style: .dark, hidCode: 0x52, matrixIndex: 88),
        KeyboardKeyDef(id: "PGDN", primaryLabel: "PGDN", secondaryLabel: "▼", widthUnits: 1.0, style: .beige, hidCode: 0x4E, matrixIndex: 94)
    ]

    static let row5: [KeyboardKeyDef] = [
        KeyboardKeyDef(id: "LCTRL", primaryLabel: "CTRL", secondaryLabel: "control", widthUnits: 1.25, style: .beige, hidCode: 0xE0, matrixIndex: 5),
        KeyboardKeyDef(id: "LWIN", primaryLabel: "WIN", secondaryLabel: "option", widthUnits: 1.25, style: .beige, hidCode: 0xE3, matrixIndex: 11),
        KeyboardKeyDef(id: "LALT", primaryLabel: "ALT", secondaryLabel: "command", widthUnits: 1.25, style: .beige, hidCode: 0xE2, matrixIndex: 17),
        KeyboardKeyDef(id: "SPACE", primaryLabel: "", secondaryLabel: "————", widthUnits: 6.25, style: .dark, hidCode: 0x2C, matrixIndex: 35),
        KeyboardKeyDef(id: "RALT", primaryLabel: "ALT GR", secondaryLabel: "command", widthUnits: 1.25, style: .beige, hidCode: 0xE6, matrixIndex: 53),
        KeyboardKeyDef(id: "FN", primaryLabel: "FN", secondaryLabel: nil, widthUnits: 1.0, style: .beige, hidCode: 0xFF, matrixIndex: 59),
        KeyboardKeyDef(id: "RCTRL", primaryLabel: "CTRL", secondaryLabel: "option", widthUnits: 1.0, style: .beige, hidCode: 0xE4, matrixIndex: 65),
        KeyboardKeyDef(id: "LEFT", primaryLabel: "◀", secondaryLabel: "〜", widthUnits: 1.0, style: .dark, hidCode: 0x50, matrixIndex: 83),
        KeyboardKeyDef(id: "DOWN", primaryLabel: "▼", secondaryLabel: "☼", widthUnits: 1.0, style: .dark, hidCode: 0x51, matrixIndex: 89),
        KeyboardKeyDef(id: "RIGHT", primaryLabel: "▶", secondaryLabel: "〰", widthUnits: 1.0, style: .dark, hidCode: 0x4F, matrixIndex: 95)
    ]

    static var allKeys: [KeyboardKeyDef] {
        return row0 + row1 + row2 + row3 + row4 + row5
    }

    // Tuş taban birim boyutu
    private let unitSize: CGFloat = 38
    private let keySpacing: CGFloat = 4

    var body: some View {
        VStack(spacing: 8) {
            // KLAVYE ŞASİSİ (Fotoğraftaki beyaz yuvarlatılmış gövde + RGB zemin)
            ZStack {
                // 1. Dış Gövde & RGB Arka Plan Işıltısı
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(white: 0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)

                // 2. RGB Backlight Katmanı (Tuşların arkasından sızan gökkuşağı aydınlatması)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.6),
                                Color.pink.opacity(0.7),
                                Color.purple.opacity(0.7),
                                Color.blue.opacity(0.7),
                                Color.teal.opacity(0.6),
                                Color.green.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(8)
                    .blur(radius: 6)
                    .opacity(0.65)

                // 3. Tuş Tabla Yuvası (Plaka)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(white: 0.92).opacity(0.7))
                    .padding(8)

                // 4. Tuş Matrisi Dizilimi
                VStack(spacing: keySpacing) {
                    // SIRA 0 (F Tuşları & Döner Knob - Klasik 75% Klavye Gruplaması ve Ayrımı)
                    HStack(spacing: 0) {
                        // ESC Tuşu
                        if let esc = Self.row0.first(where: { $0.id == "ESC" }) {
                            renderKey(esc)
                        }

                        // ESC ile F1 arası boşluk
                        Spacer(minLength: 12)

                        // F1 - F4 Grubu
                        HStack(spacing: keySpacing) {
                            ForEach(Self.row0.filter { ["F1", "F2", "F3", "F4"].contains($0.id) }) { key in
                                renderKey(key)
                            }
                        }

                        // F4 ile F5 arası boşluk
                        Spacer(minLength: 12)

                        // F5 - F8 Grubu
                        HStack(spacing: keySpacing) {
                            ForEach(Self.row0.filter { ["F5", "F6", "F7", "F8"].contains($0.id) }) { key in
                                renderKey(key)
                            }
                        }

                        // F8 ile F9 arası boşluk
                        Spacer(minLength: 12)

                        // F9 - F12 Grubu
                        HStack(spacing: keySpacing) {
                            ForEach(Self.row0.filter { ["F9", "F10", "F11", "F12"].contains($0.id) }) { key in
                                renderKey(key)
                            }
                        }

                        // F12 ile Knob arası boşluk
                        Spacer(minLength: 12)

                        // Döner Knob (Fotoğrafın sağ üstündeki metalik silindir tekerlek)
                        renderRotaryKnob()
                    }

                    // SIRA 1 (Sayılar & INS)
                    HStack(spacing: keySpacing) {
                        ForEach(Self.row1) { key in
                            renderKey(key)
                        }
                    }

                    // SIRA 2 (Q Sırası & DEL)
                    HStack(spacing: keySpacing) {
                        ForEach(Self.row2) { key in
                            renderKey(key)
                        }
                    }

                    // SIRA 3 (A Sırası & PGUP)
                    HStack(spacing: keySpacing) {
                        ForEach(Self.row3) { key in
                            renderKey(key)
                        }
                    }

                    // SIRA 4 (Shift Sırası, YUKARI OK & PGDN)
                    HStack(spacing: keySpacing) {
                        ForEach(Self.row4) { key in
                            renderKey(key)
                        }
                    }

                    // SIRA 5 (Spacebar, Alt, Ok Tuşları: Sol, Aşağı, Sağ)
                    HStack(spacing: keySpacing) {
                        ForEach(Self.row5) { key in
                            renderKey(key)
                        }
                    }
                }
                .padding(14)
            }
            .frame(width: 710, height: 310)

            // Alt Bilgilendirme Çubuğu
            if let selected = selectedKeyId {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(red: 0.98, green: 0.18, blue: 0.38))
                        .frame(width: 8, height: 8)
                    Text("Seçili Tuş:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(selected)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))

                    if let macro = assignedMacroNames[selected] {
                        Text("• Atanan Makro: \(macro)")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Text("Tıklayarak makro atayabilir veya tuş işlevini değiştirebilirsiniz")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
        }
    }

    // Tek bir tuşun 3D şık çizimi
    @ViewBuilder
    private func renderKey(_ key: KeyboardKeyDef) -> some View {
        let isSelected = selectedKeyId == key.id
        let hasCustomColor = perKeyColors[key.id]
        let hasMacro = assignedMacroNames[key.id] != nil
        let width = unitSize * key.widthUnits + (key.widthUnits - 1) * keySpacing

        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                selectedKeyId = key.id
            }
            onKeySelected?(key)
        }) {
            ZStack {
                // Tuş Gövdesi ve Rengi
                keyBackground(style: key.style, isSelected: isSelected, customColor: hasCustomColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .shadow(
                        color: isSelected ? Color.red.opacity(0.5) : Color.black.opacity(0.12),
                        radius: isSelected ? 4 : 2,
                        x: 0,
                        y: isSelected ? 1 : 2
                    )

                // Tuş Yazıları ve Simgeleri
                VStack(spacing: 1) {
                    Text(key.primaryLabel)
                        .font(.system(
                            size: key.primaryLabel.count > 4 ? 8 : (key.primaryLabel.count > 2 ? 9 : 12),
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundColor(keyTextColor(style: key.style, isSelected: isSelected))
                        .lineLimit(1)

                    if let sub = key.secondaryLabel, !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(keySubTextColor(style: key.style, isSelected: isSelected))
                            .lineLimit(1)
                    }
                }
                .padding(2)

                // Makro Atama Rozeti
                if hasMacro {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 5, height: 5)
                                .padding(3)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: width, height: unitSize)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // Tuş Arka Plan Rengi
    @ViewBuilder
    private func keyBackground(style: KeycapStyle, isSelected: Bool, customColor: Color?) -> some View {
        if isSelected {
            // Fotoğraftaki gibi kırmızı seçim vurgusu
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.2, blue: 0.25), Color(red: 0.78, green: 0.1, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if let col = customColor {
            col
        } else {
            switch style {
            case .white:
                LinearGradient(
                    colors: [Color(white: 1.0), Color(white: 0.94)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .beige:
                LinearGradient(
                    colors: [Color(red: 0.82, green: 0.83, blue: 0.78), Color(red: 0.74, green: 0.75, blue: 0.70)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .dark:
                LinearGradient(
                    colors: [Color(white: 0.32), Color(white: 0.22)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    // Tuş Metin Rengi
    private func keyTextColor(style: KeycapStyle, isSelected: Bool) -> Color {
        if isSelected {
            return .white
        }
        switch style {
        case .white:
            return Color(white: 0.15)
        case .beige:
            return Color(white: 0.20)
        case .dark:
            return .white
        }
    }

    private func keySubTextColor(style: KeycapStyle, isSelected: Bool) -> Color {
        if isSelected {
            return .white.opacity(0.85)
        }
        switch style {
        case .white:
            return Color(white: 0.45)
        case .beige:
            return Color(white: 0.40)
        case .dark:
            return .white.opacity(0.7)
        }
    }

    // Döner Tekerlek (Rotary Knob)
    @ViewBuilder
    private func renderRotaryKnob() -> some View {
        Button(action: {
            onKnobRotatedOrClicked?()
        }) {
            ZStack {
                // Dış Gövde
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.45), Color(white: 0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: unitSize + 2, height: unitSize + 2)
                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)

                // Metalik Döner Halka
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.black.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: unitSize - 2, height: unitSize - 2)

                // Merkez Gösterge Noktası
                Circle()
                    .fill(keyboardManager.wheelMode == .volume ? Color.blue : Color(red: 0.98, green: 0.18, blue: 0.38))
                    .frame(width: 6, height: 6)
                    .offset(y: -9)

                // İkon
                Image(systemName: keyboardManager.wheelMode == .volume ? "speaker.wave.2.fill" : "sun.max.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .help("Döner Tekerlek: Tıklayarak Ses ve RGB Parlaklık modları arasında geçiş yapabilirsiniz")
    }
}
