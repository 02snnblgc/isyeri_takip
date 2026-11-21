import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/izin.dart';
import '../../providers/izin_provider.dart';
import '../../core/utils/tarih_util.dart';

class IzinYonetimScreen extends StatefulWidget {
  const IzinYonetimScreen({super.key});
  @override
  State<IzinYonetimScreen> createState() => _IzinYonetimScreenState();
}

class _IzinYonetimScreenState extends State<IzinYonetimScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IzinProvider>().yukle();
    });
  }

  Future<void> _yeniIzin() async {
    final p = context.read<IzinProvider>();
    if (p.personeller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce personel ekleyin.')),
      );
      return;
    }

    int? seciliPersonel = p.personeller.first.id;
    String tur = 'yillik';
    DateTimeRange? aralik;
    final aciklamaCtrl = TextEditingController();

    final kaydet = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Yeni İzin / Rapor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: seciliPersonel,
                  decoration: const InputDecoration(labelText: 'Personel'),
                  items: p.personeller.map((e) => DropdownMenuItem(
                    value: e.id, child: Text(e.adSoyad))).toList(),
                  onChanged: (v) => setS(() => seciliPersonel = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: tur,
                  decoration: const InputDecoration(labelText: 'Tür'),
                  items: const [
                    DropdownMenuItem(value: 'yillik', child: Text('Yıllık İzin')),
                    DropdownMenuItem(value: 'rapor', child: Text('Rapor')),
                    DropdownMenuItem(value: 'mazeret', child: Text('Mazeret')),
                  ],
                  onChanged: (v) => setS(() => tur = v ?? 'yillik'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tarih aralığı'),
                  subtitle: Text(aralik == null
                      ? 'Seçilmedi'
                      : '${TarihUtil.tarihStr(aralik!.start)} → ${TarihUtil.tarihStr(aralik!.end)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final now = DateTime.now();
                      final r = await showDateRangePicker(
                        context: ctx,
                        firstDate: DateTime(now.year - 2),
                        lastDate: DateTime(now.year + 2),
                        initialDateRange: aralik,
                      );
                      if (r != null) setS(() => aralik = r);
                    },
                  ),
                ),
                TextField(
                  controller: aciklamaCtrl,
                  decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: (aralik == null || seciliPersonel == null)
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (kaydet == true && aralik != null && seciliPersonel != null) {
      final hata = await p.ekle(Izin(
        personelId: seciliPersonel!,
        baslangicTarih: TarihUtil.tarihStr(aralik!.start),
        bitisTarih: TarihUtil.tarihStr(aralik!.end),
        tur: tur,
        aciklama: aciklamaCtrl.text.trim().isEmpty ? null : aciklamaCtrl.text.trim(),
      ));
      if (!mounted) return;
      if (hata != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hata), backgroundColor: Colors.red));
      }
    }
    aciklamaCtrl.dispose();
  }

  String _turEtiket(String t) => switch (t) {
        'yillik' => 'Yıllık İzin',
        'rapor' => 'Rapor',
        'mazeret' => 'Mazeret',
        _ => t,
      };

  Color _turRenk(String t) => switch (t) {
        'yillik' => Colors.blue,
        'rapor' => Colors.red,
        'mazeret' => Colors.orange,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.watch<IzinProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('İzin / Rapor Yönetimi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _yeniIzin,
        icon: const Icon(Icons.add),
        label: const Text('Yeni İzin'),
      ),
      body: p.yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : p.izinler.isEmpty
              ? const Center(child: Text('Henüz izin kaydı yok.'))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: p.izinler.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final izin = p.izinler[i];
                    final renk = _turRenk(izin.tur);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: renk.withOpacity(0.15),
                        child: Icon(Icons.event_busy, color: renk),
                      ),
                      title: Text(p.personelAd(izin.personelId),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_turEtiket(izin.tur)} • ${izin.baslangicTarih} → ${izin.bitisTarih}'),
                          if (izin.aciklama != null && izin.aciklama!.isNotEmpty)
                            Text(izin.aciklama!,
                                style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('İzni sil?'),
                              content: const Text('Bu izin kaydı silinecek.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Vazgeç')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Sil')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await p.sil(izin.id!);
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}