import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Data & Google Sheets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('KONFIGURASI GOOGLE SHEETS & ASISTEN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _asistenCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Asisten Default', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL Web App Google Apps Script',
                      hintText: 'https://script.google.com/macros/s/.../exec',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await DatabaseHelper.instance.saveSetting('gsheet_url', _urlCtrl.text.trim());
                        await DatabaseHelper.instance.saveSetting('asisten_default', _asistenCtrl.text.trim());
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(backgroundColor: Color(0xFF1B5E20), content: Text('Pengaturan tersimpan!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Pengaturan'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('KELOLA MASTER BLOK, AFDELING, MANDOR & PEMANEN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _tipeDipilih,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Kategori Master', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'BLOK', child: Text('Daftar Blok')),
                      DropdownMenuItem(value: 'AFDELING', child: Text('Daftar Afdeling')),
                      DropdownMenuItem(value: 'MANDOR', child: Text('Daftar Mandor Panen')),
                      DropdownMenuItem(value: 'PEMANEN', child: Text('Daftar Pemanen')),
                    ],
                    onChanged: (v) {
                      setState(() => _tipeDipilih = v!);
                      _muatSemua();
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tambahItemCtrl,
                          decoration: InputDecoration(labelText: 'Tambah $_tipeDipilih Baru', border: const OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (_tambahItemCtrl.text.trim().isEmpty) return;
                          await DatabaseHelper.instance.addMaster(_tipeDipilih, _tambahItemCtrl.text.trim());
                          _tambahItemCtrl.clear();
                          _muatSemua();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                        child: const Text('Tambah'),
                      ),
                    ],
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _daftarItem.map((item) {
                      return Chip(
                        label: Text(item, style: const TextStyle(fontSize: 12)),
                        onDeleted: () async {
                          await DatabaseHelper.instance.deleteMaster(_tipeDipilih, item);
                          _muatSemua();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
