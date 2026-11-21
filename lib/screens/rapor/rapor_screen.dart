import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/tarih_util.dart';
import '../../providers/personel_provider.dart';
import '../../services/db_service.dart';
import '../../services/rapor_service.dart';
import 'kayit_liste_screen.dart';

class RaporScreen extends StatefulWidget {
  const RaporScreen({super.key});
  @override
  State<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends State<RaporScreen> {
  DateTimeRange? _aralik;
  int? _personelId;
  bool _islemde = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _aralik = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonelProvider>().yukle();
    });
  }

  Future<void> _aralikSec() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _aralik,
    );
    if (r != null) setState(() => _aralik = r);
  }

  Future<List<Map<String, dynamic>>?> _veriHazirla() async {
    if (_aralik == null) return null;
    return DbService.instance.raporSatirlari(
      baslangic: TarihUtil.tarihStr(_aralik!.start),
      bitis: TarihUtil.tarihStr(_aralik!.end),
      personelId: _personelId,
    );
  }

  Future<void> _pdfAl() async {
    setState(() => _islemde = true);
    final satirlar = await _veriHazirla();
    if (satirlar == null || satirlar.isEmpty) {
      setState(() => _islemde = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seçili aralıkta kayıt bulunamadı.')),
        );
      }
      return;
    }
    try {
      await RaporService.instance.pdfPaylas(
        satirlar: satirlar,
        baslangic: TarihUtil.tarihStr(_aralik!.start),
        bitis: TarihUtil.tarihStr(_aralik!.end),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF hatası: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _islemde = false);
  }

  Future<void> _excelAl() async {
    setState(() => _islemde = true);
    final satirlar = await _veriHazirla();
    if (satirlar == null || satirlar.isEmpty) {
      setState(() => _islemde = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seçili aralıkta kayıt bulunamadı.')),
        );
      }
      return;
    }
    try {
      await RaporService.instance.excelPaylas(
        satirlar: satirlar,
        baslangic: TarihUtil.tarihStr(_aralik!.start),
        bitis: TarihUtil.tarihStr(_aralik!.end),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel hatası: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _islemde = false);
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PersonelProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Kayıt listesi / düzeltme',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const KayitListeScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rapor Filtreleri',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.date_range),
                    title: const Text('Tarih aralığı'),
                    subtitle: Text(_aralik == null
                        ? 'Seçilmedi'
                        : '${TarihUtil.tarihStr(_aralik!.start)} → ${TarihUtil.tarihStr(_aralik!.end)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _aralikSec,
                  ),
                  DropdownButtonFormField<int?>(
                    value: _personelId,
                    decoration: const InputDecoration(
                      labelText: 'Personel (opsiyonel)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tüm personel')),
                      ...pp.personeller.map((p) => DropdownMenuItem(
                        value: p.id, child: Text(p.adSoyad))),
                    ],
                    onChanged: (v) => setState(() => _personelId = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _islemde ? null : _pdfAl,
            icon: _islemde
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf),
            label: const Text('PDF Raporu Oluştur'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _islemde ? null : _excelAl,
            icon: const Icon(Icons.table_chart),
            label: const Text('Excel Raporu Oluştur'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const KayitListeScreen())),
            icon: const Icon(Icons.edit_note),
            label: const Text('Kayıtları Görüntüle / Düzelt'),
          ),
        ],
      ),
    );
  }
}