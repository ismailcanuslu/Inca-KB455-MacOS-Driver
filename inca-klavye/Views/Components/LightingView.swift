import SwiftUI

enum LightingSection: String, CaseIterable, Identifiable {
    case mainKeys = "Aydınlatma Efektleri"
    case customLighting = "Kişisel Aydınlatma"
    case musicSync = "Müzik Ritmi"
    
    var id: String { self.rawValue }
    func title(loc: LocalizationManager = .shared) -> String {
        switch self {
        case .mainKeys: return loc.tr("lighting_section_effects", default: "Aydınlatma Efektleri")
        case .customLighting: return loc.tr("lighting_custom_header", default: "Kişisel Aydınlatma")
        case .musicSync: return loc.tr("tc_music1", default: "Müzik Ritmi")
        }
    }
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
    @ObservedObject var loc = LocalizationManager.shared
    
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
    @State private var isShowingBrushColorPicker: Bool = false
    @State private var isShowingKeyColorPicker: Bool = false
    @State private var isHoveringApplyButton: Bool = false

    // Renk Paleti Hover (Üzerine Gelme) Durumları
    @State private var hoveredColorName: String? = nil
    @State private var hoveredBrushColorName: String? = nil

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
                                Text(section.title(loc: loc))
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

                    // Klavyeye Gönder Butonu (Kullanıcı dilediğinde komutları klavyeye gönderir)
                    Button(action: {
                        commitChanges()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(loc.tr("island_save_btn", default: "Klavyeye Gönder"))
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple], startPoint: .leading, endPoint: .trailing))
                        )
                        .shadow(color: Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.35), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .help("Seçili aydınlatma ve yan şerit ayarlarını klavyeye gönderir")

                    // Klavyeden Donanım Aydınlatma Durumunu Yenile
                    Button(action: {
                        keyboardManager.queryCurrentLighting()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .bold))
                            Text(loc.tr("tc_refresh", default: "Yenile"))
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
                    .help(loc.tr("tc_refresh_help", default: "Klavyenin mevcut donanım aydınlatma modunu ve parlaklığını sorgular"))
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
                    Text(loc.tr("lighting_custom_header", default: "Kişisel Tuş Aydınlatması"))
                        .font(.system(size: 16, weight: .bold))
                    Text(loc.tr("lighting_palette_banner_desc", default: "126 tuşun tamamını dilediğiniz renkle bağımsız olarak özelleştirin. Aşağıdaki fırça rengini seçip klavyedeki tuşlara tıklayarak kendi temanızı oluşturun."))
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
                HStack(spacing: 8) {
                    Text(loc.tr("lighting_brush_title", default: "FIRÇA RENGİ"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    if let hovered = hoveredBrushColorName {
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

                    // Modern Uygulama İçi Renk Seçici Butonu
                    Button(action: {
                        isShowingBrushColorPicker = true
                    }) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(customBrushColor)
                                .frame(width: 14, height: 14)
                                .shadow(color: customBrushColor.opacity(0.6), radius: 3)
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 10))
                            Text(loc.tr("lighting_custom_brush_btn", default: "Özel Renk"))
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isShowingBrushColorPicker, arrowEdge: .bottom) {
                        ModernColorPickerView(
                            selectedColor: $customBrushColor,
                            title: loc.tr("lighting_brush_picker_title", default: "Fırça Rengi Seçici"),
                            onColorChanged: { newColor in
                                customBrushColor = newColor
                            },
                            onClose: {
                                isShowingBrushColorPicker = false
                            }
                        )
                    }
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
                                .scaleEffect(hoveredBrushColorName == preset.name ? 1.15 : 1.0)
                                .overlay(alignment: .top) {
                                    if hoveredBrushColorName == preset.name {
                                        Text(preset.name)
                                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
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
                                            .offset(y: -32)
                                            .transition(.opacity.combined(with: .scale(scale: 0.85)))
                                            .zIndex(100)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .onHover { isHovered in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredBrushColorName = isHovered ? preset.name : nil
                            }
                        }
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

            // 5 Adet Bilgisayar Diski Profil Slotu (İsteyen kullanıcı diske kaydeder)
            CustomLightingSlotsView(
                customKeyColors: $customKeyColors,
                onSlotApplied: {
                    markUnsaved()
                }
            )

            // İnteraktif Klavye Matrisi
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(loc.tr("lighting_matrix_header", default: "İNTERAKTİF TUŞ MATRİSİ (BOYAMAK İÇİN TIKLAYIN)"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    Spacer()
                    Text("\(customKeyColors.count) " + loc.tr("lighting_painted_keys_count", default: "Tuş Renklendirildi"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                EmpousaKeyboardGraphicView(
                    keyboardManager: keyboardManager,
                    selectedKeyId: $selectedKeyIdForCustom,
                    perKeyColors: customKeyColors,
                    showFooterBar: false,
                    onKeySelected: { key in
                        if selectedKeyIdForCustom == key.id {
                            // Tuş zaten seçiliyken tekrar tıklanırsa hızlı fırçala
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                customKeyColors[key.id] = customBrushColor
                                markUnsaved()
                            }
                        } else {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedKeyIdForCustom = key.id
                            }
                        }
                    }
                )

                // Seçili Tuş Aydınlatma Rengi & Modern Renk Seçici Barı
                if let keyId = selectedKeyIdForCustom {
                    let keyColor = customKeyColors[keyId] ?? Color.black
                    let isKeyPainted = customKeyColors[keyId] != nil

                    HStack(spacing: 12) {
                        // Başında yuvarlak şeklinde rengin neye benzediğini gösteren daire
                        Button(action: {
                            isShowingKeyColorPicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(keyColor)
                                    .frame(width: 24, height: 24)
                                    .shadow(color: keyColor.opacity(isKeyPainted ? 0.8 : 0.2), radius: 6)

                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                    .frame(width: 24, height: 24)

                                if !isKeyPainted {
                                    Image(systemName: "slash.circle")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Rengi modern renk seçiciyle değiştirmek için tıklayın")

                        // Seçili Tuş & Aydınlatma Rengi (RGB ve Hex)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(loc.tr("lighting_selected_key", default: "Seçili Tuş:"))
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text(keyId)
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundColor(.primary)

                                if !isKeyPainted {
                                    Text(loc.tr("lighting_unpainted_key", default: "• Boyanmamış (Işıksız)"))
                                        .font(.system(size: 10.5, weight: .medium))
                                        .foregroundColor(.secondary.opacity(0.8))
                                }
                            }

                            HStack(spacing: 6) {
                                Text(loc.tr("lighting_key_color", default: "Aydınlatma Rengi:"))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)

                                Text(keyColor.rgbString)
                                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(isKeyPainted ? Color(red: 0.98, green: 0.18, blue: 0.38) : .secondary)

                                Text("• \(keyColor.toHex())")
                                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // 1. Modern Color Picker Butonu
                        Button(action: {
                            isShowingKeyColorPicker = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "paintpalette.fill")
                                Text("Rengi Özelleştir")
                                    .font(.system(size: 11.5, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(color: Color.purple.opacity(0.4), radius: 6, y: 2)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $isShowingKeyColorPicker, arrowEdge: .top) {
                            ModernColorPickerView(
                                selectedColor: Binding(
                                    get: { customKeyColors[keyId] ?? customBrushColor },
                                    set: { newCol in
                                        customKeyColors[keyId] = newCol
                                        markUnsaved()
                                    }
                                ),
                                title: "\(keyId) Tuşu Rengi",
                                onColorChanged: { newCol in
                                    customKeyColors[keyId] = newCol
                                    markUnsaved()
                                },
                                onClose: {
                                    isShowingKeyColorPicker = false
                                }
                            )
                        }

                        // 2. Fırça Rengiyle Boya Butonu
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                customKeyColors[keyId] = customBrushColor
                                markUnsaved()
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "paintbrush.fill")
                                Text("Fırçayla Boya")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.12))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .help("Bu tuşu aktif fırça rengine (\(customBrushColor.rgbString)) boyar")

                        // 3. Söndür Butonu
                        if isKeyPainted {
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    customKeyColors.removeValue(forKey: keyId)
                                    markUnsaved()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "moon.fill")
                                    Text("Söndür")
                                        .font(.system(size: 10.5, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.12))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .help("Bu tuşun aydınlatmasını kapat (söndür)")
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                            .font(.system(size: 12))
                        Text("Aydınlatmasını incelemek veya rengini değiştirmek istediğiniz tuşun üzerine tıklayın.")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(8)
                }
            }

            // Klavyeye Gönder / Donanım Hafızasına Kaydet Barı
            HStack(spacing: 16) {
                // Klavyeye Kaydet İkon Rozeti (macOS / Control Center stili)
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.tr("lighting_hw_write_title", default: "Klavyeye Kaydet"))
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        if keyboardManager.connectionType == .wiredUSB {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text(loc.tr("lighting_hw_wired_badge", default: "Kablolu Bağlantı"))
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(.green.opacity(0.9))
                            Text(loc.tr("lighting_hw_wired_desc", default: "• 126 tuşun renk ayarları doğrudan klavyenize aktarılır."))
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                        } else {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                            Text(loc.tr("lighting_hw_wireless_badge", default: "Kablosuz Mod"))
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(.orange.opacity(0.9))
                            Text(loc.tr("lighting_hw_wireless_desc", default: "• Hızlı aktarım için Type-C kablosu önerilir."))
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Button(action: sendCustomMatrixToKeyboard) {
                    HStack(spacing: 8) {
                        if customMatrixSuccessFeedback != nil {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12.5, weight: .bold))
                            Text(loc.tr("lighting_hw_saved_btn", default: "Klavyeye Kaydedildi"))
                                .font(.system(size: 13, weight: .semibold))
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 13, weight: .medium))
                            Text(loc.tr("lighting_hw_upload_btn", default: "Klavyeye Yükle & Kaydet"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8.5)
                    .background(
                        LinearGradient(
                            colors: customMatrixSuccessFeedback != nil
                                ? [Color.green.opacity(0.85), Color.green.opacity(0.7)]
                                : [
                                    Color(red: 0.98, green: 0.22, blue: 0.42),
                                    Color(red: 0.86, green: 0.12, blue: 0.28)
                                ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.white.opacity(isHoveringApplyButton ? 0.35 : 0.2), lineWidth: 1)
                    )
                    .shadow(
                        color: customMatrixSuccessFeedback != nil
                            ? Color.green.opacity(0.3)
                            : (isHoveringApplyButton
                                ? Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.35)
                                : Color.black.opacity(0.25)),
                        radius: isHoveringApplyButton ? 6 : 4,
                        x: 0,
                        y: 2
                    )
                    .scaleEffect(isHoveringApplyButton ? 1.015 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHoveringApplyButton)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: customMatrixSuccessFeedback)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringApplyButton = hovering
                }
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
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
