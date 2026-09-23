import SwiftUI
import Combine

/// Tab 3: "Müzik Aydınlatması"
/// Canlı ekolayzer spektrumu, Işık Efekti alanındaki gibi kare kartlar (LazyVGrid)
/// ve ses/ritim hassasiyeti ayarları.
struct MusicVisualizerView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared

    @State private var gain: Double = 65
    @State private var autoGain: Bool = true
    @State private var selectedEffect: Int = 1
    @State private var sensitivity: Double = 80
    @State private var isListening: Bool = true

    // Canlı Equalizer Bar Değerleri
    @State private var barHeights: [CGFloat] = [20, 45, 70, 95, 110, 85, 60, 40, 75, 100, 90, 65, 50, 80, 95, 60]

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    let musicEffects: [(id: Int, name: String, subtitle: String, icon: String)] = [
        (1, "Spektrum Dalgalanma", "Frekans dalgaları", "waveform.path.ecg"),
        (2, "Zıplayan Bloklar", "Ekolayzer bas vuruşları", "chart.bar.fill"),
        (3, "Merkezden Dışa Ritim", "Dairesel ses yayılımı", "circle.circle.fill"),
        (4, "Nabız & Parlama", "Müzikle nabız atışı", "bolt.heart.fill"),
        (5, "Dinamik Akış", "Yumuşak ritmik akış", "water.waves"),
        (6, "Yıldız Patlaması", "Yüksek ses tepe ışıltısı", "sparkles")
    ]

    private let accentColor = Color(red: 0.98, green: 0.18, blue: 0.38)

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Başlık
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.tr("tab_music_lighting", default: "Müzik Aydınlatması"))
                        .font(.system(size: 26, weight: .bold))
                    Text("Sistem sesleri ve çalan müziğin ritmini Empousa klavye RGB aydınlatmasıyla senkronize edin")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Canlı Apple Music Tarzı Equalizer Ekranı
                VStack(spacing: 16) {
                    HStack {
                        Label("CANLI SES SPEKTRUMU", systemImage: "waveform")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)

                        Spacer()

                        HStack(spacing: 6) {
                            Circle()
                                .fill(isListening ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(isListening ? "Ses Algılanıyor (48 kHz)" : "Durduruldu")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Dinamik Dans Eden Çubuklar
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(0..<barHeights.count, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            accentColor,
                                            Color.purple,
                                            Color.blue
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: barHeights[i])
                                .animation(.spring(response: 0.15, dampingFraction: 0.5), value: barHeights[i])
                        }
                    }
                    .frame(height: 120, alignment: .bottom)
                    .padding(.vertical, 8)
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))

                // Ritim Efekt Modu Seçici (Kare Kartlar LazyVGrid - Işık Efektleri ile Birebir Tasarım)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(loc.tr("tc_kb1", default: "MÜZİK RİTİM EFEKTLERİ").uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)

                        Spacer()

                        // Klavyeye Gönder Butonu
                        Button(action: {
                            sendMusicEffectToKeyboard()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text(loc.tr("island_save_btn", default: "Klavyeye Gönder"))
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(LinearGradient(colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple], startPoint: .leading, endPoint: .trailing))
                            )
                            .shadow(color: Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.35), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .help("Seçili müzik ritim efektini klavyeye gönderir")
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 14)], spacing: 14) {
                        ForEach(musicEffects, id: \.id) { effect in
                            let isSelected = selectedEffect == effect.id

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedEffect = effect.id
                                }
                                markUnsaved()
                            }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    // Kare Efekt Kapağı
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                isSelected
                                                ? LinearGradient(colors: [accentColor, accentColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            )
                                            .frame(height: 90)

                                        Image(systemName: effect.icon)
                                            .font(.system(size: 32))
                                            .foregroundColor(isSelected ? .white : .primary.opacity(0.85))
                                            .shadow(color: isSelected ? Color.black.opacity(0.3) : .clear, radius: 4)
                                    }

                                    // Efekt Başlığı & Açıklaması
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(effect.name)
                                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? accentColor : .primary)
                                            .lineLimit(1)

                                        Text(effect.subtitle)
                                            .font(.system(size: 10, weight: .regular))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
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
                }

                // Kazanç ve Ses Ayarları Kartı
                VStack(alignment: .leading, spacing: 18) {
                    Text(loc.tr("tc_config", default: "Ses & Ritim Hassasiyeti").uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    HStack(spacing: 20) {
                        // Kazanç (Gain) Slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(loc.tr("tc_music2", default: "Kazanç (Ses Artışı)"))
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Text("%\(Int(gain))")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(accentColor)
                            }

                            Slider(value: $gain, in: 0...100, step: 1)
                                .disabled(autoGain)

                            Text(loc.tr("tc_music10", default: "Otomatik Kazanç (Otomatik Ses Artışı)"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))

                        // Otomatik Kazanç (AGC) Toggle
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $autoGain) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(loc.tr("tc_music10", default: "Otomatik Kazanç (AGC)"))
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Ses seviyesine göre dinamik ayar")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)

                            Divider()

                            HStack {
                                Text("Hassasiyet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Yüksek (%80)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
            }
            .padding(24)
        }
        .onReceive(timer) { _ in
            if isListening {
                for i in 0..<barHeights.count {
                    let base = CGFloat.random(in: 15...115)
                    barHeights[i] = min(120, max(10, base * (CGFloat(gain) / 70.0)))
                }
            }
        }
    }

    // MARK: - Komut Gönderme & Bekletme
    private func sendMusicEffectToKeyboard() {
        keyboardManager.triggerSavingStatus(message: "Klavyeye Gönderiliyor...")
        if let mode = MusicSyncMode(rawValue: UInt8(selectedEffect)) {
            keyboardManager.applyMusicSync(mode: mode)
        }
        keyboardManager.triggerSavedSuccess(message: "Müzik Aydınlatması Klavyeye Gönderildi!")
    }

    private func markUnsaved() {
        let effectName = musicEffects.first(where: { $0.id == selectedEffect })?.name ?? "Müzik Ritmi"
        keyboardManager.triggerUnsavedStatus(
            description: "Müzik: \(effectName)",
            onCommit: {
                sendMusicEffectToKeyboard()
            },
            onDiscard: {
                keyboardManager.activeMusicMode = nil
                keyboardManager.triggerIdleStatus()
            }
        )
    }
}
