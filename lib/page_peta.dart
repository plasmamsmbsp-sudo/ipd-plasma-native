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
  final TransformationController _zoomCtrl = TransformationController();
  String? _pdfPath;
  Position? _gpsSekarang;
  StreamSubscription? _liveGpsSub;
  bool _sedangRekamJalur = false;
  String _namaSesi = '';
  int _jumlahTitikTerekam = 0;
  var _daftarPinDanTrek = [];
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _muatPetaTersimpan();
    _muatPinDanTrek();
    _mulaiGpsRealTime();
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

  void _mulaiGpsRealTime() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final awal = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _gpsSekarang = awal);

      _liveGpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 3),
      ).listen((Position pos) async {
        if (mounted) {
          setState(() => _gpsSekarang = pos);
        }
        if (_sedangRekamJalur) {
          await DatabaseHelper.instance.insertGpsPoint(
            _namaSesi,
            pos.latitude,
            pos.longitude,
            tipePin: 'TREK',
            keterangan: 'Jalur Inspeksi',
          );
          if (mounted) {
            setState(() => _jumlahTitikTerekam++);
            _muatPinDanTrek();
          }
        }
      });
    } catch (_) {}
  }

  void _ubahZoom(double faktor) {
    final baru = (_currentScale * faktor).clamp(0.8, 6.0);
    setState(() {
      _currentScale = baru;
      _zoomCtrl.value = Matrix4.identity()..scale(baru);
    });
  }

  void _resetZoom() {
    setState(() {
      _currentScale = 1.0;
      _zoomCtrl.value = Matrix4.identity();
    });
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
            backgroundColor: Color(0xFF0A6836),
            content: Text('File Peta .PDF tersimpan permanen! Gunakan 2 jari atau tombol +/- untuk Zoom.'),
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
            backgroundColor: Color(0xFF0A6836),
            content: Text('Screenshot Peta & Lokasi Terkini tersimpan untuk Excel!'),
          ),
        );
      }
    } catch (_) {}
  }

  void _toggleRekamJalur() {
    if (_sedangRekamJalur) {
      setState(() => _sedangRekamJalur = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jalur trek disimpan ($_jumlahTitikTerekam titik).')),
      );
    } else {
      _namaSesi = 'Trek_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
      _jumlahTitikTerekam = 0;
      setState(() => _sedangRekamJalur = true);
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
    return const Color(0xFF0A6836);
  }

  @override
  void dispose() {
    _liveGpsSub?.cancel();
    _zoomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pinTemuan = _daftarPinDanTrek.where((e) => e['tipe_pin'] != 'TREK').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta PDF Real-Time & Zoom', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _captureScreenshotPeta, icon: const Icon(Icons.camera, color: Color(0xFFF7E300)), tooltip: 'SS Peta untuk Excel'),
          IconButton(onPressed: _eksporGpsTrackExcel, icon: const Icon(Icons.route), tooltip: 'Ekspor Trek Excel'),
          IconButton(onPressed: _pilihDanSimpanPetaPdf, icon: const Icon(Icons.folder_open), tooltip: 'Upload Peta PDF'),
        ],
      ),
      body: RepaintBoundary(
        key: _mapCaptureKey,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF0A6836).withOpacity(0.12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _gpsSekarang != null
                                  ? 'Live: ${_gpsSekarang!.latitude.toStringAsFixed(6)}, ${_gpsSekarang!.longitude.toStringAsFixed(6)}'
                                  : 'Mengunci GPS Real-Time...',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0A6836)),
                            ),
                          ],
                        ),
                        if (_gpsSekarang != null)
                          Text(
                            'Akurasi GPS: ±${_gpsSekarang!.accuracy.toStringAsFixed(1)} meter',
                            style: const TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _toggleRekamJalur,
                    icon: Icon(_sedangRekamJalur ? Icons.stop : Icons.fiber_manual_record, size: 14),
                    label: Text(_sedangRekamJalur ? 'Stop ($_jumlahTitikTerekam)' : 'Rekam Trek', style: const TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sedangRekamJalur ? Colors.red : const Color(0xFF0A6836),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: Colors.white,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(children: [Icon(Icons.my_location, color: Colors.blue, size: 15), Text(' Posisi Anda', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
                  Row(children: [Icon(Icons.location_on, color: Colors.red, size: 15), Text(' Buah Tinggal', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
                  Row(children: [Icon(Icons.location_on, color: Colors.orange, size: 15), Text(' Brondolan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
                  Row(children: [Icon(Icons.location_on, color: Colors.amber, size: 15), Text(' Pelepah', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
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
                            const Icon(Icons.map, size: 56, color: Color(0xFF0A6836)),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload file Peta Kerja Blok (.pdf) untuk melihat lokasi terkini real-time dengan fitur Zoom In / Out.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _pilihDanSimpanPetaPdf,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Upload & Simpan Peta .PDF'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A6836), foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        InteractiveViewer(
                          transformationController: _zoomCtrl,
                          minScale: 0.8,
                          maxScale: 6.0,
                          onInteractionEnd: (_) {
                            setState(() {
                              _currentScale = _zoomCtrl.value.getMaxScaleOnAxis();
                            });
                          },
                          child: PdfViewer.file(_pdfPath!),
                        ),
                        // Indikator Titik Lokasi Terkini Real-Time di atas Peta PDF
                        if (_gpsSekarang != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blueAccent, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.my_location, color: Colors.lightBlueAccent, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'POSISI REAL-TIME\n${_gpsSekarang!.latitude.toStringAsFixed(6)}, ${_gpsSekarang!.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Tombol Zoom In / Zoom Out / Reset di pojok kanan bawah peta
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Column(
                            children: [
                              FloatingActionButton.small(
                                heroTag: 'zoom_in',
                                backgroundColor: const Color(0xFF0A6836),
                                foregroundColor: Colors.white,
                                onPressed: () => _ubahZoom(1.35),
                                child: const Icon(Icons.zoom_in),
                              ),
                              const SizedBox(height: 6),
                              FloatingActionButton.small(
                                heroTag: 'zoom_out',
                                backgroundColor: const Color(0xFF0A6836),
                                foregroundColor: Colors.white,
                                onPressed: () => _ubahZoom(0.75),
                                child: const Icon(Icons.zoom_out),
                              ),
                              const SizedBox(height: 6),
                              FloatingActionButton.small(
                                heroTag: 'zoom_reset',
                                backgroundColor: const Color(0xFFB38E0C),
                                foregroundColor: Colors.white,
                                onPressed: _resetZoom,
                                child: const Icon(Icons.center_focus_strong),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              height: 115,
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
