import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:file_picker/file_picker.dart';
import 'database_helper.dart';

class PetaBlokGpsPage extends StatefulWidget {
  const PetaBlokGpsPage({super.key});

  @override
  State createState() => _PetaBlokGpsPageState();
}

class _PetaBlokGpsPageState extends State {
  final GlobalKey _mapCaptureKey = GlobalKey();
  String? _pdfPath;
  Position? _gpsSekarang;
  bool _sedangRekamJalur = false;
  StreamSubscription? _gpsSub;
  String _namaSesi = '';
  int _jumlahTitikTerekam = 0;
  var _daftarPinDanTrek = [];

  @override
  void initState() {
    super.initState();
    _muatPetaTersimpan();
    _muatPinDanTrek();
    _cekGps();
  }

  Future _muatPetaTersimpan() async {
    final saved = (await DatabaseHelper.instance.getSetting('saved_pdf_path')).toString();
    if (saved.isNotEmpty && File(saved).existsSync()) {
      if (mounted) setState(() => _pdfPath = saved);
    }
  }

  Future _muatPinDanTrek() async {
    final tracks = List.from(await DatabaseHelper.instance.getGpsTracks());
    if (mounted) setState(() => _daftarPinDanTrek = tracks);
  }

  Future _pilihDanSimpanPetaPdf() async {
    FilePickerResult? res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (res != null && res.files.single.path != null) {
      final sumber = File(res.files.single.path!);
      final dir = await getApplicationDocumentsDirectory();
      final tujuanPath = p.join(dir.path, 'PETA_BLOK_PERMANEN_KENCANA.pdf');
      await sumber.copy(tujuanPath);
      await DatabaseHelper.instance.saveSetting('saved_pdf_path', tujuanPath);

      if (mounted) {
        setState(() => _pdfPath = tujuanPath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1B5E20),
            content: Text('File Peta .PDF berhasil disimpan permanen di aplikasi!'),
          ),
        );
      }
    }
  }

  Future _captureScreenshotPeta() async {
    try {
      RenderRepaintBoundary? boundary =
          _mapCaptureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final ssPath = p.join(dir.path, 'SS_PETA_TREK_${DateTime.now().millisecondsSinceEpoch}.png');
      await File(ssPath).writeAsBytes(byteData.buffer.asUint8List());
      await DatabaseHelper.instance.saveSetting('saved_map_ss', ssPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1B5E20),
            content: Text('Screenshot Peta & Pin Temuan tersimpan otomatis untuk Lampiran Excel!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ambil screenshot peta: $e')),
        );
      }
    }
  }

  Future _cekGps() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _gpsSekarang = pos);
    } catch (_) {}
  }

  void _toggleRekamJalur() {
    if (_sedangRekamJalur) {
      _gpsSub?.cancel();
      setState(() => _sedangRekamJalur = false);
      _muatPinDanTrek();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jalur trek disimpan ($_jumlahTitikTerekam titik).')),
      );
    } else {
      _namaSesi = 'Trek_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
      _jumlahTitikTerekam = 0;
      setState(() => _sedangRekamJalur = true);

      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 8),
      ).listen((Position pos) async {
        await DatabaseHelper.instance.insertGpsPoint(
          _namaSesi,
          pos.latitude,
          pos.longitude,
          tipePin: 'TREK',
          keterangan: 'Jalur Inspeksi',
        );
        if (mounted) {
          setState(() {
            _gpsSekarang = pos;
            _jumlahTitikTerekam++;
          });
        }
      });
    }
  }

  Future _eksporGpsTrackExcel() async {
    final tracks = List.from(await DatabaseHelper.instance.getGpsTracks());
    if (tracks.isEmpty) return;

    var excel = xl.Excel.createExcel();
    xl.Sheet sheet = excel['TREK_DAN_PIN_TEMUAN'];
    excel.delete('Sheet1');
    sheet.appendRow([
      xl.TextCellValue('Sesi'),
      xl.TextCellValue('Waktu'),
      xl.TextCellValue('Warna Pin'),
      xl.TextCellValue('Keterangan Temuan'),
      xl.TextCellValue('Latitude'),
      xl.TextCellValue('Longitude'),
    ]);
    for (var t in tracks) {
      sheet.appendRow([
        xl.TextCellValue(t['sesi'].toString()),
        xl.TextCellValue(t['waktu'].toString()),
        xl.TextCellValue(t['tipe_pin'].toString()),
        xl.TextCellValue(t['keterangan'].toString()),
        xl.DoubleCellValue((t['lat'] as num).toDouble()),
        xl.DoubleCellValue((t['lng'] as num).toDouble()),
      ]);
    }
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'TREK_TEMUAN_IPD_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx');
    final bytes = excel.save();
    if (bytes != null) {
      await File(path).writeAsBytes(bytes);
      await Share.shareXFiles([XFile(path)], text: 'Data Jalur Trek & Pin Temuan GPS');
    }
  }

  Color _warnaDariPin(String tipe) {
    if (tipe == 'MERAH') return Colors.red;
    if (tipe == 'ORANYE') return Colors.orange;
    if (tipe == 'KUNING') return Colors.amber.shade700;
    return const Color(0xFF1B5E20);
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pinTemuan = _daftarPinDanTrek.where((e) => e['tipe_pin'] != 'TREK').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta PDF, Trek & Pin Temuan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _captureScreenshotPeta, icon: const Icon(Icons.camera, color: Color(0xFFFBC02D)), tooltip: 'SS Peta untuk Excel'),
          IconButton(onPressed: _eksporGpsTrackExcel, icon: const Icon(Icons.route), tooltip: 'Ekspor Trek Excel'),
          IconButton(onPressed: _pilihDanSimpanPetaPdf, icon: const Icon(Icons.folder_open), tooltip: 'Simpan Peta PDF'),
        ],
      ),
      body: RepaintBoundary(
        key: _mapCaptureKey,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _gpsSekarang != null
                          ? 'GPS: ${_gpsSekarang!.latitude.toStringAsFixed(6)}, ${_gpsSekarang!.longitude.toStringAsFixed(6)}'
                          : 'Mencari GPS...',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1B5E20)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _toggleRekamJalur,
                    icon: Icon(_sedangRekamJalur ? Icons.stop : Icons.fiber_manual_record, size: 14),
                    label: Text(_sedangRekamJalur ? 'Stop ($_jumlahTitikTerekam)' : 'Rekam Trek', style: const TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sedangRekamJalur ? Colors.red : const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: Colors.white,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(children: [Icon(Icons.location_on, color: Colors.red, size: 16), Text(' Buah Tinggal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
                  Row(children: [Icon(Icons.location_on, color: Colors.orange, size: 16), Text(' Brondolan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
                  Row(children: [Icon(Icons.location_on, color: Colors.amber, size: 16), Text(' Pelepah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: _pdfPath == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map, size: 56, color: Color(0xFF1B5E20)),
                            const SizedBox(height: 8),
                            const Text(
                              'Pilih file Peta Kerja Blok (.pdf) untuk disimpan permanen di dalam aplikasi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _pilihDanSimpanPetaPdf,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Muat & Simpan Peta .PDF'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  : PdfViewer.file(_pdfPath!),
            ),
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: pinTemuan.isEmpty
                  ? const Center(child: Text('Belum ada titik pin temuan terekam.', style: TextStyle(fontSize: 12)))
                  : ListView.builder(
                      itemCount: pinTemuan.length,
                      itemBuilder: (ctx, i) {
                        final item = pinTemuan[i];
                        final warna = _warnaDariPin(item['tipe_pin'].toString());
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.location_on, color: warna),
                          title: Text(item['keterangan'].toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text('GPS: ${item['lat']}, ${item['lng']} • ${item['waktu']}', style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
