import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/tarih_util.dart';
import '../../models/tatil.dart';
import '../../providers/tatil_provider.dart';

class TatilYonetimScreen extends StatefulWidget {
  const TatilYonetimScreen({super.key});
  @override
  State<TatilYonetimScreen> createState() => _TatilYonetimScreenState();
}

class _TatilYonetimScreenState extends State<TatilYonetimScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TatilProvider>().yukle();
    });
  }

  Future<void> _yeniTatil() async {
    final p = context.read<TatilProvider>();
    final adCtrl = TextEditingController();
    String tur = 'resmi';
    DateTime secili = DateTime.now();

    final kaydet = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Yeni Tatil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: adCtrl,
                  decoration: const InputDecoration(labelText: 'Tatil Adı'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: tur,
                  decoration: const InputDecoration(labelText: 'Tür'),
                  items: const [
                    DropdownMenuItem(value: 'resmi', child: Text('Resmi Tatil')),
                    DropdownMenuItem(value: 'hafta_sonu', child: Text('Hafta Sonu')),
                  ],
                  onChanged: (v) => setS(() => tur = v ?? 'resmi'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tarih'),
                  subtitle: Text(TarihUtil.tarihStr(secili)),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final r = await showDatePicker(
                        context: ctx,
                        initialDate: secili,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (r != null) setS(() => secili = r);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (kaydet == true) {
      if (adCtrl.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tatil adı boş olamaz.')));
        }
      } else {
        await p.ekle(Tatil(
          tarih: TarihUtil.tarihStr(secili),
          ad: adCtrl.text.trim(),
          tur: tur,
        ));
      }
    }
    adCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TatilProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tatil Yönetimi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _yeniTatil,
        icon: const Icon(Icons.add),
        label: const Text('Tatil Ekle'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Hafta sonu tatil sayılsın'),
            subtitle: const Text('Cumartesi/Pazar günleri "gelmedi" uyarısı verilmez'),
            value: p.haftaSonuTatil,
            onChanged: (v) => p.haftaSonuTatilDegistir(v),
          ),
          const Divider(height: 1),
          Expanded(
            child: p.yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : p.tatiller.isEmpty
                    ? const Center(child: Text('Henüz tatil kaydı yok.'))
                    : ListView.separated(
                        itemCount: p.tatiller.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final t = p.tatiller[i];
                          return ListTile(
                            leading: const Icon(Icons.beach_access),
                            title: Text(t.ad),
                            subtitle: Text('${t.tarih} • ${t.tur == 'resmi' ? 'Resmi' : 'Hafta Sonu'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Tatili sil?'),
                                    content: Text('${t.tarih} - ${t.ad} silinecek.'),
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
                                if (ok == true) await p.sil(t.id!);
                              },
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