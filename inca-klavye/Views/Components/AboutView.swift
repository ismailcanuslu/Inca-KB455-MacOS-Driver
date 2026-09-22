import SwiftUI

struct AboutView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 28) {
                // Üst Başlık & İkon Kartı
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 26)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 88, height: 88)
                            .shadow(color: Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.35), radius: 16, x: 0, y: 8)

                        Image(systemName: "keyboard")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 4) {
                        Text("Inca Empousa")
                            .font(.system(size: 26, weight: .bold))

                        Text(loc.tr("about_version", default: "Sürüm 1.0.0 (Build 2026.1)"))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)

                // Açıklama ve Hobi Projesi Notu
                VStack(alignment: .leading, spacing: 14) {
                    Label(loc.tr("about_project_header", default: "PROJE HAKKINDA"), systemImage: "info.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    Text(loc.tr("about_project_desc"))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.primary.opacity(0.85))
                        .lineSpacing(5)

                    Divider().padding(.vertical, 4)

                    Text(loc.tr("about_hig_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(20)
                .frame(maxWidth: 640, alignment: .leading)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))

                // Geliştirici & Bağlantılar Kartı
                VStack(alignment: .leading, spacing: 16) {
                    Label(loc.tr("about_dev_header", default: "GELİŞTİRİCİ VE KAYNAKLAR"), systemImage: "person.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.accentColor, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)
                            Text("İU")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("İsmailcan USLU")
                                .font(.system(size: 15, weight: .bold))
                            Text(loc.tr("about_dev_role", default: "Açık Kaynak Geliştirici"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Link(destination: URL(string: "https://github.com/ismailcanuslu")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                    .font(.system(size: 12))
                                Text("github.com/ismailcanuslu")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()

                    // Donanım Özeti
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc.tr("about_target_hw", default: "Hedef Donanım"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("INCA IKG-455 Empousa")
                                .font(.system(size: 13, weight: .semibold))
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc.tr("about_supported_protocols", default: "Desteklenen Protokoller"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(loc.tr("about_protocols_val", default: "Type-C Kablolu • 2.4G Kablosuz • Bluetooth 5.0"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 640, alignment: .leading)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))

                Text(loc.tr("about_copyright", default: "© 2026 İsmail Can Uslu. Tüm hakları saklıdır."))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.bottom, 20)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }
}
