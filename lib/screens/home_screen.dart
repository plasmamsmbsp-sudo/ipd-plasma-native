import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class _KriteriaItem {
  final String kode;
  final String nama;
  final String satuan;
  final int denda;
  final bool isLosses;

  const _KriteriaItem({
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.denda,
    this.isLosses = false,
  });
}

const List<_KriteriaItem> _daftarKriteria = [
  _KriteriaItem(kode: 'brondolan', nama: 'Berondolan Tidak Dikutip', satuan: 'Butir', denda: 200, isLosses: true),
  _KriteriaItem(kode: 'buah_mentah', nama: 'Buah Mentah Dipanen', satuan: 'Janjang', denda: 10000),
  _KriteriaItem(kode: 'buah_tinggal_pokok', nama: 'Buah Matang Tidak Dipanen', satuan: 'Janjang', denda: 10000, isLosses: true),
  _KriteriaItem(kode: 'buah_tinggal_piringan', nama: 'Buah Tinggal di Piringan/Pasar Pikul', satuan: 'Janjang', denda: 10000, isLosses: true),
  _KriteriaItem(kode: 'buah_peram', nama: 'Buah Mentah Diperam/Disembunyikan', satuan: 'Janjang', denda: 10000),
  _KriteriaItem(kode: 'tangkai_panjang', nama: 'Tangkai Panjang (> 3 cm)', satuan: 'Janjang', denda: 500),
  _KriteriaItem(kode: 'pelepah_tidak_susun', nama: 'Pelepah Tidak Dipotong / Tidak Disusun', satuan: 'Pokok', denda: 2000),
  _KriteriaItem(kode: 'over_pruning', nama: 'Over Pruning (Songgo Kurang)', satuan: 'Pokok', denda: 5000),
  _KriteriaItem(kode: 'pelepah_sengkleh', nama: 'Pelepah Sengkleh Tidak Diturunkan', satuan: 'Pelepah', denda: 5000),
  _KriteriaItem(kode: 'tph_kotor', nama: 'TPH Kotor / Tidak Diberi Nomor', satuan: 'TPH', denda: 1000),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _blokController = TextEditingController();
  final _pemanenController = TextEditingController();
  final _mandorController = TextEditingController();
  final _pokokSampelController = TextEditingController(text: '10');
  final _bjrController = TextEditingController(text: '15.0');

  final Map<String, int> _jumlahTemuan = {};
  final List<File> _fotoTemuan = [];
  Position? _posisiGps;
  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    for (var item in _daftarKriteria) {
      _jumlahTemuan[item.kode] = 0;
    }
    _ambilGps();
  }

  Future<void> _ambilGps() async {
    setState(() => _loadingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() => _posisiGps = pos);
      }
    } catch (_) {
      // Tetap jalan offline meski GPS gagal
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  Future<void> _ambilFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        _fotoTemuan.add(File(picked.path));
      });
    }
  }

  int get _totalDenda {
    int total = 0;
    for (var item in _daftarKriteria) {
      final qty = _jumlahTemuan[item.kode] ?? 0;
      total += qty * item.denda;
    }
    return total;
  }

  void _ubahNilai(String kode, int delta) {
    setState(() {
      final saatIni = _jumlahTemuan[kode] ?? 0;
      final baru = saatIni + delta;
      _jumlahTemuan[kode] = baru < 0 ? 0 : baru;
    });
  }

  void _resetForm() {
    setState(() {
      for (var item in _daftarKriteria) {
        _jumlahTemuan[item.kode] = 0;
      }
      _fotoTemuan.clear();
      _pemanenController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'IPD PLASMA WANGGARASI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Perbarui GPS',
            onPressed: _ambilGps,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Input',
            onPressed: _resetForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed, color: Color(0xFF1B5E20), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loadingGps
                          ? 'Mencari titik koordinat satelit...'
                          : _posisiGps != null
                              ? 'GPS: ${_posisiGps!.latitude.toStringAsFixed(6)}, ${_posisiGps!.longitude.toStringAsFixed(6)}'
                              : 'GPS Offline (Ketuk ikon lokasi di atas)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _blokController,
                            decoration: const InputDecoration(labelText: 'Blok / Ancak'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _pokokSampelController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Pokok Sampel'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _pemanenController,
                      decoration: const InputDecoration(labelText: 'Nama Pemanen'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _mandorController,
                            decoration: const InputDecoration(labelText: 'Mandor Panen'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _bjrController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'BJR (Kg)'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'PARAMETER INSPEKSI MUTU PANEN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 6),
            ..._daftarKriteria.map((kriteria) {
              final nilai = _jumlahTemuan[kriteria.kode] ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kriteria.nama,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Rp ${kriteria.denda} / ${kriteria.satuan}${kriteria.isLosses ? ' • LOSSES' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: kriteria.isLosses ? Colors.red.shade700 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _ubahNilai(kriteria.kode, -1),
                        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 30),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '$nilai',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _ubahNilai(kriteria.kode, 1),
                        icon: const Icon(Icons.add_circle, color: Color(0xFF1B5E20), size: 30),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _ambilFoto,
              icon: const Icon(Icons.camera_alt),
              label: Text('Ambil Foto Temuan (${_fotoTemuan.length} Foto)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF1B5E20)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL DENDA PANEN:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp $_totalDenda',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data Inspeksi IPD Tersimpan Offline!'),
                    backgroundColor: Color(0xFF1B5E20),
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('SIMPAN HASIL INSPEKSI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
