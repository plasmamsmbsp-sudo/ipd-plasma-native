import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../models/ipd_models.dart';

class ExcelService {
  static Future<File> generateLaporanExcel({
    required List<InspeksiItem> items,
    required MasterDatabase master,
    String? activeMapScreenshotPath,
  }) async {
    final xlsio.Workbook workbook = xlsio.Workbook();

    // Muat logo asli dari assets tanpa perubahan rasio/warna
    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assets/images/logo_kencana.png');
      logoBytes = data.buffer.asUint8List();
    } catch (_) {}

    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final tglCetak = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());

    // =========================================================================
    // SHEET 1: REKAPAN (MOBILE PORTRAIT FRIENDLY + KOP LOGO)
    // =========================================================================
    final xlsio.Worksheet sheet1 = workbook.worksheets[0];
    sheet1.name = 'REKAPAN';
    sheet1.pageSetup.orientation = xlsio.ExcelPageOrientation.portrait;
    sheet1.pageSetup.fitToPagesWide = 1;
    sheet1.pageSetup.fitToPagesTall = 0;

    // Pasang Kop Logo & Judul Perusahaan
    _buildKopSurat(sheet1, logoBytes, master, 'REKAPITULASI INSPEKSI PANEN & DENDA (IPD)', tglCetak, 8);

    // Header Tabel Ringkas Mobile-Friendly (8 Kolom pas di layar HP)
    final headers = ['No', 'Blok', 'Pemanen', 'Mandor', 'Jjg', 'Losses%', 'Temuan Utama', 'Total Denda'];
    final colWidths = [5.0, 9.5, 16.0, 12.0, 7.0, 9.5, 22.0, 15.0];

    const int headerRow = 6;
    for (int c = 0; c < headers.length; c++) {
      sheet1.getRangeByIndex(headerRow, c + 1).columnWidth = colWidths[c];
      final cell = sheet1.getRangeByIndex(headerRow, c + 1);
      cell.setText(headers[c]);
      cell.cellStyle.backColor = '#1B5E20'; // Hijau Forest Kencana
      cell.cellStyle.fontColor = '#FFFFFF';
      cell.cellStyle.bold = true;
      cell.cellStyle.fontSize = 10;
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
      cell.cellStyle.vAlign = xlsio.VAlignType.center;
      cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    }
    sheet1.setRowHeightInPixels(headerRow, 30);

    int row = headerRow + 1;
    int grandTotalDenda = 0;
    double sumLosses = 0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      grandTotalDenda += item.totalDenda;
      sumLosses += item.persentaseLosses;

      // Rangkuman singkat temuan agar tidak melebar ke samping
      List<String> ringkasanTemuan = [];
      for (var k in kDaftarKriteria) {
        final jml = item.temuan[k.kode] ?? 0;
        if (jml > 0) ringkasanTemuan.add('${k.kode}:$jml');
      }

      final rowValues = [
        '${i + 1}',
        item.blok,
        item.pemanen,
        item.mandor,
        '${item.janjangPanen}',
        '${item.persentaseLosses.toStringAsFixed(2)}%',
        ringkasanTemuan.isEmpty ? 'Bersih / SOP' : ringkasanTemuan.join(', '),
        currencyFmt.format(item.totalDenda),
      ];

      final bgColor = (i % 2 == 0) ? '#FFFFFF' : '#F1F8E9';
      for (int c = 0; c < rowValues.length; c++) {
        final cell = sheet1.getRangeByIndex(row, c + 1);
        cell.setText(rowValues[c]);
        cell.cellStyle.backColor = bgColor;
        cell.cellStyle.fontSize = 9.5;
        cell.cellStyle.wrapText = true;
        cell.cellStyle.vAlign = xlsio.VAlignType.center;
        cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
        cell.cellStyle.borders.all.color = '#CFD8DC';
        if (c == 0 || c == 1 || c == 4 || c == 5) {
          cell.cellStyle.hAlign = xlsio.HAlignType.center;
        } else if (c == 7) {
          cell.cellStyle.hAlign = xlsio.HAlignType.right;
          cell.cellStyle.bold = true;
        }
      }
      sheet1.setRowHeightInPixels(row, 28);
      row++;
    }

    // Baris Total Keseluruhan
    final avgLosses = items.isEmpty ? 0.0 : (sumLosses / items.length);
    sheet1.getRangeByIndex(row, 1, row, 5).merge();
    sheet1.getRangeByIndex(row, 1).setText('TOTAL KESELURUHAN (${items.length} SAMPEL)');
    sheet1.getRangeByIndex(row, 6).setText('${avgLosses.toStringAsFixed(2)}%');
    sheet1.getRangeByIndex(row, 7).setText('Rata-rata Losses');
    sheet1.getRangeByIndex(row, 8).setText(currencyFmt.format(grandTotalDenda));

    for (int c = 1; c <= 8; c++) {
      final cell = sheet1.getRangeByIndex(row, c);
      cell.cellStyle.backColor = '#F9A825'; // Emas Kencana
      cell.cellStyle.fontColor = '#1B5E20';
      cell.cellStyle.bold = true;
      cell.cellStyle.fontSize = 10;
      cell.cellStyle.hAlign = (c == 8) ? xlsio.HAlignType.right : xlsio.HAlignType.center;
      cell.cellStyle.vAlign = xlsio.VAlignType.center;
      cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.medium;
    }
    sheet1.setRowHeightInPixels(row, 30);

    // =========================================================================
    // SHEET 2: FOTO TEMUAN (GRID 2 KOLOM MOBILE FRIENDLY + KOP LOGO)
    // =========================================================================
    final xlsio.Worksheet sheet2 = workbook.worksheets.addWithName('FOTO_TEMUAN');
    sheet2.pageSetup.orientation = xlsio.ExcelPageOrientation.portrait;
    sheet2.pageSetup.fitToPagesWide = 1;
    _buildKopSurat(sheet2, logoBytes, master, 'DOKUMENTASI FOTO TEMUAN LAPANGAN', tglCetak, 4);

    sheet2.getRangeByIndex(6, 1).columnWidth = 22;
    sheet2.getRangeByIndex(6, 2).columnWidth = 22;
    sheet2.getRangeByIndex(6, 3).columnWidth = 22;
    sheet2.getRangeByIndex(6, 4).columnWidth = 22;

    int fotoRow = 7;
    int colIndex = 0; // 0 = kiri (kolom 1-2), 1 = kanan (kolom 3-4)

    for (final item in items) {
      for (final path in item.fotoPaths) {
        final file = File(path);
        if (!file.existsSync()) continue;

        final startCol = (colIndex == 0) ? 1 : 3;
        sheet2.getRangeByIndex(fotoRow, startCol, fotoRow, startCol + 1).merge();
        final captionCell = sheet2.getRangeByIndex(fotoRow, startCol);
        captionCell.setText('${item.blok} | ${item.pemanen} | Denda: ${currencyFmt.format(item.totalDenda)}');
        captionCell.cellStyle.backColor = '#E8F5E9';
        captionCell.cellStyle.bold = true;
        captionCell.cellStyle.fontSize = 9;
        captionCell.cellStyle.hAlign = xlsio.HAlignType.center;
        captionCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
        sheet2.setRowHeightInPixels(fotoRow, 22);

        final pic = sheet2.pictures.addStream(fotoRow + 1, startCol, file.readAsBytesSync());
        pic.height = 175;
        pic.width = 275;

        if (colIndex == 0) {
          colIndex = 1;
        } else {
          colIndex = 0;
          fotoRow += 11;
        }
      }
    }

    // =========================================================================
    // SHEET 3: SS MAP TEMUAN (SCREENSHOT PETA BLOK + TITIK TEMUAN + TREK)
    // =========================================================================
    final xlsio.Worksheet sheet3 = workbook.worksheets.addWithName('SS_MAP_TEMUAN');
    sheet3.pageSetup.orientation = xlsio.ExcelPageOrientation.portrait;
    sheet3.pageSetup.fitToPagesWide = 1;
    _buildKopSurat(sheet3, logoBytes, master, 'PETA SEBARAN TEMUAN & GPS TRACKING', tglCetak, 4);

    sheet3.getRangeByIndex(6, 1).columnWidth = 22;
    sheet3.getRangeByIndex(6, 2).columnWidth = 22;
    sheet3.getRangeByIndex(6, 3).columnWidth = 22;
    sheet3.getRangeByIndex(6, 4).columnWidth = 22;

    int mapRow = 7;
    final List<String> mapImages = [];
    if (activeMapScreenshotPath != null && File(activeMapScreenshotPath).existsSync()) {
      mapImages.add(activeMapScreenshotPath);
    }
    for (final item in items) {
      if (item.mapScreenshotPath != null &&
          File(item.mapScreenshotPath!).existsSync() &&
          !mapImages.contains(item.mapScreenshotPath)) {
        mapImages.add(item.mapScreenshotPath!);
      }
    }

    if (mapImages.isEmpty) {
      sheet3.getRangeByIndex(mapRow, 1, mapRow, 4).merge();
      sheet3.getRangeByIndex(mapRow, 1).setText(
          'Belum ada tangkapan layar Peta PDF. Buka menu Peta Blok PDF lalu tekan tombol "Simpan SS Peta ke Excel".');
    } else {
      for (int m = 0; m < mapImages.length; m++) {
        sheet3.getRangeByIndex(mapRow, 1, mapRow, 4).merge();
        final titleCell = sheet3.getRangeByIndex(mapRow, 1);
        titleCell.setText('Tangkapan Layar Peta Lokasi & Titik Temuan #${m + 1} ($tglCetak)');
        titleCell.cellStyle.backColor = '#1B5E20';
        titleCell.cellStyle.fontColor = '#FFFFFF';
        titleCell.cellStyle.bold = true;
        titleCell.cellStyle.hAlign = xlsio.HAlignType.center;
        sheet3.setRowHeightInPixels(mapRow, 24);

        final pic = sheet3.pictures.addStream(mapRow + 1, 1, File(mapImages[m]).readAsBytesSync());
        pic.height = 360;
        pic.width = 540;
        mapRow += 21;
      }
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final safeDate = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final outFile = File('${dir.path}/Rekap_IPD_${master.afdeling.replaceAll(' ', '_')}_$safeDate.xlsx');
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile;
  }

  static void _buildKopSurat(
    xlsio.Worksheet sheet,
    Uint8List? logoBytes,
    MasterDatabase master,
    String judulLaporan,
    String tglCetak,
    int totalCols,
  ) {
    // Sisipkan logo asli di pojok kiri atas (A1:A3) tanpa merubah rasio
    if (logoBytes != null) {
      final pic = sheet.pictures.addStream(1, 1, logoBytes);
      pic.height = 54;
      pic.width = 54;
    }

    sheet.getRangeByIndex(1, 2, 1, totalCols).merge();
    final c1 = sheet.getRangeByIndex(1, 2);
    c1.setText(master.pt.toUpperCase());
    c1.cellStyle.bold = true;
    c1.cellStyle.fontSize = 12;
    c1.cellStyle.fontColor = '#1B5E20';

    sheet.getRangeByIndex(2, 2, 2, totalCols).merge();
    final c2 = sheet.getRangeByIndex(2, 2);
    c2.setText('${master.kebun} — ${master.afdeling} | Asisten: ${master.asisten}');
    c2.cellStyle.fontSize = 9.5;
    c2.cellStyle.bold = true;

    sheet.getRangeByIndex(3, 2, 3, totalCols).merge();
    final c3 = sheet.getRangeByIndex(3, 2);
    c3.setText('$judulLaporan (Tanggal: $tglCetak)');
    c3.cellStyle.fontSize = 9;
    c3.cellStyle.fontColor = '#455A64';

    // Garis pembatas kop surat
    for (int col = 1; col <= totalCols; col++) {
      final borderCell = sheet.getRangeByIndex(4, col);
      borderCell.cellStyle.borders.bottom.lineStyle = xlsio.LineStyle.double;
      borderCell.cellStyle.borders.bottom.color = '#1B5E20';
    }
    sheet.setRowHeightInPixels(1, 22);
    sheet.setRowHeightInPixels(2, 20);
    sheet.setRowHeightInPixels(3, 18);
    sheet.setRowHeightInPixels(4, 8);
  }
}
