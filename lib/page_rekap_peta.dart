import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';

class RiwayatDanEksporPage extends StatefulWidget {
  const RiwayatDanEksporPage({super.key});

  @override
  State<RiwayatDanEksporPage> createState() => _RiwayatDanEksporPageState();
}

class _RiwayatDanEksporPageState extends State<RiwayatDanEksporPage> {
  List> _dataInspeksi = [];
  bool _sedangSync = false;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    final rows = await DatabaseHelper.instance.getAllInspeksi();
    if (mounted) setState(() => _dataInspeksi = rows);
  }

  Future<void> _sinkronKeGoogleSheets() async {
    final url = await DatabaseHelper.instance.getSetting('gsheet_url');
    if (url.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Isi URL Google Apps Script terlebih dahulu di tab "Master & Sheet"!')),
        );
      }
      return;
    }

    final belumSync = _dataInspeksi.where((e) => (e['synced'] ?? 0) == 0).toList();
    if (belumSync.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua data sudah tersinkron ke Google Sheets.')),
        );
      }
      return;
    }

    setState(() => _sedangSync = true);
    int berhasil = 0;

    try {
      for (var row in belumSync) {
        final payload = {
          'tanggal': row['tanggal'],
          'pt': row['pt'],
          'afdeling': row['afdeling'],
          'blok': row['blok'],
          'no_ancak': row['no_ancak'],
          'pokok_sampel': row['pokok_sampel'],
          'pemanen': row['pemanen'],
          'mandor': row['mandor'],
          'asisten': row['asisten'],
          'total_denda': row['total_denda'],
          'nilai_mutu': row['nilai_mutu'],
          'gps': (row['lat'] != null) ? '${row['lat']}, ${row['lng']}' : '-',
          'temuan_json': row['temuan_json'],
          'catatan': row['catatan'] ?? '',
        };

        final resp = await http.post(
          Uri.parse(url.trim()),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (resp.statusCode == 200 || resp.statusCode == 302) {
          await DatabaseHelper.instance.markSynced(row['id'] as int);
          berhasil++;
        }
      }
      await _muatData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFF1B5E20), content: Text('Berhasil sinkron $berhasil data ke Google Sheets!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Gagal koneksi internet / URL Sheet salah: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sedangSync = false);
    }
  }

  Future<void> _eksporExcelDanBagikan() async {
    if (_dataInspeksi.isEmpty) return;

    var excel = xl.Excel.createExcel();
    xl.Sheet sheetRekap = excel['REKAP_IPD'];
    excel.delete('Sheet1');

    sheetRekap.appendRow([
      xl.TextCellValue('No'),
      xl.TextCellValue('Tanggal'),
      xl.TextCellValue('Afdeling'),
      xl.TextCellValue('Blok'),
      xl.TextCellValue('Ancak'),
      xl.TextCellValue('Pemanen'),
      xl.TextCellValue('Mandor'),
      xl.TextCellValue('Asisten'),
      xl.TextCellValue('Total Denda (Rp)'),
      xl.TextCellValue('Skor Mutu (%)'),
      xl.TextCellValue('Koordinat GPS'),
      xl.TextCellValue('Catatan'),
    ]);

    xl.Sheet sheetDetail = excel['DETAIL_TEMUAN_SOP'];
    sheetDetail.appendRow([
      xl.TextCellValue('Tanggal'),
      xl.TextCellValue('Afdeling'),
      xl.TextCellValue('Blok'),
      xl.TextCellValue('Pemanen'),
      ...daftarParameterSop.map((e) => xl.TextCellValue('${e.kode} - ${e.nama} (${e.satuan})')),
    ]);

    xl.Sheet sheetRingkasanMandor = excel['REKAP_PER_MANDOR'];
    sheetRingkasanMandor.appendRow([
      xl.TextCellValue('Mandor'),
      xl.TextCellValue('Jumlah Sampel Ancak'),
      xl.TextCellValue('Total Denda (Rp)'),
      xl.TextCellValue('Rata-rata Mutu (%)'),
    ]);

    Map<String, List>> perMandor = {};

    for (int i = 0; i < _dataInspeksi.length; i++) {
      final row = _dataInspeksi[i];
      final temuan = Map<String, dynamic>.from(jsonDecode(row['temuan_json']));
      final gps = (row['lat'] != null) ? '${row['lat']}, ${row['lng']}' : '-';

      perMandor.putIfAbsent(row['mandor'], () => []).add(row);

      sheetRekap.appendRow([
        xl.IntCellValue(i + 1),
        xl.TextCellValue(row['tanggal']),
        xl.TextCellValue(row['afdeling']),
        xl.TextCellValue(row['blok']),
        xl.TextCellValue(row['no_ancak']),
        xl.TextCellValue(row['pemanen']),
        xl.TextCellValue(row['mandor']),
        xl.TextCellValue(row['asisten']),
        xl.IntCellValue(row['total_denda']),
        xl.DoubleCellValue((row['nilai_mutu'] as num).toDouble()),
        xl.TextCellValue(gps),
        xl.TextCellValue(row['catatan'] ?? ''),
      ]);

      sheetDetail.appendRow([
        xl.TextCellValue(row['tanggal']),
        xl.TextCellValue(row['afdeling']),
        xl.TextCellValue(row['blok']),
        xl.TextCellValue(row['pemanen']),
        ...daftarParameterSop.map((e) => xl.IntCellValue((temuan[e.kode] ?? 0) as int)),
      ]);
    }

    perMandor.forEach((mandor, list) {
      int sumDenda = list.fold(0, (s, e) => s + (e['total_denda'] as int));
      double avgMutu = list.fold(0.0, (s, e) => s + (e['nilai_mutu'] as num).toDouble()) / list.length;
      sheetRingkasanMandor.appendRow([
        xl.TextCellValue(mandor),
        xl.IntCellValue(list.length),
        xl.IntCellValue(sumDenda),
        xl.DoubleCellValue(double.parse(avgMutu.toStringAsFixed(1))),
      ]);
    });

    final dir = await getTemporaryDirectory();
    final tglFile = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final filePath = p.join(dir.path, 'LAPORAN_IPD_PLASMA_$tglFile.xlsx');
    final fileBytes = excel.save();

    if (fileBytes != null) {
      await File(filePath).writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(filePath)], text: 'Laporan IPD PLASMA - PT Kencana Agri Plasma Wanggarasi');
    }
  }

  void _bagikanKeWhatsApp() {
    if (_dataInspeksi.isEmpty) return;
    final fmtRp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final hariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dataHariIni = _dataInspeksi.where((e) => e['tanggal'] == hariIni).toList();
    final sumber = dataHariIni.isNotEmpty ? dataHariIni : _dataInspeksi;

    int grandTotalDenda = sumber.fold(0, (sum, item) => sum + (item['total_denda'] as int));
    double rataMutu = sumber.fold(0.0, (sum, item) => sum + (item['nilai_mutu'] as num).toDouble()) / sumber.length;

    StringBuffer sb = StringBuffer();
    sb.writeln('*LAPORAN INSPEKSI PANEN (IPD PLASMA)*');
    sb.writeln('*PT KENCANA AGRI - PLASMA WANGGARASI*');
    sb.writeln('Tanggal: ${DateFormat('dd MMM yyyy').format(DateTime.now())}');
    sb.writeln('Total Sampel: ${sumber.length} Ancak | Rata-rata Mutu: *${rataMutu.toStringAsFixed(1)}%*');
    sb.writeln('Total Denda SOP: *${fmtRp.format(grandTotalDenda)}*');
    sb.writeln('-----------------------------------');

    for (var r in sumber) {
      sb.writeln('• *${r['afdeling']} Blok ${r['blok']}* (Ancak ${r['no_ancak']}) - *${r['pemanen']}*');
      sb.writeln('  Mandor: ${r['mandor']} | Mutu: ${r['nilai_mutu']}% | Denda: ${fmtRp.format(r['total_denda'])}');
      final temuan = Map<String, dynamic>.from(jsonDecode(r['temuan_json']));
      List<String> rincian = [];
      for (var sop in daftarParameterSop) {
        int qty = (temuan[sop.kode] ?? 0) as int;
        if (qty > 0) rincian.add('${sop.nama}: $qty ${sop.satuan}');
      }
      if (rincian.isNotEmpty) sb.writeln('  Temuan: ${rincian.join(', ')}');
    }

    Share.share(sb.toString());
  }

  @override
  Widget build(BuildContext context) {
    final fmtRp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final belumSyncCount = _dataInspeksi.where((e) => (e['synced'] ?? 0) == 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap, Excel & Sync Sheet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _sedangSync ? null : _sinkronKeGoogleSheets,
            icon: _sedangSync
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.cloud_upload, color: Color(0xFFFBC02D)),
            tooltip: 'Sync ke Google Sheets',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sedangSync ? null : _sinkronKeGoogleSheets,
                    icon: const Icon(Icons.cloud_sync),
                    label: Text('Sync ke Google Sheets ($belumSyncCount belum terkirim)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _eksporExcelDanBagikan,
                        icon: const Icon(Icons.table_view),
                        label: const Text('Excel 3 Sheet'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _bagikanKeWhatsApp,
                        icon: const Icon(Icons.send),
                        label: const Text('Kirim WhatsApp'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBC02D), foregroundColor: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _dataInspeksi.isEmpty
                ? const Center(child: Text('Belum ada riwayat inspeksi tersimpan.'))
                : ListView.builder(
                    itemCount: _dataInspeksi.length,
                    itemBuilder: (ctx, i) {
                      final r = _dataInspeksi[i];
                      final isSynced = (r['synced'] ?? 0) == 1;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1B5E20),
                            child: Text(r['blok'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text('${r['pemanen']} (Ancak ${r['no_ancak']})', style: const TextStyle(fontWeight: FontWeight.bold))),
                              Icon(isSynced ? Icons.cloud_done : Icons.cloud_off, size: 16, color: isSynced ? Colors.green : Colors.orange),
                            ],
                          ),
                          subtitle: Text('${r['tanggal']} • ${r['afdeling']} • Mandor: ${r['mandor']}\nMutu: ${r['nilai_mutu']}% | Denda: ${fmtRp.format(r['total_denda'])}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await DatabaseHelper.instance.deleteInspeksi(r['id']);
                              _muatData();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class PetaBlokGpsPage extends StatefulWidget {
  const PetaBlokGpsPage({super.key});

  @override
  State<PetaBlokGpsPage> createState() => _PetaBlokGpsPageState();
}

class _PetaBlokGpsPageState extends State<PetaBlokGpsPage> {
  String? _pdfPath;
  Position? _gpsSekarang;
  bool _sedangRekamJalur = false;
  StreamSubscription<Position>? _gpsSub;
  String _namaSesi = '';
  int _jumlahTitikTerekam = 0;

  Future<void> _pilihPetaPdf() async {
    FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (res != null && res.files.single.path != null) {
      setState(() => _pdfPath = res.files.single.path);
    }
  }

  Future<void> _cekGps() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _gpsSekarang = pos);
    } catch (_) {}
  }

  void _toggleRekamJalur() {
    if (_sedangRekamJalur) {
      _gpsSub?.cancel();
      setState(() => _sedangRekamJalur = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rekam jalur dihentikan. Total $_jumlahTitikTerekam titik GPS tersimpan.')),
      );
    } else {
      _namaSesi = 'Inspeksi_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
      _jumlahTitikTerekam = 0;
      setState(() => _sedangRekamJalur = true);

      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((Position pos) async {
        await DatabaseHelper.instance.insertGpsPoint(_namaSesi, pos.latitude, pos.longitude);
        if (mounted) {
          setState(() {
            _gpsSekarang = pos;
            _jumlahTitikTerekam++;
          });
        }
      });
    }
  }

  Future<void> _eksporGpsTrackExcel() async {
    final tracks = await DatabaseHelper.instance.getGpsTracks();
    if (tracks.isEmpty) return;

    var excel = xl.Excel.createExcel();
    xl.Sheet sheet = excel['JEJAK_GPS_INSPEKSI'];
    excel.delete('Sheet1');
    sheet.appendRow([xl.TextCellValue('Sesi'), xl.TextCellValue('Waktu'), xl.TextCellValue('Latitude'), xl.TextCellValue('Longitude')]);
    for (var t in tracks) {
      sheet.appendRow([
        xl.TextCellValue(t['sesi']),
        xl.TextCellValue(t['waktu']),
        xl.DoubleCellValue((t['lat'] as num).toDouble()),
        xl.DoubleCellValue((t['lng'] as num).toDouble()),
      ]);
    }
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'GPS_TRACK_IPD_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx');
    final bytes = excel.save();
    if (bytes != null) {
      await File(path).writeAsBytes(bytes);
      await Share.shareXFiles([XFile(path)], text: 'Rekam Jalur GPS Inspeksi Lapangan');
    }
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cekGps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Blok PDF & Track GPS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _eksporGpsTrackExcel, icon: const Icon(Icons.route, color: Color(0xFFFBC02D)), tooltip: 'Ekspor Titik GPS'),
          IconButton(onPressed: _pilihPetaPdf, icon: const Icon(Icons.folder_open), tooltip: 'Buka Peta PDF'),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF1B5E20).withOpacity(0.1),
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _gpsSekarang != null
                      ? 'GPS: ${_gpsSekarang!.latitude.toStringAsFixed(6)}, ${_gpsSekarang!.longitude.toStringAsFixed(6)}'
                      : 'Mencari sinyal satelit GPS...',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B5E20)),
                ),
                ElevatedButton.icon(
                  onPressed: _toggleRekamJalur,
                  icon: Icon(_sedangRekamJalur ? Icons.stop : Icons.fiber_manual_record, size: 16),
                  label: Text(_sedangRekamJalur ? 'Stop ($_jumlahTitikTerekam)' : 'Rekam Jalur', style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sedangRekamJalur ? Colors.red : const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _pdfPath == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map, size: 64, color: Color(0xFF1B5E20)),
                          const SizedBox(height: 12),
                          const Text(
                            'Muat Peta Kerja Afdeling / Blok Plasma Wanggarasi (format PDF) untuk navigasi offline di lapangan.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _pilihPetaPdf,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Pilih File Peta PDF'),
                          ),
                        ],
                      ),
                    ),
                  )
                : PdfViewer.file(_pdfPath!),
          ),
        ],
      ),
    );
  }
}

class MasterDanSyncPage extends StatefulWidget {
  const MasterDanSyncPage({super.key});

  @override
  State<MasterDanSyncPage> createState() => _MasterDanSyncPageState();
}

class _MasterDanSyncPageState extends State<MasterDanSyncPage> {
  final _urlCtrl = TextEditingController();
  final _asistenCtrl = TextEditingController();
  final _tambahItemCtrl = TextEditingController();
  String _tipeDipilih = 'BLOK';
  List<String> _daftarItem = [];

  @override
  void initState() {
    super.initState();
    _muatSemua();
  }

  Future<void> _muatSemua() async {
    final url = await DatabaseHelper.instance.getSetting('gsheet_url');
    final asisten = await DatabaseHelper.instance.getSetting('asisten_default');
    final items = await DatabaseHelper.instance.getMasterByTipe(_tipeDipilih);
    if (mounted) {
      setState(() {
        _urlCtrl.text = url;
        _asistenCtrl.text = asisten;
        _daftarItem = items;
      });
    }
  }

  @o
