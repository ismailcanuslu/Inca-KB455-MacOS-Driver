import SwiftUI

struct CloudProfileItem: Identifiable {
    let id = UUID()
    var name: String
    var author: String
    var date: String
    var downloads: Int
    var likes: Int
    var category: String
    var description: String
    var tags: [String]
}

struct CloudSharingView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared

    @State private var selectedFilter: String = "Tümü"
    @State private var downloadedProfiles: Set<UUID> = []
    @State private var appliedProfileId: UUID? = nil
    @State private var showUploadModal: Bool = false
    @State private var showLoginModal: Bool = false
    @State private var username: String = "ismailcanuslu"
    @State private var isUserLoggedIn: Bool = true

    let sampleProfiles = [
        CloudProfileItem(
            name: "Cyberpunk 2077 Neon",
            author: "NeonBlade",
            date: "2026-03-12",
            downloads: 1420,
            likes: 388,
            category: "Işıklandırma",
            description: "Gece sürüşü sarı ve camgöbeği neon teması. Yan şeritler turkuaz nefes alma.",
            tags: ["RGB", "Cyberpunk", "Canlı"]
        ),
        CloudProfileItem(
            name: "CS2 Pro FPS Setup",
            author: "s1mple_fan",
            date: "2026-02-28",
            downloads: 2890,
            likes: 742,
            category: "Oyun & Makro",
            description: "WASD ve bomba tuşları sarı aydınlatmalı, Jumpthrow makrosu Space+C atanmış.",
            tags: ["FPS", "CS2", "Düşük Gecikme"]
        ),
        CloudProfileItem(
            name: "Apple Music Pastel",
            author: "DesignPro",
            date: "2026-01-15",
            downloads: 980,
            likes: 215,
            category: "Minimalist",
            description: "Gözü yormayan pastel pembe, mor ve lavanta gradyanları. Ofis çalışması için ideal.",
            tags: ["Apple", "Minimal", "Pastel"]
        ),
        CloudProfileItem(
            name: "Matrix Code Stream",
            author: "Morpheus99",
            date: "2026-03-01",
            downloads: 1650,
            likes: 430,
            category: "Işıklandırma",
            description: "Yukarıdan aşağıya yeşil dijital yağmur efekti ve donanımsal 1000Hz polling.",
            tags: ["Matrix", "Yeşil", "Kod"]
        )
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Başlık & Profilim Butonu
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc.tr("tc_yun1", default: "Bulut Paylaşım Merkezi"))
                            .font(.system(size: 26, weight: .bold))
                        Text(loc.tr("tc_yun35", default: "Topluluk tarafından paylaşılan klavye profilleri ve makroları keşfedin"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Kullanıcı Durum Rozeti
                    HStack(spacing: 8) {
                        Circle()
                            .fill(LinearGradient(colors: [Color.pink, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 28, height: 28)
                            .overlay(Text("İC").font(.system(size: 11, weight: .bold)).foregroundColor(.white))

                        VStack(alignment: .leading, spacing: 0) {
                            Text(username)
                                .font(.system(size: 12, weight: .semibold))
                            Text(loc.tr("tc_yun37", default: "Kişisel Panel"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Button(action: {
                            showUploadModal = true
                        }) {
                            Label(loc.tr("tc_yun33", default: "Buluta Yükle"), systemImage: "icloud.and.arrow.up.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                }

                // Arama ve Filtre Çubuğu
                HStack(spacing: 12) {
                    ForEach(["Tümü", "Işıklandırma", "Oyun & Makro", "Minimalist"], id: \.self) { filter in
                        Button(action: {
                            selectedFilter = filter
                        }) {
                            Text(filter)
                                .font(.system(size: 13, weight: selectedFilter == filter ? .semibold : .regular))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(selectedFilter == filter ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.06))
                                .foregroundColor(selectedFilter == filter ? .white : .primary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Profil Kartları Izgarası (Grid)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(sampleProfiles) { item in
                        VStack(alignment: .leading, spacing: 14) {
                            // Kart Başlığı
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.name)
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Yazar: @\(item.author) • \(item.date)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text(item.category)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(6)
                            }

                            Text(item.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)

                            // Etiketler
                            HStack(spacing: 6) {
                                ForEach(item.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                }
                            }

                            Divider()

                            // İndirme & Beğeni İstatistikleri ve İndir Butonu
                            HStack {
                                HStack(spacing: 12) {
                                    Label("\(item.downloads)", systemImage: "arrow.down.circle")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Label("\(item.likes)", systemImage: "heart.fill")
                                        .font(.caption2)
                                        .foregroundColor(.pink)
                                }

                                Spacer()

                                if appliedProfileId == item.id {
                                    Text("Klavyede Aktif")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.green.opacity(0.15))
                                        .clipShape(Capsule())
                                } else {
                                    Button(action: {
                                        withAnimation {
                                            downloadedProfiles.insert(item.id)
                                            appliedProfileId = item.id
                                        }
                                    }) {
                                        Label(loc.tr("tc_yun7", default: "İndir & Uygula"), systemImage: "arrow.down.to.line")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        .padding(18)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(appliedProfileId == item.id ? Color.green : Color.white.opacity(0.08), lineWidth: appliedProfileId == item.id ? 2 : 1)
                        )
                    }
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showUploadModal) {
            VStack(alignment: .leading, spacing: 20) {
                Text(loc.tr("tc_yun33", default: "Klavyeni Buluta Paylaş"))
                    .font(.title2.bold())

                Text(loc.tr("tc_yun9", default: "Profilin açıklamasını ve kullanılan aydınlatma modunu belirtin"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Profil Adı", text: .constant("Özel INCA Kurulumum"))
                    .textFieldStyle(.roundedBorder)

                TextField("Açıklama (Hangi oyunlar veya amaç için?)", text: .constant("Valorant ve kod yazma odaklı mor-cyan tema."))
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Spacer()
                    Button("İptal") { showUploadModal = false }
                        .buttonStyle(.bordered)
                    Button(loc.tr("tc_yun41", default: "Gönder & Paylaş")) {
                        showUploadModal = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(width: 440)
        }
    }
}
