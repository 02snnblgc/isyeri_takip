class Vardiya {
  final int? id;
  final String ad;            // "Sabah 08-17"
  final String baslangicSaat; // "08:00"
  final String bitisSaat;     // "17:00"
  final int toleransGirisDk;
  final int toleransCikisDk;
  final bool geceVardiyasi;

  Vardiya({
    this.id,
    required this.ad,
    required this.baslangicSaat,
    required this.bitisSaat,
    this.toleransGirisDk = 15,
    this.toleransCikisDk = 15,
    this.geceVardiyasi = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'ad': ad,
        'baslangic_saat': baslangicSaat,
        'bitis_saat': bitisSaat,
        'tolerans_giris_dk': toleransGirisDk,
        'tolerans_cikis_dk': toleransCikisDk,
        'gece_vardiyasi': geceVardiyasi ? 1 : 0,
      };

  factory Vardiya.fromMap(Map<String, dynamic> m) => Vardiya(
        id: m['id'] as int?,
        ad: m['ad'] as String,
        baslangicSaat: m['baslangic_saat'] as String,
        bitisSaat: m['bitis_saat'] as String,
        toleransGirisDk: m['tolerans_giris_dk'] as int? ?? 15,
        toleransCikisDk: m['tolerans_cikis_dk'] as int? ?? 15,
        geceVardiyasi: (m['gece_vardiyasi'] as int? ?? 0) == 1,
      );

  Vardiya copyWith({int? id}) => Vardiya(
        id: id ?? this.id,
        ad: ad,
        baslangicSaat: baslangicSaat,
        bitisSaat: bitisSaat,
        toleransGirisDk: toleransGirisDk,
        toleransCikisDk: toleransCikisDk,
        geceVardiyasi: geceVardiyasi,
      );
}