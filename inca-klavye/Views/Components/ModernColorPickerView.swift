import SwiftUI
import AppKit

/// macOS varsayılan ColorPicker'ı yerine uygulama içi modern, koyu temalı ve RGB/Hex kontrollü renk seçici.
struct ModernColorPickerView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var selectedColor: Color
    var title: String = "Özel Renk Seçici"
    var onColorChanged: ((Color) -> Void)? = nil
    var onClose: (() -> Void)? = nil

    @State private var red: Double = 250
    @State private var green: Double = 46
    @State private var blue: Double = 96
    @State private var hexInput: String = "FA2E60"
    @State private var redText: String = "250"
    @State private var greenText: String = "46"
    @State private var blueText: String = "96"
    @State private var hasCopiedHex: Bool = false

    // Hızlı Renk Kısayolları
    private let quickSwatches: [Color] = [
        Color(red: 0.98, green: 0.18, blue: 0.38), // Apple Pink-Red
        Color(red: 1.00, green: 0.22, blue: 0.00), // Fire Red
        Color(red: 1.00, green: 0.50, blue: 0.00), // Orange
        Color(red: 1.00, green: 0.82, blue: 0.10), // Sun Yellow
        Color(red: 0.20, green: 0.95, blue: 0.45), // Aurora Green
        Color(red: 0.00, green: 0.90, blue: 0.70), // Mint
        Color(red: 0.00, green: 0.85, blue: 1.00), // Neon Cyan
        Color(red: 0.10, green: 0.50, blue: 1.00), // Sky Blue
        Color(red: 0.45, green: 0.20, blue: 1.00), // Indigo
        Color(red: 0.68, green: 0.26, blue: 0.98), // Electric Purple
        Color(red: 0.95, green: 0.20, blue: 0.85), // Magenta
        Color.white,                                // Ice White
        Color(white: 0.45),                         // Neutral Gray
        Color.black                                 // Sönük / Kapalı
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Başlık
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(currentColor)
                        .frame(width: 13, height: 13)
                        .shadow(color: currentColor.opacity(0.8), radius: 5)

                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                }

                Spacer()

                if let onClose = onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Canlı Önizleme & Hex Girişi & Sistem Color Picker
            HStack(spacing: 12) {
                // Renk Kartı
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(currentColor)
                    .frame(width: 62, height: 62)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                    )
                    .shadow(color: currentColor.opacity(0.6), radius: 8, y: 3)

                VStack(alignment: .leading, spacing: 6) {
                    // HEX Giriş Alanı
                    HStack(spacing: 6) {
                        Text("#")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(.secondary)

                        TextField("RRGGBB", text: $hexInput)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15), lineWidth: 1))
                            .frame(width: 86)
                            .onChange(of: hexInput) { _, newVal in
                                handleHexInput(newVal)
                            }

                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("#" + hexInput.replacingOccurrences(of: "#", with: ""), forType: .string)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                hasCopiedHex = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    hasCopiedHex = false
                                }
                            }
                        }) {
                            Image(systemName: hasCopiedHex ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(hasCopiedHex ? .green : .secondary)
                                .padding(5)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                        .help("Hex kodunu kopyala")
                    }

                    // Sistem Color Picker Butonu & Damlalık
                    HStack(spacing: 6) {
                        ColorPicker(selection: Binding(
                            get: { currentColor },
                            set: { newCol in loadColor(newCol) }
                        )) {
                            HStack(spacing: 4) {
                                Image(systemName: "eyedropper.halffull")
                                    .font(.system(size: 11))
                                Text(loc.tr("picker_system", default: "Sistem Paleti"))
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }

                Spacer()
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)

            // Gökkuşağı Spektrumu (Hızlı Renk Seçici Barı)
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.tr("picker_spectrum", default: "RENK SPEKTRUMU"))
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.0)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1, green: 0, blue: 0),
                                        Color(red: 1, green: 0.5, blue: 0),
                                        Color(red: 1, green: 1, blue: 0),
                                        Color(red: 0, green: 1, blue: 0),
                                        Color(red: 0, green: 1, blue: 1),
                                        Color(red: 0, green: 0, blue: 1),
                                        Color(red: 0.8, green: 0, blue: 1),
                                        Color(red: 1, green: 0, blue: 0.5),
                                        Color(red: 1, green: 0, blue: 0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 14)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let fraction = max(0, min(1, value.location.x / geo.size.width))
                                        pickFromHue(fraction)
                                    }
                            )
                    }
                }
                .frame(height: 14)
            }

            // RGB Kaydırıcıları ve Sayısal Giriş Alanları
            VStack(spacing: 8) {
                rgbInputRow(label: "R", colorName: "Kırmızı", value: $red, textValue: $redText, tintColor: .red)
                rgbInputRow(label: "G", colorName: "Yeşil", value: $green, textValue: $greenText, tintColor: .green)
                rgbInputRow(label: "B", colorName: "Mavi", value: $blue, textValue: $blueText, tintColor: .blue)
            }

            // Hızlı Renk Paleti (Swatches)
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.tr("picker_quick", default: "HIZLI RENKLER"))
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.0)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(quickSwatches.indices, id: \.self) { idx in
                        let swatch = quickSwatches[idx]
                        Button(action: {
                            loadColor(swatch)
                        }) {
                            Circle()
                                .fill(swatch)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: currentColorHex == swatch.toHex() ? 2 : 0)
                                )
                                .shadow(color: swatch.opacity(0.4), radius: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Alt Butonlar
            HStack(spacing: 8) {
                Button(action: {
                    loadColor(.black)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                        Text(loc.tr("picker_turn_off", default: "Söndür (Siyah)"))
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.secondary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    selectedColor = currentColor
                    onColorChanged?(currentColor)
                    onClose?()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                        Text(loc.tr("picker_apply", default: "Rengi Uygula"))
                            .font(.system(size: 11.5, weight: .bold))
                    }
                    .padding(.horizontal, 14)
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
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96))
                .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 10)
        .onAppear {
            loadColor(selectedColor)
        }
    }

    // MARK: - RGB Satır Bileşeni (Slider + Doğrudan Sayı Girişi)
    private func rgbInputRow(label: String, colorName: String, value: Binding<Double>, textValue: Binding<String>, tintColor: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(tintColor)
                .frame(width: 14)

            Slider(value: value, in: 0...255, step: 1)
                .tint(tintColor)
                .onChange(of: value.wrappedValue) { _, newVal in
                    let intVal = Int(newVal)
                    textValue.wrappedValue = "\(intVal)"
                    syncHexAndNotify()
                }

            TextField("0", text: textValue)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .frame(width: 44, height: 22)
                .background(Color.white.opacity(0.08))
                .cornerRadius(5)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.12), lineWidth: 1))
                .onChange(of: textValue.wrappedValue) { _, newVal in
                    let digits = newVal.filter { "0123456789".contains($0) }
                    if let parsed = Int(digits) {
                        let clamped = max(0, min(255, Double(parsed)))
                        if value.wrappedValue != clamped {
                            value.wrappedValue = clamped
                            syncHexAndNotify()
                        }
                    }
                }
        }
    }

    // MARK: - Renk Hesaplama & Senkronizasyon
    private var currentColor: Color {
        Color(
            red: max(0, min(1, red / 255.0)),
            green: max(0, min(1, green / 255.0)),
            blue: max(0, min(1, blue / 255.0))
        )
    }

    private var currentColorHex: String {
        currentColor.toHex()
    }

    private func syncHexAndNotify() {
        let cr = max(0, min(255, Int(round(red))))
        let cg = max(0, min(255, Int(round(green))))
        let cb = max(0, min(255, Int(round(blue))))
        let hex = String(format: "%02X%02X%02X", cr, cg, cb)
        if hexInput.replacingOccurrences(of: "#", with: "").uppercased() != hex {
            self.hexInput = hex
        }
        let newCol = currentColor
        self.selectedColor = newCol
        onColorChanged?(newCol)
    }

    private func handleHexInput(_ input: String) {
        var clean = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if clean.hasPrefix("#") {
            clean.removeFirst()
        }
        guard clean.count == 6, let val = UInt64(clean, radix: 16) else {
            return
        }
        let r = Double((val & 0xFF0000) >> 16)
        let g = Double((val & 0x00FF00) >> 8)
        let b = Double(val & 0x0000FF)
        self.red = r
        self.green = g
        self.blue = b
        self.redText = "\(Int(r))"
        self.greenText = "\(Int(g))"
        self.blueText = "\(Int(b))"
        let newCol = currentColor
        self.selectedColor = newCol
        onColorChanged?(newCol)
    }

    private func loadColor(_ color: Color) {
        let (r, g, b) = color.rgbComponents
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.redText = "\(r)"
        self.greenText = "\(g)"
        self.blueText = "\(b)"
        let hex = String(format: "%02X%02X%02X", r, g, b)
        self.hexInput = hex
        self.selectedColor = color
        onColorChanged?(color)
    }

    private func pickFromHue(_ fraction: CGFloat) {
        let hue = fraction
        let nsColor = NSColor(hue: hue, saturation: 0.95, brightness: 0.98, alpha: 1.0)
        let r = Double(round(nsColor.redComponent * 255.0))
        let g = Double(round(nsColor.greenComponent * 255.0))
        let b = Double(round(nsColor.blueComponent * 255.0))
        self.red = r
        self.green = g
        self.blue = b
        self.redText = "\(Int(r))"
        self.greenText = "\(Int(g))"
        self.blueText = "\(Int(b))"
        let hex = String(format: "%02X%02X%02X", Int(r), Int(g), Int(b))
        self.hexInput = hex
        let newCol = currentColor
        self.selectedColor = newCol
        onColorChanged?(newCol)
    }
}

/// Renk paletlerinin yanında "Özel Renk / HEX" butonu olarak yerleştirilen, tıklandığında popover ile ModernColorPickerView açan bileşen.
struct QuickColorPickerButton: View {
    @Binding var selectedColor: Color
    var title: String = "Özel Renk / HEX"
    var onColorChange: () -> Void
    @State private var isPresented: Bool = false
    @ObservedObject var loc = LocalizationManager.shared

    var body: some View {
        Button(action: { isPresented = true }) {
            HStack(spacing: 5) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 11))
                    .foregroundColor(selectedColor)
                Text(loc.tr("lighting_custom_color_hex", default: title))
                    .font(.system(size: 11.5, weight: .bold))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4.5)
            .background(Color.white.opacity(0.1))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            ModernColorPickerView(
                selectedColor: $selectedColor,
                title: loc.tr("lighting_custom_color", default: "Özel Renk Seçici"),
                onColorChanged: { _ in
                    onColorChange()
                },
                onClose: {
                    isPresented = false
                }
            )
        }
    }
}
