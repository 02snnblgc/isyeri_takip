# İşyeri Personel Takip

Çevrimdışı çalışan, NFC ile çipli kimlik kartı okuyan, yönetici girişli personel giriş-çıkış takip uygulaması.

## Özellikler

- ✅ %100 çevrimdışı (SQLite)
- ✅ Yönetici girişi (SHA-256 + salt)
- ✅ NFC ile kart tanımlama ve kiosk okutma
- ✅ Çoklu vardiya + gece vardiyası desteği
- ✅ Tolerans ayarlı geç/erken çıkış tespiti
- ✅ Otomatik fazla mesai hesabı
- ✅ İzin / rapor / mazeret yönetimi
- ✅ Resmi tatil ve hafta sonu kuralları
- ✅ Manuel kayıt düzeltme (açık giriş kapatma)
- ✅ PDF + Excel rapor
- ✅ JSON yedekleme (dışa / içe)
- ✅ Denetim günlüğü (audit log)
- ✅ Dark/Light + 5 pastel tema
- ✅ Kiosk modunda sesli/görsel geri bildirim + canlı özet
- ✅ Wakelock (kiosk ekranı kapanmaz)
- ✅ Mükerrer okutma engeli (60 sn)

## Kurulum

### Gereksinimler
- Flutter 3.24+
- Android 8.0+ (NFC destekli cihaz)
- Android Studio veya VS Code

### Adımlar

```bash
git clone <repo-url>
cd isyeri_takip
flutter pub get