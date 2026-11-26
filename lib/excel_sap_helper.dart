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

    final headerGreen = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1B5E20'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    final subHeaderGold = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#FBC02D'),
      fontColorHex: xl.ExcelColor.fromHexString('#000000'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    final totalStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: xl.ExcelColor.fromHexString('#1B5E20'),
    );

    final firstRow = dataInspeksi.first;
    final afdeling = firstRow['afdeling'].toString();
    final tanggal = firstRow['tanggal'].toString();
    final mandor = firstRow['mandor'].toString();
    final kerani = (firstRow['kerani'] ?? '-').toString();
    final asisten = firstRow['asisten'].toString();

    sDenda.appendRow([
      xl.TextCellValue('Afdeling :'),
      xl.TextCellValue(afdeling),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('DENDA PANEN'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('Standart Administrasi Panen (SAP)'),
    ]);

    sDenda.appendRow([
      xl.TextCellValue('Tanggal :'),
      xl.TextCellValue(tanggal),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('Mandor / Kerani Panen : $mandor / $kerani'),
    ]);

    sDenda.appendRow([xl.TextCellValue('')]);

    sDenda.appendRow([
      xl.TextCellValue('No. Urut'),
      xl.TextCellValue('Nama Pemanen'),
      xl.TextCellValue('Hasil Bruto (Jjg)'),
      xl.TextCellValue('BM (Jjg)'),
      xl.TextCellValue('BM (Rp)'),
      xl.TextCellValue('BTP (Jjg)'),
      xl.TextCellValue('BTP (Rp)'),
      xl.TextCellValue('BTG (Jjg)'),
      xl.TextCellValue('BTG (Rp)'),
      xl.TextCellValue('BPM (Jjg)'),
      xl.TextCellValue('BPM (Rp)'),
      xl.TextCellValue('TP (Jjg)'),
      xl.TextCellValue('TP (Rp)'),
      xl.TextCellValue('SP (Pkk)'),
      xl.TextCellValue('SP (Rp)'),
      xl.TextCellValue('OP (Pkk)'),
      xl.TextCellValue('OP (Rp)'),
      xl.TextCellValue('PS (Plp)'),
      xl.TextCellValue('PS (Rp)'),
      xl.TextCellValue('BRDT (Btr)'),
      xl.TextCellValue('BRDT (Rp)'),
      xl.TextCellValue('ALT (TPH)'),
      xl.TextCellValue('ALT (Rp)'),
      xl.TextCellValue('Jumlah (Rp)'),
      xl.TextCellValue('Hasil Netto (Jjg)'),
      xl.TextCellValue('KETERANGAN (Blok, Ancak & Losses %)'),
    ]);

    for (int col = 0; col < 26; col++) {
      sDenda.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 3)).cellStyle = headerGreen;
    }

    sDenda.appendRow([
      xl.TextCellValue('TARIF'),
      xl.TextCellValue('DENDA SOP'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.IntCellValue(10000),
      xl.TextCellValue(''),
      xl.IntCellValue(10000),
      xl.TextCellValue(''),
      xl.IntCellValue(10000),
      xl.TextCellValue(''),
      xl.IntCellValue(10000),
      xl.TextCellValue(''),
      xl.IntCellValue(500),
      xl.TextCellValue(''),
      xl.IntCellValue(2000),
      xl.TextCellValue(''),
      xl.IntCellValue(5000),
      xl.TextCellValue(''),
      xl.IntCellValue(5000),
      xl.TextCellValue(''),
      xl.IntCellValue(200),
      xl.TextCellValue(''),
      xl.IntCellValue(1000),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
    ]);

    for (int col = 0; col < 26; col++) {
      sDenda.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 4)).cellStyle = subHeaderGold;
    }

    int sumBruto = 0;
    int sumNetto = 0;
    int grandTotalRp = 0;
    final sumQty = List.filled(10, 0);
    final sumRp = List.filled(10, 0);

    final int jumlahBarisCetak = dataInspeksi.length > 25 ? dataInspeksi.length : 25;

    for (int i = 0; i < jumlahBarisCetak; i++) {
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

        final List<xl.CellValue> rowCells = [
          xl.IntCellValue(i + 1),
          xl.TextCellValue(r['pemanen'].toString()),
          xl.IntCellValue(bruto),
        ];

        for (int pIdx = 0; pIdx < daftarParameterSop.length; pIdx++) {
          final sop = daftarParameterSop[pIdx];
          final int qty = (temuan[sop.kode] ?? 0) as int;
          final int rp = qty * sop.dendaPerUnit;
          sumQty[pIdx] += qty;
          sumRp[pIdx] += rp;
          rowCells.add(xl.IntCellValue(qty));
          rowCells.add(xl.IntCellValue(rp));
        }

        final ket = 'Blok ${r['blok']} | Ancak ${r['no_ancak']} | Losses: ${r['total_losses_kg']} kg (${r['persen_losses']}%)';
        rowCells.add(xl.IntCellValue(totalDendaRow));
        rowCells.add(xl.IntCellValue(netto));
        rowCells.add(xl.TextCellValue(ket));

        sDenda.appendRow(rowCells);
      } else {
        sDenda.appendRow([
          xl.IntCellValue(i + 1),
          xl.TextCellValue(''),
          xl.TextCellValue(''),
          xl.TextCellValue(''),
          xl.IntCellValue(0),
          xl.TextCellValue(''),
          xl.IntCellValue(0),
          xl.TextCellValue(''),
          xl.IntCellValue(0),
          xl.TextCellValue(''),
          xl.IntCellValue(0),
          xl.TextCellValue(''),
          xl.IntCellValue(0),
          xl.TextCellValue(''),
          xl.IntCellValue(0),
          xl.TextCellValue(''),
          xl.IntCellValue(0),
          xl.TextCellValue(''),
          xl.IntCellValue(0),
          xl.TextCellValue(''),
          xl.IntCellValue(0),
          xl.TextCellValue(''),
          xl.IntCellValue(0),
          xl.IntCellValue(0),
          xl.TextCellValue(''),
          xl.TextCellValue(''),
        ]);
      }
    }

    final List<xl.CellValue> totalRowCells = [
      xl.TextCellValue(''),
      xl.TextCellValue('JUMLAH'),
      xl.IntCellValue(sumBruto),
    ];
    for (int pIdx = 0; pIdx < 10; pIdx++) {
      totalRowCells.add(xl.IntCellValue(sumQty[pIdx]));
      totalRowCells.add(xl.IntCellValue(sumRp[pIdx]));
    }
    totalRowCells.add(xl.IntCellValue(grandTotalRp));
    totalRowCells.add(xl.IntCellValue(sumNetto));
    totalRowCells.add(xl.TextCellValue(''));
    sDenda.appendRow(totalRowCells);

    final int idxBarisJumlah = 5 + jumlahBarisCetak;
    for (int col = 0; col < 26; col++) {
      sDenda.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: idxBarisJumlah)).cellStyle = totalStyle;
    }

    sDenda.appendRow([xl.TextCellValue('')]);
    sDenda.appendRow([
      xl.TextCellValue('Keterangan Kode:'),
      xl.TextCellValue('BM = Memotong Buah Mentah'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('Disetujui Oleh,'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('Diperiksa Oleh,'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('Dibuat Oleh,'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('Dibuat Oleh,'),
    ]);
    sDenda.appendRow([xl.TextCellValue(''), xl.TextCellValue('BTP = Buah Tinggal di Pokok | BTG = Buah Tinggal Gawangan/Piringan | BPM = Buah Mentah Diperam')]);
    sDenda.appendRow([xl.TextCellValue(''), xl.TextCellValue('TP = Tangkai Panjang > 3cm | SP = Susunan Pelepah & Tidak Potong 2 | OP = Over Pruning')]);
    sDenda.appendRow([
      xl.TextCellValue(''),
      xl.TextCellValue('PS = Pelepah Sengkleh | BRDT = Berondolan Tinggal Ancak & TPH | ALT = Alas TPH'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('($asisten) Asisten Afdeling'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('Mandor 1'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('($mandor) Mandor Panen'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('($kerani) Kerani Buah'),
    ]);

    xl.Sheet sFoto = excel['LAMPIRAN_FOTO_GRID'];
    sFoto.appendRow([
      xl.TextCellValue('LAMPIRAN BUKTI FOTO LAPANGAN & PETA TREK GPS - PT KENCANA AGRI'),
    ]);
    sFoto.appendRow([
      xl.TextCellValue('Slot'),
      xl.TextCellValue('Keterangan Bukti Foto Kolom 1'),
      xl.TextCellValue('File Foto 1'),
      xl.TextCellValue('Keterangan Bukti Foto Kolom 2'),
      xl.TextCellValue('File Foto 2'),
    ]);

    final semuaFoto = [];
    final savedMapSs = (await DatabaseHelper.instance.getSetting('saved_map_ss')).toString();
    if (savedMapSs.isNotEmpty && File(savedMapSs).existsSync()) {
      semuaFoto.add({
        'ket': 'SCREENSHOT PETA BLOK & JALUR TREK TEMUAN GPS',
        'path': savedMapSs,
      });
    }

    for (var r in dataInspeksi) {
      final paths = List.from(jsonDecode(r['foto_paths'].toString()));
      for (var fp in paths) {
        semuaFoto.add({
          'ket': 'Blok ${r['blok']} (Ancak ${r['no_ancak']}) - ${r['pemanen']} | Losses: ${r['persen_losses']}% | Denda: Rp ${r['total_denda']}',
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

    xl.Sheet sMandor = excel['REKAP_LOSSES_MANDOR'];
    sMandor.appendRow([
      xl.TextCellValue('Mandor Panen'),
      xl.TextCellValue('Total Sampel Ancak'),
      xl.TextCellValue('Total Losses Brondol (kg)'),
      xl.TextCellValue('Total Losses Buah (kg)'),
      xl.TextCellValue('Total Losses (kg)'),
      xl.TextCellValue('Rata-rata Losses (%)'),
      xl.TextCellValue('Total Denda (Rp)'),
    ]);

    var perMandor = {};
    for (var r in dataInspeksi) {
      final m = r['mandor'].toString();
      if (!perMandor.containsKey(m)) perMandor[m] = [];
      (perMandor[m] as List).add(r);
    }

    perMandor.forEach((m, rawList) {
      final list = rawList as List;
      double sumB = list.fold(0.0, (s, e) => s + ((e['losses_brondolan_kg'] ?? 0.0) as num).toDouble());
      double sumBuah = list.fold(0.0, (s, e) => s + ((e['losses_buah_kg'] ?? 0.0) as num).toDouble());
      double sumTot = list.fold(0.0, (s, e) => s + ((e['total_losses_kg'] ?? 0.0) as num).toDouble());
      double avgPct = list.fold(0.0, (s, e) => s + ((e['persen_losses'] ?? 0.0) as num).toDouble()) / list.length;
      int sumD = list.fold(0, (s, e) => s + ((e['total_denda'] ?? 0) as int));

      sMandor.appendRow([
        xl.TextCellValue(m.toString()),
        xl.IntCellValue(list.length),
        xl.DoubleCellValue(double.parse(sumB.toStringAsFixed(2))),
        xl.DoubleCellValue(double.parse(sumBuah.toStringAsFixed(2))),
        xl.DoubleCellValue(double.parse(sumTot.toStringAsFixed(2))),
        xl.DoubleCellValue(double.parse(avgPct.toStringAsFixed(2))),
        xl.IntCellValue(sumD),
      ]);
    });

    final dir = await getTemporaryDirectory();
    final tglFile = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final filePath = p.join(dir.path, 'DENDA_PANEN_SAP_IPD_$tglFile.xlsx');
    final fileBytes = excel.save();

    if (fileBytes != null) {
      await File(filePath).writeAsBytes(fileBytes);
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Rekap Denda Panen (SAP) & Losses IPD PLASMA - PT Kencana Agri',
      );
    }
  }
}
