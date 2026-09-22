<p align="center">
  <img src="inca-klavye/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" width="120" alt="Inca Empousa"/>
</p>

<h1 align="center">Inca Empousa IKG-455 — macOS Driver</h1>

<p align="center">
  <strong>Hobi amaçlı, tersine mühendislik ile geliştirilmiş gayri resmi macOS sürücüsü</strong><br>
  Unofficial macOS driver built through reverse engineering · Hall-Effect Magnetic Axis Keyboard
</p>

<p align="center">
  <a href="https://github.com/ismailcanuslu/Inca-KB455-MacOS-Driver/releases/latest">
    <img src="https://img.shields.io/github/v/release/ismailcanuslu/Inca-KB455-MacOS-Driver?label=Son%20S%C3%BCr%C3%BCm&style=flat-square&color=ff2d55" alt="Latest Release"/>
  </a>
  <img src="https://img.shields.io/badge/macOS-14%2B-brightgreen?style=flat-square" alt="macOS 14+"/>
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square" alt="Swift"/>
  <img src="https://img.shields.io/badge/Durum-Beta-yellow?style=flat-square" alt="Beta"/>
  <img src="https://img.shields.io/badge/Lisans-MIT-blue?style=flat-square" alt="MIT License"/>
</p>

---

## ⚠️ Bilinen Sorunlar — Lütfen Önce Okuyun!

> **Bu uygulama beta aşamasındadır. Kullanmadan önce aşağıdaki sorunları dikkatlice okuyun.**

| Sorun | Etki | Durum |
|-------|------|--------|
| 🔴 **2.4G alıcı klavyeyi bozabilir** | Klavye soft-brick olabilir, fabrika sıfırlaması gerekebilir | Aktif geliştirme |
| 🟡 Pil yüzdesi doğru gösterilmiyor | Gerçek değerden farklı bir yüzde görünebilir | Araştırılıyor |
| 🟡 Knob modu otomatik güncellenmiyor | Uygulama yeniden başlatılana kadar eski mod gösterilir | Araştırılıyor |
| 🟡 Mac / Windows mod algılama hatalı | Klavye modunu değiştirince UI güncellenmeyebilir | Araştırılıyor |
| 🔵 Hassasiyet (actuation) ayarı yok | Orijinal Windows yazılımında da bu özellik klavyeyi bug'a soktuğundan eklenmedi | Bilinçli karar |

### 🔌 Bağlantı Önerisi

```
✅ Type-C USB  → Tüm özellikler desteklenir. BUNU KULLANIN.
🚫 2.4G Kablosuz → GELİŞTİRME AŞAMASINDA. KULLANMAYIN!
   Klavyenizi soft-brick edebilir ve fabrika sıfırlaması gerektirebilir.
```

---

## 🔬 Bu Proje Nedir?

Inca Empousa IKG-455 için **hobi amaçlı** geliştirilmiş **gayri resmi** macOS sürücüsüdür. Inca'nın bu klavye için resmi macOS sürücüsü bulunmuyor — ama klavyeyi çok sevdiğim için kendi sürücümü geliştirdim.

### Teknik Temel

- 📦 **USB Paket Analizi** — Orijinal Windows sürücüsü (`OemDrv.exe`) ile klavye arasındaki HID iletişimi Wireshark/usbpcap ile sniff edildi
- 🔍 **Ghidra ile Tersine Mühendislik** — `OemDrv.exe` ve `KB.ini` analiz edilerek Feature Report formatları, LedOpt komut yapısı ve protokol dizisi çözüldü
- 🎨 **Sıfırdan macOS UI** — Apple Music ve macOS Liquid Glass tasarım dilinden ilham alınarak SwiftUI ile tamamen yazıldı

---

## ✨ Özellikler

- 🎨 **18 Donanım Aydınlatma Efekti** — Gökkuşağı, Nefes Alma, Dalgalı Parıltı, Reaktif ve daha fazlası
- 🖌️ **Kişisel Tuş Matrisi (LedOpt 19)** — 126 tuşun tamamını bağımsız renklendir
- 🌈 **Çok Renkli Mod** — Destekleyen efektlerde gökkuşağı spektrumu
- 🎵 **Müzik Ritim Senkronizasyonu** — 10 donanımsal ritim modu
- ⌨️ **Makro Stüdyosu** — Donanımsal makro atama
- 📺 **TFT Ekran Kontrolü** — GIF ve özel görseller
- 🔋 **Canlı Batarya Durumu**
- 🌍 **Türkçe / İngilizce / Almanca**
- 💾 **Dynamic Island Kayıt Sistemi** — Değişiklikleri klavye EEPROM'una yaz / geri al

---

## 📥 Kurulum

1. [Releases](https://github.com/ismailcanuslu/Inca-KB455-MacOS-Driver/releases) sayfasından en son `.dmg` dosyasını indirin
2. DMG'yi açın, `Inca Empousa.app`'i **Applications** klasörüne sürükleyin
3. İlk açılışta: **Sistem Ayarları → Gizlilik ve Güvenlik → Giriş İzleme** → Inca Empousa'ya izin verin
4. Klavyeyi **Type-C USB** ile bağlayın

> **Gatekeeper uyarısı alırsanız:** Uygulama notarize edilmemiştir. `Ctrl + Tıkla → Aç` ile onaylayın.

---

## 🛠️ Geliştirme

**Gereksinimler:** Xcode 15+, macOS 14+, Swift 5.9

```bash
git clone https://github.com/ismailcanuslu/Inca-KB455-MacOS-Driver.git
cd Inca-KB455-MacOS-Driver
open inca-klavye.xcodeproj
```

---

## 🗺️ Yol Haritası

- [ ] 2.4G kablosuz kararlı destek
- [ ] Bluetooth desteği
- [ ] Pil yüzdesi doğru okuma
- [ ] Gerçek zamanlı mod senkronizasyonu (Mac/Win/Knob)
- [ ] Profil kaydetme / bulut senkronizasyonu
- [ ] Notarization

---

## ⚖️ Yasal Uyarı

Bu proje Inca ile hiçbir resmi bağlantısı olmayan bağımsız bir hobi projesidir. Tersine mühendislik yalnızca birlikte çalışabilirlik amacıyla yapılmıştır. Kullanım tamamen kendi sorumluluğunuzdadır.

---

<p align="center">
  Made with ❤️ for the Inca Empousa IKG-455 community<br>
  <sub>Packet sniffing + Ghidra + SwiftUI + çok kahve ☕</sub>
</p>
