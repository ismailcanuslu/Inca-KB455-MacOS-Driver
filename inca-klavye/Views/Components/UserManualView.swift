import SwiftUI

struct UserManualView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Üst Başlık Kartı
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .shadow(color: Color.blue.opacity(0.35), radius: 12, x: 0, y: 6)

                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc.tr("tc_manual", default: "Kullanma Kılavuzu"))
                            .font(.system(size: 24, weight: .bold))

                        Text(loc.tr("manual_subtitle", default: "INCA IKG-455 Donanımsal Kısayollar ve Kontrol Rehberi"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.top, 10)

                // 1. Döner Tekerlek Özel Kartı (ÖNE ÇIKAN)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "dial.medium.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.pink)
                        Text(loc.tr("manual_knob_header", default: "DÖNER TEKERLEK ÇALIŞMA MANTIĞI"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                        Spacer()
                    }

                    VStack(spacing: 10) {
                        manualActionRow(
                            combo: loc.tr("manual_knob_hold_combo", default: "Basılı Tut"),
                            action: loc.tr("manual_knob_hold_action", default: "Ses & Medya Modu ⟷ RGB Parlaklık Modu"),
                            desc: loc.tr("manual_knob_hold_desc", default: "Tekerleğe dik şekilde basılı tuttuğunuzda klavye ışıkları 3 defa yanıp söner ve çalışma modunu değiştirir."),
                            badgeColor: .pink
                        )

                        manualActionRow(
                            combo: loc.tr("manual_knob_click_combo", default: "Tıkla"),
                            action: loc.tr("manual_knob_click_action", default: "Sesi Kapat (Mute) ya da Efekt Değiştir"),
                            desc: loc.tr("manual_knob_click_desc", default: "Ses modundayken sesi tamamen susturur/açar. Işık modundayken ana aydınlatma efektini bir sonraki moda atlatır."),
                            badgeColor: .blue
                        )

                        manualActionRow(
                            combo: loc.tr("manual_knob_turn_combo", default: "Sağa/Sola Çevir"),
                            action: loc.tr("manual_knob_turn_action", default: "Ses Seviyesi ya da Işık Parlaklığı"),
                            desc: loc.tr("manual_knob_turn_desc", default: "Ses modunda sistem sesini artırıp azaltır; ışık modunda klavye aydınlatmasının parlaklık kademesini ayarlar."),
                            badgeColor: .green
                        )
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))

                // 2. Bağlantı Modları (3-Modlu Bağlantı)
                manualSectionCard(
                    title: loc.tr("manual_conn_header", default: "BAĞLANTI MODLARI & EŞLEŞTİRME"),
                    icon: "antenna.radiowaves.left.and.right",
                    iconColor: .green
                ) {
                    manualActionRow(
                        combo: "Fn + 1 / 2 / 3",
                        action: loc.tr("manual_fn_123_action", default: "Bluetooth 5.0 (Cihaz 1, 2, 3)"),
                        desc: loc.tr("manual_fn_123_desc", default: "Kısa basış cihazlar arası geçiş yapar; 3 saniye basılı tutma Bluetooth eşleştirme modunu başlatır."),
                        badgeColor: .blue
                    )

                    manualActionRow(
                        combo: "Fn + 4",
                        action: loc.tr("manual_fn_4_action", default: "2.4G Kablosuz Alıcı"),
                        desc: loc.tr("manual_fn_4_desc", default: "Klavyeyi kutudan çıkan 2.4 GHz USB kablosuz alıcı moduna geçirir."),
                        badgeColor: .green
                    )

                    manualActionRow(
                        combo: "Fn + 5",
                        action: loc.tr("manual_fn_5_action", default: "Type-C Kablolu Bağlantı"),
                        desc: loc.tr("manual_fn_5_desc", default: "USB-C kablosu üzerinden en yüksek yoklama hızı (1000Hz) ile kablolu moda geçer."),
                        badgeColor: .purple
                    )
                }

                // 3. RGB & Aydınlatma Kısayolları
                manualSectionCard(
                    title: loc.tr("manual_rgb_header", default: "RGB AYDINLATMA KONTROLLERİ"),
                    icon: "sparkles",
                    iconColor: .yellow
                ) {
                    manualActionRow(
                        combo: "Fn + Ins (Insert)",
                        action: loc.tr("manual_fn_slash_action", default: "Arka Aydınlatma Efekti"),
                        desc: loc.tr("manual_fn_slash_desc", default: "Dahili 18 RGB efekti arasında sırayla geçiş yapar."),
                        badgeColor: .yellow
                    )

                    manualActionRow(
                        combo: "Fn + Enter",
                        action: loc.tr("manual_fn_enter_action", default: "Donanım Renk Paleti Değiştir"),
                        desc: "Seçili efektin tek renk modunda donanımsal renkler (Kırmızı, Yeşil, Mavi, Sarı, Mor, Cyan, Beyaz) arasında geçiş yapar.",
                        badgeColor: .orange
                    )

                    manualActionRow(
                        combo: "Fn + Backspace",
                        action: "Pil Durumu Göstergesi",
                        desc: "Sayı tuşları (1..0) üzerindeki yeşil LED'ler anlık pil seviyesini yüzde olarak klavye üzerinde görselleştirir.",
                        badgeColor: .green
                    )

                    manualActionRow(
                        combo: "Fn + Boşluk (Space)",
                        action: loc.tr("manual_fn_space_action", default: "Işıkları Kapat / Aç"),
                        desc: loc.tr("manual_fn_space_desc", default: "Klavyenin tüm arka aydınlatmasını anında kapatır ya da tekrar açar."),
                        badgeColor: .secondary
                    )

                    manualActionRow(
                        combo: "Fn + Sol Win",
                        action: "Windows Tuşu Kilidi (Win Lock)",
                        desc: "Oyun sırasında yanlışlıkla basılmasını önlemek için Windows tuşunu kilitler ya da kilidi kaldırır.",
                        badgeColor: .purple
                    )

                    manualActionRow(
                        combo: "Fn + Yukarı Ok (↑)",
                        action: loc.tr("manual_fn_up_action", default: "Parlaklık Artır (+)"),
                        desc: loc.tr("manual_fn_up_desc", default: "Arka aydınlatmanın parlaklık kademesini artırır."),
                        badgeColor: .cyan
                    )

                    manualActionRow(
                        combo: "Fn + Aşağı Ok (↓)",
                        action: loc.tr("manual_fn_down_action", default: "Parlaklık Azalt (-)"),
                        desc: loc.tr("manual_fn_down_desc", default: "Arka aydınlatmanın parlaklık kademesini kısar."),
                        badgeColor: .cyan
                    )

                    manualActionRow(
                        combo: "Fn + Sağ Ok (→)",
                        action: loc.tr("manual_fn_right_action", default: "Efekt Hızı Artır (+)"),
                        desc: loc.tr("manual_fn_right_desc", default: "Animasyon ve dalga efektlerinin akış hızını artırır."),
                        badgeColor: .teal
                    )

                    manualActionRow(
                        combo: "Fn + Sol Ok (←)",
                        action: loc.tr("manual_fn_left_action", default: "Efekt Hızı Azalt (-)"),
                        desc: loc.tr("manual_fn_left_desc", default: "Animasyon ve dalga efektlerinin akış hızını yavaşlatır."),
                        badgeColor: .teal
                    )
                }

                // 4. Sistem & Sıfırlama Kısayolları
                manualSectionCard(
                    title: loc.tr("manual_system_header", default: "SİSTEM & SIFIRLAMA"),
                    icon: "gearshape.arrow.triangle.2.circlepath",
                    iconColor: .orange
                ) {
                    manualActionRow(
                        combo: "Fn + Esc",
                        action: loc.tr("manual_fn_esc_action", default: "Fabrika Ayarlarına Sıfırlama"),
                        desc: loc.tr("manual_fn_esc_desc", default: "Klavyeyi ilk fabrika ayarlarına sıfırlar ve dahili hafızayı yeniler."),
                        badgeColor: .red
                    )

                    manualActionRow(
                        combo: "Fn + A",
                        action: loc.tr("manual_fn_a_action", default: "macOS Modu (Mac Layout)"),
                        desc: loc.tr("manual_fn_a_desc", default: "Klavyeyi macOS tuş düzenine geçirir (Command ⌘ ve Option ⌥ düzeni aktif olur)."),
                        badgeColor: .purple
                    )

                    manualActionRow(
                        combo: "Fn + W",
                        action: loc.tr("manual_fn_w_action", default: "Windows Modu (Win Layout)"),
                        desc: loc.tr("manual_fn_w_desc", default: "Klavyeyi standart Windows/PC tuş dizilimine geri alır."),
                        badgeColor: .blue
                    )
                }
            }
            .padding(24)
        }
    }

    // Yardımcı Kısayol Satırı
    @ViewBuilder
    private func manualActionRow(combo: String, action: String, desc: String, badgeColor: Color) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(combo)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 165, height: 32)
                .background(badgeColor.opacity(0.15))
                .foregroundColor(badgeColor)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(badgeColor.opacity(0.3), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(action)
                    .font(.system(size: 13, weight: .semibold))

                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineSpacing(2.5)
            }

            Spacer()
        }
        .padding(.vertical, 3)
    }

    // Yardımcı Kart Yapısı
    @ViewBuilder
    private func manualSectionCard<Content: View>(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
            }

            VStack(spacing: 12) {
                content()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
