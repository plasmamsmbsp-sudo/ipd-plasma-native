import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ipd_models.dart';
import '../services/excel_service.dart';
import '../services/sheets_service.dart';
import '../services/storage_service.dart';
import 'master_data_screen.dart';
import 'pdf_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MasterDatabase _master = MasterDatabase();
  List<InspeksiItem> _items = [];
  String? _latestMapScreenshotPath;

  final TextEditingController _blokCtrl = TextEditingController(text: 'BLOK A01');
  final TextEditingController _pemanenCtrl = TextEditingController();
  final TextEditingController _nikCtrl = TextEditingController();
  final TextEditingController _mandorCtrl = TextEditingController(text: 'Budi');
  final TextEditingController _tphCtrl = TextEditingController(text: '01');
  final TextEditingController _bjrCtrl = TextEditingController(text: '16.5');
  final TextEditingController _jjgCtrl = TextEditingController(text: '60');

  // Controller angka langsung untuk setiap kriteria (termasuk Berondolan)
  final Map<String, TextEditingController> _temuanControllers = {};
  final List<String> _currentFotos = [];

  @override
  void initState() {
    super.initState();
    for (var k in kDaftarKriteria) {
      _temuanControllers[k.kode] = TextEditingController(text: '0');
    }
    _loadAll();
  }

  Future<void> _loadAll() async {
    final m = await StorageService.loadMaster();
    final list = await StorageService.loadInspeksi();
    setState(() {
      _master = m;
      _items = list;
      if (_master.daftarMandor.isNotEmpty) _mandorCtrl.text = _master.daftarMandor.first;
    });
  }

  void _ubahNilaiKriteria(String kode, int delta) {
    final ctrl = _temuanControllers[kode]!;
    final current = int.tryParse(ctrl.text) ?? 0;
    final next = (current + delta).clamp(0, 99999);
    setState(() {
      ctrl.text = '$next';
    });
  }

  Future<void> _ambilFotoTemuan() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (picked != null) {
      setState(() => _currentFotos.add(picked.path));
    }
  }

  Future<void> _simpanInspeksi() async {
    if (_pemanenCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Pemanen wajib diisi!')),
      );
      return;
    }

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    final Map<String, int> mapTemuan = {};
    for (var k in kDaftarKriteria) {
      mapTemuan[k.kode] = int.tryParse(_temuanControllers[k.kode]!.text) ?? 0;
    }

    final newItem = InspeksiItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tanggal: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      pt: _master.pt,
      kebun: _master.kebun,
      afdeling: _master.afdeling,
      asisten: _master.asisten,
      mandor: _mandorCtrl.text.trim(),
      pemanen: _pemanenCtrl.text.trim(),
      nikPemanen: _nikCtrl.text.trim(),
      blok: _blokCtrl.text.trim().toUpperCase(),
      noTph: _tphCtrl.text.trim(),
      pokokSampel: 10,
      bjr: double.tryParse(_bjrCtrl.text) ?? 16.0,
      janjangPanen: int.tryParse(_jjgCtrl.text) ?? 50,
      temuan: mapTemuan,
      fotoPaths: List.from(_currentFotos),
      mapScreenshotPath: _latestMapScreenshotPath,
      lat: pos?.latitude,
      lng: pos?.longitude,
    );

    setState(() {
      _items.insert(0, newItem);
      _currentFotos.clear();
      for (var k in kDaftarKriteria) {
        _temuanControllers[k.kode]!.text = '0';
      }
    });
    await StorageService.saveInspeksi(_items);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B5E20),
          content: Text(
            'Tersimpan Offline! Losses: ${newItem.persentaseLosses.toStringAsFixed(2)}% | Denda: Rp ${newItem.totalDenda}',
          ),
        ),
      );
    }
  }

  Future<void> _exportDanShareExcel() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada data inspeksi untuk direkap.')),
      );
      return;
    }
    final file = await ExcelService.generateLaporanExcel(
      items: _items,
      master: _master,
      activeMapScreenshotPath: _latestMapScreenshotPath,
    );
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Rekapitulasi IPD ${_master.kebun} - ${_master.afdeling} (3 Sheet: Rekapan, Foto Temuan, SS Map)',
    );
  }

  Future<void> _kirimKeGoogleSheets() async {
    if (_master.gasWebhookUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi URL Web App Google Sheets terlebih dahulu di menu Master Data.')),
      );
      return;
    }
    final ok = await SheetsService.syncRingkasanToSheets(
      webhookUrl: _master.gasWebhookUrl,
      master: _master,
      items: _items,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? const Color(0xFF1B5E20) : Colors.red,
          content: Text(ok
              ? 'Berhasil sinkronisasi Ranking Losses, Mutu Ancak & Total Denda ke Google Sheets!'
              : 'Gagal terhubung ke Google Sheets. Periksa koneksi internet.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final totalSemuaDenda = _items.fold<int>(0, (sum, e) => sum + e.totalDenda);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            // Logo asli tanpa merubah bentuk/warna
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo_kencana.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFFF9A825)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('IPD PLASMA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${_master.kebun} • ${_master.afdeling}',
                      style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Peta PDF Blok',
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfMapScreen(
                    items: _items,
                    onMapScreenshotSaved: (path) => setState(() => _latestMapScreenshotPath = path),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Master Data & WA Sync',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MasterDataScreen(
                    master: _master,
                    onSave: (updated) => setState(() => _master = updated),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Kartu Ringkasan Eksekutif
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL DENDA TERKUMPUL',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(currency.format(totalSemuaDenda),
                            style: const TextStyle(
                                color: Color(0xFFF9A825), fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Chip(
                      backgroundColor: Colors.white,
                      label: Text('${_items.length} Sampel',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9A825),
                          foregroundColor: const Color(0xFF1B5E20),
                        ),
                        onPressed: _exportDanShareExcel,
                        icon: const Icon(Icons.table_view, size: 18),
                        label: const Text('Excel 3 Sheet', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1B5E20),
                        ),
                        onPressed: _kirimKeGoogleSheets,
                        icon: const Icon(Icons.cloud_upload, size: 18),
                        label: const Text('Sync Sheets', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Form Identitas Pemanen & Blok
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Identitas Pemeriksaan Ancak',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _blokCtrl,
                          decoration: const InputDecoration(labelText: 'Blok', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _tphCtrl,
                          decoration: const InputDecoration(labelText: 'No. TPH', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _bjrCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'BJR (Kg)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _pemanenCtrl,
                          decoration: const InputDecoration(labelText: 'Nama Pemanen', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _nikCtrl,
                          decoration: const InputDecoration(labelText: 'NIK', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mandorCtrl,
                          decoration: const InputDecoration(labelText: 'Mandor Panen', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _jjgCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Janjang Panen', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Form Input 10 Kriteria (Ketik Langsung + Tombol - / +)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. Input Temuan Mutu Buah & Ancak',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20))),
                  const Text('Ketik angka langsung (misal: 45 butir berondolan) atau gunakan tombol − / +',
                      style: TextStyle(fontSize: 11.5, color: Colors.black54)),
                  const Divider(height: 18),
                  ...kDaftarKriteria.map((k) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(k.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('Denda: Rp ${k.tarif} / ${k.satuan}',
                                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _ubahNilaiKriteria(k.kode, -1),
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          ),
                          SizedBox(
                            width: 64,
                            height: 38,
                            child: TextField(
                              controller: _temuanControllers[k.kode],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _ubahNilaiKriteria(k.kode, 1),
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B5E20)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dokumentasi Foto & Tombol Simpan
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _ambilFotoTemuan,
                icon: const Icon(Icons.camera_alt),
                label: Text('Foto (${_currentFotos.length})'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _simpanInspeksi,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('SIMPAN INSPEKSI', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Daftar Riwayat Inspeksi Hari Ini
          const Text('Riwayat Pemeriksaan Tersimpan (Offline)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ..._items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.tingkatRisiko == 'MERAH'
                        ? Colors.red
                        : (item.tingkatRisiko == 'ORANYE' ? Colors.deepOrange : Colors.amber),
                    child: Text(item.blok.replaceAll('BLOK ', ''),
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text('${item.pemanen} (${item.mandor})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: Text(
                      'Losses: ${item.persentaseLosses.toStringAsFixed(2)}% • Denda: ${currency.format(item.totalDenda)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () async {
                      setState(() => _items.removeWhere((e) => e.id == item.id));
                      await StorageService.saveInspeksi(_items);
                    },
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
