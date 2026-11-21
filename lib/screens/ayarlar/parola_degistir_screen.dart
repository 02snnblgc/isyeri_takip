import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/db_service.dart';

class ParolaDegistirScreen extends StatefulWidget {
  const ParolaDegistirScreen({super.key});
  @override
  State<ParolaDegistirScreen> createState() => _ParolaDegistirScreenState();
}

class _ParolaDegistirScreenState extends State<ParolaDegistirScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mevcutCtrl = TextEditingController();
  final _yeniCtrl = TextEditingController();
  final _tekrarCtrl = TextEditingController();
  bool _gizli1 = true, _gizli2 = true, _gizli3 = true;
  bool _islemde = false;

  @override
  void dispose() {
    _mevcutCtrl.dispose();
    _yeniCtrl.dispose();
    _tekrarCtrl.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final k = auth.kullanici;
    if (k == null) return;

    setState(() => _islemde = true);

    final mevcutDogru = await DbService.instance
        .girisDogrula(k.kullaniciAdi, _mevcutCtrl.text);
    if (!mevcutDogru) {
      if (mounted) {
        setState(() => _islemde = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mevcut parola hatalı.'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    await DbService.instance.parolaDegistir(k.id!, _yeniCtrl.text);
    await DbService.instance.auditYaz(k.id, 'parola_degistir', null);
    if (!mounted) return;
    setState(() => _islemde = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parola güncellendi.'),
          backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parola Değiştir')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _mevcutCtrl,
              obscureText: _gizli1,
              decoration: InputDecoration(
                labelText: 'Mevcut Parola',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_gizli1
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _gizli1 = !_gizli1),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Mevcut parola gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _yeniCtrl,
              obscureText: _gizli2,
              decoration: InputDecoration(
                labelText: 'Yeni Parola (en az 6 karakter)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_gizli2
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _gizli2 = !_gizli2),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 6) {
                  return 'En az 6 karakter olmalı';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tekrarCtrl,
              obscureText: _gizli3,
              decoration: InputDecoration(
                labelText: 'Yeni Parola (tekrar)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_gizli3
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _gizli3 = !_gizli3),
                ),
              ),
              validator: (v) => v != _yeniCtrl.text
                  ? 'Parolalar eşleşmiyor'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _islemde ? null : _kaydet,
              icon: _islemde
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock_reset),
              label: const Text('Parolayı Güncelle'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}