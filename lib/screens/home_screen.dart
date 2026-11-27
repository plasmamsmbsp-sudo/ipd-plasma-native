import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ipd_models.dart';

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

  // Menyimpan jumlah temuan per kode kriteria
  final Map<String, int> _jumlahTemuan = {};
  final List<File> _fotoTemuan = [];
  Position? _posisiGps;
  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    for (var item in kDaftarKriteria) {
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
    for (var item in kDaftarKriteria) {
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
      for (var item in kDaftarKriteria) {
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
            // Banner Status GPS Offline
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

            // Form Identitas Blok & Pemanen
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

            // Daftar 10 Kriteria Denda & Losses
            const Text(
              'PARAMETER INSPEKSI MUTU PANEN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 6),
            ...kDaftarKriteria.map((kriteria) {
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

            // Tombol Kamera Dokumentasi
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

            // Ringkasan Total Denda
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
