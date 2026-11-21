import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/personel.dart';
import '../../providers/personel_provider.dart';
import 'personel_form_screen.dart';

class PersonelListeScreen extends StatefulWidget {
  const PersonelListeScreen({super.key});
  @override
  State<PersonelListeScreen> createState() => _PersonelListeScreenState();
}

class _PersonelListeScreenState extends State<PersonelListeScreen> {
  final _aramaCtrl = TextEditingController();
  String _arama = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonelProvider>().yukle();
    });
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  Future<void> _silOnay(Personel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Personeli sil?'),
        content: Text('${p.adSoyad} kalıcı olarak silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final hata = await context.read<PersonelProvider>().sil(p.id!);
    if (!mounted) return;
    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hata), backgroundColor: Colors.red));
    }
  }

  Future<void> _kartAktiflikToggle(Personel p) async {
    final hata = await context.read<PersonelProvider>()
        .kartAktiflik(p.id!, !p.kartAktif);
    if (!mounted) return;
    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hata), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PersonelProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personeller'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _aramaCtrl,
              decoration: InputDecoration(
                hintText: 'Ad soyad ara...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                _arama = v;
                context.read<PersonelProvider>().yukle(arama: v);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Yeni Personel'),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => const PersonelFormScreen()));
          if (mounted) context.read<PersonelProvider>().yukle(arama: _arama);
        },
      ),
      body: prov.yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : prov.personeller.isEmpty
              ? _bosDurum()
              : RefreshIndicator(
                  onRefresh: () => prov.yukle(arama: _arama),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 90, top: 6),
                    itemCount: prov.personeller.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = prov.personeller[i];
                      final vardiya = prov.vardiyaById(p.ozelVardiyaId ?? p.vardiyaId);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: p.kartUid == null
                              ? Colors.orange.shade100
                              : p.kartAktif
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                          child: Icon(
                            p.kartUid == null
                                ? Icons.credit_card_off
                                : p.kartAktif
                                    ? Icons.credit_card
                                    : Icons.block,
                            color: p.kartUid == null
                                ? Colors.orange.shade800
                                : p.kartAktif
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                          ),
                        ),
                        title: Text(p.adSoyad,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (vardiya != null)
                              Text('${vardiya.ad} • ${vardiya.baslangicSaat}-${vardiya.bitisSaat}'),
                            Text(
                              p.kartUid == null
                                  ? 'Kart tanımlı değil'
                                  : 'Kart: ${p.kartUid}${p.ozelVardiyaId != null ? " • ÖZEL VARDİYA" : ""}',
                              style: TextStyle(
                                fontSize: 11,
                                color: p.kartUid == null ? Colors.orange : null,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'duzenle') {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => PersonelFormScreen(personel: p)));
                              if (mounted) {
                                context.read<PersonelProvider>().yukle(arama: _arama);
                              }
                            } else if (v == 'kart_toggle') {
                              _kartAktiflikToggle(p);
                            } else if (v == 'kart_temizle') {
                              final hata = await context
                                  .read<PersonelProvider>()
                                  .kartUidTemizle(p.id!);
                              if (hata != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(hata)));
                              }
                            } else if (v == 'sil') {
                              _silOnay(p);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'duzenle',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Düzenle'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'kart_toggle',
                              child: ListTile(
                                leading: Icon(p.kartAktif ? Icons.block : Icons.check_circle),
                                title: Text(p.kartAktif ? 'Kartı bloke et' : 'Kartı aktifleştir'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (p.kartUid != null)
                              const PopupMenuItem(
                                value: 'kart_temizle',
                                child: ListTile(
                                  leading: Icon(Icons.credit_card_off),
                                  title: Text('Kartı kaldır'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'sil',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Sil', style: TextStyle(color: Colors.red)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _bosDurum() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 72, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_arama.isEmpty ? 'Henüz personel yok' : 'Sonuç bulunamadı',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text(_arama.isEmpty
              ? 'Sağ alttaki butondan ilk personeli ekleyin.'
              : 'Arama kriterini değiştirin.',
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}