import SwiftUI

struct ContentView: View {
    @StateObject private var keyboardManager = KeyboardManager()
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var selectedTab: SettingsTab = .lighting
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isShowingSplashScreen: Bool = true

    enum SettingsTab: String, CaseIterable, Identifiable {
        case lighting = "tc_kb1"
        case customLighting = "tab_custom_lighting"
        case music = "tc_music1"
        case keybinds = "tc_msg18"
        case tftScreen = "tc_screen11"
        case macro = "tc_mac_def"
        case cloud = "tc_yun1"
        case settings = "tc_config"
        case manual = "tc_manual"
        case about = "tc_about"
        
        var id: String { self.rawValue }

        static var sidebarTabs: [SettingsTab] {
            [.lighting, .customLighting, .music, .keybinds, .macro, .cloud, .settings, .manual]
        }
        
        func title(loc: LocalizationManager) -> String {
            switch self {
            case .lighting: return loc.tr("tab_lighting", default: "Aydınlatma")
            case .customLighting: return loc.tr("tab_custom_lighting", default: "Özelleştirilmiş Aydınlatma")
            case .music: return loc.tr("tab_music_lighting", default: "Müzik Aydınlatması")
            case .keybinds: return loc.tr("tc_msg18", default: "Tuş Atamaları")
            case .tftScreen: return loc.tr("tc_screen11", default: "TFT Ekran & GIF")
            case .macro: return loc.tr("tc_mac_def", default: "Makro Stüdyosu")
            case .cloud: return loc.tr("tc_yun1", default: "Paylaşım Merkezi")
            case .settings: return loc.tr("tc_config", default: "Cihaz & Ayarlar")
            case .manual: return loc.tr("tc_manual", default: "Kullanma Kılavuzu")
            case .about: return loc.tr("tc_about", default: "Hakkında")
            }
        }

        var icon: String {
            switch self {
            case .lighting: return "sparkles"
            case .customLighting: return "paintpalette.fill"
            case .music: return "waveform.path.ecg"
            case .keybinds: return "keyboard.fill"
            case .tftScreen: return "tv.fill"
            case .macro: return "bolt.square.fill"
            case .cloud: return "icloud.fill"
            case .settings: return "gearshape.2.fill"
            case .manual: return "book.closed.fill"
            case .about: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sol Yan Menü (Apple Music Sidebar)
            VStack(alignment: .leading, spacing: 0) {
                // Aygıt Başlığı (Yalnızca Klavye Marka & Model Bilgisi)
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: keyboardManager.isConnected 
                                        ? [Color(red: 0.98, green: 0.18, blue: 0.38), Color(red: 0.85, green: 0.1, blue: 0.28)] 
                                        : [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Empousa IKG-455")
                                .font(.system(size: 13.5, weight: .bold))
                                .lineLimit(1)
                            
                            Circle()
                                .fill(keyboardManager.isConnected ? Color.green : Color.orange)
                                .frame(width: 6, height: 6)
                        }

                        Text("Magnetic Gaming Keyboard")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider()
                    .padding(.horizontal, 12)

                // Apple Music / macOS Sidebar Navigasyon Listesi
                List(SettingsTab.sidebarTabs, selection: $selectedTab) { tab in
                    NavigationLink(value: tab) {
                        Label {
                            Text(tab.title(loc: loc))
                                .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                        } icon: {
                            Image(systemName: tab.icon)
                                .foregroundColor(selectedTab == tab ? Color(red: 0.98, green: 0.18, blue: 0.38) : .secondary)
                        }
                    }
                    .tag(tab)
                    .disabled(!keyboardManager.isConnected && tab != .settings && tab != .manual)
                    .opacity(!keyboardManager.isConnected && tab != .settings && tab != .manual ? 0.4 : 1.0)
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)

                // Alt Bağlantı Rozeti (Sol bar esneyince tam genişler)
                HStack(spacing: 8) {
                    Circle()
                        .fill(keyboardManager.isConnected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(keyboardManager.statusMessage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
            }
            .frame(minWidth: 260)
            .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 360)
        } detail: {
            // Sağ İçerik Alanı
            VStack(spacing: 0) {
                // macOS Giriş İzleme (Input Monitoring) İzin Uyarısı
                if !keyboardManager.hasInputMonitoringPermission {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("macOS Güvenlik İzni Gerekli (Giriş İzleme)")
                                .font(.system(size: 12, weight: .bold))
                            Text("Klavyeye aydınlatma ve ayar komutları gönderebilmek için Sistem Ayarları'ndan 'Giriş İzleme' iznini açın. Listede çıkmıyorsa '+' ile ekleyin.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            keyboardManager.revealAppInFinder()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.fill")
                                Text("Finder'da Göster (+ Ekle)")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .help("Uygulama paketini Finder'da açar; Sistem Ayarları'ndaki '+' butonuna tıklayıp buradaki uygulamayı seçebilirsiniz.")

                        Button(action: {
                            keyboardManager.requestInputMonitoringPermission()
                        }) {
                            Text("Sistem Ayarlarını Aç")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.12))
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.orange.opacity(0.3)), alignment: .bottom)
                }

                Group {
                    if !keyboardManager.isConnected && selectedTab != .about && selectedTab != .settings && selectedTab != .manual {
                        NoDeviceConnectedView(keyboardManager: keyboardManager, loc: loc)
                    } else {
                        switch selectedTab {
                    case .lighting:
                        LightingView(keyboardManager: keyboardManager)
                    case .customLighting:
                        CustomLightingView(keyboardManager: keyboardManager)
                    case .music:
                        MusicVisualizerView(keyboardManager: keyboardManager)
                    case .keybinds:
                        KeybindsView(keyboardManager: keyboardManager)
                    case .tftScreen:
                        TftScreenView(keyboardManager: keyboardManager)
                    case .macro:
                        MacroStudioView(keyboardManager: keyboardManager)
                    case .cloud:
                        CloudSharingView(keyboardManager: keyboardManager)
                    case .settings:
                        DeviceSettingsView(keyboardManager: keyboardManager)
                    case .manual:
                        UserManualView(keyboardManager: keyboardManager, loc: loc)
                    case .about:
                        AboutView(keyboardManager: keyboardManager, loc: loc)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
    .toolbar {
        // Sol Taraf: Info Butonu ve hemen sağında boşluklu Döner Tekerlek (Knob) Butonu
        ToolbarItem(placement: .navigation) {
            HStack(spacing: 12) {
                // Info (Bilgi / Hakkında) Butonu
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = .about
                    }
                }) {
                    Image(systemName: selectedTab == .about ? "info.circle.fill" : "info.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedTab == .about ? Color(red: 0.98, green: 0.18, blue: 0.38) : .secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedTab == .about ? Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.12) : Color.white.opacity(0.06))
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(loc.tr("tc_about", default: "Hakkında"))

                // Döner Tekerlek (Knob) Modu Rozet Butonu (Ayrı bağımsız buton, arada net boşluk)
                if keyboardManager.isConnected {
                    Button(action: {
                        // Tekerlek modu göstergesi
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: keyboardManager.wheelMode == .volume ? "speaker.wave.2.fill" : "sun.max.fill")
                                .font(.system(size: 11))
                                .foregroundColor(keyboardManager.wheelMode == .volume ? .blue : .yellow)
                            Text(keyboardManager.wheelMode.badgeTitle(loc: loc))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(7)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .help(keyboardManager.wheelMode == .volume 
                        ? "Döner Tekerlek: Ses Kontrolü (Fn+Tekerlek ile Aydınlatma moduna geçer)"
                        : "Döner Tekerlek: Aydınlatma Kontrolü (Fn+Tekerlek ile Ses moduna geçer)")
                }
            }
        }

        // Sağ Taraf: En sağda Yardım Butonu, hemen solunda Dil Seçici
        ToolbarItemGroup(placement: .primaryAction) {
            // Dil Seçici (Yardım butonunun hemen solunda)
            Menu {
                ForEach(AppLanguage.allCases) { lang in
                    Button(action: { loc.setLanguage(lang) }) {
                        HStack {
                            Text(lang.displayName)
                            if loc.currentLanguage == lang { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                    Text(loc.currentLanguage.code)
                        .font(.system(size: 11, weight: .bold))
                }
            }

            // Yardım (Kullanma Kılavuzu & Donanım Kısayolları) Butonu (En Sağda)
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedTab = .manual
                }
            }) {
                Image(systemName: selectedTab == .manual ? "questionmark.circle.fill" : "questionmark.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selectedTab == .manual ? Color(red: 0.98, green: 0.18, blue: 0.38) : .secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedTab == .manual ? Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.12) : Color.white.opacity(0.06))
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(loc.tr("tc_manual", default: "Kullanma Kılavuzu & Donanım Kısayolları"))
        }
    }
        .tint(Color(red: 0.98, green: 0.18, blue: 0.38)) // Apple Music Pink
        .animation(.easeInOut(duration: 0.25), value: keyboardManager.isConnected)

        // Yüzen Dinamik Ada (iPhone tarzı barın sınırlarından bağımsız, aşağıya doğru esneyen tasarım)
        DynamicIslandFloatingView(keyboardManager: keyboardManager, loc: loc)
            .padding(.top, 6)
            .ignoresSafeArea(.all, edges: .top)
            .zIndex(500)

        // Xcode Tarzı Başlangıç Açılış Ekranı (Splash Screen)
        if isShowingSplashScreen {
            XcodeSplashScreenView(
                keyboardManager: keyboardManager,
                isPresented: $isShowingSplashScreen
            )
            .transition(.asymmetric(
                insertion: .opacity,
                removal: .opacity.combined(with: .scale(scale: 1.04))
            ))
            .zIndex(999)
        }
    }
}

    private var connectionShortLabel: String {
        switch keyboardManager.connectionType {
        case .disconnected: return "Yok"
        case .wireless24G: return "2.4G"
        case .wiredUSB: return "USB-C"
        case .bluetooth: return "BT"
        }
    }

    private var batteryIcon: String {
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


