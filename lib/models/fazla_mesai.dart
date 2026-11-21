class FazlaMesai {
  final int? id;
  final int personelId;
  final String tarih;
  final int dakika;
  final String kaynak; // otomatik | manuel

  FazlaMesai({
    this.id,
    required this.personelId,
    required this.tarih,
    required this.dakika,
    this.kaynak = 'otomatik',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'personel_id': personelId,
        'tarih': tarih,
        'dakika': dakika,
        'kaynak': kaynak,
      };

  factory FazlaMesai.fromMap(Map<String, dynamic> m) => FazlaMesai(
        id: m['id'] as int?,
        personelId: m['personel_id'] as int,
        tarih: m['tarih'] as String,
        dakika: m['dakika'] as int,
        kaynak: m['kaynak'] as String? ?? 'otomatik',
      );
}