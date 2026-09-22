import SwiftUI

struct ContentView: View {
    @StateObject private var keyboardManager = KeyboardManager()
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var selectedTab: SettingsTab = .lighting
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isShowingSplashScreen: Bool = true

    enum SettingsTab: String, CaseIterable, Identifiable {
        case lighting = "tc_kb1"
        case keybinds = "tc_msg18"
        case tftScreen = "tc_screen11"
        case macro = "tc_mac_def"
        case music = "tc_music1"
        case cloud = "tc_yun1"
        case settings = "tc_config"
        case manual = "tc_manual"
        case about = "tc_about"
        
        var id: String { self.rawValue }

        static var sidebarTabs: [SettingsTab] {
            [.lighting, .keybinds, .macro, .music, .cloud, .settings]
        }
        
        func title(loc: LocalizationManager) -> String {
            switch self {
            case .lighting: return loc.tr("tc_kb1", default: "Aydınlatma")
            case .keybinds: return loc.tr("tc_msg18", default: "Tuş Atamaları")
            case .tftScreen: return loc.tr("tc_screen11", default: "TFT Ekran & GIF")
            case .macro: return loc.tr("tc_mac_def", default: "Makro Stüdyosu")
            case .music: return loc.tr("tc_music1", default: "Müzik & Ses")
            case .cloud: return loc.tr("tc_yun1", default: "Paylaşım Merkezi")
            case .settings: return loc.tr("tc_config", default: "Cihaz & Ayarlar")
            case .manual: return loc.tr("tc_manual", default: "Kullanma Kılavuzu")
            case .about: return loc.tr("tc_about", default: "Hakkında")
            }
        }

        var icon: String {
            switch self {
            case .lighting: return "sparkles"
            case .keybinds: return "keyboard.fill"
            case .tftScreen: return "tv.fill"
            case .macro: return "bolt.square.fill"
            case .music: return "waveform.path.ecg"
            case .cloud: return "icloud.fill"
            case .settings: return "gearshape.2.fill"
            case .manual: return "book.closed.fill"
            case .about: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sol Yan Menü (Apple Music Sidebar)
            VStack(alignment: .leading, spacing: 0) {
                // Aygıt Başlığı & Hızlı Durum
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: keyboardManager.isConnected 
                                            ? [Color(red: 0.98, green: 0.18, blue: 0.38), Color.purple]
                                            : [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "keyboard.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 6) {
                                Text("Empousa IKG-455")
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                
                                Circle()
                                    .fill(keyboardManager.isConnected ? Color.green : Color.orange)
                                    .frame(width: 6, height: 6)
                            }

                            Text("Magnetic Gaming\nKeyboard")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        // Hızlı Dil Değiştirici Menüsü (Minimalist Apple Tarzı)
                        Menu {
                            ForEach(AppLanguage.allCases) { lang in
                                Button(action: {
                                    loc.setLanguage(lang)
                                }) {
                                    HStack {
                                        Text(lang.displayName)
                                        if loc.currentLanguage == lang {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.system(size: 10))
                                Text(loc.currentLanguage.code)
                                    .font(.system(size: 11, weight: .bold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 7))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                        }
                        .menuStyle(.borderlessButton)
                    }

                    // Yalnızca Cihaz Bağlıyken Gösterilen Rozetler
                    if keyboardManager.isConnected {
                        VStack(alignment: .leading, spacing: 5) {
                            // Satır 1: Pil + Bağlantı (sabit üstte kalır)
                            HStack(spacing: 6) {
                                // Pil
                                if keyboardManager.batteryLevel >= 100 && keyboardManager.isCharging {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 10))
                                        Text("%100")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.15))
                                    .cornerRadius(6)
                                    .help(loc.tr("tc_fully_charged", default: "Tamamen Şarj Oldu"))
                                } else if keyboardManager.batteryLevel <= 20 && !keyboardManager.isCharging {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 10))
                                        Text("%\(keyboardManager.batteryLevel)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.red)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.18))
                                    .cornerRadius(6)
                                    .help(loc.tr("tc_low_battery", default: "Batarya Zayıf"))
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: batteryIcon)
                                            .foregroundColor(batteryColor)
                                            .font(.system(size: 10))
                                        Text("%\(keyboardManager.batteryLevel)")
                                            .font(.system(size: 10, weight: .semibold))
                                        if keyboardManager.isCharging {
                                            Image(systemName: "bolt.fill")
                                                .font(.system(size: 8))
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(6)
                                }

                                // Bağlantı Modu (USB / 2.4G / BT)
                                HStack(spacing: 4) {
                                    Image(systemName: keyboardManager.connectionType.icon)
                                        .font(.system(size: 10))
                                        .foregroundColor(.cyan)
                                    Text(connectionShortLabel)
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(6)

                                Spacer()
                            }

                            // Satır 2: Mac Modu + Tekerlek Modu (aşağı inebilir)
                            HStack(spacing: 6) {
                                // İşletim Sistemi Modu (Mac / Win)
                                HStack(spacing: 4) {
                                    Image(systemName: keyboardManager.isMacMode ? "apple.logo" : "window.vertical.closed")
                                        .font(.system(size: 10))
                                    Text(keyboardManager.isMacMode ? "Mac" : "Win")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(6)

                                // Döner Tekerlek (Knob) Modu Rozeti
                                HStack(spacing: 4) {
                                    Image(systemName: keyboardManager.wheelMode == .volume ? "speaker.wave.2.fill" : "sun.max.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(keyboardManager.wheelMode == .volume ? .blue : .yellow)
                                    Text(keyboardManager.wheelMode == .volume ? "Ses" : "Işık")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(6)
                                .help("Tekerlek Modu: \(keyboardManager.wheelMode.name)")

                                Spacer()
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        // Bağlantı Bekleniyor Durum Rozeti
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                            Text("Bağlantı Bekleniyor")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
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
                    .disabled(!keyboardManager.isConnected && tab != .settings)
                    .opacity(!keyboardManager.isConnected && tab != .settings ? 0.4 : 1.0)
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
                    case .keybinds:
                        KeybindsView(keyboardManager: keyboardManager)
                    case .tftScreen:
                        TftScreenView(keyboardManager: keyboardManager)
                    case .macro:
                        MacroStudioView(keyboardManager: keyboardManager)
                    case .music:
                        MusicVisualizerView(keyboardManager: keyboardManager)
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
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    withAnimation { selectedTab = .manual }
                }) {
                    Image(systemName: "questionmark.circle")
                }
                .help(loc.tr("tc_manual", default: "Kullanma Kılavuzu & Donanım Kısayolları"))

                Button(action: {
                    withAnimation { selectedTab = .about }
                }) {
                    Image(systemName: "info.circle")
                }
                .help(loc.tr("tc_about", default: "Hakkında"))

                // Döner Tekerlek (Knob) Modu Rozeti (Info butonunun hemen sağında)
                if keyboardManager.isConnected {
                    HStack(spacing: 5) {
                        Image(systemName: keyboardManager.wheelMode == .volume ? "speaker.wave.2.fill" : "sun.max.fill")
                            .font(.system(size: 11))
                            .foregroundColor(keyboardManager.wheelMode == .volume ? .blue : .yellow)
                        Text(keyboardManager.wheelMode == .volume ? "Tekerlek: Ses" : "Tekerlek: Işık")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(7)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .help("Tekerlek Modu: \(keyboardManager.wheelMode.name)")
                }
            }

            ToolbarItem(placement: .principal) {
                dynamicIslandPrincipalBar
                    .animation(.spring(response: 0.42, dampingFraction: 0.68, blendDuration: 0.2), value: keyboardManager.islandStatus)
            }

            ToolbarItemGroup(placement: .automatic) {
                // Hızlı Dil Değiştirici
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

                // Canlı Batarya Durumu Rozeti
                if keyboardManager.isConnected {
                    if keyboardManager.batteryLevel >= 100 && keyboardManager.isCharging {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                            Text("%100 • \(loc.tr("tc_fully_charged", default: "Tamamen Şarj Oldu"))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.3), lineWidth: 1))
                        .cornerRadius(8)
                    } else if keyboardManager.batteryLevel <= 20 && !keyboardManager.isCharging {
                        HStack(spacing: 5) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                            Text("%\(keyboardManager.batteryLevel) • \(loc.tr("tc_low_battery", default: "Batarya Zayıf"))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.14))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.35), lineWidth: 1))
                        .cornerRadius(8)
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: batteryIcon)
                                .foregroundColor(batteryColor)
                            Text("%\(keyboardManager.batteryLevel)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            if keyboardManager.isCharging {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(8)
                    }

                    // Canlı Tekerlek Modu Rozeti (Knob Mode: Ses / Aydınlatma)
                    HStack(spacing: 5) {
                        Image(systemName: keyboardManager.wheelMode == .volume ? "speaker.wave.2.fill" : "sun.max.fill")
                            .foregroundColor(keyboardManager.wheelMode == .volume ? .blue : .yellow)
                            .font(.system(size: 11))
                        Text(keyboardManager.wheelMode == .volume ? "Tekerlek: Ses Kontrolü" : "Tekerlek: Aydınlatma Kontrolü")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(keyboardManager.wheelMode == .volume ? Color.blue.opacity(0.12) : Color.yellow.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(keyboardManager.wheelMode == .volume ? Color.blue.opacity(0.3) : Color.yellow.opacity(0.35), lineWidth: 1)
                    )
                    .cornerRadius(8)
                    .help("Döner Tekerlek Modu: Klavyedeki döner tekerleğe basarak Ses veya Aydınlatma modu arasında geçiş yapabilirsiniz")
                }
            }
        }
        .tint(Color(red: 0.98, green: 0.18, blue: 0.38)) // Apple Music Pink
        .animation(.easeInOut(duration: 0.25), value: keyboardManager.isConnected)

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

    // MARK: - Dinamik Ada Üst Bar (Toolbar Principal Dynamic Island)
    @ViewBuilder
    private var dynamicIslandPrincipalBar: some View {
        switch keyboardManager.islandStatus {
        case .idle:
            HStack(spacing: 8) {
                Circle()
                    .fill(keyboardManager.isConnected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)

                Text(keyboardManager.isConnected ? "Inca Empousa" : loc.tr("tc_searching_connection", default: "Bağlantı Aranıyor..."))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .layoutPriority(1)

                if keyboardManager.isConnected {
                    HStack(spacing: 4) {
                        Image(systemName: keyboardManager.connectionType.icon)
                            .font(.system(size: 10, weight: .medium))
                        Text(connectionShortLabel)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 5)
            .frame(height: 30)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .transition(.scale(scale: 0.9).combined(with: .opacity))

        case .unsavedChanges(let description):
            VStack(spacing: 6) {
                // Üst Satır: Durum & Bilgi
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.25))
                            .frame(width: 18, height: 18)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 10, weight: .bold))
                    }

                    Text("KAYDEDİLMEMİŞ DEĞİŞİKLİKLER")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.primary)
                        .tracking(0.5)

                    if !description.isEmpty {
                        Text(description)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(5)
                    }

                    Spacer()
                }

                // Alt Satır: Alt Bilgi & Aksiyon Butonları
                HStack(spacing: 12) {
                    Text("Klavyeye aktarılmayı bekliyor")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    // Vazgeç Butonu
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            keyboardManager.onDiscardChangesRequested?()
                            keyboardManager.triggerIdleStatus()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                            Text("Vazgeç")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .help("Değişiklikleri iptal et ve önceki ayarlara dön")

                    // Klavyeye Kaydet Butonu
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            keyboardManager.onCommitChangesRequested?()
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Klavyeye Kaydet")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.98, green: 0.18, blue: 0.38), Color(red: 0.85, green: 0.1, blue: 0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(color: Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.5), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .help("Değişiklikleri klavye donanım belleğine yaz")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minWidth: 440)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.orange.opacity(0.1))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.9), Color.orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.orange.opacity(0.35), radius: 14, y: 6)
            .transition(.scale(scale: 0.9).combined(with: .opacity))

        case .saving(let message):
            HStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text(message.isEmpty ? "Klavyeye Yazılıyor..." : message)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("Donanım EEPROM belleği güncelleniyor...")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .frame(minWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.cyan.opacity(0.1))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.cyan.opacity(0.7), lineWidth: 1.5)
            )
            .shadow(color: Color.cyan.opacity(0.3), radius: 10, y: 4)
            .transition(.scale(scale: 0.9).combined(with: .opacity))

        case .saved(let message):
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .bold))

                VStack(alignment: .leading, spacing: 1) {
                    Text(message.isEmpty ? "Ayarlar Kaydedildi!" : message)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                    Text("Değişiklikler klavye donanımına başarıyla yazıldı ✓")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .frame(minWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.green.opacity(0.1))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.green.opacity(0.7), lineWidth: 1.5)
            )
            .shadow(color: Color.green.opacity(0.3), radius: 10, y: 4)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
}


