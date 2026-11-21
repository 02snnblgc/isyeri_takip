class Kayit {
  final int? id;
  final int personelId;
  final String tarih;       // yyyy-MM-dd
  final String? girisSaati; // HH:mm:ss
  final String? cikisSaati;
  final String durum;       // normal/gec/erken_cikis/gelmedi/izinli/raporlu
  final bool manuelDuzeltme;
  final String? duzeltmeNotu;
  final String olusturmaTs;

  Kayit({
    this.id,
    required this.personelId,
    required this.tarih,
    this.girisSaati,
    this.cikisSaati,
    this.durum = 'normal',
    this.manuelDuzeltme = false,
    this.duzeltmeNotu,
    required this.olusturmaTs,
  });

  bool get acikGiris => girisSaati != null && cikisSaati == null;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'personel_id': personelId,
        'tarih': tarih,
        'giris_saati': girisSaati,
        'cikis_saati': cikisSaati,
        'durum': durum,
        'manuel_duzeltme': manuelDuzeltme ? 1 : 0,
        'duzeltme_notu': duzeltmeNotu,
        'olusturma_ts': olusturmaTs,
      };

  factory Kayit.fromMap(Map<String, dynamic> m) => Kayit(
        id: m['id'] as int?,
        personelId: m['personel_id'] as int,
        tarih: m['tarih'] as String,
        girisSaati: m['giris_saati'] as String?,
        cikisSaati: m['cikis_saati'] as String?,
        durum: m['durum'] as String? ?? 'normal',
        manuelDuzeltme: (m['manuel_duzeltme'] as int? ?? 0) == 1,
        duzeltmeNotu: m['duzeltme_notu'] as String?,
        olusturmaTs: m['olusturma_ts'] as String,
      );

  Kayit copyWith({
    int? id, String? girisSaati, String? cikisSaati, String? durum,
    bool? manuelDuzeltme, String? duzeltmeNotu,
  }) => Kayit(
    id: id ?? this.id,
    personelId: personelId,
    tarih: tarih,
    girisSaati: girisSaati ?? this.girisSaati,
    cikisSaati: cikisSaati ?? this.cikisSaati,
    durum: durum ?? this.durum,
    manuelDuzeltme: manuelDuzeltme ?? this.manuelDuzeltme,
    duzeltmeNotu: duzeltmeNotu ?? this.duzeltmeNotu,
    olusturmaTs: olusturmaTs,
  );
}