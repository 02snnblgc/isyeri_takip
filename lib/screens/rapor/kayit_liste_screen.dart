import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/tarih_util.dart';
import '../../providers/auth_provider.dart';
import '../../services/db_service.dart';

class KayitListeScreen extends StatefulWidget {
  const KayitListeScreen({super.key});
  @override
  State<KayitListeScreen> createState() => _KayitListeScreenState();
}

class _KayitListeScreenState extends State<KayitListeScreen> {
  DateTimeRange? _aralik;
  List<Map<String, dynamic>> _kayitlar = [];
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _aralik = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
    _yukle();
  }

  Future<void> _yukle() async {
    if (_aralik == null) return;
    setState(() => _yukleniyor = true);
    try {
      _kayitlar = await DbService.instance.kayitlariGetir(
        baslangic: TarihUtil.tarihStr(_aralik!.start),
        bitis: TarihUtil.tarihStr(_aralik!.end),
      );
    } catch (e) {
      debugPrint('Kayıt yükleme hatası: $e');
    }
    setState(() => _yukleniyor = false);
  }

  Future<void> _aralikSec() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _aralik,
    );
    if (r != null) {
      setState(() => _aralik = r);
      _yukle();
    }
  }

  Future<void> _acikGirisiKapat(Map<String, dynamic> k) async {
    final kayitId = k['id'] as int;
    final adSoyad = k['ad_soyad'] as String? ?? 'Personel';
    final tarih = k['tarih'] as String;
    final giris = k['giris_saati'] as String? ?? '-';

    TimeOfDay secilen = const TimeOfDay(hour: 17, minute: 0);
    final notCtrl = TextEditingController(text: 'Kart okutmayı unuttu');

    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Çıkış saatini manuel gir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$adSoyad • $tarih • Giriş: $giris'),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Çıkış saati'),
                subtitle: Text(
                    '${secilen.hour.toString().padLeft(2, '0')}:${secilen.minute.toString().padLeft(2, '0')}'),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final t = await showTimePicker(
                        context: ctx, initialTime: secilen);
                    if (t != null) setS(() => secilen = t);
                  },
                ),
              ),
              TextField(
                controller: notCtrl,
                decoration: const InputDecoration(labelText: 'Not'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Vazgeç')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Kaydet')),
          ],
        ),
      ),
    );

    if (onay == true) {
      final cikis =
          '${secilen.hour.toString().padLeft(2, '0')}:${secilen.minute.toString().padLeft(2, '0')}:00';
      final kullaniciId = context.read<AuthProvider>().kullanici?.id;
      await DbService.instance.acikGirisiManuelKapat(
        kayitId: kayitId,
        yeniCikisSaati: cikis,
        not: notCtrl.text.trim().isEmpty ? null : notCtrl.text.trim(),
        kullaniciId: kullaniciId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çıkış saati manuel olarak kaydedildi.')),
        );
        _yukle();
      }
    }
    notCtrl.dispose();
  }

  Future<void> _kayitDuzenle(Map<String, dynamic> k) async {
    final kayitId = k['id'] as int;
    final adSoyad = k['ad_soyad'] as String? ?? 'Personel';
    final giris = k['giris_saati'] as String?;
    final cikis = k['cikis_saati'] as String?;

    final girisCtrl = TextEditingController(text: giris ?? '');
    final cikisCtrl = TextEditingController(text: cikis ?? '');
    final notCtrl = TextEditingController(text: k['duzeltme_notu'] as String? ?? '');

    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Kaydı Düzenle — $adSoyad'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tarih: ${k['tarih']}'),
              const SizedBox(height: 8),
              TextField(
                controller: girisCtrl,
                decoration: const InputDecoration(
                  labelText: 'Giriş (HH:mm:ss)',
                  hintText: '08:05:00',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cikisCtrl,
                decoration: const InputDecoration(
                  labelText: 'Çıkış (HH:mm:ss)',
                  hintText: '17:10:00',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notCtrl,
                decoration: const InputDecoration(labelText: 'Düzeltme notu'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet')),
        ],
      ),
    );

    if (onay == true) {
      final kullaniciId = context.read<AuthProvider>().kullanici?.id;
      await DbService.instance.kayitManuelGuncelle(
        kayitId: kayitId,
        yeniGiris: girisCtrl.text.trim().isEmpty ? null : girisCtrl.text.trim(),
        yeniCikis: cikisCtrl.text.trim().isEmpty ? null : cikisCtrl.text.trim(),
        not: notCtrl.text.trim().isEmpty ? null : notCtrl.text.trim(),
        kullaniciId: kullaniciId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt güncellendi.')),
        );
        _yukle();
      }
    }
    girisCtrl.dispose();
    cikisCtrl.dispose();
    notCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Listesi / Düzeltme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Tarih aralığı',
            onPressed: _aralikSec,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_aralik != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.date_range),
                  title: Text(
                      '${TarihUtil.tarihStr(_aralik!.start)} → ${TarihUtil.tarihStr(_aralik!.end)}'),
                  subtitle: Text('${_kayitlar.length} kayıt'),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _yukle,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : _kayitlar.isEmpty
                    ? const Center(child: Text('Kayıt bulunamadı.'))
                    : ListView.separated(
                        itemCount: _kayitlar.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final k = _kayitlar[i];
                          final acik = k['giris_saati'] != null &&
                              k['cikis_saati'] == null;
                          final durum = k['durum'] as String? ?? '';
                          return ListTile(
                            leading: Icon(
                              acik ? Icons.lock_open : Icons.check,
                              color: acik ? Colors.orange : Colors.green,
                            ),
                            title: Text(k['ad_soyad'] as String? ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${k['tarih']} • Giriş: ${k['giris_saati'] ?? '-'} • Çıkış: ${k['cikis_saati'] ?? '-'} • $durum',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'kapat') _acikGirisiKapat(k);
                                if (v == 'duzenle') _kayitDuzenle(k);
                              },
                              itemBuilder: (_) => [
                                if (acik)
                                  const PopupMenuItem(
                                    value: 'kapat',
                                    child: ListTile(
                                      leading: Icon(Icons.lock),
                                      title: Text('Çıkışı manuel kapat'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'duzenle',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Kaydı düzenle'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}