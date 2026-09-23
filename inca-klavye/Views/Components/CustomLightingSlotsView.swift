import SwiftUI

/// Kişisel aydınlatma (Özel Tuş Matrisi) için bilgisayar diskinde tutulan 5 profili gösteren ve yöneten bileşen.
struct CustomLightingSlotsView: View {
    @ObservedObject var slotsManager = CustomLightingSlotsManager.shared
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var customKeyColors: [String: Color]
    var onSlotApplied: (() -> Void)? = nil

    @State private var renamingSlot: CustomLightingSlot? = nil
    @State private var renameText: String = ""
    @State private var feedbackMessage: String? = nil
    @State private var slotToLoad: CustomLightingSlot? = nil
    @State private var showLoadConfirmAlert: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Başlık ve Durum
            HStack(spacing: 8) {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))

                Text(loc.tr("slots_header", default: "BİLGİSAYAR DİSKİ PROFİL SLOTLARI (5 SLOT)"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                Spacer()

                if let feedback = feedbackMessage {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 11))
                        Text(feedback)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(6)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    Text(loc.tr("slots_subtitle", default: "Değişiklikleri diske kalıcı olarak kaydeder"))
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }

            // 5 Slot Yatay Grid / HStack
            HStack(spacing: 10) {
                ForEach(slotsManager.slots) { slot in
                    slotCard(slot: slot)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .sheet(item: $renamingSlot) { slot in
            renameSheet(for: slot)
        }
        .alert(loc.tr("confirm_slot_load_title", default: "Profili Yükle"), isPresented: $showLoadConfirmAlert) {
            Button(loc.tr("slots_load", default: "Yükle")) {
                if let s = slotToLoad {
                    loadSlotToMatrix(s.id)
                }
                slotToLoad = nil
            }
            Button(loc.tr("tc_cancel", default: "İptal"), role: .cancel) {
                slotToLoad = nil
            }
        } message: {
            if let s = slotToLoad {
                Text(String(format: loc.tr("confirm_slot_load_msg", default: "'%@' profilini klavyeye yüklemek istediğinizden emin misiniz?"), s.title))
            }
        }
    }

    // MARK: - Tekil Slot Kartı
    private func slotCard(slot: CustomLightingSlot) -> some View {
        let isActive = slotsManager.activeSlotId == slot.id

        return VStack(alignment: .leading, spacing: 9) {
            // Üst Satır: Slot Numarası & Aktif Rozeti & Menü
            HStack {
                HStack(spacing: 4) {
                    Text(loc.tr("slots_slot_prefix", default: "SLOT") + " \(slot.id)")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(isActive ? Color(red: 0.98, green: 0.18, blue: 0.38) : .secondary)

                    if isActive {
                        Circle()
                            .fill(Color(red: 0.98, green: 0.18, blue: 0.38))
                            .frame(width: 5, height: 5)
                    }
                }

                Spacer()

                // Slot Seçenekleri Menüsü
                Menu {
                    Button(action: {
                        renameText = slot.title
                        renamingSlot = slot
                    }) {
                        Label(loc.tr("slots_rename", default: "Adını Değiştir"), systemImage: "pencil")
                    }

                    Button(action: {
                        saveCurrentColorsToSlot(slot.id)
                    }) {
                        Label(loc.tr("slots_save_over", default: "Mevcut Matrisi Bu Slota Kaydet"), systemImage: "arrow.down.doc.fill")
                    }

                    if !slot.isEmpty {
                        Divider()
                        Button(role: .destructive, action: {
                            withAnimation {
                                slotsManager.clearSlot(id: slot.id)
                                showFeedback("Slot \(slot.id) temizlendi")
                            }
                        }) {
                            Label(loc.tr("slots_clear", default: "Slotu Sıfırla (Boşalt)"), systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
            }

            // Slot Başlığı
            Text(slot.title)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)

            // Durum & Renk Önizleme Noktaları
            if slot.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "tray")
                        .font(.system(size: 9))
                    Text(loc.tr("slots_empty", default: "Boş Slot"))
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.secondary.opacity(0.6))
                .frame(height: 16)
            } else {
                HStack(spacing: 6) {
                    Text("\(slot.keyCount) " + loc.tr("slots_key_count", default: "Tuş"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)

                    // Minik Renk Önizleme Noktaları
                    HStack(spacing: 3) {
                        ForEach(slot.distinctPreviewColors.indices, id: \.self) { idx in
                            Circle()
                                .fill(slot.distinctPreviewColors[idx])
                                .frame(width: 7, height: 7)
                        }
                    }
                }
                .frame(height: 16)
            }

            Divider()
                .padding(.vertical, 1)

            // Eylem Butonları: Yükle & Kaydet
            HStack(spacing: 6) {
                // Yükle Butonu (Slot doluysa)
                Button(action: {
                    slotToLoad = slot
                    showLoadConfirmAlert = true
                }) {
                    Text(loc.tr("slots_load", default: "Yükle"))
                        .font(.system(size: 10.5, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            slot.isEmpty
                                ? Color.white.opacity(0.04)
                                : (isActive ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.12))
                        )
                        .foregroundColor(
                            slot.isEmpty
                                ? .secondary.opacity(0.4)
                                : (isActive ? .white : .primary)
                        )
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(slot.isEmpty)
                .help(slot.isEmpty ? "Slot boş" : "\(slot.title) profilini klavyeye yükle")

                // Kaydet Butonu (Mevcut renkleri bu slota kaydet)
                Button(action: {
                    saveCurrentColorsToSlot(slot.id)
                }) {
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.secondary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Ekranda boyadığınız renkleri Slot \(slot.id)'ye diske kaydeder")
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(isActive ? Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.08) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(
                    isActive
                        ? Color(red: 0.98, green: 0.18, blue: 0.38).opacity(0.4)
                        : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Slot Yeniden Adlandırma Sayfası
    private func renameSheet(for slot: CustomLightingSlot) -> some View {
        VStack(spacing: 18) {
            HStack {
                Text(loc.tr("slots_dialog_title", default: "Slot Yeniden Adlandır") + " (\(slot.id))")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }

            TextField("Profil Adı (örn: FPS Rekabetçi, Cyberpunk, Yazılım)", text: $renameText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))

            HStack {
                Button(loc.tr("island_discard_btn", default: "Vazgeç")) {
                    renamingSlot = nil
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(loc.tr("tc_apply", default: "Kaydet")) {
                    if !renameText.trimmingCharacters(in: .whitespaces).isEmpty {
                        slotsManager.renameSlot(id: slot.id, newTitle: renameText)
                        showFeedback("Slot \(slot.id) yeniden adlandırıldı")
                    }
                    renamingSlot = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.98, green: 0.18, blue: 0.38))
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    // MARK: - Eylemler
    private func loadSlotToMatrix(_ id: Int) {
        let loaded = slotsManager.loadColors(for: id)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            customKeyColors = loaded
        }
        if let slot = slotsManager.slots.first(where: { $0.id == id }) {
            showFeedback("\(slot.title) yüklendi ✓")
        }
        onSlotApplied?()
    }

    private func saveCurrentColorsToSlot(_ id: Int) {
        slotsManager.saveSlot(id: id, colors: customKeyColors)
        if let slot = slotsManager.slots.first(where: { $0.id == id }) {
            showFeedback("\(slot.title) diske kaydedildi ✓")
        }
    }

    private func showFeedback(_ text: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            feedbackMessage = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                if feedbackMessage == text {
                    feedbackMessage = nil
                }
            }
        }
    }
}
