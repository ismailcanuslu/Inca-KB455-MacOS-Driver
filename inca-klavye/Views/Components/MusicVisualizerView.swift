import SwiftUI
import Combine

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

    let musicEffects = [
        (id: 1, name: "Spektrum Dalgalanma", icon: "waveform.path.ecg"),
        (id: 2, name: "Zıplayan Bloklar", icon: "chart.bar.fill"),
        (id: 3, name: "Merkezden Dışa Ritim", icon: "circle.circle.fill"),
        (id: 4, name: "Nabız & Parlama", icon: "bolt.heart.fill")
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Başlık
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.tr("tc_music1", default: "Müzik & Ses Senkronizasyonu"))
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
                                            Color(red: 0.98, green: 0.18, blue: 0.38),
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

                // Ritim Efekt Modu Seçici
                VStack(alignment: .leading, spacing: 14) {
                    Text(loc.tr("tc_kb1", default: "Işık Efekti Modu"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    HStack(spacing: 12) {
                        ForEach(musicEffects, id: \.id) { effect in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedEffect = effect.id
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Image(systemName: effect.icon)
                                        .font(.title3)
                                        .foregroundColor(selectedEffect == effect.id ? .white : Color(red: 0.98, green: 0.18, blue: 0.38))

                                    Text(effect.name)
                                        .font(.system(size: 13, weight: selectedEffect == effect.id ? .bold : .medium))
                                        .foregroundColor(selectedEffect == effect.id ? .white : .primary)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(selectedEffect == effect.id ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(selectedEffect == effect.id ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Kazanç ve Ses Ayarları Kartı
                VStack(alignment: .leading, spacing: 18) {
                    Text(loc.tr("tc_config", default: "Ses & Ritim Hassasiyeti"))
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
                                    .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
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
            // Çubukların canlı rastgele oynaması (Ses simülasyonu)
            if isListening {
                for i in 0..<barHeights.count {
                    let base = CGFloat.random(in: 15...115)
                    barHeights[i] = min(120, max(10, base * (CGFloat(gain) / 70.0)))
                }
            }
        }
    }
}
