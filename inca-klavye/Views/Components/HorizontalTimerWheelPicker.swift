import SwiftUI
import AppKit
import AudioToolbox

/// iPhone sayaç çarkı tarzında, soldan sağa kaydırılabilen ve her adımda mekanik "tırrr tırrr" ses/haptik geri bildirimi veren yatay uyku süresi seçicisi.
struct HorizontalTimerWheelPicker: View {
    @Binding var selectedSeconds: Int
    var onSave: (Int) -> Void
    var onCancel: () -> Void
    
    @ObservedObject var loc = LocalizationManager.shared
    
    // Geçici düzenleme değeri (Kaydet'e basılana kadar asıl değeri korur)
    @State private var tempSeconds: Int
    @State private var dragOffset: CGFloat = 0
    @State private var lastPlayedStep: Int = -1
    @State private var isNeverSleep: Bool = false
    
    // Ayarlar: 20 saniye - 1200 saniye (20 dakika)
    private let minSeconds: Int = 20
    private let maxSeconds: Int = 1200
    private let stepSeconds: Int = 5 // Her 5 saniyede 1 çentik
    private let tickSpacing: CGFloat = 8 // Her çentik arası piksel mesafesi
    
    init(selectedSeconds: Binding<Int>, onSave: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self._selectedSeconds = selectedSeconds
        self.onSave = onSave
        self.onCancel = onCancel
        let initialVal = selectedSeconds.wrappedValue
        self._tempSeconds = State(initialValue: initialVal == 0 ? 180 : max(20, min(1200, initialVal)))
        self._isNeverSleep = State(initialValue: initialVal == 0)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Başlık & Büyük Dijital Sayaç
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                        Text(loc.tr("settings_sleep_title", default: "Otomatik Uyku Sayacı").uppercased())
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                    }
                    
                    if isNeverSleep {
                        Text(loc.tr("settings_sleep_never", default: "Asla (Sürekli Açık)"))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(formattedDigitalTime(tempSeconds))
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                            
                            Text(humanReadableDescription(tempSeconds))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                        }
                    }
                }
                
                Spacer()
                
                // "Asla / Sürekli Açık" Geçiş Butonu
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isNeverSleep.toggle()
                        triggerTickSound()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isNeverSleep ? "moon.stars.fill" : "moon.fill")
                        Text(isNeverSleep ? "Sayaç Moduna Geç" : "Asla Uyuma (Sürekli Açık)")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isNeverSleep ? Color.orange.opacity(0.18) : Color.white.opacity(0.08))
                    .foregroundColor(isNeverSleep ? .orange : .secondary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isNeverSleep ? Color.orange.opacity(0.4) : Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Eğer "Asla" seçili değilse yatay cetvel çarkını göster
            if !isNeverSleep {
                VStack(spacing: 8) {
                    // Yatay Çark Alanı (Soldan Sağa Kaydırmalı Tırrr Tırrr Cetveli)
                    GeometryReader { geo in
                        let centerWidth = geo.size.width / 2
                        let currentOffset = -CGFloat((tempSeconds - minSeconds) / stepSeconds) * tickSpacing + dragOffset
                        
                        ZStack(alignment: .center) {
                            // Cetvel Çizgileri ve Metinleri
                            Canvas { context, size in
                                let totalSteps = (maxSeconds - minSeconds) / stepSeconds
                                for step in 0...totalSteps {
                                    let stepSec = minSeconds + step * stepSeconds
                                    let xPos = centerWidth + currentOffset + CGFloat(step) * tickSpacing
                                    
                                    // Yalnızca ekranda görünen çentikleri çiz (Performans optimizasyonu)
                                    guard xPos >= -20 && xPos <= size.width + 20 else { continue }
                                    
                                    let isMinute = stepSec % 60 == 0
                                    let isHalfMinute = stepSec % 30 == 0
                                    let isMajor = isMinute || stepSec == 20 || isHalfMinute
                                    
                                    let tickHeight: CGFloat = isMinute ? 28 : (isHalfMinute ? 18 : 10)
                                    let tickWidth: CGFloat = isMinute ? 2.0 : 1.0
                                    let tickOpacity: Double = isMinute ? 0.9 : (isHalfMinute ? 0.6 : 0.25)
                                    
                                    let rect = CGRect(
                                        x: xPos - tickWidth / 2,
                                        y: (size.height - tickHeight) / 2,
                                        width: tickWidth,
                                        height: tickHeight
                                    )
                                    context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(Color.primary.opacity(tickOpacity)))
                                }
                            }
                            
                            // Merkez Göstergesi (Kırmızı/Pembe Neon İbre)
                            ZStack {
                                // Hafif Parıltı
                                Rectangle()
                                    .fill(Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.25))
                                    .frame(width: 8, height: 46)
                                    .blur(radius: 4)
                                
                                // Ana Çizgi
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 3, height: 44)
                                    .shadow(color: Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.6), radius: 3)
                                
                                // Üst ve Alt Küçük Okçuluklar
                                VStack {
                                    Image(systemName: "arrowtriangle.down.fill")
                                        .font(.system(size: 7))
                                        .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                                    Spacer()
                                    Image(systemName: "arrowtriangle.up.fill")
                                        .font(.system(size: 7))
                                        .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                                }
                                .frame(height: 54)
                            }
                        }
                        // Kenarlarda yumuşak karartma / drum efekti maskesi
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .black, location: 0.15),
                                    .init(color: .black, location: 0.85),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentShape(Rectangle())
                        // Soldan sağa kaydırma hareketi (Drag Gesture)
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { val in
                                    dragOffset = val.translation.width
                                    let deltaSteps = Int(round(-dragOffset / tickSpacing))
                                    let baseStep = (tempSeconds - minSeconds) / stepSeconds
                                    let targetStep = max(0, min((maxSeconds - minSeconds) / stepSeconds, baseStep + deltaSteps))
                                    let computedSec = minSeconds + targetStep * stepSeconds
                                    
                                    if computedSec != tempSeconds {
                                        tempSeconds = computedSec
                                        dragOffset = 0
                                        triggerTickSound()
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                        )
                    }
                    .frame(height: 60)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    
                    // Alt Cetvel Etiketleri (Hızlı Gösterim)
                    HStack {
                        Text("20 sn")
                        Spacer()
                        Text("1 dk")
                        Spacer()
                        Text("3 dk (Önerilen)")
                            .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                            .fontWeight(.bold)
                        Spacer()
                        Text("10 dk")
                        Spacer()
                        Text("20 dk")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                }
            }
            
            // Hızlı Seçim Rozetleri (Presets)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    presetButton(title: "20 sn", seconds: 20)
                    presetButton(title: "30 sn", seconds: 30)
                    presetButton(title: "1 dk", seconds: 60)
                    presetButton(title: "3 dk ★", seconds: 180, isRecommended: true)
                    presetButton(title: "5 dk", seconds: 300)
                    presetButton(title: "10 dk", seconds: 600)
                    presetButton(title: "20 dk", seconds: 1200)
                }
                .padding(.horizontal, 2)
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            // Aksiyon Butonları (Vazgeç & Kaydet)
            HStack(spacing: 12) {
                Text(isNeverSleep 
                     ? "Klavye uyku moduna hiç geçmeyecek, sürekli aktif kalacaktır."
                     : "\(formattedDigitalTime(tempSeconds)) boyunca tuşa basılmazsa LED'ler söner ve uykuya geçer."
                )
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                
                Spacer()
                
                // Vazgeç Butonu
                Button(action: {
                    onCancel()
                }) {
                    Text(loc.tr("tc_cancel", default: "Vazgeç"))
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                
                // Kaydet Butonu
                Button(action: {
                    let finalVal = isNeverSleep ? 0 : tempSeconds
                    selectedSeconds = finalVal
                    onSave(finalVal)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(loc.tr("tc_apply", default: "Kaydet"))
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Color(red: 0.98, green: 0.18, blue: 0.38))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.4), lineWidth: 1.5)
        )
    }
    
    // MARK: - Hızlı Önayar Butonu
    private func presetButton(title: String, seconds: Int, isRecommended: Bool = false) -> some View {
        let isSelected = !isNeverSleep && tempSeconds == seconds
        return Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isNeverSleep = false
                tempSeconds = seconds
                triggerTickSound()
            }
        }) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    isSelected
                        ? Color(red: 0.98, green: 0.18, blue: 0.38)
                        : (isRecommended ? Color.purple.opacity(0.2) : Color.white.opacity(0.06))
                )
                .foregroundColor(isSelected ? .white : (isRecommended ? .pink : .primary))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.clear : (isRecommended ? Color.purple.opacity(0.4) : Color.white.opacity(0.1)), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - iPhone Mekanik "Tırrr Tırrr" Ses & Haptik Tetikleyicisi
    private func triggerTickSound() {
        // macOS sistem çark / tuş sesi (1104 = iOS & macOS çark/klavye tık sesi)
        AudioServicesPlaySystemSound(1104)
        // Force Touch Trackpad haptik geri bildirimi
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
    
    // MARK: - Zaman Formatlayıcıları
    private func formattedDigitalTime(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func humanReadableDescription(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        if m == 0 {
            return "\(s) Saniye"
        } else if s == 0 {
            return "\(m) Dakika"
        } else {
            return "\(m) dk \(s) sn"
        }
    }
}
