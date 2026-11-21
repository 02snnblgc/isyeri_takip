class Tatil {
  final int? id;
  final String tarih; // yyyy-MM-dd
  final String ad;
  final String tur;   // resmi | hafta_sonu

  Tatil({this.id, required this.tarih, required this.ad, required this.tur});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'tarih': tarih, 'ad': ad, 'tur': tur,
      };

  factory Tatil.fromMap(Map<String, dynamic> m) => Tatil(
        id: m['id'] as int?,
        tarih: m['tarih'] as String,
        ad: m['ad'] as String,
        tur: m['tur'] as String,
      );
}