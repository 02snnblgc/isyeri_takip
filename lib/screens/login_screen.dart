import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tema_provider.dart';
import '../widgets/tema_secici_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kadiCtrl = TextEditingController(text: 'admin');
  final _parolaCtrl = TextEditingController();
  bool _parolaGizli = true;

  @override
  void dispose() {
    _kadiCtrl.dispose();
    _parolaCtrl.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.giris(_kadiCtrl.text.trim(), _parolaCtrl.text);
    if (!mounted) return;
    if (!ok && auth.hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.hata!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.topRight,
                    child: TemaSeciciWidget(
                      mevcutMod: tema.mod,
                      pastelIndex: tema.pastelIndex,
                      onMod: tema.modDegistir,
                      onPastel: tema.pastelDegistir,
                    ),
                  ),
                  Icon(Icons.badge_outlined, size: 80,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('İşyeri Personel Takip',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Yönetici Girişi',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _kadiCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Kullanıcı Adı',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Kullanıcı adı gerekli' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _parolaCtrl,
                          obscureText: _parolaGizli,
                          decoration: InputDecoration(
                            labelText: 'Parola',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_parolaGizli
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _parolaGizli = !_parolaGizli),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Parola gerekli' : null,
                          onFieldSubmitted: (_) => _girisYap(),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: auth.yukleniyor ? null : _girisYap,
                            icon: auth.yukleniyor
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.login),
                            label: Text(auth.yukleniyor ? 'Giriş yapılıyor...' : 'Giriş Yap'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'İlk giriş: admin / admin123 — girişten sonra değiştirin.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}