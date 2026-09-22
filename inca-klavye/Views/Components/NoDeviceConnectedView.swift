import SwiftUI

struct NoDeviceConnectedView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // İkon ve Işık Efekti
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)

                Image(systemName: "keyboard.badge.ellipsis")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.secondary)
            }

            // Metin Başlığı
            VStack(spacing: 8) {
                Text("Empousa Klavye Bağlı Değil")
                    .font(.system(size: 24, weight: .bold))

                Text("Aydınlatma, tuş katmanları, TFT ekran ve donanım ayarlarını yapılandırmak için klavyenizi bağlayın.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)
            }

            // Bağlantı Yöntemleri Kartları (Apple HIG)
            HStack(spacing: 16) {
                connectionCard(
                    icon: "cable.connector",
                    title: "USB-C Kablolu",
                    desc: "Type-C kablosunu doğrudan Mac'inize bağlayın."
                )

                connectionCard(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "2.4G Kablosuz",
                    desc: "USB alıcıyı takın ve klavyenin arka anahtarını '2.4G' moduna alın."
                )

                connectionCard(
                    icon: "dot.radiowaves.left.and.right",
                    title: "Bluetooth",
                    desc: "Fn + 1/2/3 tuşlarıyla Mac'inizin Bluetooth menüsünden eşleştirin."
                )
            }
            .frame(maxWidth: 720)
            .padding(.horizontal, 24)

            // Durum Göstergesi
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(keyboardManager.statusMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func connectionCard(icon: String, title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.accentColor)
                Spacer()
            }

            Text(title)
                .font(.system(size: 14, weight: .bold))

            Text(desc)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
