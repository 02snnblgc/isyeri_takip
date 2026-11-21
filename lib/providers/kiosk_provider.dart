import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../core/utils/tarih_util.dart';
import '../models/fazla_mesai.dart';
import '../models/kayit.dart';
import '../models/personel.dart';
import '../models/vardiya.dart';
import '../services/db_service.dart';
import '../services/mesai_hesap_service.dart';
import '../services/ses_service.dart';

enum KioskDurum { basarili, gec, hata, mukerrer, yok }

class KioskSonuc {
  final KioskDurum durum;
  final String baslik;
  final String? altYazi;
  final String? personelAd;
  final String? islem;
  KioskSonuc({
    required this.durum,
    required this.baslik,
    this.altYazi,
    this.personelAd,
    this.islem,
  });
}

class KioskProvider extends ChangeNotifier {
  KioskSonuc? _sonuc;
  Timer? _sonucTimer;

  int _iceridekiSayisi = 0;
  int _gelmeyenSayisi = 0;
  int _erkenCikanSayisi = 0;

  KioskSonuc? get sonuc => _sonuc;
  int get iceridekiSayisi => _iceridekiSayisi;
  int get gelmeyenSayisi => _gelmeyenSayisi;
  int get erkenCikanSayisi => _erkenCikanSayisi;

  Future<void> kartOkundu(String uid) async {
    final simdi = DateTime.now();
    final tarih = TarihUtil.tarihStr(simdi);
    final saat = TarihUtil.saatStr(simdi);

    final personel = await DbService.instance.personelKartUidIle(uid);
    if (personel == null) {
      _goster(KioskSonuc(
        durum: KioskDurum.hata,
        baslik: 'Kart tanınmadı',
        altYazi: 'Bu kart sisteme tanımlı değil.\nUID: $uid',
      ));
      await SesService.instance.cal(KioskSes.hata);
      return;
    }

    final vardiyaId = personel.ozelVardiyaId ?? personel.vardiyaId;
    final vardiyalar = await DbService.instance.vardiyalariGetir();
    Vardiya? vardiya;
    try {
      vardiya = vardiyalar.firstWhere((v) => v.id == vardiyaId);
    } catch (_) {
      vardiya = null;
    }
    if (vardiya == null) {
      _goster(KioskSonuc(
        durum: KioskDurum.hata,
        baslik: 'Vardiya tanımsız',
        altYazi: '${personel.adSoyad} için vardiya atanmamış.',
        personelAd: personel.adSoyad,
      ));
      await SesService.instance.cal(KioskSes.hata);
      return;
    }

    final mukerrer = await DbService.instance.sonOkutmaMukerrer(
        personel.id!, saniye: AppConstants.mukerrerOkutmaSaniye);
    if (mukerrer) {
      _goster(KioskSonuc(
        durum: KioskDurum.mukerrer,
        baslik: 'Zaten okutuldu',
        altYazi:
            'Lütfen ${AppConstants.mukerrerOkutmaSaniye} saniye bekleyin.',
        personelAd: personel.adSoyad,
      ));
      await SesService.instance.cal(KioskSes.uyari);
      await _ozetYenile(tarih);
      return;
    }

    final acik = await DbService.instance.acikGirisGetir(personel.id!);
    if (acik != null && acik.tarih == tarih) {
      await _cikisIsle(personel, vardiya, acik, tarih, saat);
      await _ozetYenile(tarih);
      return;
    }

    await _girisIsle(personel, vardiya, tarih, saat);
    await _ozetYenile(tarih);
  }

  Future<void> _girisIsle(
      Personel p, Vardiya v, String tarih, String saat) async {
    final (girisDurum, gecikme) =
        MesaiHesapService.instance.girisDegerlendir(saat, v);
    final durum = girisDurum == GirisDurum.gec
        ? AppConstants.durumGec
        : AppConstants.durumNormal;

    await DbService.instance.kayitEkle(Kayit(
      personelId: p.id!,
      tarih: tarih,
      girisSaati: saat,
      durum: durum,
      olusturmaTs: DateTime.now().toIso8601String(),
    ));
    await DbService.instance.auditYaz(
        null, 'kiosk_giris', '${p.adSoyad} ($saat)');

    if (girisDurum == GirisDurum.gec) {
      _goster(KioskSonuc(
        durum: KioskDurum.gec,
        baslik: 'GEÇ GİRİŞ',
        altYazi: '$gecikme dk gecikme • Giriş: $saat',
        personelAd: p.adSoyad,
        islem: 'giris',
      ));
      await SesService.instance.cal(KioskSes.uyari);
    } else {
      _goster(KioskSonuc(
        durum: KioskDurum.basarili,
        baslik: 'GİRİŞ BAŞARILI',
        altYazi: 'Saat: $saat',
        personelAd: p.adSoyad,
        islem: 'giris',
      ));
      await SesService.instance.cal(KioskSes.basarili);
    }
  }

  Future<void> _cikisIsle(Personel p, Vardiya v, Kayit acik,
      String tarih, String saat) async {
    final (cikisDurum, erken) =
        MesaiHesapService.instance.cikisDegerlendir(saat, v);
    final fazlaDk = MesaiHesapService.instance.fazlaMesaiDakika(saat, v);

    var yeniDurum = acik.durum;
    if (cikisDurum == CikisDurum.erken) {
      yeniDurum = AppConstants.durumErkenCikis;
    }

    await DbService.instance.kayitGuncelle(
        acik.copyWith(cikisSaati: saat, durum: yeniDurum));
    await DbService.instance.auditYaz(
        null, 'kiosk_cikis', '${p.adSoyad} ($saat)');

    if (fazlaDk > 0) {
      await DbService.instance.fazlaMesaiEkle(FazlaMesai(
        personelId: p.id!,
        tarih: tarih,
        dakika: fazlaDk,
        kaynak: 'otomatik',
      ));
    }

    if (cikisDurum == CikisDurum.erken) {
      _goster(KioskSonuc(
        durum: KioskDurum.gec,
        baslik: 'ERKEN ÇIKIŞ',
        altYazi: '$erken dk erken • Çıkış: $saat',
        personelAd: p.adSoyad,
        islem: 'cikis',
      ));
      await SesService.instance.cal(KioskSes.uyari);
    } else {
      final alt = fazlaDk > 0
          ? 'Saat: $saat • Fazla mesai: $fazlaDk dk'
          : 'Saat: $saat';
      _goster(KioskSonuc(
        durum: KioskDurum.basarili,
        baslik: 'ÇIKIŞ BAŞARILI',
        altYazi: alt,
        personelAd: p.adSoyad,
        islem: 'cikis',
      ));
      await SesService.instance.cal(KioskSes.basarili);
    }
  }

  void _goster(KioskSonuc s) {
    _sonuc = s;
    notifyListeners();
    _sonucTimer?.cancel();
    _sonucTimer = Timer(
      const Duration(seconds: AppConstants.kioskFeedbackSaniye),
      () {
        _sonuc = null;
        notifyListeners();
      },
    );
  }

  Future<void> _ozetYenile(String tarih) async {
    try {
      _iceridekiSayisi = await DbService.instance.iceridekiSayisi(tarih);
      _erkenCikanSayisi = await DbService.instance.erkenCikanSayisi(tarih);
      // Doğru "gelmeyen": tatil + izin hariç
      final gelmeyenler = await DbService.instance.bugunGelmeyenler(tarih);
      _gelmeyenSayisi = gelmeyenler.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Özet yenileme hatası: $e');
    }
  }

  Future<void> ozetYenileDisaridan() async {
    await _ozetYenile(TarihUtil.tarihStr(DateTime.now()));
  }

  @override
  void dispose() {
    _sonucTimer?.cancel();
    super.dispose();
  }
}
