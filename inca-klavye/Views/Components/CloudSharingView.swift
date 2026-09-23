import SwiftUI

/// Bulut Paylaşım Merkezi (Sharing Center)
/// Mock data yerine "Yapım Aşamasında / Çok Yakında" bilgilendirme ve gelecek özellikler vitrini.
struct CloudSharingView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared

    @State private var isPulsing: Bool = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                // 1. Üst Başlık
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.tr("tc_yun1", default: "Paylaşım Merkezi"))
                        .font(.system(size: 26, weight: .bold))
                    Text("Topluluk profilleri, makrolar ve özel RGB ışık efektleri bulut paylaşım platformu")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 2. Ana "Yapım Aşamasında" Hero Kartı
                VStack(spacing: 20) {
                    // Parlayan Bulut İkonu
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.3), Color.purple.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 96, height: 96)
                            .scaleEffect(isPulsing ? 1.08 : 0.96)
                            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: isPulsing)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 76, height: 76)
                            .shadow(color: Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.5), radius: 16, x: 0, y: 6)

                        Image(systemName: "icloud.and.arrow.up.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 12)

                    // Durum Rozeti
                    HStack(spacing: 6) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 11))
                        Text("YAPIM AŞAMASINDA • ÇOK YAKINDA")
                            .font(.system(size: 11.5, weight: .bold))
                            .tracking(1.0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.15))
                    .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.3), lineWidth: 1)
                    )

                    // Açıklama Metinleri
                    VStack(spacing: 8) {
                        Text("Bulut Paylaşım Merkezi Geliştiriliyor")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Empousa oyuncularının kendi hazırladıkları 126 tuş bağımsız RGB aydınlatma temalarını, profesyonel oyun makrolarını ve performans profillerini birbirleriyle paylaşabileceği bulut altyapımız üzerinde çalışıyoruz.")
                            .font(.system(size: 13.5))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .frame(maxWidth: 580)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

                // 3. Gelecek Özellikler Vitrini (Roadmap Cards)
                VStack(alignment: .leading, spacing: 14) {
                    Label("YAKINDA EKLENECEK ÖZELLİKLER", systemImage: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    HStack(spacing: 16) {
                        featurePreviewCard(
                            icon: "paintpalette.fill",
                            title: "Topluluk Aydınlatma Temaları",
                            description: "Diğer kullanıcıların tasarladığı özel ışık efektlerini ve renk paletlerini tek tıkla klavyenize aktarın.",
                            accentColor: Color(red: 0.98, green: 0.18, blue: 0.38)
                        )

                        featurePreviewCard(
                            icon: "bolt.square.fill",
                            title: "Makro & Kısayol Kütüphanesi",
                            description: "Espor ve üretkenlik için popüler oyun ve yazılımlara özel hazırlanmış optimize tuş dizilimleri.",
                            accentColor: Color.purple
                        )

                        featurePreviewCard(
                            icon: "arrow.triangle.2.circlepath.icloud.fill",
                            title: "Bulut Yedekleme & Senkronizasyon",
                            description: "Kendi klavye konfigürasyonlarınızı ve tuş profillerinizi bulutta güvenle saklayın.",
                            accentColor: Color.blue
                        )
                    }
                }

                // 4. Bilgilendirme Alt Notu
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)

                    Text("Paylaşım Merkezi bir sonraki güncelleme ile aktif olacaktır. Cihazınızı ve aydınlatmalarınızı sol menüdeki sekmelerden tam yetkiyle özelleştirmeye devam edebilirsiniz.")
                        .font(.system(size: 12.5))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)

                    Spacer()
                }
                .padding(16)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
            }
            .padding(24)
        }
        .onAppear {
            isPulsing = true
        }
    }

    // MARK: - Gelecek Özellik Kartı Bileşeni
    private func featurePreviewCard(icon: String, title: String, description: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accentColor.opacity(0.16))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
