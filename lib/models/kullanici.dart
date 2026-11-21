class Kullanici {
  final int? id;
  final String kullaniciAdi;
  final String parolaHash;
  final String tuz;
  final String rol; // 'yonetici' | 'gozlemci'
  final String olusturmaTarihi;

  Kullanici({
    this.id,
    required this.kullaniciAdi,
    required this.parolaHash,
    required this.tuz,
    this.rol = 'yonetici',
    required this.olusturmaTarihi,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'kullanici_adi': kullaniciAdi,
        'parola_hash': parolaHash,
        'tuz': tuz,
        'rol': rol,
        'olusturma_tarihi': olusturmaTarihi,
      };

  factory Kullanici.fromMap(Map<String, dynamic> m) => Kullanici(
        id: m['id'] as int?,
        kullaniciAdi: m['kullanici_adi'] as String,
        parolaHash: m['parola_hash'] as String,
        tuz: m['tuz'] as String,
        rol: m['rol'] as String? ?? 'yonetici',
        olusturmaTarihi: m['olusturma_tarihi'] as String,
      );
}