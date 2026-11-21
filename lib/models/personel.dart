class Personel {
  final int? id;
  final String adSoyad;
  final String? kartUid;    // null → kart henüz tanımlanmamış
  final bool kartAktif;
  final String? fotoYol;
  final int? vardiyaId;
  final int? ozelVardiyaId;
  final String? iseGirisTarihi;
  final bool aktif;

  Personel({
    this.id,
    required this.adSoyad,
    this.kartUid,
    this.kartAktif = true,
    this.fotoYol,
    this.vardiyaId,
    this.ozelVardiyaId,
    this.iseGirisTarihi,
    this.aktif = true,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'ad_soyad': adSoyad,
        'kart_uid': kartUid,
        'kart_aktif': kartAktif ? 1 : 0,
        'foto_yol': fotoYol,
        'vardiya_id': vardiyaId,
        'ozel_vardiya_id': ozelVardiyaId,
        'ise_giris_tarihi': iseGirisTarihi,
        'aktif': aktif ? 1 : 0,
      };

  factory Personel.fromMap(Map<String, dynamic> m) => Personel(
        id: m['id'] as int?,
        adSoyad: m['ad_soyad'] as String,
        kartUid: m['kart_uid'] as String?,
        kartAktif: (m['kart_aktif'] as int? ?? 1) == 1,
        fotoYol: m['foto_yol'] as String?,
        vardiyaId: m['vardiya_id'] as int?,
        ozelVardiyaId: m['ozel_vardiya_id'] as int?,
        iseGirisTarihi: m['ise_giris_tarihi'] as String?,
        aktif: (m['aktif'] as int? ?? 1) == 1,
      );

  Personel copyWith({
    int? id, String? adSoyad, String? kartUid, bool? kartAktif,
    String? fotoYol, int? vardiyaId, int? ozelVardiyaId,
    String? iseGirisTarihi, bool? aktif,
  }) => Personel(
    id: id ?? this.id,
    adSoyad: adSoyad ?? this.adSoyad,
    kartUid: kartUid ?? this.kartUid,
    kartAktif: kartAktif ?? this.kartAktif,
    fotoYol: fotoYol ?? this.fotoYol,
    vardiyaId: vardiyaId ?? this.vardiyaId,
    ozelVardiyaId: ozelVardiyaId ?? this.ozelVardiyaId,
    iseGirisTarihi: iseGirisTarihi ?? this.iseGirisTarihi,
    aktif: aktif ?? this.aktif,
  );
}