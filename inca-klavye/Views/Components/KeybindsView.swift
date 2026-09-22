import SwiftUI

struct KeybindsView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared

    @State private var selectedLayer: Int = 1
    @State private var selectedKeyId: String? = "W"
    @State private var selectedKeyName: String = "W Tuşu"
    @State private var selectedCategory: String = "Komutlar"
    @State private var assignedCommand: String = "Standart Tuş Vuruşu"

    let layers = [
        (id: 1, name: "Varsayılan (Base)", desc: "Standart 83 tuş dizilimi"),
        (id: 2, name: "FN1 Katmanı", desc: "Fn tuşuyla birlikte çalışan multimedya ve fonksiyon tuşları"),
        (id: 3, name: "FN2 Katmanı", desc: "İkincil özel fonksiyon katmanı"),
        (id: 4, name: "Tap Katmanı", desc: "Kısa dokunuş (Tap) ile tetiklenen özel atamalar")
    ]

    let quickCommands: [(key: String, name: String, icon: String)] = [
        ("tc_cmd1", "Pencereyi Kapat", "xmark.circle.fill"),
        ("tc_cmd11", "Win Tuşunu Kilitle", "lock.fill"),
        ("tc_cmd6", "Masaüstünü Göster", "menubar.dock.rectangle"),
        ("tc_cmd7", "Görev Yöneticisi", "chart.bar.xaxis"),
        ("tc_kbmedia_cal", "Hesap Makinesi", "plus.forwardslash.minus"),
        ("tc_kbmedia_mail", "E-posta", "envelope.fill"),
        ("tc_kbmedia_main", "Ana Sayfa / Web", "safari.fill"),
        ("tc_kbmedia_msel", "Medya Çalar", "play.rectangle.fill"),
        ("tc_vol_up", "Ses +", "speaker.wave.3.fill"),
        ("tc_vol_dw", "Ses -", "speaker.wave.1.fill"),
        ("tc_mute", "Sessiz Mod", "speaker.slash.fill")
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Başlık
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.tr("tc_msg18", default: "Tuş Atamaları ve Katmanlar"))
                        .font(.system(size: 26, weight: .bold))
                    Text("Donanımsal 4 katmanlı (Base, FN1, FN2, Tap) tuş özelleştirme ve komut atama paneli")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Katman Seçici Segment
                VStack(alignment: .leading, spacing: 12) {
                    Text(loc.tr("tc_kb10", default: "AKTİF DÜZEN KATMANI"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    HStack(spacing: 12) {
                        ForEach(layers, id: \.id) { layer in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedLayer = layer.id
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(layer.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(selectedLayer == layer.id ? .white : .primary)
                                    Text(layer.desc)
                                        .font(.caption2)
                                        .foregroundColor(selectedLayer == layer.id ? .white.opacity(0.8) : .secondary)
                                        .lineLimit(2)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(selectedLayer == layer.id ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(selectedLayer == layer.id ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // İNTERAKTİF KLAVYE GÖRSELİ (Kullanıcı doğrudan tuşa tıklayarak seçer)
                VStack(alignment: .center, spacing: 10) {
                    EmpousaKeyboardGraphicView(
                        keyboardManager: keyboardManager,
                        selectedKeyId: $selectedKeyId,
                        onKeySelected: { keyDef in
                            self.selectedKeyName = "\(keyDef.primaryLabel.isEmpty ? keyDef.id : keyDef.primaryLabel) Tuşu"
                        },
                        onKnobRotatedOrClicked: {
                            keyboardManager.toggleWheelMode()
                        }
                    )
                    .scaleEffect(0.96)
                }
                .frame(maxWidth: .infinity)

                // Hızlı Komut ve Kısayol Atama Paleti (Windows App tc_cmd & tc_kbmedia)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label(loc.tr("tc_msg28", default: "HIZLI KOMUT ATAMA PALETİ").uppercased(), systemImage: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)

                        Spacer()

                        Text("Seçili Tuş: \(selectedKeyName)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                        ForEach(quickCommands, id: \.key) { cmd in
                            Button(action: {
                                withAnimation {
                                    assignedCommand = loc.tr(cmd.key, default: cmd.name)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: cmd.icon)
                                        .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                                        .font(.system(size: 13))
                                    Text(loc.tr(cmd.key, default: cmd.name))
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        Text("Atanan Fonksiyon: ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(assignedCommand)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 4)
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))

                // Çakışma Önleme (Debounce Time) Kartı
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Çakışma Önleme (Debounce Time)", systemImage: "timer")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text("\(keyboardManager.debounceTimeMs) ms")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                    }

                    Slider(value: Binding(
                        get: { Double(keyboardManager.debounceTimeMs) },
                        set: { 
                            let val = Int($0)
                            keyboardManager.setDebounceTime(ms: val)
                        }
                    ), in: 1...20, step: 1)

                    HStack {
                        Text("1 ms (En Hızlı)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("8 ms (Önerilen)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("20 ms (Maksimum Filtre)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))

                // Orijinal Donanım Protokolü Notu
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Orijinal Donanım Protokolü")
                            .font(.system(size: 13, weight: .bold))
                        Text("Klavyenin Windows sürücüsü (KB.ini ve OemDrv.exe) incelendiğinde; cihazın 'Magnetic Axis' adını taşımasına karşın sürücüsünde analog milimetre aktüasyon veya Rapid Trigger kaydırıcısı bulunmamaktadır. Tuş tetiklemeleri donanımsal 4 katman ve yazılımsal Debounce filtresiyle yönetilmektedir.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.2), lineWidth: 1))
            }
            .padding(24)
        }
    }
}
