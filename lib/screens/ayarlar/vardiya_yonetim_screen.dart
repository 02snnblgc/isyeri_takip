import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vardiya.dart';
import '../../providers/vardiya_provider.dart';

class VardiyaYonetimScreen extends StatefulWidget {
  const VardiyaYonetimScreen({super.key});
  @override
  State<VardiyaYonetimScreen> createState() => _VardiyaYonetimScreenState();
}

class _VardiyaYonetimScreenState extends State<VardiyaYonetimScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VardiyaProvider>().yukle();
    });
  }

  Future<void> _form({Vardiya? mevcut}) async {
    final p = context.read<VardiyaProvider>();
    final adCtrl = TextEditingController(text: mevcut?.ad ?? '');
    TimeOfDay baslangic = _toTime(mevcut?.baslangicSaat ?? '08:00');
    TimeOfDay bitis = _toTime(mevcut?.bitisSaat ?? '17:00');
    int toleransGiris = mevcut?.toleransGirisDk ?? 15;
    int toleransCikis = mevcut?.toleransCikisDk ?? 15;
    bool gece = mevcut?.geceVardiyasi ?? false;

    final kaydet = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(mevcut == null ? 'Yeni Vardiya' : 'Vardiyayı Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: adCtrl,
                  decoration: const InputDecoration(labelText: 'Vardiya Adı'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Başlangıç'),
                        subtitle: Text(_fmt(baslangic)),
                        onTap: () async {
                          final r = await showTimePicker(context: ctx, initialTime: baslangic);
                          if (r != null) setS(() => baslangic = r);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bitiş'),
                        subtitle: Text(_fmt(bitis)),
                        onTap: () async {
                          final r = await showTimePicker(context: ctx, initialTime: bitis);
                          if (r != null) setS(() => bitis = r);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text('Giriş toleransı: $toleransGiris dk')),
                    Slider(
                      value: toleransGiris.toDouble(),
                      min: 0, max: 60, divisions: 12,
                      label: '$toleransGiris dk',
                      onChanged: (v) => setS(() => toleransGiris = v.round()),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text('Çıkış toleransı: $toleransCikis dk')),
                    Slider(
                      value: toleransCikis.toDouble(),
                      min: 0, max: 60, divisions: 12,
                      label: '$toleransCikis dk',
                      onChanged: (v) => setS(() => toleransCikis = v.round()),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gece vardiyası'),
                  subtitle: const Text('Bitiş ertesi güne sarkar (örn. 22:00-06:00)'),
                  value: gece,
                  onChanged: (v) => setS(() => gece = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: adCtrl.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (kaydet == true) {
      final yeni = Vardiya(
        id: mevcut?.id,
        ad: adCtrl.text.trim(),
        baslangicSaat: _fmt(baslangic),
        bitisSaat: _fmt(bitis),
        toleransGirisDk: toleransGiris,
        toleransCikisDk: toleransCikis,
        geceVardiyasi: gece,
      );
      String? hata;
      if (mevcut == null) {
        hata = await p.ekle(yeni);
      } else {
        hata = await p.guncelle(yeni);
      }
      if (!mounted) return;
      if (hata != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hata), backgroundColor: Colors.red));
      }
    }
    adCtrl.dispose();
  }

  TimeOfDay _toTime(String hm) {
    final p = hm.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VardiyaProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Vardiya Yönetimi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Vardiya'),
      ),
      body: p.yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : p.vardiyalar.isEmpty
              ? const Center(child: Text('Vardiya yok.'))
              : ListView.separated(
                  itemCount: p.vardiyalar.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final v = p.vardiyalar[i];
                    return ListTile(
                      leading: Icon(v.geceVardiyasi ? Icons.nightlight : Icons.wb_sunny),
                      title: Text(v.ad, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${v.baslangicSaat} - ${v.bitisSaat} • Tolerans: +${v.toleransGirisDk}/-${v.toleransCikisDk} dk${v.geceVardiyasi ? ' • Gece' : ''}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (s) async {
                          if (s == 'duzenle') {
                            _form(mevcut: v);
                          } else if (s == 'sil') {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Vardiyayı sil?'),
                                content: Text('${v.ad} silinecek. Atanmış personel varsa etkilenebilir.'),
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
                            if (ok == true) await p.sil(v.id!);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'duzenle', child: Text('Düzenle')),
                          PopupMenuItem(value: 'sil', child: Text('Sil')),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}