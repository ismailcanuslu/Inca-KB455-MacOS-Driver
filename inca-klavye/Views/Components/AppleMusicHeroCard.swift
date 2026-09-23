import SwiftUI

struct AppleMusicHeroCard: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared
    var currentColor: Color
    var activeEffectName: String
    var selectedEffect: LightingEffect? = nil
    var isMulticolor: Bool = false

    @State private var breathingPhase: Bool = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Arka Plan Dinamik Ambient Glow (Seçili efekte göre zarafetle uyum sağlar)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ambientBackgroundGradient)
                .opacity(breathingOpacity)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: breathingPhase)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            ambientBorderGradient,
                            lineWidth: 1.2
                        )
                )
                .shadow(color: ambientGlowColor.opacity(0.35), radius: 25, x: 0, y: 10)

            // İçerik
            HStack(spacing: 24) {
                // Sol Görsel / Simge (Apple Music Albüm Kapağı Estetiği)
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.75),
                                    ambientGlowColor.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)

                    // Reaktif / Dalga efekti için hafif konsantrik halka
                    if selectedEffect == .reactive || selectedEffect == .waveRipple {
                        Circle()
                            .stroke(currentColor.opacity(0.35), lineWidth: 1.5)
                            .frame(width: 90, height: 90)
                            .scaleEffect(breathingPhase ? 1.05 : 0.95)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: breathingPhase)
                    }

                    // Klavye İkonografisi & Işıltı
                    VStack(spacing: 6) {
                        Image(systemName: effectIcon)
                            .font(.system(size: 38))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: iconGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: ambientGlowColor, radius: 12)

                        Text("IKG-455")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Orta Bilgi Alanı
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(loc.tr("hero_series", default: "EMPOUSA SERİSİ"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(currentColor)
                            .tracking(1.5)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(loc.tr("hero_hall_effect", default: "HALL EFFECT MANYETİK EKSEN"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    Text("Inca Empousa IKG-455")
                        .font(.system(size: 26, weight: .bold, design: .default))
                        .foregroundColor(.white)

                    Text(loc.tr("hero_active_effect", default: "Aktif Efekt:") + " \(activeEffectName)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    // Rozetler (Pil, Mod, Bağlantı)
                    HStack(spacing: 10) {
                        // Pil Rozeti
                        if keyboardManager.batteryLevel >= 100 && keyboardManager.isCharging {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 11))
                                Text(loc.tr("tc_fully_charged", default: "Tamamen Şarj Oldu"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.16))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.green.opacity(0.35), lineWidth: 1))
                        } else if keyboardManager.batteryLevel <= 20 && !keyboardManager.isCharging {
                            HStack(spacing: 5) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 11))
                                Text("%\(keyboardManager.batteryLevel) • \(loc.tr("tc_low_battery", default: "Batarya Zayıf"))")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.18))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.red.opacity(0.35), lineWidth: 1))
                        } else {
                            HStack(spacing: 5) {
                                Image(systemName: batteryIconName)
                                    .foregroundColor(batteryColor)
                                Text("%\(keyboardManager.batteryLevel)")
                                    .font(.system(size: 12, weight: .semibold))
                                if keyboardManager.isCharging {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(.yellow)
                                }
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }

                        // Mac / Win Modu Rozeti
                        HStack(spacing: 5) {
                            Image(systemName: keyboardManager.isMacMode ? "apple.logo" : "window.vertical.closed")
                                .font(.system(size: 11))
                            Text(keyboardManager.isMacMode ? "Mac Modu" : "Windows Modu")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))

                        // Bağlantı Rozeti
                        HStack(spacing: 5) {
                            Circle()
                                .fill(keyboardManager.isConnected ? Color.green : Color.red)
                                .frame(width: 7, height: 7)
                            Image(systemName: keyboardManager.connectionType.icon)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text(keyboardManager.connectionType.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))

                        // Döner Tekerlek (Knob) Modu Rozeti
                        HStack(spacing: 5) {
                            Image(systemName: keyboardManager.wheelMode == .volume ? "speaker.wave.2.fill" : "sun.max.fill")
                                .font(.system(size: 11))
                                .foregroundColor(keyboardManager.wheelMode == .volume ? .blue : .yellow)
                            Text(keyboardManager.wheelMode.badgeTitle(loc: loc))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                }

                Spacer()
            }
            .padding(20)
        }
        .frame(height: 155)
        .onAppear {
            breathingPhase = true
        }
    }

    // MARK: - Seçilen Efekte Göre Dinamik Uyum Sağlayan Görsel Özellikler
    private var ambientGlowColor: Color {
        guard let effect = selectedEffect else { return currentColor }
        switch effect {
        case .rainbow, .rainbowWheel, .waterfall:
            return Color.purple
        case .neonStream:
            return Color.cyan
        case .off:
            return Color.gray
        default:
            return currentColor
        }
    }

    private var ambientBackgroundGradient: LinearGradient {
        guard let effect = selectedEffect else {
            return LinearGradient(
                colors: [currentColor.opacity(0.45), Color(nsColor: .windowBackgroundColor).opacity(0.85), Color.black.opacity(0.6)],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }

        switch effect {
        case .rainbow, .rainbowWheel, .waterfall:
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.4),
                    Color.purple.opacity(0.35),
                    Color.blue.opacity(0.3),
                    Color(nsColor: .windowBackgroundColor).opacity(0.85)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        case .neonStream:
            return LinearGradient(
                colors: [
                    Color.cyan.opacity(0.45),
                    Color.green.opacity(0.3),
                    Color(nsColor: .windowBackgroundColor).opacity(0.85)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        case .reactive, .waveRipple:
            return LinearGradient(
                colors: [
                    currentColor.opacity(0.5),
                    currentColor.opacity(0.2),
                    Color(nsColor: .windowBackgroundColor).opacity(0.88)
                ],
                startPoint: .center,
                endPoint: .bottomLeading
            )
        case .off:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.04),
                    Color(nsColor: .windowBackgroundColor).opacity(0.92),
                    Color.black.opacity(0.7)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        default:
            return LinearGradient(
                colors: [
                    currentColor.opacity(0.45),
                    Color(nsColor: .windowBackgroundColor).opacity(0.85),
                    Color.black.opacity(0.6)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }

    private var ambientBorderGradient: LinearGradient {
        guard let effect = selectedEffect else {
            return LinearGradient(colors: [currentColor.opacity(0.6), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        switch effect {
        case .rainbow, .rainbowWheel, .waterfall:
            return LinearGradient(
                colors: [Color.pink.opacity(0.7), Color.purple.opacity(0.6), Color.cyan.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .neonStream:
            return LinearGradient(
                colors: [Color.cyan.opacity(0.8), Color.mint.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .off:
            return LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [currentColor.opacity(0.6), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var breathingOpacity: Double {
        if selectedEffect == .breathing {
            return breathingPhase ? 0.95 : 0.45
        }
        return 1.0
    }

    private var effectIcon: String {
        return selectedEffect?.icon ?? "keyboard.fill"
    }

    private var iconGradientColors: [Color] {
        guard let effect = selectedEffect else { return [.white, currentColor] }
        switch effect {
        case .rainbow, .rainbowWheel, .waterfall:
            return [.white, .cyan, .purple]
        case .neonStream:
            return [.white, .cyan]
        case .off:
            return [.gray, .secondary]
        default:
            return [.white, currentColor]
        }
    }

    private var batteryIconName: String {
        let level = keyboardManager.batteryLevel
        if keyboardManager.isCharging {
            if level >= 100 { return "battery.100.bolt" }
            if level > 75 { return "battery.100.bolt" }
            if level > 50 { return "battery.75.bolt" }
            if level > 25 { return "battery.50.bolt" }
            return "battery.25.bolt"
        }
        if level <= 20 { return "battery.0" }
        if level > 75 { return "battery.100" }
        if level > 50 { return "battery.75" }
        if level > 25 { return "battery.50" }
        return "battery.25"
    }

    private var batteryColor: Color {
        let level = keyboardManager.batteryLevel
        if keyboardManager.isCharging { return .green }
        if level <= 20 { return .red }
        if level <= 50 { return .orange }
        return .green
    }
}
