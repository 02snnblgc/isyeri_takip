import 'package:flutter/material.dart';
import '../../services/db_service.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});
  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<Map<String, dynamic>> _loglar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    _loglar = await DbService.instance.auditLoglariGetir(limit: 300);
    setState(() => _yukleniyor = false);
  }

  String _islemEtiket(String islem) => switch (islem) {
        'kiosk_giris' => 'Kiosk Giriş',
        'kiosk_cikis' => 'Kiosk Çıkış',
        'manuel_cikis_duzeltme' => 'Manuel Çıkış Düzeltme',
        'manuel_kayit_guncelle' => 'Manuel Kayıt Güncelleme',
        _ => islem,
      };

  IconData _ikon(String islem) {
    if (islem.contains('giris')) return Icons.login;
    if (islem.contains('cikis')) return Icons.logout;
    if (islem.contains('duzeltme') || islem.contains('guncelle')) return Icons.edit;
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Denetim Günlüğü'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _yukle),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _loglar.isEmpty
              ? const Center(child: Text('Henüz log yok.'))
              : ListView.separated(
                  itemCount: _loglar.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final l = _loglar[i];
                    final islem = l['islem'] as String? ?? '';
                    final ts = l['ts'] as String? ?? '';
                    final kullanici = l['kullanici_adi'] as String?;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.15),
                        child: Icon(_ikon(islem), color: Colors.blue, size: 20),
                      ),
                      title: Text(_islemEtiket(islem),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l['detay'] as String? ?? '-'),
                          Text(
                            '${kullanici ?? "Sistem"} • ${ts.replaceFirst('T', ' ').substring(0, 19)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}