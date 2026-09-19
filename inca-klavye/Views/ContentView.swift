import SwiftUI

struct ContentView: View {
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var selectedTab: SettingsTab = .lighting

    enum SettingsTab: String, CaseIterable, Identifiable {
        case lighting = "Aydınlatma"
        case keybinds = "Tuş Atamaları"
        case macros = "Makrolar"
        case profiles = "Profiller"
        
        var id: String { self.rawValue }
        var icon: String {
            switch self {
            case .lighting: return "lightbulb.max"
            case .keybinds: return "keyboard"
            case .macros: return "command"
            case .profiles: return "person.crop.square"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sol Yan Menü (Sidebar)
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationTitle("Klavye Kontrol")
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(keyboardManager.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(keyboardManager.isConnected ? "Klavye Bağlı" : "Klavye Aranıyor...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        } detail: {
            // Sağ İçerik Alanı
            VStack(alignment: .leading, spacing: 20) {
                switch selectedTab {
                case .lighting:
                    LightingView(keyboardManager: keyboardManager)
                case .keybinds:
                    Text("Tuş Atamaları Yapılandırması")
                        .font(.title2)
                        .foregroundColor(.secondary)
                case .macros:
                    Text("Makro Yönetim Paneli")
                        .font(.title2)
                        .foregroundColor(.secondary)
                case .profiles:
                    Text("Profil Yönetimi")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
