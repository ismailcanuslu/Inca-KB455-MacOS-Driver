import SwiftUI

/// Apple Dynamic Island tarzı, pencerenin üstünde yüzen ve aşağıya doğru esneyen dinamik ada bileşeni.
/// Donanım EEPROM koruması gereği kaydedilmemiş değişiklikler olduğunda akıcı bir yay (spring) animasyonuyla
/// aşağı doğru genişleyerek detaylı durum ve eylem butonlarını sunar.
struct DynamicIslandFloatingView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc: LocalizationManager

    @State private var isHovered: Bool = false
    @State private var pulseAnimation: Bool = false

    private var connectionShortLabel: String {
        switch keyboardManager.connectionType {
        case .disconnected: return loc.tr("tc_searching_connection", default: "Yok")
        case .wireless24G: return "2.4G"
        case .wiredUSB: return "USB-C"
        case .bluetooth: return "BT"
        }
    }

    var body: some View {
        islandContent
            .animation(.spring(response: 0.44, dampingFraction: 0.72, blendDuration: 0.15), value: keyboardManager.islandStatus)
            .onAppear {
                pulseAnimation = true
            }
    }

    @ViewBuilder
    private var islandContent: some View {
        switch keyboardManager.islandStatus {
        case .idle:
            idleIslandView

        case .unsavedChanges(let description):
            unsavedChangesIslandView(description: description)

        case .saving(let message):
            savingIslandView(message: message)

        case .saved(let message):
            savedIslandView(message: message)
        }
    }

    // MARK: - 1. Normal (Idle) Kompakt Kapsül
    private var idleIslandView: some View {
        HStack(spacing: 8) {
            // Canlı Donanım İkonu & Nefes Alan LED Işıltısı
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        (keyboardManager.isConnected ? Color.green : Color.orange).opacity(0.18)
                    )
                    .frame(width: 20, height: 20)

                Image(systemName: keyboardManager.isConnected ? "keyboard.fill" : "antenna.radiowaves.left.and.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(keyboardManager.isConnected ? .green : .orange)
            }
            .shadow(
                color: (keyboardManager.isConnected ? Color.green : Color.orange).opacity(pulseAnimation ? 0.75 : 0.15),
                radius: pulseAnimation ? 5 : 2
            )
            .animation(
                .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                value: pulseAnimation
            )

            Text(keyboardManager.isConnected ? "Inca Empousa" : loc.tr("tc_searching_connection", default: "Bağlantı Aranıyor..."))
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            if keyboardManager.isConnected {
                HStack(spacing: 4) {
                    Image(systemName: keyboardManager.connectionType.icon)
                        .font(.system(size: 9, weight: .semibold))
                    Text(connectionShortLabel)
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
                .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(height: 32)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.88))
                .background(.ultraThinMaterial, in: Capsule())
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.28 : 0.15),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 3)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
        .help(keyboardManager.isConnected ? "Inca Empousa IKG-455: Cihaz Hazır" : "Klavye aranıyor...")
    }

    // MARK: - 2. Genişletilmiş Dinamik Ada (Unsaved Changes - Aşağıya Esneme)
    private func unsavedChangesIslandView(description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Üst Satır: Başlık, Durum Rozeti & Varsa Değişiklik Kategorisi
            HStack(alignment: .center, spacing: 10) {
                // Dikkat İkonu
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.22))
                        .frame(width: 26, height: 26)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(loc.tr("island_unsaved_title", default: "KAYDEDİLMEMİŞ DEĞİŞİKLİKLER"))
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.6)

                    Text(loc.tr("island_unsaved_desc", default: "Klavyeye aktarılmayı bekleyen ayarlar var"))
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                }

                if !description.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 8, weight: .semibold))
                        Text(description)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                    )
                }

                Spacer()

                // Canlı Donanım Bekleme Rozeti
                HStack(spacing: 5) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 9, weight: .bold))
                    Text(loc.tr("island_preview_badge", default: "Önizlemede"))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Color.orange.opacity(0.14))
                .clipShape(Capsule())
            }

            // Orta Satır: Bilgilendirme Kutusu
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange.opacity(0.9))
                    .font(.system(size: 12))

                Text(loc.tr("island_preview_info", default: "Yapılan değişiklikler şu an ekranda ve cihazda test ediliyor. Klavye yeniden başlatıldığında kaybolmaması için dahili EEPROM belleğine yazın."))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.06))
            .cornerRadius(9)

            // Alt Satır: Bellek Bilgisi & Eylem Butonları
            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(loc.tr("island_eeprom_protection", default: "Donanım EEPROM Koruması"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Vazgeç Butonu
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        keyboardManager.onDiscardChangesRequested?()
                        keyboardManager.triggerIdleStatus()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 10, weight: .bold))
                        Text(loc.tr("island_discard_btn", default: "Vazgeç"))
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.12))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help(loc.tr("island_discard_help", default: "Değişiklikleri iptal et ve önceki donanım ayarlarına geri dön"))

                // Klavyeye Kaydet Butonu
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        keyboardManager.onCommitChangesRequested?()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(loc.tr("island_save_btn", default: "Klavyeye Kaydet"))
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.18, blue: 0.38),
                                Color(red: 0.85, green: 0.1, blue: 0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(color: Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.55), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .help(loc.tr("island_save_help", default: "Değişiklikleri klavyenin dahili çipine kalıcı olarak yaz"))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .frame(width: 530)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.85),
                            Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.55),
                            Color.orange.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.65), radius: 24, x: 0, y: 12)
        .shadow(color: Color.orange.opacity(0.25), radius: 14, x: 0, y: 4)
    }

    // MARK: - 3. Kaydediliyor (Saving) Durumu
    private func savingIslandView(message: String) -> some View {
        HStack(spacing: 14) {
            ProgressView()
                .scaleEffect(0.8)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(message.isEmpty ? "Klavyeye Yazılıyor..." : message)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)

                Text("Donanım EEPROM belleği güncelleniyor, lütfen bekleyin...")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(width: 420)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.cyan.opacity(0.65), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.55), radius: 20, x: 0, y: 10)
        .shadow(color: Color.cyan.opacity(0.3), radius: 10, x: 0, y: 4)
    }

    // MARK: - 4. Başarıyla Kaydedildi (Saved) Durumu
    private func savedIslandView(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20, weight: .bold))

            VStack(alignment: .leading, spacing: 2) {
                Text(message.isEmpty ? "Ayarlar Başarıyla Kaydedildi!" : message)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.green)

                Text("Değişiklikler klavye donanım belleğine yazıldı ✓")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(width: 400)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.green.opacity(0.7), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.55), radius: 20, x: 0, y: 10)
        .shadow(color: Color.green.opacity(0.35), radius: 10, x: 0, y: 4)
    }
}
