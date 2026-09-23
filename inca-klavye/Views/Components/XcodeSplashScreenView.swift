import SwiftUI
import AppKit

struct XcodeSplashScreenView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @Binding var isPresented: Bool

    @State private var progress: Double = 0.15
    @State private var statusText: String = "HID Denetleyicisi Başlatılıyor..."
    @State private var iconScale: CGFloat = 0.88
    @State private var iconOpacity: Double = 0.0
    @State private var cardScale: CGFloat = 0.96
    @State private var cardOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Tam Pencere Buzlu Cam Arka Planı (Xcode tarzı blur)
            Color.black.opacity(0.45)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // Xcode Tarzı Karşılama Penceresi (Floating Welcome Card)
            VStack(spacing: 0) {
                HStack(spacing: 28) {
                    // Sol Alan: Büyük Uygulama Logosu & Glow
                    ZStack {
                        // Ambient Glow
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.4),
                                        Color.purple.opacity(0.3),
                                        Color.cyan.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 130, height: 130)
                            .blur(radius: 16)

                        // Uygulama Simgesi Kutusu
                        if let appIcon = NSApplication.shared.applicationIconImage {
                            Image(nsImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                                )
                                .shadow(color: Color.black.opacity(0.4), radius: 14, x: 0, y: 8)
                        } else {
                            // Yedek Apple Tarzı İkon Grafiği
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(white: 0.18), Color(white: 0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "keyboard.fill")
                                            .font(.system(size: 46))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color.white, Color(red: 0.98, green: 0.18, blue: 0.38)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                        Text("EMPOUSA")
                                            .font(.system(size: 9, weight: .black, design: .monospaced))
                                            .foregroundColor(.cyan)
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                                )
                                .shadow(color: Color.black.opacity(0.4), radius: 14, x: 0, y: 8)
                        }
                    }
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                    // Sağ Alan: Başlık, Sürüm ve Yükleme Aşaması
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("INCA EMPOUSA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                                .tracking(1.8)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("IKG-455")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Text("Inca Empousa")
                            .font(.system(size: 30, weight: .bold, design: .default))
                            .foregroundColor(.white)

                        Text("Sürüm 1.0 • macOS Sürücüsü")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))

                        Spacer().frame(height: 12)

                        // Durum ve Progress Bar
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(statusText)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))

                                Spacer()

                                if keyboardManager.isConnected {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 6, height: 6)
                                        Text(keyboardManager.connectionType.rawValue)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.14))
                                    .cornerRadius(6)
                                }
                            }

                            // Xcode Tarzı İnce Apple Progress Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.12))
                                        .frame(height: 5)

                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.98, green: 0.18, blue: 0.38),
                                                    Color.purple,
                                                    Color.cyan
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * CGFloat(progress), height: 5)
                                        .animation(.easeInOut(duration: 0.35), value: progress)
                                }
                            }
                            .frame(height: 5)
                        }
                    }
                }
                .padding(.horizontal, 34)
                .padding(.top, 36)
                .padding(.bottom, 28)

                Divider()
                    .background(Color.white.opacity(0.1))

                // Alt Bilgi / Hızlı Geçiş Alanı
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                        Text("2.4GHz Lightspeed & 1000Hz Yoklama")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Başla / Atla Butonu
                    Button(action: {
                        dismissWithAnimation()
                    }) {
                        HStack(spacing: 4) {
                            Text("Başla")
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.2))
            }
            .frame(width: 540)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.92))
                    .background(.ultraThickMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.55), radius: 35, x: 0, y: 15)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            runStartupSequence()
        }
    }

    private func runStartupSequence() {
        // Kartın yumuşak Xcode girişi
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            cardScale = 1.0
            cardOpacity = 1.0
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // Aşama 1: HID Denetleyicisi
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                progress = 0.45
                statusText = "USB & 2.4G Aygıt Kanalları Taranıyor..."
            }
        }

        // Aşama 2: Profil & Aydınlatma Kontrolü
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                progress = 0.80
                if keyboardManager.isConnected {
                    statusText = "Empousa Bağlandı: Profil Senkronize Ediliyor..."
                } else {
                    statusText = "Klavye Profilleri Hazırlanıyor..."
                }
            }
        }

        // Aşama 3: Tamamlandı
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation {
                progress = 1.0
                statusText = "Hazır! Arayüz Açılıyor..."
            }
        }

        // Aşama 4: Otomatik Xcode-tarzı Açılış Kapanışı
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            dismissWithAnimation()
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            cardScale = 1.04
            cardOpacity = 0.0
            isPresented = false
        }
    }
}
