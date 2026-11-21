import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tema_provider.dart';
import '../../core/constants.dart';
import '../izin/izin_yonetim_screen.dart';
import '../rapor/kayit_liste_screen.dart';
import 'audit_log_screen.dart';
import 'parola_degistir_screen.dart';
import 'tatil_yonetim_screen.dart';
import 'vardiya_yonetim_screen.dart';
import 'yedek_screen.dart';

class AyarlarScreen extends StatelessWidget {
  const AyarlarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _baslik(context, 'Yönetim'),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Vardiya Yönetimi'),
          subtitle: const Text('Vardiya ekle/düzenle/sil'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const VardiyaYonetimScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.beach_access),
          title: const Text('Tatil Yönetimi'),
          subtitle: const Text('Resmi tatil ve hafta sonu kuralları'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const TatilYonetimScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.event_busy),
          title: const Text('İzin / Rapor Yönetimi'),
          subtitle: const Text('Yıllık izin, rapor, mazeret'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const IzinYonetimScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.edit_note),
          title: const Text('Kayıt Düzeltme'),
          subtitle: const Text('Açık girişleri manuel kapat'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const KayitListeScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Denetim Günlüğü'),
          subtitle: const Text('Kim, ne zaman, ne yaptı?'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const AuditLogScreen())),
        ),
        const Divider(),
        _baslik(context, 'Veri'),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Yedekleme'),
          subtitle: const Text('Dışa / içe aktar (JSON)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const YedekScreen())),
        ),
        const Divider(),
        _baslik(context, 'Görünüm'),
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: const Text('Tema Modu'),
          subtitle: Text(switch (tema.mod) {
            ThemeMode.light => 'Açık',
            ThemeMode.dark => 'Koyu',
            _ => 'Sistem',
          }),
          trailing: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto)),
            ],
            selected: {tema.mod},
            onSelectionChanged: (s) => tema.modDegistir(s.first),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Pastel Renk'),
          subtitle: Text(AppConstants.pastelAdlari[tema.pastelIndex]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            children: [
              for (int i = 0; i < AppConstants.pastelRenkler.length; i++)
                GestureDetector(
                  onTap: () => tema.pastelDegistir(i),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppConstants.pastelRenkler[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == tema.pastelIndex
                            ? Colors.black54
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: i == tema.pastelIndex
                        ? const Icon(Icons.check, size: 20)
                        : null,
                  ),
                ),
            ],
          ),
        ),
        const Divider(),
        _baslik(context, 'Hesap'),
        ListTile(
          leading: const Icon(Icons.person),
          title: Text(context.watch<AuthProvider>().kullanici?.kullaniciAdi ?? '-'),
          subtitle: Text(
              'Rol: ${context.watch<AuthProvider>().kullanici?.rol ?? '-'}'),
        ),
        ListTile(
          leading: const Icon(Icons.lock_reset),
          title: const Text('Parola Değiştir'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const ParolaDegistirScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          onTap: () => context.read<AuthProvider>().cikis(),
        ),
        const SizedBox(height: 30),
        Center(
          child: Text('İşyeri Takip v0.6.0',
              style: TextStyle(
                  fontSize: 11, color: Theme.of(context).hintColor)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _baslik(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
        child: Text(t,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            )),
      );
}
