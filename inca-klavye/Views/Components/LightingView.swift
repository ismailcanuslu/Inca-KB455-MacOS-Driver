import SwiftUI

enum LightingSection: String, CaseIterable, Identifiable {
    case mainKeys = "Aydınlatma Efektleri"
    case customLighting = "Kişisel Aydınlatma"
    case musicSync = "Müzik Ritmi"
    
    var id: String { self.rawValue }
    var icon: String {
        switch self {
        case .mainKeys: return "sparkles"
        case .customLighting: return "paintpalette.fill"
        case .musicSync: return "waveform"
        }
    }
}

struct LightingView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    
    @State private var activeSection: LightingSection = .mainKeys
    
    // Ana Tuş Takımı Ayarları
    @State private var keyboardColor: Color = Color(red: 0.98, green: 0.18, blue: 0.38) // Apple Music Pink
    @State private var brightness: Double = 100.0
    @State private var speed: Double = 2.0
    @State private var selectedEffect: LightingEffect = .rainbow
    @State private var isMulticolor: Bool = false
    
    // Yan Şerit LED Ayarları
    @State private var sideLedColor: Color = Color(red: 0.0, green: 0.85, blue: 1.0) // Neon Cyan
    @State private var sideBrightness: Double = 75.0
    @State private var sideSpeed: Double = 2.0
    @State private var selectedSideEffect: SideLEDEffect = .streaming

    // Kişisel Aydınlatma (LedOpt 19 / Özel Matris) Ayarları
    @State private var customBrushColor: Color = Color(red: 0.98, green: 0.18, blue: 0.38)
    @State private var customKeyColors: [String: Color] = [:]
    @State private var selectedKeyIdForCustom: String? = nil
    @State private var customMatrixSuccessFeedback: String? = nil



    // Apple Music tarzı canlı RGB renk paleti
    let presetColors: [(name: String, color: Color)] = [
        ("Apple Kırmızı", Color(red: 0.98, green: 0.18, blue: 0.38)),
        ("Neon Cyan", Color(red: 0.0, green: 0.85, blue: 1.0)),
        ("Aurora Yeşil", Color(red: 0.2, green: 0.95, blue: 0.45)),
        ("Elektrik Mor", Color(red: 0.68, green: 0.26, blue: 0.98)),
        ("Güneş Sarısı", Color(red: 1.0, green: 0.82, blue: 0.1)),
        ("Ateş Turuncu", Color(red: 1.0, green: 0.45, blue: 0.1)),
        ("Buz Beyazı", Color.white),
        ("Koyu Mavi", Color(red: 0.0, green: 0.48, blue: 1.0))
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                // 1. Apple Music Tarzı Hero Banner (Seçili efekte dinamik uyum sağlar)
                AppleMusicHeroCard(
                    keyboardManager: keyboardManager,
                    currentColor: isMulticolor ? Color.purple : keyboardColor,
                    activeEffectName: currentActiveTitle,
                    selectedEffect: selectedEffect,
                    isMulticolor: isMulticolor
                )

                // 2. Aydınlatma Modu Seçici Segment (Apple Music Segmented Control)
                HStack(spacing: 8) {
                    ForEach(LightingSection.allCases) { section in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                activeSection = section
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: section.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(section.rawValue)
                                    .font(.system(size: 13, weight: activeSection == section ? .bold : .medium))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .foregroundColor(activeSection == section ? .white : .secondary)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(activeSection == section ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.06))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()

                    // Klavyeden Donanım Aydınlatma Durumunu Yenile
                    Button(action: {
                        keyboardManager.queryCurrentLighting()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .bold))
                            Text("Yenile")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing))
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .help("Klavyenin mevcut donanım aydınlatma modunu ve parlaklığını sorgular")
                }

                // 3. Bölüm İçeriği
                switch activeSection {
                case .mainKeys:
                    mainKeysLightingSection
                case .customLighting:
                    customLightingSection
                case .musicSync:
                    musicSyncSection
                }
            }
            .padding(24)
        }
        .onReceive(keyboardManager.$activeBrightness) { newBrightness in
            let newPercent = Double(newBrightness) * 25.0
            if abs(brightness - newPercent) > 1.0 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    brightness = newPercent
                }
            }
        }
        .onReceive(keyboardManager.$activeSpeed) { newSpeed in
            if Int(speed) != Int(newSpeed) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    speed = Double(min(4, newSpeed))
                }
            }
        }
        .onReceive(keyboardManager.$activeEffectId) { newEffectId in
            if let effect = LightingEffect(rawValue: newEffectId), selectedEffect != effect {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedEffect = effect
                }
            }
        }
    }

    private var currentActiveTitle: String {
        switch activeSection {
        case .mainKeys:
            return selectedEffect.name
        case .customLighting:
            return "Kişisel Tuş Matrisi (Özel)"
        case .musicSync:
            return keyboardManager.activeMusicMode?.name ?? "Müzik Ritmi"
        }
    }

    private var filteredEffects: [LightingEffect] {
        LightingEffect.allCases.filter { $0 != .custom && $0 != .off }
    }

    // MARK: - 1. Ana Tuş Takımı Bölümü
    private var mainKeysLightingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Hızlı Ayarlar: Parlaklık, Hız, Renk
            quickControlsView(
                brightnessValue: $brightness,
                speedValue: $speed,
                selectedColor: $keyboardColor,
                isMulticolor: $isMulticolor,
                supportsMulticolor: selectedEffect.supportsMulticolor,
                onBrightnessChange: markUnsaved,
                onSpeedChange: markUnsaved,
                onColorChange: markUnsaved
            )

            // Efekt Seçici Grid
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("ANA AYDINLATMA EFEKTLERİ")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    Spacer()
                    Text("\(filteredEffects.count) Donanım Modu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 14)], spacing: 14) {
                    ForEach(filteredEffects) { effect in
                        EffectCardView(
                            title: effect.name,
                            subTitle: effect.subtitle,
                            icon: effect.icon,
                            isSelected: selectedEffect == effect && keyboardManager.activeMusicMode == nil,
                            accentColor: isMulticolor ? Color.purple : keyboardColor
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedEffect = effect
                                // Efekt çok renkli desteklemiyorsa multi-color modunu sıfırla
                                if !effect.supportsMulticolor {
                                    isMulticolor = false
                                }
                                markUnsaved()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 2. Yan Şerit (Side LED) Bölümü
    private var sideLedLightingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Yan Şerit Açıklama Kartı
            HStack(spacing: 14) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 26))
                    .foregroundColor(sideLedColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Empousa Çevresel Yan Şerit LED (Side Glow)")
                        .font(.system(size: 14, weight: .bold))
                    Text("Klavyenin alt ve yan şeritlerinden masaya yansıyan dinamik atmosfer aydınlatmasını özelleştirin.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))

            // Hızlı Ayarlar: Parlaklık, Hız, Renk
            quickControlsView(
                brightnessValue: $sideBrightness,
                speedValue: $sideSpeed,
                selectedColor: $sideLedColor,
                onBrightnessChange: markUnsaved,
                onSpeedChange: markUnsaved,
                onColorChange: markUnsaved
            )

            // Yan Şerit Efektleri Grid
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("YAN ŞERİT EFEKTLERİ")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    Spacer()
                    Text("\(SideLEDEffect.allCases.count) Donanım Modu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 14)], spacing: 14) {
                    ForEach(SideLEDEffect.allCases) { effect in
                        EffectCardView(
                            title: effect.name,
                            subTitle: effect.subtitle,
                            icon: effect.icon,
                            isSelected: selectedSideEffect == effect,
                            accentColor: sideLedColor
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedSideEffect = effect
                                markUnsaved()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 3. Kişisel Aydınlatma Bölümü (LedOpt 19 - 126 Tuş Matrisi)
    private var customLightingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Başlık & Açıklama Banner'ı
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [customBrushColor, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Kişisel Tuş Aydınlatması (LedOpt 19)")
                        .font(.system(size: 16, weight: .bold))
                    Text("126 tuşun tamamını dilediğiniz renkle bağımsız olarak özelleştirin. Aşağıdaki fırça rengini seçip klavyedeki tuşlara tıklayarak kendi temanızı oluşturun.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let success = customMatrixSuccessFeedback {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(success)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(10)
                    .transition(.opacity)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))

            // Fırça Renkleri ve Hızlı Şablonlar
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("FIRÇA RENGİ")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    Spacer()
                    ColorPicker("Özel Fırça Rengi", selection: $customBrushColor)
                        .labelsHidden()
                }

                HStack(spacing: 12) {
                    ForEach(presetColors, id: \.name) { preset in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                customBrushColor = preset.color
                            }
                        }) {
                            Circle()
                                .fill(preset.color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: customBrushColor == preset.color ? 2.5 : 0)
                                )
                                .shadow(color: preset.color.opacity(customBrushColor == preset.color ? 0.7 : 0.2), radius: 6)
                        }
                        .buttonStyle(.plain)
                        .help(preset.name)
                    }

                    Spacer()

                    // Hızlı Şablon Butonları
                    HStack(spacing: 8) {
                        Button(action: applyGamerPreset) {
                            HStack(spacing: 5) {
                                Image(systemName: "gamecontroller.fill")
                                Text("WASD & Yönler")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Button(action: applyRainbowRowsPreset) {
                            HStack(spacing: 5) {
                                Image(systemName: "rainbow")
                                Text("Gökkuşağı")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Button(action: fillAllKeysWithBrush) {
                            HStack(spacing: 5) {
                                Image(systemName: "paintbrush.fill")
                                Text("Tümünü Boya")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Button(action: clearAllCustomKeys) {
                            HStack(spacing: 5) {
                                Image(systemName: "trash")
                                Text("Temizle")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.12))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))

            // İnteraktif Klavye Matrisi
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("İNTERAKTİF TUŞ MATRİSİ (BOYAMAK İÇİN TIKLAYIN)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    Spacer()
                    Text("\(customKeyColors.count) Tuş Renklendirildi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                EmpousaKeyboardGraphicView(
                    keyboardManager: keyboardManager,
                    selectedKeyId: $selectedKeyIdForCustom,
                    perKeyColors: customKeyColors,
                    onKeySelected: { key in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            customKeyColors[key.id] = customBrushColor
                        }
                    }
                )
            }

            // Klavyeye Gönder / Uygula Barı
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Özel Renk Matrisini Uygula")
                        .font(.system(size: 13, weight: .bold))
                    Text(keyboardManager.connectionType == .wiredUSB ? "Kablolu USB modunda 126 tuşun tam RGB profili doğrudan donanım çipine aktarılır." : "Özel tuş matrisini tam renkli yüklemek için klavyeyi Type-C kablosuyla bağlayın.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: sendCustomMatrixToKeyboard) {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text("Klavyeye Yükle & Kaydet")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 13))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: Color.purple.opacity(0.35), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private func applyGamerPreset() {
        var newColors: [String: Color] = [:]
        let gamerKeys = ["W", "A", "S", "D", "UP", "DOWN", "LEFT", "RIGHT", "ESC", "SPACE"]
        for key in EmpousaKeyboardGraphicView.allKeys {
            if gamerKeys.contains(key.id) {
                newColors[key.id] = customBrushColor
            } else {
                newColors[key.id] = Color.blue.opacity(0.18)
            }
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            customKeyColors = newColors
        }
    }

    private func applyRainbowRowsPreset() {
        var newColors: [String: Color] = [:]
        let rowColors: [Color] = [
            Color.red,
            Color.orange,
            Color.yellow,
            Color.green,
            Color.cyan,
            Color.purple
        ]
        let rows = [
            EmpousaKeyboardGraphicView.row0,
            EmpousaKeyboardGraphicView.row1,
            EmpousaKeyboardGraphicView.row2,
            EmpousaKeyboardGraphicView.row3,
            EmpousaKeyboardGraphicView.row4,
            EmpousaKeyboardGraphicView.row5
        ]
        for (i, row) in rows.enumerated() {
            let col = rowColors[i % rowColors.count]
            for key in row {
                newColors[key.id] = col
            }
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            customKeyColors = newColors
        }
    }

    private func fillAllKeysWithBrush() {
        var newColors: [String: Color] = [:]
        for key in EmpousaKeyboardGraphicView.allKeys {
            newColors[key.id] = customBrushColor
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            customKeyColors = newColors
        }
    }

    private func clearAllCustomKeys() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            customKeyColors.removeAll()
        }
    }

    private func sendCustomMatrixToKeyboard() {
        // 378 baytlık donanımsal renk matrisi:
        // Sniff Paket 851 & 861 kanıtı: Veri düzlemsel (planar) olarak iletilir:
        // 0..125:   Kırmızı (Red) düzlemi   -> key.matrixIndex
        // 126..251: Yeşil (Green) düzlemi   -> 126 + key.matrixIndex
        // 252..377: Mavi (Blue) düzlemi     -> 252 + key.matrixIndex
        var rgbBuffer = [UInt8](repeating: 0, count: 378)
        for key in EmpousaKeyboardGraphicView.allKeys {
            let col = customKeyColors[key.id] ?? Color.black
            if let comps = col.cgColor?.components, comps.count >= 3 {
                let r = UInt8(max(0, min(255, comps[0] * 255)))
                let g = UInt8(max(0, min(255, comps[1] * 255)))
                let b = UInt8(max(0, min(255, comps[2] * 255)))
                let idx = key.matrixIndex
                if idx < 126 {
                    rgbBuffer[idx] = r
                    rgbBuffer[126 + idx] = g
                    rgbBuffer[252 + idx] = b
                }
            }
        }

        keyboardManager.triggerSavingStatus(message: "Özel Renk Haritası Yükleniyor...")
        keyboardManager.applyCustomKeyColors(rgbData: rgbBuffer)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            customMatrixSuccessFeedback = "Özel Tuş Renk Haritası klavyeye başarıyla aktarıldı!"
        }
        keyboardManager.triggerSavedSuccess(message: "Kişisel Renkler Kaydedildi!")

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation {
                customMatrixSuccessFeedback = nil
            }
        }
    }

    // MARK: - 4. Müzik Senkronizasyon Bölümü
    private var musicSyncSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Müzik Görselleştirici Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dinamik Ses ve Müzik Ritmi")
                            .font(.system(size: 17, weight: .bold))
                        Text("Çalan müziğe ve çevre seslerine göre klavye LED'lerinin dans ettiği donanımsal ritim algoritmaları.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // Canlı Ekolayzır Animasyonu
                    HStack(spacing: 3) {
                        ForEach(0..<6) { idx in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient(colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple], startPoint: .bottom, endPoint: .top))
                                .frame(width: 4, height: CGFloat(12 + ((idx * 7) % 18)))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))

            // 10 Müzik Modu Grid
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("MÜZİK RİTİM PRESETLERİ")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    Spacer()
                    Text("10 Donanımsal Ritim")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 14)], spacing: 14) {
                    ForEach(MusicSyncMode.allCases) { mode in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if keyboardManager.activeMusicMode == mode {
                                    keyboardManager.stopMusicSync()
                                } else {
                                    keyboardManager.applyMusicSync(mode: mode)
                                }
                            }
                        }) {
                            let isActive = keyboardManager.activeMusicMode == mode
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            isActive
                                            ? LinearGradient(colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .frame(width: 42, height: 42)

                                    Image(systemName: mode.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(isActive ? .white : .primary)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(mode.name)
                                        .font(.system(size: 13, weight: isActive ? .bold : .medium))
                                        .foregroundColor(isActive ? Color(red: 0.98, green: 0.18, blue: 0.38) : .primary)
                                        .lineLimit(1)
                                    Text(mode.subtitle)
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if isActive {
                                    Image(systemName: "waveform.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isActive ? Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.4))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(isActive ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.08), lineWidth: isActive ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Yardımcı Hızlı Kontrol Bileşeni
    @ViewBuilder
    private func quickControlsView(
        brightnessValue: Binding<Double>,
        speedValue: Binding<Double>,
        selectedColor: Binding<Color>,
        isMulticolor: Binding<Bool> = .constant(false),
        supportsMulticolor: Bool = false,
        onBrightnessChange: @escaping () -> Void,
        onSpeedChange: @escaping () -> Void,
        onColorChange: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("HIZLI AYARLAR")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1.2)

            HStack(spacing: 20) {
                // Parlaklık Slider
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Parlaklık", systemImage: "sun.max.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(brightnessValue.wrappedValue == 0 ? "KAPALI (0/4)" : "Seviye \(Int(round(brightnessValue.wrappedValue / 25.0)))/4")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(brightnessValue.wrappedValue == 0 ? .red : .secondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "sun.min")
                            .foregroundColor(.secondary)
                        Slider(value: brightnessValue, in: 0...100, step: 25) { _ in
                            onBrightnessChange()
                        }
                        .tint(selectedColor.wrappedValue)
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))

                // Efekt Hızı Slider
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Efekt Hızı", systemImage: "speedometer")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text("Seviye \(Int(speedValue.wrappedValue) + 1)/5")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "tortoise.fill")
                            .foregroundColor(.secondary)
                        Slider(value: speedValue, in: 0...4, step: 1) { _ in
                            onSpeedChange()
                        }
                        .tint(selectedColor.wrappedValue)
                        Image(systemName: "hare.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }

            // Renk Paleti & Picker
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("RENK PALETİ")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    Spacer()
                    // Çok Renkli modu açıksa color picker'ı gizle
                    if !isMulticolor.wrappedValue {
                        ColorPicker("Özel Renk Seç", selection: selectedColor)
                            .labelsHidden()
                            .onChange(of: selectedColor.wrappedValue) { _, _ in
                                onColorChange()
                            }
                    }
                }

                HStack(spacing: 14) {
                    // Çok Renkli (Rainbow) Butonu — yalnızca destekleyen efektlerde görünür
                    if supportsMulticolor {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isMulticolor.wrappedValue.toggle()
                            }
                            onColorChange()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        AngularGradient(
                                            colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                                            center: .center
                                        )
                                    )
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: isMulticolor.wrappedValue ? 2.5 : 0)
                                    )
                                    .shadow(color: Color.purple.opacity(isMulticolor.wrappedValue ? 0.7 : 0.2), radius: 6)

                                if isMulticolor.wrappedValue {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Çok Renkli (Gökkuşağı Spektrumu)")

                        // Ayırıcı çizgi
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 1, height: 26)
                    }

                    // Tek Renkli preset'ler (Çok Renkli aktifse soluk göster)
                    ForEach(presetColors, id: \.name) { preset in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isMulticolor.wrappedValue = false
                                selectedColor.wrappedValue = preset.color
                            }
                            onColorChange()
                        }) {
                            Circle()
                                .fill(preset.color)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: !isMulticolor.wrappedValue && selectedColor.wrappedValue == preset.color ? 2.5 : 0)
                                    )
                                .shadow(color: preset.color.opacity(!isMulticolor.wrappedValue && selectedColor.wrappedValue == preset.color ? 0.7 : 0.2), radius: 6)
                                .opacity(isMulticolor.wrappedValue ? 0.35 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .help(preset.name)
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private func applyMainSettings() {
        if selectedEffect == .off {
            keyboardManager.turnOffLights()
            return
        }
        
        let hwBrightness = UInt8(round((brightness / 100.0) * 4.0))
        if hwBrightness == 0 {
            keyboardManager.turnOffLights()
            return
        }

        guard let components = keyboardColor.cgColor?.components, components.count >= 3 else {
            return
        }
        let r = UInt8(max(0, min(255, components[0] * 255)))
        let g = UInt8(max(0, min(255, components[1] * 255)))
        let b = UInt8(max(0, min(255, components[2] * 255)))
        let hwSpeed = UInt8(speed)

        keyboardManager.applyLighting(
            effect: selectedEffect.rawValue,
            speed: hwSpeed,
            brightness: hwBrightness,
            red: r,
            green: g,
            blue: b,
            isMulticolor: isMulticolor
        )
    }

    private func applySideSettings() {
        guard let components = sideLedColor.cgColor?.components, components.count >= 3 else {
            return
        }
        let r = UInt8(max(0, min(255, components[0] * 255)))
        let g = UInt8(max(0, min(255, components[1] * 255)))
        let b = UInt8(max(0, min(255, components[2] * 255)))
        let hwBrightness = UInt8(round((sideBrightness / 100.0) * 4.0))
        let hwSpeed = UInt8(sideSpeed)

        keyboardManager.applySideLED(
            effect: selectedSideEffect.rawValue,
            speed: hwSpeed,
            brightness: hwBrightness,
            red: r,
            green: g,
            blue: b
        )
    }

    // MARK: - Donanım Koruması: Kaydet & Vazgeç İşlemleri
    private func markUnsaved() {
        keyboardManager.triggerUnsavedStatus(
            description: "Işıklandırma: \(selectedEffect.name)",
            onCommit: {
                commitChanges()
            },
            onDiscard: {
                discardChanges()
            }
        )
    }

    private func commitChanges() {
        keyboardManager.triggerSavingStatus(message: "Işıklar Kaydediliyor...")
        applyMainSettings()
        keyboardManager.triggerSavedSuccess(message: "Işık Ayarları Kaydedildi!")
    }

    private func discardChanges() {
        keyboardManager.queryCurrentLighting()
        keyboardManager.triggerIdleStatus()
    }
}

// Apple Music Albüm Kapağı Estetiğinde Efekt Kartı
struct EffectCardView: View {
    let title: String
    let subTitle: String
    let icon: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Albüm Kapağı Sanatı
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [accentColor, accentColor.opacity(0.6)] : [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 90)

                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(isSelected ? .white : .primary.opacity(0.8))
                        .shadow(color: isSelected ? Color.black.opacity(0.3) : .clear, radius: 4)
                }

                // Efekt Başlığı
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? accentColor : .primary)
                        .lineLimit(1)

                    Text(subTitle)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? accentColor : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? accentColor.opacity(0.3) : Color.clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}
