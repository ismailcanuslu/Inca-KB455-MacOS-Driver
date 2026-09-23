import SwiftUI

/// Tab 2: "Özelleştirilmiş Aydınlatma"
/// 126 tuşun tamamını bağımsız renklendirme, fırça paleti, interaktif klavye matrisi,
/// 5 disk profil slotu ve klavyeye kaydetme alanı.
struct CustomLightingView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared

    // Fırça ve Tuş Renklendirme Durumu
    @State private var customBrushColor: Color = Color(red: 0.98, green: 0.18, blue: 0.38)
    @State private var selectedKeyIdForCustom: String? = nil
    @State private var customKeyColors: [String: Color] = [:]
    @State private var customMatrixSuccessFeedback: String? = nil
    @State private var isColorPickerPresented: Bool = false
    @State private var hoveredBrushColorName: String? = nil

    private let quickPalette: [(color: Color, name: String)] = [
        (Color(red: 0.98, green: 0.18, blue: 0.38), "Empousa Pembesi"),
        (.red, "Kırmızı"),
        (.orange, "Turuncu"),
        (.yellow, "Sarı"),
        (.green, "Yeşil"),
        (.cyan, "Açık Mavi (Cyan)"),
        (.blue, "Mavi"),
        (.purple, "Mor"),
        (.white, "Beyaz"),
        (.black, "Işık Kapalı (Siyah)")
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Başlık Banner'ı
                headerBanner

                // 2. Fırça Paleti & Hızlı Renk Seçimi
                brushPaletteSection

                // 3. Bilgisayar Diski Profil Slotları (5 Slot)
                CustomLightingSlotsView(
                    customKeyColors: $customKeyColors,
                    onSlotApplied: {
                        markUnsaved()
                    }
                )

                // 4. İnteraktif Klavye (Boyamak İçin Tıklayın)
                interactiveKeyboardSection

                // 5. Klavyeye Kaydetme & İşlem Barı
                saveActionBar
            }
            .padding(24)
        }
        .sheet(isPresented: $isColorPickerPresented) {
            ModernColorPickerView(
                selectedColor: $customBrushColor,
                title: loc.tr("lighting_brush_picker_title", default: "Fırça Rengi Seçici"),
                onClose: { isColorPickerPresented = false }
            )
        }
    }

    // MARK: - 1. Başlık Banner'ı
    private var headerBanner: some View {
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
                Text(loc.tr("tab_custom_lighting", default: "Özelleştirilmiş Aydınlatma"))
                    .font(.system(size: 18, weight: .bold))
                Text(loc.tr("lighting_palette_banner_desc", default: "126 tuşun tamamını dilediğiniz renkle bağımsız olarak özelleştirin. Aşağıdaki fırça rengini seçip tuşlara tıklayarak kendi temanızı oluşturun."))
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
        .padding(18)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 2. Fırça Paleti
    private var brushPaletteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(loc.tr("lighting_brush_title", default: "FIRÇA RENGİ").uppercased(), systemImage: "paintbrush.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                if let hovered = hoveredBrushColorName {
                    Text("•  \(hovered)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(customBrushColor)
                        .transition(.opacity)
                }

                Spacer()

                Button(action: { isColorPickerPresented = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 11))
                            .foregroundColor(customBrushColor)
                        Text(loc.tr("lighting_custom_color_hex", default: "Özel Renk / HEX"))
                            .font(.system(size: 11.5, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                // Aktif Fırça Önizlemesi
                ZStack {
                    Circle()
                        .fill(customBrushColor)
                        .frame(width: 36, height: 36)
                        .shadow(color: customBrushColor.opacity(0.6), radius: 6)

                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }

                Divider().frame(height: 28)

                // Hızlı Renkler
                ForEach(quickPalette.indices, id: \.self) { idx in
                    let item = quickPalette[idx]
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            customBrushColor = item.color
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 26, height: 26)

                            if customBrushColor == item.color {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2.5)
                                    .frame(width: 26, height: 26)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(item.color == .white ? .black : .white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredBrushColorName = isHovering ? item.name : nil
                        }
                    }
                    .help(item.name)
                }

                Spacer()

                // Hızlı İşlemler: Tümünü Boya & Temizle
                Button(action: fillAllCustomKeys) {
                    HStack(spacing: 4) {
                        Image(systemName: "paintbrush.pointed.fill")
                        Text(loc.tr("lighting_preset_fill", default: "Tümünü Boya"))
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: clearAllCustomKeys) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text(loc.tr("lighting_preset_clear", default: "Temizle"))
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
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 3. İnteraktif Klavye
    private var interactiveKeyboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(loc.tr("lighting_matrix_header", default: "İNTERAKTİF KLAVYE (BOYAMAK İÇİN TIKLAYIN)"))
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

            // Seçili Tuş Bilgisi Barı
            if let keyId = selectedKeyIdForCustom {
                let currentKeyColor = customKeyColors[keyId] ?? customBrushColor
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Text(loc.tr("lighting_selected_key", default: "Seçili Tuş:"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(keyId)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }

                    Circle()
                        .fill(currentKeyColor)
                        .frame(width: 14, height: 14)
                        .shadow(color: currentKeyColor.opacity(0.6), radius: 3)

                    Text("Renk: \(colorRgbString(currentKeyColor))")
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            customKeyColors[keyId] = customBrushColor
                            markUnsaved()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "paintbrush.fill")
                            Text("Fırçayla Boya")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(red: 0.98, green: 0.18, blue: 0.38))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        isColorPickerPresented = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "eyedropper")
                            Text("Renk Değiştir")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 4. Klavyeye Kaydetme Barı
    private var saveActionBar: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(loc.tr("lighting_hw_write_title", default: "Klavyeye Gönder"))
                    .font(.system(size: 14, weight: .bold))
                Text(loc.tr("lighting_hw_wired_desc", default: "• 126 tuşun renk ayarları doğrudan klavyenize aktarılır."))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: saveCustomMatrixToKeyboard) {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane.fill")
                    Text(loc.tr("lighting_hw_upload_btn", default: "Klavyeye Gönder"))
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(9)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Eylemler
    private func fillAllCustomKeys() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            for key in EmpousaKeyboardGraphicView.allKeys {
                customKeyColors[key.id] = customBrushColor
            }
            markUnsaved()
        }
    }

    private func clearAllCustomKeys() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            customKeyColors.removeAll()
            markUnsaved()
        }
    }

    private func saveCustomMatrixToKeyboard() {
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

        keyboardManager.triggerSavingStatus(message: "Klavyeye Gönderiliyor...")
        keyboardManager.applyCustomKeyColors(rgbData: rgbBuffer)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            customMatrixSuccessFeedback = loc.tr("lighting_hw_success_msg", default: "Özel tuş renkleri klavyeye başarıyla aktarıldı!")
        }
        keyboardManager.triggerSavedSuccess(message: "Özel Renkler Klavyeye Gönderildi!")

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                customMatrixSuccessFeedback = nil
            }
        }
    }

    private func markUnsaved() {
        keyboardManager.triggerUnsavedStatus(
            description: "Özel Tuş Renkleri",
            onCommit: {
                saveCustomMatrixToKeyboard()
            },
            onDiscard: {
                customKeyColors.removeAll()
            }
        )
    }

    private func colorRgbString(_ c: Color) -> String {
        guard let nsColor = NSColor(c).usingColorSpace(.sRGB) else { return "RGB" }
        let r = Int(nsColor.redComponent * 255)
        let g = Int(nsColor.greenComponent * 255)
        let b = Int(nsColor.blueComponent * 255)
        return "R:\(r) G:\(g) B:\(b)"
    }
}
