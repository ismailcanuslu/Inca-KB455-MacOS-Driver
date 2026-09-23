import SwiftUI

/// Apple Dynamic Island tarzı, pencerenin üstünde yüzen dinamik ada bileşeni.
/// Ana ada daima "Inca Empousa IKG-455" aygıt ve bağlantı durumunu korur.
/// Kaydedilmemiş değişiklik veya işlem durumunda ana adayı bozmadan hemen altında
/// ikinci bir dinamik ada kapsülü akıcı bir yay (spring) animasyonuyla açılır.
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
        VStack(spacing: 7) {
            // 1. Üst Ana Dinamik Ada (Daima Inca Empousa ve Cihaz Durumu)
            mainIdentityIslandView

            // 2. Alt Dinamik Ada (Kaydedilmemiş Değişiklikler veya İşlem Bildirimi)
            if keyboardManager.islandStatus != .idle {
                secondaryAlertIslandView(status: keyboardManager.islandStatus)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.94)).combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.94)).combined(with: .move(edge: .top))
                        )
                    )
            }
        }
        .animation(.spring(response: 0.40, dampingFraction: 0.74, blendDuration: 0.15), value: keyboardManager.islandStatus)
        .onAppear {
            pulseAnimation = true
        }
    }

    // MARK: - 1. Üst Ana Dinamik Ada (Her Zaman Sabit ve Aktif)
    private var mainIdentityIslandView: some View {
        HStack(spacing: 9) {
            // Canlı Donanım İkonu & Durum Işıltısı
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

            // Klavye Adı
            Text(keyboardManager.isConnected ? "Inca Empousa IKG-455" : loc.tr("tc_searching_connection", default: "Bağlantı Aranıyor..."))
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            if keyboardManager.isConnected {
                // Bağlantı Modu Rozeti
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

                // Pil Rozeti
                HStack(spacing: 3) {
                    Image(systemName: batterySystemIcon)
                        .font(.system(size: 10))
                        .foregroundColor(batteryStatusColor)
                    Text("%\(keyboardManager.batteryLevel)")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
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
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 3)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
    }

    // MARK: - 2. Alt Dinamik Ada (Uyarı & İşlem Kapsülü)
    @ViewBuilder
    private func secondaryAlertIslandView(status: KeyboardManager.IslandStatus) -> some View {
        Group {
            switch status {
            case .idle:
                EmptyView()

            case .unsavedChanges(let description):
                unsavedChangesIslandView(description: description)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        )
                    )

            case .saving(let message):
                savingIslandView(message: message)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        )
                    )

            case .saved(let message):
                savedIslandView(message: message)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        )
                    )

            case .wirelessWarning(let title, let message):
                wirelessWarningIslandView(title: title, message: message)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        )
                    )
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.2), value: status)
    }

    // MARK: - Kaydedilmemiş Değişiklikler Kapsülü
    private func unsavedChangesIslandView(description: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            // Üst Satır: Dikkat İkonu, Başlık & Açıklama
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.22))
                        .frame(width: 24, height: 24)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 11, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(loc.tr("island_unsaved_title", default: "KAYDEDİLMEMİŞ DEĞİŞİKLİKLER"))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.6)

                    Text(description.isEmpty ? loc.tr("island_unsaved_desc", default: "Klavyeye aktarılmayı bekleyen ayarlar var") : description)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                // Beklemede Rozeti
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 5, height: 5)
                    Text(loc.tr("island_preview_badge", default: "Beklemede"))
                        .font(.system(size: 9, weight: .bold))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.18))
                .foregroundColor(.orange)
                .clipShape(Capsule())
            }

            // Alt Satır: Bilgi Notu & Eylem Butonları
            HStack(spacing: 10) {
                Text(loc.tr("island_preview_info", default: "Seçilen ayarları klavyeye göndermek için 'Klavyeye Gönder' butonuna tıklayın."))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)

                Spacer()

                // Vazgeç Butonu
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        keyboardManager.onDiscardChangesRequested?()
                        keyboardManager.triggerIdleStatus()
                    }
                }) {
                    Text(loc.tr("island_discard_btn", default: "Vazgeç"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(7)
                }
                .buttonStyle(.plain)

                // Klavyeye Gönder Butonu
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        keyboardManager.onCommitChangesRequested?()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(loc.tr("island_save_btn", default: "Klavyeye Gönder"))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(7)
                    .shadow(color: Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.4), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 440)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.55), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 14, x: 0, y: 6)
        .shadow(color: Color.orange.opacity(0.2), radius: 8, x: 0, y: 2)
    }

    // MARK: - Kaydediliyor Kapsülü
    private func savingIslandView(message: String) -> some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.75)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(message.isEmpty ? "Klavyeye Gönderiliyor..." : message)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)

                Text("Komutlar klavyenize aktarılıyor, lütfen bekleyin...")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(width: 380)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.cyan.opacity(0.6), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 14, x: 0, y: 6)
    }

    // MARK: - Kaydedildi Kapsülü
    private func savedIslandView(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 17, weight: .bold))

            VStack(alignment: .leading, spacing: 2) {
                Text(message.isEmpty ? "Klavyeye Başarıyla Gönderildi!" : message)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Tüm ayarlar klavyenizde aktif ve kullanıma hazır.")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(width: 380)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.green.opacity(0.65), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 14, x: 0, y: 6)
    }

    // MARK: - Kablosuz Bağlantı Uyarısı Kapsülü (2.4G)
    private func wirelessWarningIslandView(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            // Üst Satır: Uyarı İkonu, Başlık & Rozet
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.22))
                        .frame(width: 26, height: 26)

                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .foregroundColor(.orange)
                        .font(.system(size: 12, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.6)

                    Text(message)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Sinyal Sorunu Rozeti
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 5, height: 5)
                        .overlay(
                            Circle()
                                .fill(Color.orange.opacity(0.4))
                                .frame(width: 10, height: 10)
                        )
                    Text(loc.tr("island_wireless_badge", default: "Bağlantı Sorunu"))
                        .font(.system(size: 9, weight: .bold))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.18))
                .foregroundColor(.orange)
                .clipShape(Capsule())
            }

            // Alt Satır: Öneri & Eylem Butonları
            HStack(spacing: 10) {
                Text(loc.tr("island_wireless_hint", default: "Klavyeyi alıcıya yaklaştırın veya bir tuşa basarak uyandırın."))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)

                Spacer()

                // Kapat Butonu
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        keyboardManager.dismissWirelessWarning()
                    }
                }) {
                    Text(loc.tr("island_discard_btn", default: "Kapat"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(7)
                }
                .buttonStyle(.plain)

                // Tekrar Dene Butonu
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        keyboardManager.retryLastWirelessOperation()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .bold))
                        Text(loc.tr("island_wireless_retry_btn", default: "Tekrar Dene"))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color(red: 0.95, green: 0.45, blue: 0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(7)
                    .shadow(color: Color.orange.opacity(0.4), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 460)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.7), Color.orange.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: Color.black.opacity(0.5), radius: 14, x: 0, y: 6)
        .shadow(color: Color.orange.opacity(0.25), radius: 10, x: 0, y: 3)
    }

    // MARK: - Yardımcı Hesaplamalar
    private var batteryStatusColor: Color {
        if keyboardManager.isCharging { return .green }
        if keyboardManager.batteryLevel <= 20 { return .red }
        if keyboardManager.batteryLevel <= 50 { return .orange }
        return .green
    }

    private var batterySystemIcon: String {
        if keyboardManager.isCharging { return "battery.100.bolt" }
        let lvl = keyboardManager.batteryLevel
        if lvl >= 90 { return "battery.100" }
        if lvl >= 75 { return "battery.75" }
        if lvl >= 50 { return "battery.50" }
        if lvl >= 25 { return "battery.25" }
        return "battery.0"
    }
}
