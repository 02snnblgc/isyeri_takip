  Future<void> _cikisOnay() async {
    final kadiCtrl = TextEditingController(text: 'admin'); // Varsayılan olarak admin yazılı gelsin
    final parolaCtrl = TextEditingController();
    bool hatali = false;
    String hataMesaji = '';

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Yönetici Girişi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Yönetici paneline geçmek için bilgilerinizi girin.'),
              const SizedBox(height: 12),
              TextField(
                controller: kadiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: parolaCtrl,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Parola',
                  border: const OutlineInputBorder(),
                  errorText: hatali ? hataMesaji : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                // Kullanıcı adı ve parolayı doğrudan AuthProvider'a gönderiyoruz.
                final basarili = await auth.giris(kadiCtrl.text.trim(), parolaCtrl.text);
                if (basarili) {
                  Navigator.pop(ctx, true);
                } else {
                  setStateDialog(() {
                    hatali = true;
                    hataMesaji = auth.hata ?? 'Hatalı giriş';
                  });
                }
              },
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
    
    kadiCtrl.dispose();
    parolaCtrl.dispose();
    
    if (ok == true && mounted) {
      // Başarılı girişte Yönetici Paneline (AnaScreen) geç
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AnaScreen()),
      );
    }
  }
