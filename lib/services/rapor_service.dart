import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RaporService {
  RaporService._();
  static final RaporService instance = RaporService._();

  // PDF Türkçe karakter için Roboto fontu asset'ten yükleniyor.
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _fontlariYukle() async {
    if (_regular != null) return;
    _regular = await PdfGoogleFonts.robotoRegular();
    _bold = await PdfGoogleFonts.robotoBold();
  }

  String _trDurum(String s) => switch (s) {
        'normal' => 'Normal',
        'gec' => 'Geç',
        'erken_cikis' => 'Erken Çıkış',
        'gelmedi' => 'Gelmedi',
        'izinli' => 'İzinli',
        'raporlu' => 'Raporlu',
        _ => s,
      };

  String _trTarih(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('dd.MM.yyyy').format(d);
  }

  // ================= PDF =================
  Future<Uint8List> pdfOlustur({
    required List<Map<String, dynamic>> satirlar,
    required String baslangic,
    required String bitis,
    String? baslik,
  }) async {
    await _fontlariYukle();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            baslik ?? 'Personel Mesai Raporu',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (ctx) => [
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Başlangıç: ${_trTarih(baslangic)}'),
                pw.Text('Bitiş: ${_trTarih(bitis)}'),
                pw.Text('Toplam: ${satirlar.length} kayıt'),
              ],
            ),
          ),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Tarih', 'Personel', 'Vardiya',
              'Giriş', 'Çıkış', 'Durum', 'Fazla Mesai'
            ],
            data: satirlar.map((s) {
              final fm = (s['fazla_mesai_dk'] as int?) ?? 0;
              return [
                _trTarih(s['tarih'] as String),
                s['ad_soyad'] as String? ?? '-',
                s['vardiya_adi'] as String? ?? '-',
                s['giris_saati'] as String? ?? '-',
                s['cikis_saati'] as String? ?? '-',
                _trDurum(s['durum'] as String? ?? '-'),
                fm > 0 ? '$fm dk' : '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
            },
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> pdfPaylas({
    required List<Map<String, dynamic>> satirlar,
    required String baslangic,
    required String bitis,
    String? baslik,
  }) async {
    final bytes = await pdfOlustur(
      satirlar: satirlar,
      baslangic: baslangic,
      bitis: bitis,
      baslik: baslik,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'mesai_raporu_${baslangic}_${bitis}.pdf',
    );
  }

  // ================= EXCEL =================
  Future<Uint8List> excelOlustur({
    required List<Map<String, dynamic>> satirlar,
    required String baslangic,
    required String bitis,
  }) async {
    final excel = Excel.createExcel();
    final sayfa = excel['Mesai Raporu'];
    excel.delete('Sheet1');

    // Başlık satırı
    final basliklar = [
      'Tarih', 'Personel', 'Vardiya', 'Giriş', 'Çıkış',
      'Durum', 'Fazla Mesai (dk)', 'Manuel Düzeltme', 'Düzeltme Notu'
    ];
    for (var c = 0; c < basliklar.length; c++) {
      final cell = sayfa.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(basliklar[c]);
      cell.cellStyle = CellStyle(bold: true);
    }

    // Veri satırları
    for (var r = 0; r < satirlar.length; r++) {
      final s = satirlar[r];
      final degerler = <String>[
        _trTarih(s['tarih'] as String),
        s['ad_soyad'] as String? ?? '-',
        s['vardiya_adi'] as String? ?? '-',
        s['giris_saati'] as String? ?? '-',
        s['cikis_saati'] as String? ?? '-',
        _trDurum(s['durum'] as String? ?? '-'),
        '${(s['fazla_mesai_dk'] as int?) ?? 0}',
        ((s['manuel_duzeltme'] as int?) ?? 0) == 1 ? 'Evet' : 'Hayır',
        s['duzeltme_notu'] as String? ?? '',
      ];
      for (var c = 0; c < degerler.length; c++) {
        final cell = sayfa.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        cell.value = TextCellValue(degerler[c]);
      }
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Excel oluşturulamadı');
    }
    return Uint8List.fromList(bytes);
  }

  Future<void> excelPaylas({
    required List<Map<String, dynamic>> satirlar,
    required String baslangic,
    required String bitis,
  }) async {
    final bytes = await excelOlustur(
      satirlar: satirlar,
      baslangic: baslangic,
      bitis: bitis,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'mesai_raporu_${baslangic}_${bitis}.xlsx',
    );
  }
}