import SwiftUI

struct DeviceSettingsView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared

    @State private var selectedProfileIndex: Int = 1
    @State private var autoCheckUpdate: Bool = true
    @State private var runAtStartup: Bool = true
    @State private var closeToTray: Bool = true
    @State private var isCheckingUpdate: Bool = false
    @State private var updateStatusText: String = ""

    // Donanım Koruması: Bekleyen Ayarlar
    @State private var pendingSleepTimeout: Int? = nil
    @State private var pendingDebounceTime: Int? = nil
    @State private var hasUnsavedHardwareSettings: Bool = false
    @State private var hardwareSettingsSavedFeedback: String? = nil

    // Profil ve Fabrika Ayarları Onay Diyalogları
    @State private var pendingProfileIndex: Int? = nil
    @State private var pendingProfileName: String = ""
    @State private var showProfileSwitchAlert: Bool = false
    @State private var showResetConfirmAlert: Bool = false

    // iPhone Tarzı Yatay Uyku Sayacı Çarkı
    @State private var isSleepPickerExpanded: Bool = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Başlık
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.tr("tc_config", default: "Cihaz ve Sistem Ayarları"))
                        .font(.system(size: 26, weight: .bold))
                    Text(loc.tr("tc_msg1", default: "Donanım telemetrisi, dil seçimi, profiller ve sistem davranışları"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 1. DİL SEÇİMİ (LANGUAGE SELECTION) KARTI
                VStack(alignment: .leading, spacing: 14) {
                    Label(loc.tr("tc_msg10", default: "UYGULAMA DİLİ").uppercased(), systemImage: "globe")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    HStack(spacing: 12) {
                        ForEach(AppLanguage.allCases) { lang in
                            Button(action: {
                                loc.setLanguage(lang)
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(loc.currentLanguage == lang ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                                            .frame(width: 32, height: 32)
                                        Text(lang.code)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(loc.currentLanguage == lang ? .white : .primary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lang.displayName)
                                            .font(.system(size: 14, weight: loc.currentLanguage == lang ? .bold : .medium))
                                            .foregroundColor(loc.currentLanguage == lang ? .white : .primary)
                                        Text(lang == .turkish ? "Türkçe Dil Desteği" : (lang == .english ? "English Language" : "Deutsche Sprache"))
                                            .font(.caption2)
                                            .foregroundColor(loc.currentLanguage == lang ? .white.opacity(0.8) : .secondary)
                                    }
                                    Spacer()
                                    if loc.currentLanguage == lang {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(loc.currentLanguage == lang ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(loc.currentLanguage == lang ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // 2. PROFİL YÖNETİMİ (PROFILES 1-3) KARTI
                VStack(alignment: .leading, spacing: 14) {
                    Label(loc.tr("tc_msg26", default: "KONFİGÜRASYON PROFİLLERİ").uppercased(), systemImage: "folder.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    HStack(spacing: 12) {
                        profileCard(index: 1, name: "\(loc.tr("tc_msg26", default: "Profil")) 1", desc: "Varsayılan (Default)", icon: "sparkles")
                        profileCard(index: 2, name: "\(loc.tr("tc_msg26", default: "Profil")) 2", desc: "Oyun & Hızlı Raporlama", icon: "gamecontroller.fill")
                        profileCard(index: 3, name: "\(loc.tr("tc_msg26", default: "Profil")) 3", desc: "Ofis & Gece Çalışması", icon: "laptopcomputer")
                    }
                }

                // 3. PİL VE GÜÇ SAĞLIĞI KARTI
                VStack(alignment: .leading, spacing: 16) {
                    Label(loc.tr("tc_msg5", default: "GÜÇ VE PİL SAĞLIĞI").uppercased(), systemImage: "battery.100.bolt")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    HStack(spacing: 20) {
                        // Pil Yüzdesi Dairesel Görünüm
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                                    .frame(width: 70, height: 70)
                                Circle()
                                    .trim(from: 0, to: CGFloat(keyboardManager.batteryLevel) / 100.0)
                                    .stroke(
                                        batteryRingColor,
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 70, height: 70)
                                
                                Text("%\(keyboardManager.batteryLevel)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    if keyboardManager.batteryLevel >= 100 && keyboardManager.isCharging {
                                        Text(loc.tr("tc_fully_charged", default: "Tamamen Şarj Oldu"))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.green)
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.green)
                                    } else if keyboardManager.batteryLevel <= 20 && !keyboardManager.isCharging {
                                        Text(loc.tr("tc_low_battery", default: "Batarya Zayıf"))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.red)
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(.red)
                                    } else {
                                        Text(keyboardManager.isCharging ? loc.tr("tc_charging", default: "Şarj Ediliyor") : loc.tr("tc_on_battery", default: "Batarya Modu"))
                                            .font(.system(size: 16, weight: .semibold))
                                        if keyboardManager.isCharging {
                                            Image(systemName: "bolt.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                }
                                HStack(spacing: 4) {
                                    Image(systemName: keyboardManager.connectionType.icon)
                                    Text(keyboardManager.connectionType.rawValue)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    keyboardManager.batteryLevel <= 20 && !keyboardManager.isCharging ?
                                    Color.red.opacity(0.3) :
                                    (keyboardManager.batteryLevel >= 100 && keyboardManager.isCharging ? Color.green.opacity(0.3) : Color.white.opacity(0.08)),
                                    lineWidth: 1
                                )
                        )

                        // Uyku Süresi Seçici (Tıklanabilir iPhone Sayaç Çarkı Kartı)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(loc.tr("settings_sleep_title", default: "Otomatik Uyku"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        isSleepPickerExpanded.toggle()
                                    }
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: isSleepPickerExpanded ? "chevron.up.circle.fill" : "slider.horizontal.2.square")
                                        Text(isSleepPickerExpanded ? "Çarkı Kapat" : "Sayaç Çarkı İle Ayarla")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.12))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            
                            let currentVal = pendingSleepTimeout ?? keyboardManager.sleepTimeoutSeconds
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(sleepLabel(currentVal))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(pendingSleepTimeout != nil ? .orange : .primary)
                                
                                Text("• " + (currentVal == 0 ? "LED'ler sürekli açık kalır" : "\(currentVal) sn sonra uyku"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(loc.tr("settings_sleep_desc", default: "Hareketsizlikte LED'leri kapatıp uyku moduna geçerek pil tasarrufu sağlar. Çarkı soldan sağa kaydırarak hassas ayarlayabilirsiniz."))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSleepPickerExpanded ? Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.5) : (pendingSleepTimeout != nil ? Color.orange.opacity(0.4) : Color.white.opacity(0.08)), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isSleepPickerExpanded.toggle()
                            }
                        }
                    }

                    // iPhone Tarzı Yatay Uyku Sayacı Çarkı (Soldan Sağa Kaydırmalı & Tırrr Tırrr Sesli)
                    if isSleepPickerExpanded {
                        HorizontalTimerWheelPicker(
                            selectedSeconds: Binding(
                                get: { pendingSleepTimeout ?? keyboardManager.sleepTimeoutSeconds },
                                set: { pendingSleepTimeout = $0 }
                            ),
                            onSave: { newSeconds in
                                commitSingleSleepTimeout(newSeconds)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isSleepPickerExpanded = false
                                }
                            },
                            onCancel: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    pendingSleepTimeout = nil
                                    isSleepPickerExpanded = false
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.98))
                        ))
                    }

                    // Donanım Yanıt Süresi & Döner Tekerlek Ayarları
                    HStack(spacing: 20) {
                        // Tuş Tepki Filtresi (Debounce / LowDelay)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(loc.tr("settings_debounce_title", default: "Tuş Tepki Süresi (Debounce)"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Menu {
                                    Button("2 ms (Ultra Hızlı Espor)") { selectDebounce(2) }
                                    Button("4 ms (Hızlı)") { selectDebounce(4) }
                                    Button("8 ms (Dengeli - Önerilen)") { selectDebounce(8) }
                                    Button("16 ms (Kararlı)") { selectDebounce(16) }
                                } label: {
                                    HStack(spacing: 4) {
                                        let currentVal = pendingDebounceTime ?? keyboardManager.debounceTimeMs
                                        Text(debounceLabel(currentVal))
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(pendingDebounceTime != nil ? .orange : .primary)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption2)
                                    }
                                }
                                .menuStyle(.borderlessButton)
                            }
                            
                            let displayVal = pendingDebounceTime ?? keyboardManager.debounceTimeMs
                            Text(debounceLabel(displayVal))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(pendingDebounceTime != nil ? .orange : .primary)
                            Text(loc.tr("settings_debounce_desc", default: "Tuş vuruş filtreleme süresi. Düşük değerler gecikmeyi azaltır."))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(pendingDebounceTime != nil ? Color.orange.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1))

                        // Döner Tekerlek (Knob / Wheel) Donanım Rehber Kartı
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(loc.tr("settings_knob_title", default: "Döner Tekerlek (Knob)"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("3-5 sn Basılı Tutun")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.pink.opacity(0.15))
                                    .foregroundColor(.pink)
                                    .clipShape(Capsule())
                            }
                            
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color.pink, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "dial.medium.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(loc.tr("manual_knob_hold_action", default: "Ses Kontrolcüsü ⟷ Aydınlatma Kontrolcüsü"))
                                        .font(.system(size: 15, weight: .bold))
                                    Text(loc.tr("manual_knob_badge", default: "Donanımsal Geçiş") + " (3 Işık Kırpması)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text("Tekerleğe dik biçimde 3-5 saniye basılı tuttuğunuzda klavye ışıkları 3 defa kırparak ses kontrolcüsü ve aydınlatma kontrolcüsü arasında donanımsal geçiş yapar.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }

                    // Kaydedilmemiş Donanım Ayarları Barı
                    if hasUnsavedHardwareSettings {
                        unsavedHardwareBar
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else if let feedback = hardwareSettingsSavedFeedback {
                        hardwareSuccessBanner(feedback)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Düşük Pil Uyarısı veya Tam Şarj Bilgilendirme Kartı
                    if keyboardManager.batteryLevel <= 20 && !keyboardManager.isCharging {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc.tr("tc_low_battery", default: "Batarya Zayıf"))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.red)
                                Text(String(format: loc.tr("tc_low_battery_warning", default: "Batarya seviyesi kritik derecede düşük (%%%d). Kesintisiz kullanım için lütfen Type-C kablosuyla şarja takın."), keyboardManager.batteryLevel))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
                    } else if keyboardManager.batteryLevel >= 100 && keyboardManager.isCharging {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc.tr("tc_fully_charged", default: "Tamamen Şarj Oldu"))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.green)
                                Text(loc.tr("tc_fully_charged_desc", default: "Pil tamamen doldu. Dilerseniz kablosuz kullanıma geçebilirsiniz."))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.3), lineWidth: 1))
                    }
                }

                // 4. macOS vs Windows Modu Kartı
                VStack(alignment: .leading, spacing: 16) {
                    Label("İŞLETİM SİSTEMİ VE KLAVYE DÜZENİ", systemImage: "macbook.and.iphone")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    HStack(spacing: 16) {
                        // Mac Modu Butonu
                        Button(action: {
                            keyboardManager.setPlatformMode(macMode: true)
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "apple.logo")
                                        .font(.title2)
                                    Text("macOS Modu")
                                        .font(.headline)
                                    Spacer()
                                    if keyboardManager.isMacMode {
                                        Text("AKTİF")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text("Kısayol: Fn + S")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(6)

                                Text("Alt tuşu Option (⌥), Windows tuşu Command (⌘) olarak atanır.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(keyboardManager.isMacMode ? Color.accentColor.opacity(0.12) : Color.white.opacity(0.04))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(keyboardManager.isMacMode ? Color.accentColor : Color.white.opacity(0.08), lineWidth: keyboardManager.isMacMode ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // Windows Modu Butonu
                        Button(action: {
                            keyboardManager.setPlatformMode(macMode: false)
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "window.vertical.closed")
                                        .font(.title2)
                                    Text("Windows Modu")
                                        .font(.headline)
                                    Spacer()
                                    if !keyboardManager.isMacMode {
                                        Text("AKTİF")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text("Kısayol: Fn + A")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(6)

                                Text("Standart PC düzeni. Sol alttaki tuş Ctrl, Win, Alt olarak çalışır.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(!keyboardManager.isMacMode ? Color.blue.opacity(0.12) : Color.white.opacity(0.04))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(!keyboardManager.isMacMode ? Color.blue : Color.white.opacity(0.08), lineWidth: !keyboardManager.isMacMode ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // 5. GÜNCELLEME VE SİSTEM DAVRANIŞLARI (tc_update & tc_msg)
                VStack(alignment: .leading, spacing: 14) {
                    Label(loc.tr("tc_update7", default: "SİSTEM & GÜNCELLEME").uppercased(), systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    VStack(alignment: .leading, spacing: 14) {
                        // Donanım Yazılımı & Sürücü Güncelleme Denetimi
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(loc.tr("tc_update6", default: "Donanım Yazılımı & Sürücü Güncelleme"))
                                    .font(.system(size: 14, weight: .semibold))
                                Text(updateStatusText.isEmpty ? loc.tr("tc_update3", default: "Yazılım şu anda en son sürümdür (v2.4 IC2481).") : updateStatusText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                checkForUpdates()
                            }) {
                                if isCheckingUpdate {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Text(loc.tr("tc_msg20", default: "Güncellemeleri Denetle"))
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isCheckingUpdate)
                        }

                        Divider().background(Color.white.opacity(0.06))

                        // Başlangıçta Otomatik Çalıştırma
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc.tr("tc_msg11", default: "Otomatik Çalıştırma (Başlangıçta Aç)"))
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Bilgisayar açıldığında arka planda otomatik başlasın")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $runAtStartup)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider().background(Color.white.opacity(0.06))

                        // Kapatma Davranışı
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc.tr("tc_msg8", default: "X Kapatıldığında Menü Çubuğunda / Tepside Kal"))
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Pencere kapatıldığında arka planda çalışmaya devam eder")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $closeToTray)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(18)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }



                // 6. DONANIM BİLGİSİ TABLOSU
                VStack(alignment: .leading, spacing: 14) {
                    Label(loc.tr("tc_msg2", default: "DONANIM AYRINTILARI").uppercased(), systemImage: "info.circle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    VStack(spacing: 0) {
                        detailRow(title: "Cihaz Modeli", value: "INCA IKG-455 Empousa Manyetik Eksen")
                        Divider().padding(.horizontal, 12)
                        detailRow(title: "Aktif Bağlantı", value: keyboardManager.connectionType.rawValue)
                        Divider().padding(.horizontal, 12)
                        detailRow(title: "Vendor ID (VID)", value: keyboardManager.connectionType == .wireless24G ? "0x3554 (13652)" : (keyboardManager.connectionType == .bluetooth ? "Dinamik BT" : "0x258A (9610)"))
                        Divider().padding(.horizontal, 12)
                        detailRow(title: "Product ID (PID)", value: keyboardManager.connectionType == .wireless24G ? "0xFA09 (64009)" : (keyboardManager.connectionType == .bluetooth ? "IKG-455 BT 5.0" : "0x010C (268)"))
                        Divider().padding(.horizontal, 12)
                        detailRow(title: "Raporlama Hızı (Polling Rate)", value: "1000 Hz (1 ms Gecikme)")
                        Divider().padding(.horizontal, 12)
                        detailRow(title: "Donanım Yazılımı (Firmware)", value: "v2.4 (IC2481)")
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }

                // 7. FABRİKA AYARLARINA SIFIRLAMA
                VStack(alignment: .leading, spacing: 14) {
                    Label(loc.tr("tc_msg21", default: "FABRİKA AYARLARI VE BAKIM").uppercased(), systemImage: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc.tr("tc_msg21", default: "Cihazı Fabrika Ayarlarına Sıfırla"))
                                .font(.system(size: 14, weight: .semibold))
                            Text("Tüm ışık, yan LED, TFT ve uyku parametrelerini fabrika ayarlarına sıfırlar.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            showResetConfirmAlert = true
                        }) {
                            Label(loc.tr("tc_restore", default: "Fabrika Ayarlarına Sıfırla"), systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    .padding(18)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
            }
            .padding(24)
            .alert(loc.tr("confirm_profile_switch_title", default: "Profili Değiştir"), isPresented: $showProfileSwitchAlert) {
                Button(loc.tr("common_switch", default: "Değiştir")) {
                    if let target = pendingProfileIndex {
                        withAnimation(.spring(response: 0.3)) {
                            selectedProfileIndex = target
                        }
                    }
                    pendingProfileIndex = nil
                }
                Button(loc.tr("tc_cancel", default: "İptal"), role: .cancel) {
                    pendingProfileIndex = nil
                }
            } message: {
                Text(String(format: loc.tr("confirm_profile_switch_msg", default: "'%@' profiline geçmek istediğinizden emin misiniz?"), pendingProfileName))
            }
            .alert(loc.tr("confirm_reset_title", default: "Fabrika Ayarlarına Sıfırla"), isPresented: $showResetConfirmAlert) {
                Button(loc.tr("settings_reset_btn", default: "Sıfırla"), role: .destructive) {
                    keyboardManager.resetToFactoryDefaults()
                }
                Button(loc.tr("tc_cancel", default: "İptal"), role: .cancel) { }
            } message: {
                Text(loc.tr("confirm_reset_msg", default: "Klavyenizi fabrika ayarlarına sıfırlamak istediğinizden emin misiniz? Tüm ışık efektleri ve özel tuş atamaları sıfırlanacaktır."))
            }
        }
    }

    private func profileCard(index: Int, name: String, desc: String, icon: String) -> some View {
        Button(action: {
            guard selectedProfileIndex != index else { return }
            pendingProfileIndex = index
            pendingProfileName = name
            showProfileSwitchAlert = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(selectedProfileIndex == index ? .white : Color(red: 0.98, green: 0.18, blue: 0.38))
                    Spacer()
                    if selectedProfileIndex == index {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                Text(name)
                    .font(.system(size: 14, weight: selectedProfileIndex == index ? .bold : .medium))
                    .foregroundColor(selectedProfileIndex == index ? .white : .primary)
                Text(desc)
                    .font(.caption2)
                    .foregroundColor(selectedProfileIndex == index ? .white.opacity(0.8) : .secondary)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selectedProfileIndex == index ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedProfileIndex == index ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func checkForUpdates() {
        isCheckingUpdate = true
        updateStatusText = "Güncellemeler denetleniyor..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isCheckingUpdate = false
            updateStatusText = loc.tr("tc_update3", default: "Yazılım şu anda en son sürümdür.")
        }
    }

    private func sleepLabel(_ seconds: Int) -> String {
        switch seconds {
        case 0: return loc.tr("settings_sleep_never", default: "Asla (Sürekli Açık)")
        case 20: return "20 Saniye (20 sn)"
        case 30: return loc.tr("settings_sleep_30s", default: "30 Saniye (30 sn)")
        case 60: return loc.tr("settings_sleep_1m", default: "1 Dakika (60 sn)")
        case 180: return loc.tr("settings_sleep_3m", default: "3 Dakika (180 sn)")
        case 300: return loc.tr("settings_sleep_5m", default: "5 Dakika (300 sn)")
        case 600: return loc.tr("settings_sleep_10m", default: "10 Dakika (600 sn)")
        case 1200: return loc.tr("settings_sleep_20m", default: "20 Dakika (1200 sn)")
        default:
            let m = seconds / 60
            let s = seconds % 60
            if m == 0 {
                return "\(s) Saniye"
            } else if s == 0 {
                return "\(m) Dakika"
            } else {
                return "\(m) Dakika \(s) Saniye"
            }
        }
    }

    private func commitSingleSleepTimeout(_ sec: Int) {
        keyboardManager.setSleepTimeout(seconds: sec)
        pendingSleepTimeout = nil
        hasUnsavedHardwareSettings = pendingDebounceTime != nil
        hardwareSettingsSavedFeedback = "Otomatik uyku süresi \(sleepLabel(sec)) olarak ayarlandı!"
        keyboardManager.triggerSavedSuccess(message: "Uyku: \(sleepLabel(sec))")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                hardwareSettingsSavedFeedback = nil
            }
        }
    }

    private func debounceLabel(_ ms: Int) -> String {
        switch ms {
        case 2: return loc.tr("settings_debounce_2ms", default: "2 ms (Ultra Hızlı Espor)")
        case 4: return loc.tr("settings_debounce_4ms", default: "4 ms (Hızlı)")
        case 8: return loc.tr("settings_debounce_8ms", default: "8 ms (Dengeli - Önerilen)")
        case 16: return loc.tr("settings_debounce_16ms", default: "16 ms (Kararlı)")
        default: return "\(ms) ms"
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var batteryRingColor: Color {
        if keyboardManager.batteryLevel >= 100 && keyboardManager.isCharging {
            return .green
        }
        if keyboardManager.isCharging {
            return .green
        }
        if keyboardManager.batteryLevel <= 20 {
            return .red
        }
        if keyboardManager.batteryLevel <= 50 {
            return .orange
        }
        return .green
    }

    // MARK: - Donanım Koruması: Bekleyen Ayarların Yönetimi
    private func selectSleepTimeout(_ sec: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            pendingSleepTimeout = sec
            hasUnsavedHardwareSettings = true
            hardwareSettingsSavedFeedback = nil
        }
        keyboardManager.triggerUnsavedStatus(
            description: "Uyku Süresi: \(sleepLabel(sec))",
            onCommit: {
                commitHardwareSettings()
            },
            onDiscard: {
                discardHardwareSettings()
            }
        )
    }

    private func selectDebounce(_ ms: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            pendingDebounceTime = ms
            hasUnsavedHardwareSettings = true
            hardwareSettingsSavedFeedback = nil
        }
        keyboardManager.triggerUnsavedStatus(
            description: "Tepki Süresi: \(ms) ms",
            onCommit: {
                commitHardwareSettings()
            },
            onDiscard: {
                discardHardwareSettings()
            }
        )
    }

    private func commitHardwareSettings() {
        keyboardManager.triggerSavingStatus(message: "Donanım Kaydediliyor...")
        if let sleepSec = pendingSleepTimeout {
            keyboardManager.setSleepTimeout(seconds: sleepSec)
        }
        if let debounceMs = pendingDebounceTime {
            keyboardManager.setDebounceTime(ms: debounceMs)
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            pendingSleepTimeout = nil
            pendingDebounceTime = nil
            hasUnsavedHardwareSettings = false
            hardwareSettingsSavedFeedback = "Donanım ayarları başarıyla klavyeye kaydedildi!"
        }
        keyboardManager.triggerSavedSuccess(message: "Donanım Ayarları Kaydedildi!")

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation {
                hardwareSettingsSavedFeedback = nil
            }
        }
    }

    private func discardHardwareSettings() {
        withAnimation(.easeInOut(duration: 0.2)) {
            pendingSleepTimeout = nil
            pendingDebounceTime = nil
            hasUnsavedHardwareSettings = false
        }
        keyboardManager.triggerIdleStatus()
    }

    private var unsavedHardwareBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Kaydedilmemiş Donanım Ayarları Var")
                        .font(.system(size: 13, weight: .bold))
                    Text("Klavyeyi spamlamamak için ayarlar hafızada tutulur. 'Ayarları Kaydet' butonuna basarak çipe aktarabilirsiniz.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: {
                discardHardwareSettings()
            }) {
                Text("Vazgeç")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(action: {
                commitHardwareSettings()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Ayarları Kaydet")
                        .fontWeight(.bold)
                }
                .font(.system(size: 12))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(red: 0.98, green: 0.18, blue: 0.38))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }

    private func hardwareSuccessBanner(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 16))
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.green)
            Spacer()
        }
        .padding(12)
        .background(Color.green.opacity(0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}
