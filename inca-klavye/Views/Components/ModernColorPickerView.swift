import SwiftUI
import AppKit

/// macOS varsayılan ColorPicker'ı yerine uygulama içi modern, koyu temalı ve RGB/Hex kontrollü renk seçici.
struct ModernColorPickerView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var selectedColor: Color
    var title: String = "Renk Seçici"
    var onColorChanged: ((Color) -> Void)? = nil
    var onClose: (() -> Void)? = nil

    @State private var red: Double = 250
    @State private var green: Double = 46
    @State private var blue: Double = 96
    @State private var hexInput: String = ""

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
        VStack(alignment: .leading, spacing: 16) {
            // Başlık
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(currentColor)
                        .frame(width: 14, height: 14)
                        .shadow(color: currentColor.opacity(0.8), radius: 6)

                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                }

                Spacer()

                if let onClose = onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Canlı Önizleme & RGB / Hex Bilgi Kartı
            HStack(spacing: 14) {
                // Renk Kartı
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(currentColor)
                    .frame(width: 58, height: 58)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                    )
                    .shadow(color: currentColor.opacity(0.6), radius: 10, y: 3)

                // Metin Bilgileri
                VStack(alignment: .leading, spacing: 4) {
                    Text("RGB(\(Int(red)), \(Int(green)), \(Int(blue)))")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text(currentColorHex)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)

                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(currentColorHex, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Hex kodunu kopyala")
                    }

                    Text(colorDescription)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                Spacer()
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)

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

            // RGB Kaydırıcıları
            VStack(spacing: 9) {
                rgbSliderRow(label: "R", colorName: "Kırmızı", value: $red, tintColor: .red)
                rgbSliderRow(label: "G", colorName: "Yeşil", value: $green, tintColor: .green)
                rgbSliderRow(label: "B", colorName: "Mavi", value: $blue, tintColor: .blue)
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
        .frame(width: 290)
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

    // MARK: - RGB Satır Bileşeni
    private func rgbSliderRow(label: String, colorName: String, value: Binding<Double>, tintColor: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(tintColor)
                .frame(width: 14)

            Slider(value: value, in: 0...255, step: 1)
                .tint(tintColor)
                .onChange(of: value.wrappedValue) { _, _ in
                    let newCol = currentColor
                    selectedColor = newCol
                    onColorChanged?(newCol)
                }

            Text("\(Int(value.wrappedValue))")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    // MARK: - Renk Hesaplama Yardımcıları
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

    private var colorDescription: String {
        if red < 20 && green < 20 && blue < 20 { return "Işıksız (Siyah)" }
        if red > 230 && green > 230 && blue > 230 { return "Parlak Beyaz" }
        if red > 200 && green < 50 && blue < 50 { return "Kırmızı Tonu" }
        if red > 200 && green > 150 && blue < 50 { return "Sarı / Turuncu Tonu" }
        if green > 200 && red < 80 { return "Yeşil Tonu" }
        if blue > 200 && green > 150 { return "Açık Mavi (Cyan)" }
        if blue > 200 && red < 80 { return "Mavi Tonu" }
        if red > 180 && blue > 180 { return "Mor / Pembe Tonu" }
        return "Özel RGB Karışımı"
    }

    private func loadColor(_ color: Color) {
        let (r, g, b) = color.rgbComponents
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
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
        let newCol = currentColor
        self.selectedColor = newCol
        onColorChanged?(newCol)
    }
}
