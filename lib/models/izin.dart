class Izin {
  final int? id;
  final int personelId;
  final String baslangicTarih; // yyyy-MM-dd
  final String bitisTarih;
  final String tur; // yillik | rapor | mazeret
  final String? aciklama;

  Izin({
    this.id,
    required this.personelId,
    required this.baslangicTarih,
    required this.bitisTarih,
    required this.tur,
    this.aciklama,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'personel_id': personelId,
        'baslangic_tarih': baslangicTarih,
        'bitis_tarih': bitisTarih,
        'tur': tur,
        'aciklama': aciklama,
      };

  factory Izin.fromMap(Map<String, dynamic> m) => Izin(
        id: m['id'] as int?,
        personelId: m['personel_id'] as int,
        baslangicTarih: m['baslangic_tarih'] as String,
        bitisTarih: m['bitis_tarih'] as String,
        tur: m['tur'] as String,
        aciklama: m['aciklama'] as String?,
      );
}