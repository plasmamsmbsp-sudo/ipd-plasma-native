import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IpdPlasmaApp());
}

// ============================================================================
// KONSTANTA & 10 PARAMETER DENDA SOP PANEN (PT KENCANA AGRI - PLASMA WANGGARASI)
// ============================================================================
class SopDendaItem {
  final String kode;
  final String nama;
  final String satuan;
  final int dendaPerUnit;
  final String kategori; // 'ANCAK' atau 'TPH'

  const SopDendaItem({
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.dendaPerUnit,
    required this.kategori,
  });
}

const List<SopDendaItem> daftarParameterSop = [
  SopDendaItem(kode: 'P1', nama: 'Buah Mentah Dipanen', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'TPH'),
  SopDendaItem(kode: 'P2', nama: 'Buah Matang Tinggal di Pokok', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P3', nama: 'Buah Tinggal di Gawangan/Piringan', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P4', nama: 'Buah Mentah Diperam/Disembunyikan', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P5', nama: 'Tangkai Panjang (> 3 cm)', satuan: 'Jjg', dendaPerUnit: 500, kategori: 'TPH'),
  SopDendaItem(kode: 'P6', nama: 'Susunan Pelepah / Tidak Potong 2', satuan: 'Plp', dendaPerUnit: 2000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P7', nama: 'Over Pruning (Pelepah Sengkleh/Habis)', satuan: 'Pkk', dendaPerUnit: 5000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P8', nama: 'Pelepah Sengkleh Tidak Dipotong', satuan: 'Plp', dendaPerUnit: 5000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P9', nama: 'Berondolan Tinggal di Piringan/Pasar Pikul', satuan: 'Btr', dendaPerUnit: 200, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P10', nama: 'Tidak Pakai Alas TPH / Berondolan Kotor', satuan: 'TPH', dendaPerUnit: 1000, kategori: 'TPH'),
];

// ============================================================================
// DATABASE OFFLINE SQLITE PERMANEN
// ============================================================================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ipd_plasma_wanggarasi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inspeksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        pt TEXT NOT NULL,
        afdeling TEXT NOT NULL,
        blok TEXT NOT NULL,
        no_ancak TEXT NOT NULL,
        pokok_sampel INTEGER NOT NULL,
        pemanen TEXT NOT NULL,
        mandor TEXT NOT NULL,
        asisten TEXT NOT NULL,
        lat REAL,
        lng REAL,
        temuan_json TEXT NOT NULL,
        total_denda INTEGER NOT NULL,
        nilai_mutu REAL NOT NULL,
        foto_paths TEXT NOT NULL,
        catatan TEXT
      )
    ''');
  }

  Future<int> insertInspeksi(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('inspeksi', row);
  }

  Future<List>> getAllInspeksi() async {
    final db = await instance.database;
    return await db.query('inspeksi', orderBy: 'id DESC');
  }

  Future<int> deleteInspeksi(int id) async {
    final db = await instance.database;
    return await db.delete('inspeksi', where: 'id = ?', whereArgs: [id]);
  }
}

// ============================================================================
// APLIKASI UTAMA (TEMA HIJAU & EMAS PT KENCANA AGRI)
// ============================================================================
class IpdPlasmaApp extends StatelessWidget {
  const IpdPlasmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPD PLASMA - Kencana Agri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // Forest Green Kencana Agri
          primary: const Color(0xFF1B5E20),
          secondary: const Color(0xFFFBC02D), // Gold/Yellow Kencana Agri
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  // ============================================================================
// HALAMAN 1: FORM INPUT INSPEKSI PANEN (IPD PLASMA)
// ============================================================================
class FormInspeksiPage extends StatefulWidget {
  const FormInspeksiPage({super.key});

  @override
  State<FormInspeksiPage> createState() => _FormInspeksiPageState();
}

class _FormInspeksiPageState extends State<FormInspeksiPage> {
  final _ptCtrl = TextEditingController(text: 'PT Kencana Agri - Plasma Wanggarasi');
  final _afdCtrl = TextEditingController(text: 'AFD BSP');
  final _blokCtrl = TextEditingController();
  final _ancakCtrl = TextEditingController();
  final _pokokCtrl = TextEditingController(text: '25');
  final _pemanenCtrl = TextEditingController();
  final _mandorCtrl = TextEditingController(text: 'Mas Budi');
  final _asistenCtrl = TextEditingController(text: 'Sukri');
  final _catatanCtrl = TextEditingController();

  DateTime _tanggal = DateTime.now();
  Position? _posisiGps;
  bool _sedangAmbilGps = false;

  final Map<String, int> _jumlahTemuan = {
    for (var item in daftarParameterSop) item.kode: 0
  };
  final List<String> _fotoPaths = [];

  @override
  void initState() {
    super.initState();
    _ambilGps();
  }

  Future<void> _ambilGps() async {
    setState(() => _sedangAmbilGps = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) setState(() => _posisiGps = pos);
      }
    } catch (_) {}
    if (mounted) setState(() => _sedangAmbilGps = false);
  }

  Future<void> _ambilFoto(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? foto = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (foto != null) {
      final dir = await getApplicationDocumentsDirectory();
      final namaFile = 'IPD_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePermanen = await File(foto.path).copy(p.join(dir.path, namaFile));
      setState(() => _fotoPaths.add(filePermanen.path));
    }
  }

  int get _totalDenda {
    int total = 0;
    for (var item in daftarParameterSop) {
      total += (_jumlahTemuan[item.kode] ?? 0) * item.dendaPerUnit;
    }
    return total;
  }

  double get _nilaiMutu {
    int jmlPelanggaran = _jumlahTemuan.values.fold(0, (a, b) => a + b);
    double skor = 100.0 - (jmlPelanggaran * 2.5);
    return skor < 0 ? 0.0 : skor;
  }

  Future<void> _simpanInspeksi() async {
    if (_blokCtrl.text.trim().isEmpty || _pemanenCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi Blok dan Nama Pemanen terlebih dahulu!')),
      );
      return;
    }

    final data = {
      'tanggal': DateFormat('yyyy-MM-dd').format(_tanggal),
      'pt': _ptCtrl.text.trim(),
      'afdeling': _afdCtrl.text.trim(),
      'blok': _blokCtrl.text.trim().toUpperCase(),
      'no_ancak': _ancakCtrl.text.trim(),
      'pokok_sampel': int.tryParse(_pokokCtrl.text) ?? 25,
      'pemanen': _pemanenCtrl.text.trim(),
      'mandor': _mandorCtrl.text.trim(),
      'asisten': _asistenCtrl.text.trim(),
      'lat': _posisiGps?.latitude,
      'lng': _posisiGps?.longitude,
      'temuan_json': jsonEncode(_jumlahTemuan),
      'total_denda': _totalDenda,
      'nilai_mutu': _nilaiMutu,
      'foto_paths': jsonEncode(_fotoPaths),
      'catatan': _catatanCtrl.text.trim(),
    };

    await DatabaseHelper.instance.insertInspeksi(data);

    setState(() {
      _blokCtrl.clear();
      _ancakCtrl.clear();
      _pemanenCtrl.clear();
      _catatanCtrl.clear();
      for (var item in daftarParameterSop) {
        _jumlahTemuan[item.kode] = 0;
      }
      _fotoPaths.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1B5E20),
          content: Text('Data Inspeksi IPD tersimpan ke Database Offline!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmtRp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IPD PLASMA - KENCANA AGRI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Inspeksi Panen Kelapa Sawit (Native)', style: TextStyle(fontSize: 11, color: Color(0xFFFBC02D))),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _ambilGps,
            icon: _sedangAmbilGps
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(_posisiGps != null ? Icons.gps_fixed : Icons.gps_off,
                    color: _posisiGps != null ? const Color(0xFFFBC02D) : Colors.redAccent),
            tooltip: 'Perbarui Koordinat GPS',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // KARTU IDENTITAS LOKASI & PETUGAS
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('1. IDENTITAS BLOK & PEMANEN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _tanggal,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _tanggal = picked);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('dd/MM/yyyy').format(_tanggal)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _afdCtrl, decoration: const InputDecoration(labelText: 'Afdeling', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _blokCtrl, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Blok *', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _ancakCtrl, decoration: const InputDecoration(labelText: 'No. Ancak', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(flex: 2, child: TextField(controller: _pemanenCtrl, decoration: const InputDecoration(labelText: 'Nama Pemanen *', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _pokokCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jml Pokok', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _mandorCtrl, decoration: const InputDecoration(labelText: 'Mandor Panen', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _asistenCtrl, decoration: const InputDecoration(labelText: 'Asisten Afdeling', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  if (_posisiGps != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'GPS Terkunci: ${_posisiGps!.latitude.toStringAsFixed(6)}, ${_posisiGps!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // KARTU 10 PARAMETER DENDA SOP
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. TEMUAN 10 PARAMETER DENDA SOP', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const Divider(),
                  ...daftarParameterSop.map((item) {
                    final nilai = _jumlahTemuan[item.kode] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.kode}. ${item.nama}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('${fmtRp.format(item.dendaPerUnit)} / ${item.satuan} (${item.kategori})',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: nilai > 0 ? () => setState(() => _jumlahTemuan[item.kode] = nilai - 1) : null,
                            icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text('$nilai', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _jumlahTemuan[item.kode] = nilai + 1),
                            icon: const Icon(Icons.add_circle, color: Color(0xFF1B5E20)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // KARTU FOTO BUKTI & CATATAN
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('3. FOTO BUKTI LAPANGAN & CATATAN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _ambilFoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => _ambilFoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeri'),
                      ),
                    ],
                  ),
                  if (_fotoPaths.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 85,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _fotoPaths.length,
                        itemBuilder: (ctx, i) => Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(_fotoPaths[i]), width: 85, height: 85, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _fotoPaths.removeAt(i)),
                                child: const CircleAvatar(radius: 11, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: _catatanCtrl,
                    decoration: const InputDecoration(labelText: 'Catatan / Tindak Lanjut Mandor', border: OutlineInputBorder(), isDense: true),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // RINGKASAN DENDA & TOMBOL SIMPAN
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Denda: ${fmtRp.format(_totalDenda)}',
                        style: const TextStyle(color: Color(0xFFFBC02D), fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Skor Mutu Panen: ${_nilaiMutu.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _simpanInspeksi,
                  icon: const Icon(Icons.save),
                  label: const Text('SIMPAN DATA', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBC02D),
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================================
// HALAMAN 2: REKAP DATA, EKSPOR EXCEL (.XLSX) & SHARE WHATSAPP
// ============================================================================
class RiwayatDanEksporPage extends StatefulWidget {
  const RiwayatDanEksporPage({super.key});

  @override
  State<RiwayatDanEksporPage> createState() => _RiwayatDanEksporPageState();
}

class _RiwayatDanEksporPageState extends State<RiwayatDanEksporPage> {
  List> _dataInspeksi = [];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    final rows = await DatabaseHelper.instance.getAllInspeksi();
    if (mounted) setState(() => _dataInspeksi = rows);
  }

  Future<void> _eksporExcelDanBagikan() async {
    if (_dataInspeksi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada data inspeksi untuk diekspor.')));
      return;
    }

    var excel = xl.Excel.createExcel();
    // SHEET 1: REKAP INSPEKSI
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

    // SHEET 2: DETAIL 10 PARAMETER
    xl.Sheet sheetDetail = excel['DETAIL_TEMUAN_SOP'];
    sheetDetail.appendRow([
      xl.TextCellValue('Tanggal'),
      xl.TextCellValue('Blok'),
      xl.TextCellValue('Pemanen'),
      ...daftarParameterSop.map((e) => xl.TextCellValue('${e.kode} (${e.satuan})')),
    ]);

    for (int i = 0; i < _dataInspeksi.length; i++) {
      final row = _dataInspeksi[i];
      final temuan = Map<String, dynamic>.from(jsonDecode(row['temuan_json']));
      final gps = (row['lat'] != null) ? '${row['lat']}, ${row['lng']}' : '-';

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
        xl.TextCellValue(row['blok']),
        xl.TextCellValue(row['pemanen']),
        ...daftarParameterSop.map((e) => xl.IntCellValue((temuan[e.kode] ?? 0) as int)),
      ]);
    }

    final dir = await getTemporaryDirectory();
    final tglFile = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final filePath = p.join(dir.path, 'LAPORAN_IPD_PLASMA_$tglFile.xlsx');
    final fileBytes = excel.save();

    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Laporan Inspeksi Panen (IPD PLASMA) - PT Kencana Agri Plasma Wanggarasi',
      );
    }
  }

  void _bagikanKeWhatsApp() {
    if (_dataInspeksi.isEmpty) return;
    final fmtRp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final hariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dataHariIni = _dataInspeksi.where((e) => e['tanggal'] == hariIni).toList();
    final sumber = dataHariIni.isNotEmpty ? dataHariIni : _dataInspeksi;

    int grandTotal

  @override
  Widget build(BuildContext context) {
    final pages = [
      const FormInspeksiPage(),
      const RiwayatDanEksporPage(),
      const PetaBlokGpsPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        indicatorColor: const Color(0xFFFBC02D).withOpacity(0.35),
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check, color: Color(0xFF1B5E20)),
            label: 'Input IPD',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart, color: Color(0xFF1B5E20)),
            label: 'Rekap & Excel',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF1B5E20)),
            label: 'Peta & GPS',
          ),
        ],
      ),
    );
  }
}
