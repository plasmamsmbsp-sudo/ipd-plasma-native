import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class ExcelSapHelper {
  static Future eksporExcelFormatResmi(List dataInspeksi) async {
    if (dataInspeksi.isEmpty) return;

    var excel = xl.Excel.createExcel();
    xl.Sheet sDenda = excel['DENDA_PANEN'];
    excel.delete('Sheet1');

    final thinBorder = xl.Border(borderStyle: xl.BorderStyle.Thin, borderColorHex: xl.ExcelColor.fromHexString('#000000'));
    final headerGrey = xl.CellStyle(
      bold: true,
      fontSize: 9,
      backgroundColorHex: xl.ExcelColor.fromHexString('#D9D9D9'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
    );

    final cellNormal = xl.CellStyle(
      fontSize: 9,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
    );

    final cellCenter = xl.CellStyle(
      fontSize: 9,
      horizontalAlign: xl.HorizontalAlign.Center,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
    );

    final cellRight = xl.CellStyle(
      fontSize: 9,
      horizontalAlign: xl.HorizontalAlign.Right,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
    );

    final cellTotal = xl.CellStyle(
      bold: true,
      fontSize: 9,
      backgroundColorHex: xl.ExcelColor.fromHexString('#F2F2F2'),
      topBorder: thinBorder,
      bottomBorder: thinBorder,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
    );

    final firstRow = dataInspeksi.first;
    final afdeling = firstRow['afdeling'].toString();
    final tanggal = firstRow['tanggal'].toString();
    final mandor = firstRow['mandor'].toString();
    final kerani = (firstRow['kerani'] ?? '-').toString();
    final asisten = firstRow['asisten'].toString();

    // Baris 0: Afdeling, DENDA PANEN, Standart Administrasi Panen (SAP)
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), xl.TextCellValue('Afdeling :'), cellStyle: xl.CellStyle(bold: true, fontSize: 9));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0), xl.TextCellValue(afdeling), cellStyle: xl.CellStyle(fontSize: 9));
    sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 0), xl.CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 0));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 0), xl.TextCellValue('DENDA PANEN'), cellStyle: xl.CellStyle(bold: true, fontSize: 13, horizontalAlign: xl.HorizontalAlign.Center));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: 0), xl.TextCellValue('Standart Administrasi Panen (SAP) Page'), cellStyle: xl.CellStyle(italic: true, fontSize: 8));

    // Baris 1: Tanggal & Mandor/Kerani Panen
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1), xl.TextCellValue('Tanggal :'), cellStyle: xl.CellStyle(bold: true, fontSize: 9));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1), xl.TextCellValue(tanggal), cellStyle: xl.CellStyle(fontSize: 9));
    sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 1), xl.CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: 1));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 1), xl.TextCellValue('Mandor/Kerani Panen : $mandor / $kerani'), cellStyle: xl.CellStyle(fontSize: 9, horizontalAlign: xl.HorizontalAlign.Center));

    // Header Tabel (Baris 3, 4, 5, 6 persis Slide 2)
    sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3), xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3), xl.TextCellValue('No.\nUrut'));

    sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3), xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3), xl.TextCellValue('Nama'));

    sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3), xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 6));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3), xl.TextCellValue('Hasil\nBruto\n(Jjg)'));

    sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3), xl.CellIndex.indexByColumnRow(columnIndex: 22, rowIndex: 3));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3), xl.TextCellValue('DENDA'));

    final kodeHeader = ['BM', 'BTP', 'BTC', 'BPM', 'TP', 'SP', 'OP', 'PS', 'BRDT', 'ALT'];
    final satuanHeader = ['Jjg', 'Jjg', 'Jjg', 'Jjg', 'Jjg', 'pkk', 'pkk', 'Plp', 'Butir', 'TPH'];
    final tarifHeader = [10000, 10000, 10000, 10000, 500, 2000, 5000, 5000, 200, 1000];

    for (int k = 0; k < 10; k++) {
      int c1 = 3 + (k * 2);
      int c2 = c1 + 1;
      sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: c1, rowIndex: 4), xl.CellIndex.indexByColumnRow(columnIndex: c2, rowIndex: 4));
      sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c1, rowIndex: 4), xl.TextCellValue(kodeHeader[k]));
      sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c1, rowIndex: 5), xl.TextCellValue(satuanHeader[k]));
      sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c2, rowIndex: 5), xl.TextCellValue('Rp'));
      sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c2, rowIndex: 6), xl.IntCellValue(tarifHeader[k]));
    }

    sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: 3), xl.CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: 6));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: 3), xl.TextCellValue('Jumlah\n(Rp)'));

    sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: 24, rowIndex: 3), xl.CellIndex.indexByColumnRow(columnIndex: 24, rowIndex: 6));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 24, rowIndex: 3), xl.TextCellValue('Hasil\nNetto\n(Jjg)'));

    sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: 25, rowIndex: 3), xl.CellIndex.indexByColumnRow(columnIndex: 25, rowIndex: 6));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 25, rowIndex: 3), xl.TextCellValue('KETERANGAN'));

    for (int r = 3; r <= 6; r++) {
      for (int c = 0; c <= 25; c++) {
        sDenda.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).cellStyle = headerGrey;
      }
    }

    int sumBruto = 0;
    int sumNetto = 0;
    int grandTotalRp = 0;
    final sumQty = List.filled(10, 0);
    final sumRp = List.filled(10, 0);
    final int jumlahBarisCetak = dataInspeksi.length > 25 ? dataInspeksi.length : 25;

    for (int i = 0; i < jumlahBarisCetak; i++) {
      int rowIdx = 7 + i;
      sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx), xl.IntCellValue(i + 1), cellStyle: cellCenter);

      if (i < dataInspeksi.length) {
        final r = dataInspeksi[i];
        final temuan = Map.from(jsonDecode(r['temuan_json'].toString()));
        final int bruto = (r['tapak_panen'] ?? 0) as int;
        final int bm = (temuan['P1'] ?? 0) as int;
        final int netto = (bruto - bm) < 0 ? 0 : (bruto - bm);
        final int totalDendaRow = (r['total_denda'] ?? 0) as int;

        sumBruto += bruto;
        sumNetto += netto;
        grandTotalRp += totalDendaRow;

        sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx), xl.TextCellValue(r['pemanen'].toString()), cellStyle: cellNormal);
        sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx), xl.IntCellValue(bruto), cellStyle: cellRight);

        for (int k = 0; k < 10; k++) {
          final sop = daftarParameterSop[k];
          final int qty = (temuan[sop.kode] ?? 0) as int;
          final int rp = qty * sop.dendaPerUnit;
          sumQty[k] += qty;
          sumRp[k] += rp;
          int c1 = 3 + (k * 2);
          int c2 = c1 + 1;
          sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c1, rowIndex: rowIdx), qty > 0 ? xl.IntCellValue(qty) : xl.TextCellValue(''), cellStyle: cellCenter);
          sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c2, rowIndex: rowIdx), xl.IntCellValue(rp), cellStyle: cellRight);
        }

        final ket = 'Blok ${r['blok']} | Losses: ${r['total_losses_kg']} kg (${r['persen_losses']}%)';
        sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: rowIdx), xl.IntCellValue(totalDendaRow), cellStyle: cellRight);
        sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 24, rowIndex: rowIdx), xl.IntCellValue(netto), cellStyle: cellRight);
        sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 25, rowIndex: rowIdx), xl.TextCellValue(ket), cellStyle: cellNormal);
      } else {
        sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx), xl.TextCellValue(''), cellStyle: cellNormal);
        sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx), xl.TextCellValue(''), cellStyle: cellRight);
        for (int k = 0; k < 10; k++) {
          int c1 = 3 + (k * 2);
          int c2 = c1 + 1;
          sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c1, rowIndex: rowIdx), xl.TextCellValue(''), cellStyle: cellCenter);
          sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c2, rowIndex: rowIdx), xl.IntCellValue(0), cellStyle: cellRight);
        }
        sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: rowIdx), xl.IntCellValue(0), cellStyle: cellRight);
        sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 24, rowIndex: rowIdx), xl.TextCellValue(''), cellStyle: cellRight);
        sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 25, rowIndex: rowIdx), xl.TextCellValue(''), cellStyle: cellNormal);
      }
    }

    // Baris JUMLAH (persis Slide 2)
    int rJumlah = 7 + jumlahBarisCetak;
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rJumlah), xl.TextCellValue(''), cellStyle: cellTotal);
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rJumlah), xl.TextCellValue('JUMLAH'), cellStyle: cellTotal);
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rJumlah), xl.IntCellValue(sumBruto), cellStyle: cellTotal);
    for (int k = 0; k < 10; k++) {
      int c1 = 3 + (k * 2);
      int c2 = c1 + 1;
      sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c1, rowIndex: rJumlah), xl.IntCellValue(sumQty[k]), cellStyle: cellTotal);
      sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c2, rowIndex: rJumlah), xl.IntCellValue(sumRp[k]), cellStyle: cellTotal);
    }
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: rJumlah), xl.IntCellValue(grandTotalRp), cellStyle: cellTotal);
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 24, rowIndex: rJumlah), xl.IntCellValue(sumNetto), cellStyle: cellTotal);
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 25, rowIndex: rJumlah), xl.TextCellValue(''), cellStyle: cellTotal);

    // Keterangan Kode & Kolom Tanda Tangan Persis Slide 2
    int rKet = rJumlah + 2;
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rKet), xl.TextCellValue('Rata-rata hasil panen per orang = ...... Jjg = ...... Kg'), cellStyle: xl.CellStyle(fontSize: 8));
    sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rKet + 1), xl.TextCellValue('Keterangan :'), cellStyle: xl.CellStyle(bold: true, fontSize: 8));

    final ketList = [
      ['BM', 'Memotong Buah Mentah'],
      ['BTP', 'Buah Tinggal di Pokok'],
      ['BTC', 'Buah Tinggal di Gawangan / Piringan'],
      ['BPM', 'Buah Mentah Diperam'],
      ['TP', 'Tangkai Panjang > 3 CM'],
      ['SP', 'Susunan Pelepah & Tidak potong 2 pelepah'],
      ['OP', 'Over Pruning'],
      ['PS', 'Pelepah Sengkleh'],
      ['BRDT', 'Berondol Tinggal /Ancak & TPH'],
      ['ALT', 'Alas TPH'],
    ];
    for (int idx = 0; idx < ketList.length; idx++) {
      sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rKet + 2 + idx), xl.TextCellValue(ketList[idx][0]), cellStyle: xl.CellStyle(fontSize: 8));
      sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rKet + 2 + idx), xl.TextCellValue(ketList[idx][1]), cellStyle: xl.CellStyle(fontSize: 8));
    }

    // Kotak Tanda Tangan (Disetujui Oleh, Diperiksa Oleh, Dibuat Oleh, Dibuat oleh)
    final ttdHeaders = [
      [14, 16, 'Disetujui Oleh', 'Asisten Afdeling ($asisten)'],
      [17, 19, 'Diperiksa Oleh', 'Mandor 1'],
      [20, 22, 'Dibuat Oleh', 'Mandor Panen ($mandor)'],
      [23, 25, 'Dibuat oleh.', 'Kerani Buah ($kerani)'],
    ];
    for (var ttd in ttdHeaders) {
      int cStart = ttd[0] as int;
      int cEnd = ttd[1] as int;
      sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: cStart, rowIndex: rKet + 2), xl.CellIndex.indexByColumnRow(columnIndex: cEnd, rowIndex: rKet + 2));
      sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: cStart, rowIndex: rKet + 2), xl.TextCellValue(ttd[2].toString()), cellStyle: cellCenter);

      sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: cStart, rowIndex: rKet + 3), xl.CellIndex.indexByColumnRow(columnIndex: cEnd, rowIndex: rKet + 6));
      for (int rr = rKet + 3; rr <= rKet + 6; rr++) {
        for (int cc = cStart; cc <= cEnd; cc++) {
          sDenda.cell(xl.CellIndex.indexByColumnRow(columnIndex: cc, rowIndex: rr)).cellStyle = cellNormal;
        }
      }

      sDenda.merge(xl.CellIndex.indexByColumnRow(columnIndex: cStart, rowIndex: rKet + 7), xl.CellIndex.indexByColumnRow(columnIndex: cEnd, rowIndex: rKet + 7));
      sDenda.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: cStart, rowIndex: rKet + 7), xl.TextCellValue(ttd[3].toString()), cellStyle: cellCenter);
    }

    // Sheet 2: Lampiran Foto Grid & Screenshot Peta Trek
    xl.Sheet sFoto = excel['LAMPIRAN_FOTO_GRID'];
    sFoto.appendRow([xl.TextCellValue('LAMPIRAN BUKTI FOTO LAPANGAN & PETA TREK GPS - PT KENCANA AGRI')]);
    sFoto.appendRow([
      xl.TextCellValue('Slot'),
      xl.TextCellValue('Keterangan Kolom 1'),
      xl.TextCellValue('Nama File 1'),
      xl.TextCellValue('Keterangan Kolom 2'),
      xl.TextCellValue('Nama File 2'),
    ]);

    final semuaFoto = [];
    final savedMapSs = (await DatabaseHelper.instance.getSetting('saved_map_ss')).toString();
    if (savedMapSs.isNotEmpty && File(savedMapSs).existsSync()) {
      semuaFoto.add({'ket': 'SCREENSHOT PETA BLOK & JALUR TREK TEMUAN GPS', 'path': savedMapSs});
    }
    for (var r in dataInspeksi) {
      final paths = List.from(jsonDecode(r['foto_paths'].toString()));
      for (var fp in paths) {
        semuaFoto.add({
          'ket': 'Blok ${r['blok']} (Ancak ${r['no_ancak']}) - ${r['pemanen']} | Losses: ${r['persen_losses']}%',
          'path': fp.toString(),
        });
      }
    }

    int gridNo = 1;
    for (int i = 0; i < semuaFoto.length; i += 2) {
      final f1 = semuaFoto[i];
      final f2 = (i + 1 < semuaFoto.length) ? semuaFoto[i + 1] : null;
      sFoto.appendRow([
        xl.IntCellValue(gridNo++),
        xl.TextCellValue(f1['ket'].toString()),
        xl.TextCellValue(p.basename(f1['path'].toString())),
        xl.TextCellValue(f2 != null ? f2['ket'].toString() : '-'),
        xl.TextCellValue(f2 != null ? p.basename(f2['path'].toString()) : '-'),
      ]);
    }

    final dir = await getTemporaryDirectory();
    final tglFile = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final filePath = p.join(dir.path, 'DENDA_PANEN_SAP_IPD_$tglFile.xlsx');
    final fileBytes = excel.save();

    if (fileBytes != null) {
      await File(filePath).writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(filePath)], text: 'Rekap Denda Panen (SAP) - PT Kencana Agri');
    }
  }
}
