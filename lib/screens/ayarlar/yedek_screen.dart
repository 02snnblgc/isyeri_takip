import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/db_service.dart';
import '../../services/yedek_service.dart';

class YedekScreen extends StatefulWidget {
  const YedekScreen({super.key});
  @override
  State<YedekScreen> createState() => _YedekScreenState();
}

class _YedekScreenState extends State<YedekScreen> {
  bool _islemde = false;

  Future<void> _yedekAl() async {
    setState(() => _islemde = true);
    try {
      await YedekService.instance.yedekAl();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yedek oluşturuldu.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedek alma hatası: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _islemde = false);
  }

  Future<void> _yedekYukle() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yedekten yükle'),
        content: const Text(
            'DİKKAT: Mevcut personel, kayıt, izin ve tatil verileri silinip yedekteki veriler yüklenecek. Devam edilsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Devam')),
        ],
      ),
    );
    if (onay != true) return;

    // Yeni API: FilePicker.pickFiles doğrudan List<PlatformFile> döndürür.
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    
    if (result == null || result.isEmpty || result.first.path == null) return;

    setState(() => _islemde = true);
    try {
      final metin = await File(result.first.path!).readAsString();
      // JSON doğrulama
      jsonDecode(metin);
      final sayi = await YedekService.instance.yedekYukle(metin);
      
      final kullaniciId = context.read<AuthProvider>().kullanici?.id;
      await DbService.instance.auditYaz(
          kullaniciId, 'yedek_yukle', '$sayi tablo yüklendi');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedek yüklendi ($sayi tablo).'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme hatası: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _islemde = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yedekleme')),
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
                  const Text('Yedek Nedir?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Tüm personel, kayıt, izin, tatil, vardiya ve ayarlar tek bir JSON dosyasına aktarılır. Bu dosyayı e-posta, Drive veya WhatsApp ile saklayabilirsiniz.',
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _islemde ? null : _yedekAl,
            icon: _islemde
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file),
            label: const Text('Yedek Al (Dışa Aktar)'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _islemde ? null : _yedekYukle,
            icon: const Icon(Icons.download),
            label: const Text('Yedekten Yükle (İçe Aktar)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 20),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.warning_amber, color: Colors.orange),
            title: Text('Önemli Uyarı'),
            subtitle: Text(
                'Yedekten yükleme, mevcut personel ve kayıtları SİLER. Önce mutlaka dışa aktarın.'),
          ),
        ],
      ),
    );
  }
}
