import SwiftUI

struct MacroItem: Identifiable, Hashable {
    let id = UUID()
    var macroSlot: UInt8 // 0 = Macro 1, 1 = Macro 2...
    var name: String
    var folder: String
    var loopMode: Int // 1: Döngü Sayısı, 2: Tuş Bırakılana Kadar, 3: Herhangi Bir Tuşa Kadar
    var loopCount: Int
    var actions: [KeyboardCommand.HardwareMacroAction]

    static func == (lhs: MacroItem, rhs: MacroItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// USB HID Klavye Kodları Yardımcısı
enum HIDKeyHelper {
    static let map: [String: UInt8] = [
        "A": 0x04, "B": 0x05, "C": 0x06, "D": 0x07, "E": 0x08, "F": 0x09,
        "G": 0x0A, "H": 0x0B, "I": 0x0C, "J": 0x0D, "K": 0x0E, "L": 0x0F,
        "M": 0x10, "N": 0x11, "O": 0x12, "P": 0x13, "Q": 0x14, "R": 0x15,
        "S": 0x16, "T": 0x17, "U": 0x18, "V": 0x19, "W": 0x1A, "X": 0x1B,
        "Y": 0x1C, "Z": 0x1D,
        "1": 0x1E, "2": 0x1F, "3": 0x20, "4": 0x21, "5": 0x22,
        "6": 0x23, "7": 0x24, "8": 0x25, "9": 0x26, "0": 0x27,
        "Enter": 0x28, "Escape": 0x29, "Backspace": 0x2A, "Tab": 0x2B, "Space": 0x2C,
        "Yukarı Ok (Up)": 0x52, "Aşağı Ok (Down)": 0x51, "Sol Ok (Left)": 0x50, "Sağ Ok (Right)": 0x4F,
        "F1": 0x3A, "F2": 0x3B, "F3": 0x3C, "F4": 0x3D, "F5": 0x3E, "F6": 0x3F,
        "F7": 0x40, "F8": 0x41, "F9": 0x42, "F10": 0x43, "F11": 0x44, "F12": 0x45
    ]

    static func name(for code: UInt8) -> String {
        for (k, v) in map {
            if v == code { return k }
        }
        return String(format: "0x%02X", code)
    }
}

struct MacroStudioView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    @ObservedObject var loc = LocalizationManager.shared

    @State private var showNewMacroSheet: Bool = false
    @State private var newMacroName: String = ""
    @State private var statusFeedback: String? = nil

    // İnteraktif görsel klavyeden seçilen tuş (Fotoğraftaki gibi varsayılan Yukarı Ok seçili)
    @State private var selectedKeyId: String? = "UP"
    @State private var selectedKeyDef: KeyboardKeyDef? = KeyboardKeyDef(
        id: "UP",
        primaryLabel: "▲",
        secondaryLabel: "⚙",
        widthUnits: 1.0,
        style: .dark,
        hidCode: 0x52,
        matrixIndex: 80
    )

    // Katman seçimi (0=Base, 1=FN1, 2=FN2, 3=Tap) - Sniff Paket 871 doğrulaması: Layer 2
    @State private var selectedLayer: UInt8 = 2

    // Tuşlara atanan makroların haritası (KeyId -> Makro İsmi)
    @State private var assignedMacroMap: [String: String] = [
        "UP": "new2" // Sniff 871/877 kanıtı: Yukarı oka 'new2' atanmış
    ]

    // Örnek ve sniff kayıtlı makrolar
    @State private var macros: [MacroItem] = [
        MacroItem(
            macroSlot: 0,
            name: "new2",
            folder: "Orijinal Sniff Kaydı",
            loopMode: 1,
            loopCount: 1,
            actions: [
                KeyboardCommand.HardwareMacroAction(hidCode: 0x04, isKeyDown: true, delayMs: 141),
                KeyboardCommand.HardwareMacroAction(hidCode: 0x04, isKeyDown: false, delayMs: 1969),
                KeyboardCommand.HardwareMacroAction(hidCode: 0x05, isKeyDown: true, delayMs: 109),
                KeyboardCommand.HardwareMacroAction(hidCode: 0x05, isKeyDown: false, delayMs: 0)
            ]
        ),
        MacroItem(
            macroSlot: 1,
            name: "CS2 Jumpthrow",
            folder: "Oyun",
            loopMode: 1,
            loopCount: 1,
            actions: [
                KeyboardCommand.HardwareMacroAction(hidCode: 0x2C, isKeyDown: true, delayMs: 0),
                KeyboardCommand.HardwareMacroAction(hidCode: 0x2C, isKeyDown: false, delayMs: 50),
                KeyboardCommand.HardwareMacroAction(hidCode: 0x1A, isKeyDown: true, delayMs: 20),
                KeyboardCommand.HardwareMacroAction(hidCode: 0x1A, isKeyDown: false, delayMs: 80)
            ]
        )
    ]

    @State private var selectedMacroIndex: Int = 0

    var currentMacro: MacroItem {
        if selectedMacroIndex < macros.count {
            return macros[selectedMacroIndex]
        }
        return macros[0]
    }

    var body: some View {
        HStack(spacing: 0) {
            // SOL PANEL: Makro Listesi
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.tr("tc_mac_def", default: "Makro Stüdyosu"))
                        .font(.system(size: 20, weight: .bold))
                    Text("Donanım Çipi Doğrudan Programlama (Cmd 0x05)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Yeni Makro Butonu
                Button(action: {
                    showNewMacroSheet = true
                }) {
                    Label(loc.tr("tc_macro_msg2", default: "Yeni Makro"), systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .padding(.horizontal, 16)

                Divider()

                // Makrolar ScrollView
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(macros.indices, id: \.self) { idx in
                            let macro = macros[idx]
                            Button(action: {
                                selectedMacroIndex = idx
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(selectedMacroIndex == idx ? .white : Color(red: 0.98, green: 0.18, blue: 0.38))
                                        .font(.system(size: 14))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(macro.name)
                                            .font(.system(size: 13, weight: selectedMacroIndex == idx ? .bold : .medium))
                                            .foregroundColor(selectedMacroIndex == idx ? .white : .primary)
                                        Text("\(macro.actions.count) Eylem • Slot #\(macro.macroSlot + 1)")
                                            .font(.caption2)
                                            .foregroundColor(selectedMacroIndex == idx ? .white.opacity(0.8) : .secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(selectedMacroIndex == idx ? .white : .secondary)
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedMacroIndex == idx ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.white.opacity(0.04))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
            .frame(width: 230)
            .background(.ultraThinMaterial)

            Divider()

            // SAĞ PANEL: Görsel Klavye & Atama Alanı
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center, spacing: 18) {
                    // 1. Üst Başlık & Butonlar
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentMacro.name)
                                .font(.system(size: 22, weight: .bold))
                            Text("Slot #\(currentMacro.macroSlot + 1) — Donanım Hafızasına Yazıma Hazır")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Klavyeye Yaz (Save to Hardware) Butonu
                        Button(action: {
                            uploadCurrentMacroToKeyboard()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("Klavyeye Yaz (Upload)")
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.98, green: 0.18, blue: 0.38))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        // Sil Butonu
                        Button(action: {
                            if macros.count > 1 {
                                macros.remove(at: selectedMacroIndex)
                                selectedMacroIndex = max(0, selectedMacroIndex - 1)
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Durum Bildirim Banner'ı
                    if let feedback = statusFeedback {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(feedback)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                    }

                    // 2. İNTERAKTİF GÖRSEL KLAVYE (Fotoğraftaki Birebir Empousa Klavyesi)
                    VStack(alignment: .center, spacing: 8) {
                        EmpousaKeyboardGraphicView(
                            keyboardManager: keyboardManager,
                            selectedKeyId: $selectedKeyId,
                            assignedMacroNames: assignedMacroMap,
                            onKeySelected: { keyDef in
                                self.selectedKeyDef = keyDef
                            },
                            onKnobRotatedOrClicked: {
                                keyboardManager.toggleWheelMode()
                            }
                        )
                        .scaleEffect(0.96)
                    }
                    .padding(.horizontal, 8)

                    // 3. SEÇİLİ TUŞA MAKRO ATAMA KONTROL KARTI
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SEÇİLİ TUŞ:")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            HStack(spacing: 6) {
                                Text(selectedKeyDef?.primaryLabel.isEmpty == true ? "SPACE" : (selectedKeyDef?.primaryLabel ?? "YUKARI OK"))
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                                Text("(\(selectedKeyDef?.id ?? "UP"))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider().frame(height: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("DÜZEN KATMANI:")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Picker("", selection: $selectedLayer) {
                                Text("Varsayılan (Base)").tag(UInt8(0))
                                Text("FN1").tag(UInt8(1))
                                Text("FN2 (Önerilen)").tag(UInt8(2))
                                Text("Dokun (Tap)").tag(UInt8(3))
                            }
                            .labelsHidden()
                            .controlSize(.small)
                        }

                        Spacer()

                        Button(action: {
                            assignMacroToSelectedKey()
                        }) {
                            Label("Bu Tuşa Ata (Assign)", systemImage: "link")
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)

                        Button(action: {
                            clearSelectedKeyAssignment()
                        }) {
                            Label("Sıfırla", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                    .padding(14)
                    .frame(maxWidth: 710)
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .padding(.horizontal, 24)

                    // 4. EYLEM SIRALAMASI & GECİKME ÇİZELGESİ (4-BYTE ACTION TUPLES)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("EYLEM SIRALAMASI & GECİKME ÇİZELGESİ (4-BYTE ACTION TUPLES)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1.0)
                            Spacer()
                            Text("\(currentMacro.actions.count) Adım")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(currentMacro.actions.indices, id: \.self) { aIdx in
                                    let action = currentMacro.actions[aIdx]
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 4) {
                                            Image(systemName: action.isKeyDown ? "arrow.down.circle.fill" : "arrow.up.circle")
                                                .foregroundColor(action.isKeyDown ? .green : .orange)
                                                .font(.system(size: 13))
                                            Text(HIDKeyHelper.name(for: action.hidCode))
                                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        }

                                        HStack {
                                            Text("\(action.delayMs) ms")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color(red: 0.98, green: 0.18, blue: 0.38))
                                            Text(action.isKeyDown ? "Basıldı" : "Bırakıldı")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }

                                        Text(String(format: "0x%04X 0x%02X 0x%02X", action.delayMs, action.hidCode, action.isKeyDown ? 0x80 : 0x00))
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.secondary.opacity(0.7))
                                    }
                                    .padding(12)
                                    .frame(minWidth: 120)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: 710)
                    .padding(.horizontal, 24)

                    // 5. DÖNGÜ VE TETİKLEME MODU KARTI
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DÖNGÜ VE TETİKLEME MODU")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.0)

                        VStack(spacing: 8) {
                            HStack {
                                RadioButton(isSelected: currentMacro.loopMode == 1) {
                                    setLoopMode(1)
                                }
                                Text(loc.tr("tc_macro_msg17", default: "Döngü Sayısı"))
                                    .font(.system(size: 13))
                                Spacer()
                                Stepper("\(currentMacro.loopCount) Kez", value: Binding(
                                    get: { currentMacro.loopCount },
                                    set: { setLoopCount($0) }
                                ), in: 1...255)
                                .disabled(currentMacro.loopMode != 1)
                            }

                            Divider().background(Color.white.opacity(0.06))

                            HStack {
                                RadioButton(isSelected: currentMacro.loopMode == 2) {
                                    setLoopMode(2)
                                }
                                Text(loc.tr("tc_macro_msg18", default: "Tuş Serbest Bırakılana Kadar Döngü"))
                                    .font(.system(size: 13))
                                Spacer()
                            }

                            Divider().background(Color.white.opacity(0.06))

                            HStack {
                                RadioButton(isSelected: currentMacro.loopMode == 3) {
                                    setLoopMode(3)
                                }
                                Text(loc.tr("tc_macro_msg19", default: "Herhangi Bir Tuşa Basılana Kadar Döngü"))
                                    .font(.system(size: 13))
                                Spacer()
                            }
                        }
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                    .frame(maxWidth: 710)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showNewMacroSheet) {
            VStack(spacing: 16) {
                Text(loc.tr("tc_macro_msg2", default: "Yeni Makro Oluştur"))
                    .font(.headline)

                TextField("Makro Adı (örn: Fast-Buy)", text: $newMacroName)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("İptal") {
                        showNewMacroSheet = false
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Oluştur") {
                        if !newMacroName.isEmpty {
                            let newSlot = UInt8(macros.count)
                            let newMacro = MacroItem(
                                macroSlot: newSlot,
                                name: newMacroName,
                                folder: "Genel",
                                loopMode: 1,
                                loopCount: 1,
                                actions: [
                                    KeyboardCommand.HardwareMacroAction(hidCode: 0x04, isKeyDown: true, delayMs: 100),
                                    KeyboardCommand.HardwareMacroAction(hidCode: 0x04, isKeyDown: false, delayMs: 50)
                                ]
                            )
                            macros.append(newMacro)
                            selectedMacroIndex = macros.count - 1
                            newMacroName = ""
                            showNewMacroSheet = false
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(width: 320)
        }
    }

    private func setLoopMode(_ mode: Int) {
        if selectedMacroIndex < macros.count {
            macros[selectedMacroIndex].loopMode = mode
        }
    }

    private func setLoopCount(_ count: Int) {
        if selectedMacroIndex < macros.count {
            macros[selectedMacroIndex].loopCount = count
        }
    }

    // Makroyu doğrudan klavyenin hafıza çipine yazar (06 05)
    private func uploadCurrentMacroToKeyboard() {
        let macro = currentMacro
        let ok = keyboardManager.saveMacroToKeyboard(
            macroIndex: macro.macroSlot,
            name: macro.name,
            actions: macro.actions
        )
        if ok {
            withAnimation {
                statusFeedback = "✅ '\(macro.name)' makrosu klavye çipine başarıyla kaydedildi!"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation { statusFeedback = nil }
            }
        }
    }

    // Seçilen tuşa makroyu atar (06 03)
    private func assignMacroToSelectedKey() {
        guard let keyDef = selectedKeyDef else { return }
        let macro = currentMacro
        let macroId = macro.macroSlot + 1
        let loopCountByte = UInt8(min(255, max(1, macro.loopCount)))
        let ok = keyboardManager.assignMacroToKey(
            layer: selectedLayer,
            keyIndex: keyDef.matrixIndex,
            macroId: macroId,
            loopCount: loopCountByte
        )
        if ok {
            assignedMacroMap[keyDef.id] = macro.name
            withAnimation {
                statusFeedback = "🔗 '\(macro.name)' makrosu '\(keyDef.primaryLabel.isEmpty ? keyDef.id : keyDef.primaryLabel)' tuşuna başarıyla atandı!"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation { statusFeedback = nil }
            }
        }
    }

    // Tuş atamasını sıfırlar (06 03)
    private func clearSelectedKeyAssignment() {
        guard let keyDef = selectedKeyDef else { return }
        let ok = keyboardManager.clearKeyAssignment(
            layer: selectedLayer,
            keyIndex: keyDef.matrixIndex
        )
        if ok {
            assignedMacroMap.removeValue(forKey: keyDef.id)
            withAnimation {
                statusFeedback = "🧹 '\(keyDef.primaryLabel.isEmpty ? keyDef.id : keyDef.primaryLabel)' tuş ataması varsayılana sıfırlandı."
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation { statusFeedback = nil }
            }
        }
    }
}

// Radyo Buton Yardımcısı
struct RadioButton: View {
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(isSelected ? Color(red: 0.98, green: 0.18, blue: 0.38) : Color.secondary.opacity(0.5), lineWidth: 2)
                    .frame(width: 16, height: 16)
                if isSelected {
                    Circle()
                        .fill(Color(red: 0.98, green: 0.18, blue: 0.38))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
