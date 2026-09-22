import SwiftUI
import Combine

struct TftScreenView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared

    @State private var playbackIntervalMs: Double = 120
    @State private var rotationAngle: Double = 0
    @State private var currentFrameIndex: Int = 0
    @State private var isUploading: Bool = false
    @State private var uploadProgress: Double = 0.0
    @State private var showSuccessToast: Bool = false
    @State private var selectedTemplateId: Int = 1

    let timer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    let templates = [
        (id: 1, name: "Matrix Akışı", desc: "Dinamik yeşil dijital kod yağmuru", icon: "waveform.path.ecg"),
        (id: 2, name: "Sistem Telemetrisi", desc: "Pil, bağlantı ve donanım frekansı", icon: "cpu"),
        (id: 3, name: "Dijital & Analog Saat", desc: "Tarih, saat ve durum göstergeleri", icon: "clock"),
        (id: 4, name: "Neon Spektrum", desc: "Apple Music ritmik dalga formu", icon: "waveform"),
        (id: 5, name: "Empousa Amblem", desc: "Minimalist kurumsal logo", icon: "keyboard")
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Başlık
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.tr("tc_screen11", default: "TFT Renkli Ekran & Animasyon"))
                        .font(.system(size: 26, weight: .bold))
                    Text(loc.tr("tc_screen1", default: "Klavyenin üzerindeki renkli bilgi ekranını ve GIF oynatıcıyı özelleştirin"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Canlı TFT Ekran Simülasyonu (Hardware Display Replica)
                HStack(spacing: 24) {
                    // Minyatür Klavye TFT Ekranı
                    VStack(spacing: 12) {
                        ZStack {
                            // Metalik Gövde Çerçevesi
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(white: 0.20), Color(white: 0.10)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 290, height: 190)
                                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                                )

                            // Ekran Camı / IPS Panel
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black)
                                .frame(width: 250, height: 150)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )

                            // Canlı Ekran İçeriği
                            VStack(spacing: 6) {
                                // Üst Bilgi Çubuğu
                                HStack {
                                    HStack(spacing: 4) {
                                        Image(systemName: keyboardManager.isMacMode ? "apple.logo" : "window.vertical.closed")
                                            .font(.system(size: 9))
                                        Text(keyboardManager.isMacMode ? "MAC" : "WIN")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    .foregroundColor(.white.opacity(0.8))

                                    Spacer()

                                    HStack(spacing: 4) {
                                        Image(systemName: keyboardManager.connectionType.icon)
                                            .font(.system(size: 8))
                                        Text(keyboardManager.connectionType == .wireless24G ? "2.4G" : (keyboardManager.connectionType == .bluetooth ? "BT" : "USB"))
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    .foregroundColor(.cyan)

                                    HStack(spacing: 3) {
                                        Image(systemName: keyboardManager.isCharging ? "battery.100.bolt" : "battery.100")
                                            .font(.system(size: 8))
                                        Text("%\(keyboardManager.batteryLevel)")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    .foregroundColor(keyboardManager.isCharging ? .yellow : .green)
                                }
                                .padding(.horizontal, 12)
                                .padding(.top, 6)

                                Divider().background(Color.white.opacity(0.15))

                                // Merkez Ekran Görünümü (Seçilen Şablona Göre)
                                renderScreenContent()
                                    .frame(maxHeight: .infinity)
                                    .rotationEffect(.degrees(rotationAngle))
                            }
                            .frame(width: 240, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Text("INCA IKG-455 OLED/IPS Panel (1.14\" 135x240 px)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    // Şablon Seçici Kartı
                    VStack(alignment: .leading, spacing: 12) {
                        Text(loc.tr("tc_screen14", default: "Hazır Ekran Şablonları"))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.0)

                        VStack(spacing: 6) {
                            ForEach(templates, id: \.id) { tpl in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedTemplateId = tpl.id
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: tpl.icon)
                                            .font(.system(size: 14))
                                            .foregroundColor(selectedTemplateId == tpl.id ? .white : Color(red: 0.98, green: 0.18, blue: 0.38))
                                            .frame(width: 20)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(tpl.name)
                                                .font(.system(size: 13, weight: selectedTemplateId == tpl.id ? .bold : .medium))
                                                .foregroundColor(selectedTemplateId == tpl.id ? .white : .primary)
                                            Text(tpl.desc)
                                                .font(.caption2)
                                                .foregroundColor(selectedTemplateId == tpl.id ? .white.opacity(0.8) : .secondary)
                                        }

                                        Spacer()

                                        if selectedTemplateId == tpl.id {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedTemplateId == tpl.id ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.04))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // İçe Aktar ve Sıfırla
                        HStack(spacing: 10) {
                            Button(action: {}) {
                                Label(loc.tr("tc_screen15", default: "Özel GIF İçe Aktar"), systemImage: "photo.on.rectangle")
                                    .font(.system(size: 12))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button(action: { rotationAngle = 0 }) {
                                Label(loc.tr("tc_screen10", default: "Sıfırla"), systemImage: "arrow.uturn.backward")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }

                // Ayarlar ve Döndürme Kontrolleri
                VStack(alignment: .leading, spacing: 16) {
                    Text(loc.tr("tc_config", default: "Animasyon & Oynatma Parametreleri"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    HStack(spacing: 16) {
                        // Oynatma Aralığı
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(loc.tr("tc_screen16", default: "Oynatma aralığı（ms）"))
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Text("\(Int(playbackIntervalMs)) ms")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                            }

                            Slider(value: $playbackIntervalMs, in: 30...300, step: 10)

                            HStack {
                                Text("30 ms (Hızlı)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("300 ms (Yavaş)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))

                        // Görsel Yönü
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Görsel Yönü")
                                .font(.system(size: 13, weight: .semibold))

                            HStack(spacing: 12) {
                                Button(action: { withAnimation { rotationAngle -= 90 } }) {
                                    Label(loc.tr("tc_screen20", default: "Sola döndür"), systemImage: "rotate.left")
                                        .font(.system(size: 12))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)

                                Button(action: { withAnimation { rotationAngle += 90 } }) {
                                    Label(loc.tr("tc_screen21", default: "Sağa döndür"), systemImage: "rotate.right")
                                        .font(.system(size: 12))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }

                // Ekrana Yükleme (Upload) Bölümü
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc.tr("tc_screen12", default: "Uygula & Ekrana Aktar"))
                                .font(.system(size: 16, weight: .bold))
                            Text(loc.tr("tc_screen19", default: "Kablosuz ve kablolu modda klavye belleğine aktarılır"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: { simulateUpload() }) {
                            if isUploading {
                                HStack(spacing: 8) {
                                    ProgressView().controlSize(.small)
                                    Text("%\(Int(uploadProgress * 100)) Aktarılıyor...")
                                }
                            } else {
                                Label(loc.tr("tc_screen12", default: "Ekrana Aktar"), systemImage: "arrow.up.circle.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isUploading)
                    }

                    if isUploading {
                        ProgressView(value: uploadProgress)
                            .progressViewStyle(.linear)
                            .tint(Color(red: 0.98, green: 0.18, blue: 0.38))
                    }

                    if showSuccessToast {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Animasyon donanım ekranına aktarıldı.")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            .padding(24)
        }
        .onReceive(timer) { _ in
            currentFrameIndex = (currentFrameIndex + 1) % 12
        }
    }

    @ViewBuilder
    private func renderScreenContent() -> some View {
        switch selectedTemplateId {
        case 1:
            // Matrix Akışı
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    ForEach(0..<8, id: \.self) { col in
                        VStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { row in
                                Text(String((col * 4 + row + currentFrameIndex) % 10))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(row == (currentFrameIndex % 4) ? .white : .green.opacity(0.7))
                            }
                        }
                    }
                }
                Text("MATRIX v2.4")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            }
        case 2:
            // Sistem Telemetrisi
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("POLLING")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("1000 Hz")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LATENCY")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("1.0 ms")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                Text("EMPOUSA SENSOR OK")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
        case 3:
            // Dijital Saat
            VStack(spacing: 2) {
                Text("17:48")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("PAZAR, 20 EYLÜL")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        case 4:
            // Neon Spektrum
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<10, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 12, height: CGFloat(((i + currentFrameIndex) % 8 + 2) * 8))
                }
            }
            .frame(height: 50, alignment: .bottom)
        default:
            // Empousa Amblem
            VStack(spacing: 6) {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                Text("INCA EMPOUSA")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }

    private func simulateUpload() {
        isUploading = true
        uploadProgress = 0.0
        showSuccessToast = false

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
            uploadProgress += 0.08
            if uploadProgress >= 1.0 {
                t.invalidate()
                isUploading = false
                withAnimation { showSuccessToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showSuccessToast = false }
                }
            }
        }
    }
}
