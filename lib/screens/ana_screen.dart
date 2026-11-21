import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/kiosk_provider.dart';
import '../widgets/saat_widget.dart';
import 'ayarlar/ayarlar_screen.dart';
import 'kiosk_screen.dart';
import 'personel/personel_liste_screen.dart';
import 'rapor/rapor_screen.dart';

class AnaScreen extends StatefulWidget {
  const AnaScreen({super.key});
  @override
  State<AnaScreen> createState() => _AnaScreenState();
}

class _AnaScreenState extends State<AnaScreen> {
  int _index = 0;

  Future<void> _kioskAc() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => const KioskScreen(),
      fullscreenDialog: true,
    ));
    if (!mounted) return;
    context.read<KioskProvider>().ozetYenileDisaridan();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kp = context.watch<KioskProvider>();

    final sayfalar = <Widget>[
      _PanelTab(onKiosk: _kioskAc, kp: kp),
      const PersonelListeScreen(),
      const RaporScreen(),
      const AyarlarScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_index) {
          0 => 'Panel',
          1 => 'Personeller',
          2 => 'Rapor',
          _ => 'Ayarlar',
        }),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Center(
              child: Text(auth.kullanici?.kullaniciAdi ?? '',
                  style: const TextStyle(fontSize: 12)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
            onPressed: () => context.read<AuthProvider>().cikis(),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: sayfalar),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Panel'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Personel'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Rapor'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}

class _PanelTab extends StatefulWidget {
  final VoidCallback onKiosk;
  final KioskProvider kp;
  const _PanelTab({required this.onKiosk, required this.kp});

  @override
  State<_PanelTab> createState() => _PanelTabState();
}

class _PanelTabState extends State<_PanelTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.kp.ozetYenileDisaridan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Center(child: SaatWidget(buyuk: true)),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _sayac(context, 'İçeride',
                          widget.kp.iceridekiSayisi, Colors.green),
                      _sayac(context, 'Gelmeyen',
                          widget.kp.gelmeyenSayisi, Colors.orange),
                      _sayac(context, 'Erken Çıkan',
                          widget.kp.erkenCikanSayisi, Colors.red),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Kiosk açıkken canlı güncellenir',
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).hintColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            onPressed: widget.onKiosk,
            icon: const Icon(Icons.nfc, size: 28),
            label: const Text('Kiosk Modunu Aç',
                style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                context.read<KioskProvider>().ozetYenileDisaridan(),
            icon: const Icon(Icons.refresh),
            label: const Text('Özeti Yenile'),
          ),
        ],
      ),
    );
  }

  Widget _sayac(
      BuildContext context, String etiket, int deger, Color renk) {
    return Column(
      children: [
        Text('$deger',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: renk)),
        Text(etiket, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
