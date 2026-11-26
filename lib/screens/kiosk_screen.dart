import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/kiosk_provider.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';
import '../services/nfc_service.dart';
import '../widgets/ozet_panel_widget.dart';
import '../widgets/saat_widget.dart';
import 'ana_screen.dart'; // Yönetici paneline geçiş için gerekli

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});
  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final kp = context.read<KioskProvider>();
      await kp.ozetYenileDisaridan();
      await NfcService.instance.baslatKiosk((uid) {
        kp.kartOkundu(uid);
      });
    });
  }

  @override
  void dispose() {
    NfcService.instance.durdurKiosk();
    WakelockPlus.disable();
    super.dispose();
  }

  Color _durumRenk(KioskDurum d) => switch (d) {
        KioskDurum.basarili => Colors.green.shade600,
        KioskDurum.gec => Colors.red.shade600,
        KioskDurum.hata => Colors.red.shade800,
        KioskDurum.mukerrer => Colors.orange.shade700,
        KioskDurum.yok => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    final kp = context.watch<KioskProvider>();
    final sonuc = kp.sonuc;
    final overlayAktif = sonuc != null && sonuc.durum != KioskDurum.yok;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: SaatWidget(buyuk: true, renk: Colors.white),
                      ),
                      // YÖNETİCİ GİRİŞ BUTONU
                      IconButton.filledTonal(
                        tooltip: 'Yönetici Girişi',
                        onPressed: _cikisOnay,
                        icon: const Icon(Icons.admin_panel_settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OzetPanelWidget(
                    icerideki: kp.iceridekiSayisi,
                    gelmeyen: kp.gelmeyenSayisi,
                    erkenCikan: kp.erkenCikanSayisi,
                    onRenk: Colors.white,
                  ),
                  const Spacer(),
                  Container(
                    width: 180, height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: const Icon(Icons.nfc,
                        size: 100, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  const Text('Kartınızı okutun',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 8),
                  Text('Telefonun arka yüzeyine yaklaştırın',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      )),
                  const Spacer(),
                  Text('NFC hazır',
                      style: TextStyle(
                        color: Colors.green.shade300,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
          ),

          if (overlayAktif)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  color: _durumRenk(sonuc.durum),
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              sonuc.durum == KioskDurum.basarili
                                  ? Icons.check_circle
                                  : sonuc.durum == KioskDurum.mukerrer
                                      ? Icons.info
                                      : Icons.warning_amber_rounded,
                              size: 110, color: Colors.white),
                            const SizedBox(height: 14),
                            if (sonuc.personelAd != null)
                              Text(sonuc.personelAd!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                  )),
                            const SizedBox(height: 12),
                            Text(sonuc.baslik,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                )),
                            if (sonuc.altYazi != null) ...[
                              const SizedBox(height: 8),
                              Text(sonuc.altYazi!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _cikisOnay() async {
    final kadiCtrl = TextEditingController(text: 'admin'); // Varsayılan olarak admin yazılı gelsin
    final parolaCtrl = TextEditingController();
    bool hatali = false;
    String hataMesaji = '';

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Yönetici Girişi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Yönetici paneline geçmek için bilgilerinizi girin.'),
              const SizedBox(height: 12),
              TextField(
                controller: kadiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: parolaCtrl,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Parola',
                  border: const OutlineInputBorder(),
                  errorText: hatali ? hataMesaji : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                // Kullanıcı adı ve parolayı doğrudan AuthProvider'a gönderiyoruz.
                final basarili = await auth.giris(kadiCtrl.text.trim(), parolaCtrl.text);
                if (basarili) {
                  Navigator.pop(ctx, true);
                } else {
                  setStateDialog(() {
                    hatali = true;
                    hataMesaji = auth.hata ?? 'Hatalı giriş';
                  });
                }
              },
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
    
    kadiCtrl.dispose();
    parolaCtrl.dispose();
    
    if (ok == true && mounted) {
      // Başarılı girişte Yönetici Paneline (AnaScreen) geç
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AnaScreen()),
      );
    }
  }
}
