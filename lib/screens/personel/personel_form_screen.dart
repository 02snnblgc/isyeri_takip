import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/personel.dart';
import '../../providers/personel_provider.dart';
import '../../services/nfc_service.dart';

class PersonelFormScreen extends StatefulWidget {
  final Personel? personel;
  const PersonelFormScreen({super.key, this.personel});

  @override
  State<PersonelFormScreen> createState() => _PersonelFormScreenState();
}

class _PersonelFormScreenState extends State<PersonelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _adCtrl;
  int? _vardiyaId;
  int? _ozelVardiyaId;
  String? _kartUid;
  bool _kartAktif = true;
  bool _kaydediliyor = false;

  bool get _duzenleme => widget.personel != null;

  @override
  void initState() {
    super.initState();
    final p = widget.personel;
    _adCtrl = TextEditingController(text: p?.adSoyad ?? '');
    _vardiyaId = p?.vardiyaId;
    _ozelVardiyaId = p?.ozelVardiyaId;
    _kartUid = p?.kartUid;
    _kartAktif = p?.kartAktif ?? true;
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    super.dispose();
  }

  Future<void> _kartOkut() async {
    // Önce mevcut okutma varsa iptal
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Kartı telefonun NFC bölgesine yaklaştırın...')),
    );
    final uid = await NfcService.instance.tekOkut();
    if (!mounted) return;
    if (uid == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Kart okunamadı veya iptal edildi.'),
            backgroundColor: Colors.red),
      );
      return;
    }
    // Aynı UID başka personelde mi?
    final kullanimda = await context
        .read<PersonelProvider>()
        .kartUidKullanimda(uid, hariçId: widget.personel?.id);
    if (!mounted) return;
    if (kullanimda) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Bu kart başka bir personele tanımlı!'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _kartUid = uid);
    messenger.showSnackBar(
      SnackBar(content: Text('Kart okundu: $uid'),
          backgroundColor: Colors.green),
    );
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vardiyaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir vardiya seçin.')),
      );
      return;
    }
    setState(() => _kaydediliyor = true);

    final yeni = Personel(
      id: widget.personel?.id,
      adSoyad: _adCtrl.text.trim(),
      kartUid: _kartUid,
      kartAktif: _kartAktif,
      vardiyaId: _vardiyaId,
      ozelVardiyaId: _ozelVardiyaId,
      iseGirisTarihi: widget.personel?.iseGirisTarihi,
      aktif: widget.personel?.aktif ?? true,
    );
    final hata = await context.read<PersonelProvider>().kaydet(yeni);
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hata), backgroundColor: Colors.red));
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PersonelProvider>();
    final vardiyalar = prov.vardiyalar;

    return Scaffold(
      appBar: AppBar(title: Text(_duzenleme ? 'Personel Düzenle' : 'Yeni Personel')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _adCtrl,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ad soyad gerekli' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _vardiyaId,
              decoration: const InputDecoration(
                labelText: 'Vardiya (Zorunlu)',
                prefixIcon: Icon(Icons.schedule),
                border: OutlineInputBorder(),
              ),
              items: vardiyalar.map((v) => DropdownMenuItem(
                value: v.id,
                child: Text('${v.ad} (${v.baslangicSaat} - ${v.bitisSaat})'),
              )).toList(),
              onChanged: (v) => setState(() => _vardiyaId = v),
              validator: (v) => v == null ? 'Vardiya seçin' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              value: _ozelVardiyaId,
              decoration: const InputDecoration(
                labelText: 'Özel Vardiya (opsiyonel)',
                helperText: 'Engelli/hastalık gibi durumlar için farklı vardiya',
                prefixIcon: Icon(Icons.medical_information_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Yok —')),
                ...vardiyalar.map((v) => DropdownMenuItem(
                  value: v.id,
                  child: Text('${v.ad} (${v.baslangicSaat} - ${v.bitisSaat})'),
                )),
              ],
              onChanged: (v) => setState(() => _ozelVardiyaId = v),
            ),
            const SizedBox(height: 22),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_kartUid == null
                            ? Icons.credit_card_off
                            : Icons.credit_card,
                            color: _kartUid == null ? Colors.orange : Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _kartUid == null
                                ? 'Kart tanımlı değil'
                                : 'Kart UID: $_kartUid',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _kaydediliyor ? null : _kartOkut,
                            icon: const Icon(Icons.nfc),
                            label: Text(_kartUid == null ? 'Kart Okut' : 'Yeniden Okut'),
                          ),
                        ),
                        if (_kartUid != null) ...[
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Kartı kaldır',
                            onPressed: () => setState(() => _kartUid = null),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ],
                    ),
                    if (_kartUid != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Kart aktif'),
                        subtitle: const Text('Kapalıysa bu kartla giriş yapılamaz'),
                        value: _kartAktif,
                        onChanged: (v) => setState(() => _kartAktif = v),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _kaydediliyor ? null : _kaydet,
                icon: _kaydediliyor
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_kaydediliyor ? 'Kaydediliyor...' : 'Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}