import SwiftUI

struct LightingView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared
    
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

    // Renk Paleti Hover (Üzerine Gelme) Durumları
    @State private var hoveredColorName: String? = nil

    // Apple Music tarzı canlı RGB renk paleti
    let presetColors: [(name: String, color: Color)] = [
        ("Kırmızı", Color(red: 0.98, green: 0.18, blue: 0.38)),
        ("Açık Mavi (Cyan)", Color(red: 0.0, green: 0.85, blue: 1.0)),
        ("Yeşil", Color(red: 0.2, green: 0.95, blue: 0.45)),
        ("Mor", Color(red: 0.68, green: 0.26, blue: 0.98)),
        ("Sarı", Color(red: 1.0, green: 0.82, blue: 0.1)),
        ("Turuncu", Color(red: 1.0, green: 0.45, blue: 0.1)),
        ("Beyaz", Color.white),
        ("Mavi", Color(red: 0.0, green: 0.48, blue: 1.0))
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                // 1. Apple Music Tarzı Hero Banner (Seçili efekte dinamik uyum sağlar)
                AppleMusicHeroCard(
                    keyboardManager: keyboardManager,
                    currentColor: isMulticolor ? Color.purple : keyboardColor,
                    activeEffectName: currentActiveTitle,
                    selectedEffect: activeLightingEffect,
                    isMulticolor: isMulticolor
                )

                // 2. Aksiyon Butonları (Kaydet ve Yenile)
                HStack(spacing: 8) {
                    Spacer()

                    // Kaydet Butonu (Apple HIG tasarımına uygun sade, modern buton)
                    Button(action: {
                        commitChanges()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(loc.tr("island_save_btn", default: "Kaydet"))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 16)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(red: 0.98, green: 0.18, blue: 0.38))
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Seçili aydınlatma ve yan şerit ayarlarını klavyeye kaydeder")

                    // Klavyeden Donanım Aydınlatma Durumunu Yenile
                    Button(action: {
                        keyboardManager.queryCurrentLighting()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                            Text(loc.tr("tc_refresh", default: "Yenile"))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .foregroundColor(.primary)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .help(loc.tr("tc_refresh_help", default: "Klavyenin mevcut donanım aydınlatma modunu ve parlaklığını sorgular"))
                }

                // 3. Ana Tuş Takımı Aydınlatma Efektleri
                mainKeysLightingSection

                Divider()
                    .padding(.vertical, 8)

                // 4. Yan Şerit LED Aydınlatma Efektleri
                sideLedLightingSection
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
        .onAppear {
            if let effect = LightingEffect(rawValue: keyboardManager.activeEffectId) {
                selectedEffect = effect
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

    private var activeLightingEffect: LightingEffect {
        LightingEffect(rawValue: keyboardManager.activeEffectId) ?? selectedEffect
    }

    private var currentActiveTitle: String {
        if let music = keyboardManager.activeMusicMode {
            return music.name
        }
        if keyboardManager.activeEffectId == LightingEffect.custom.rawValue || keyboardManager.activeEffectId == 21 {
            return loc.tr("tab_custom_lighting", default: "Özelleştirilmiş Aydınlatma")
        }
        if let active = LightingEffect(rawValue: keyboardManager.activeEffectId) {
            return active.localizedName(loc: loc)
        }
        return selectedEffect.localizedName(loc: loc)
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
                    Text(loc.tr("lighting_main_header", default: "ANA AYDINLATMA EFEKTLERİ"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    Spacer()
                    Text("\(filteredEffects.count) " + loc.tr("lighting_modes_count", default: "Donanım Modu"))
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
                    Text(loc.tr("lighting_side_title", default: "Empousa Çevresel Yan Şerit LED (Side Glow)"))
                        .font(.system(size: 14, weight: .bold))
                    Text(loc.tr("lighting_side_desc", default: "Klavyenin alt ve yan şeritlerinden masaya yansıyan dinamik atmosfer aydınlatmasını özelleştirin."))
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
                    Text(loc.tr("lighting_side_header", default: "YAN ŞERİT EFEKTLERİ"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    Spacer()
                    Text("\(SideLEDEffect.allCases.count) " + loc.tr("lighting_modes_count", default: "Donanım Modu"))
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
            Text(loc.tr("lighting_quick_settings", default: "HIZLI AYARLAR"))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1.2)

            HStack(spacing: 20) {
                // Parlaklık Slider
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(loc.tr("lighting_brightness", default: "Parlaklık"), systemImage: "sun.max.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(brightnessValue.wrappedValue == 0 ? loc.tr("lighting_off", default: "KAPALI") + " (0/4)" : loc.tr("lighting_level", default: "Seviye") + " \(Int(round(brightnessValue.wrappedValue / 25.0)))/4")
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
                        Label(loc.tr("lighting_speed", default: "Efekt Hızı"), systemImage: "speedometer")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(loc.tr("lighting_level", default: "Seviye") + " \(Int(speedValue.wrappedValue) + 1)/5")
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
                HStack(spacing: 8) {
                    Text(loc.tr("lighting_palette", default: "RENK PALETİ"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    if let hovered = hoveredColorName {
                        HStack(spacing: 5) {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(hovered)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .transition(.opacity)
                    }

                    Spacer()
                    // Çok Renkli modu kapalıysa anlaşılır Özel Renk / HEX butonu
                    if !isMulticolor.wrappedValue {
                        QuickColorPickerButton(
                            selectedColor: selectedColor,
                            onColorChange: onColorChange
                        )
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
                            .scaleEffect(hoveredColorName == "Çok Renkli (Gökkuşağı)" ? 1.15 : 1.0)
                            .overlay(alignment: .top) {
                                if hoveredColorName == "Çok Renkli (Gökkuşağı)" {
                                    Text("Çok Renkli (Gökkuşağı)")
                                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 3.5)
                                        .background(
                                            Capsule()
                                                .fill(Color.black.opacity(0.9))
                                                .shadow(color: Color.purple.opacity(0.5), radius: 6, y: 2)
                                        )
                                        .overlay(
                                            Capsule().stroke(Color.purple.opacity(0.6), lineWidth: 1.5)
                                        )
                                        .fixedSize()
                                        .offset(y: -34)
                                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                                        .zIndex(100)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .zIndex(hoveredColorName == "Çok Renkli (Gökkuşağı)" ? 60 : 1)
                        .onHover { isHovered in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredColorName = isHovered ? "Çok Renkli (Gökkuşağı)" : nil
                            }
                        }
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
                                .scaleEffect(hoveredColorName == preset.name ? 1.15 : 1.0)
                                .overlay(alignment: .top) {
                                    if hoveredColorName == preset.name {
                                        Text(preset.name)
                                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 3.5)
                                            .background(
                                                Capsule()
                                                    .fill(Color.black.opacity(0.9))
                                                    .shadow(color: preset.color.opacity(0.5), radius: 6, y: 2)
                                            )
                                            .overlay(
                                                Capsule().stroke(preset.color.opacity(0.6), lineWidth: 1.5)
                                            )
                                            .fixedSize()
                                            .offset(y: -34)
                                            .transition(.opacity.combined(with: .scale(scale: 0.85)))
                                            .zIndex(100)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .zIndex(hoveredColorName == preset.name ? 60 : 1)
                        .onHover { isHovered in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredColorName = isHovered ? preset.name : nil
                            }
                        }
                        .help(preset.name)
                    }
                }
                .padding(.top, 10)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .zIndex(30)
        }
        .zIndex(20)
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
        keyboardManager.triggerSavingStatus(message: "Klavyeye Gönderiliyor...")
        applyMainSettings()
        applySideSettings()
        keyboardManager.triggerSavedSuccess(message: "Işık Ayarları Klavyeye Gönderildi!")
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
