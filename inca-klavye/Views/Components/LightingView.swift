import SwiftUI

struct LightingView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    
    @State private var keyboardColor: Color = .blue
    @State private var brightness: Double = 80.0
    @State private var selectedEffect: LightingEffect = .breathing

    enum LightingEffect: UInt8, CaseIterable, Identifiable {
        case solid = 0x01
        case breathing = 0x02
        case wave = 0x03
        case reactive = 0x04
        
        var id: UInt8 { self.rawValue }
        var name: String {
            switch self {
            case .solid: return "Sabit"
            case .breathing: return "Nefes Alma"
            case .wave: return "Dalga"
            case .reactive: return "Reaktif"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("RGB Aydınlatma")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Efekt Seçimi
                Picker("Işık Efekti", selection: $selectedEffect) {
                    ForEach(LightingEffect.allCases) { effect in
                        Text(effect.name).tag(effect)
                    }
                }
                .pickerStyle(.segmented)
                
                Divider()
                
                // Renk Seçici
                ColorPicker("LED Rengi", selection: $keyboardColor)
                
                // Parlaklık Slider'ı
                VStack(alignment: .leading) {
                    Text("Parlaklık: \(Int(brightness))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: "sun.min")
                        Slider(value: $brightness, in: 0...100)
                        Image(systemName: "sun.max.fill")
                    }
                }
                
                // Uygula Butonu (Ghidra protokolüne göre paket üretip gönderir)
                Button(action: {
                    // 1. NSColor'a çevirip sRGB uzayına zorluyoruz (Katalog renk hatasını engeller)
                    let nsColor = NSColor(keyboardColor)
                    guard let convertedColor = nsColor.usingColorSpace(.sRGB) else {
                        print("Renk renk uzayına dönüştürülemedi!")
                        return
                    }
                    
                    // 2. Artık güvenle sRGB bileşenlerini alabiliriz
                    let red = UInt8(convertedColor.redComponent * 255)
                    let green = UInt8(convertedColor.greenComponent * 255)
                    let blue = UInt8(convertedColor.blueComponent * 255)
                    
                    // Modüler modelimizden paketi oluşturuyoruz
                    let packet = KeyboardCommand.createLightingPacket(
                        effect: selectedEffect.rawValue,
                        red: red,
                        green: green,
                        blue: blue,
                        brightness: UInt8(brightness)
                    )
                    
                    // Donanıma fırlatıyoruz
                    keyboardManager.sendFeatureReport(reportID: 0x01, data: packet)
                }) {
                    Text("Ayarları Klavyeye Uygula")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 10)
            }
        }
    }
}
