import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'input_helper.dart';
import 'input_widgets.dart';
import 'splash_logo.dart';

class FormInspeksiPage extends StatefulWidget {
  const FormInspeksiPage({super.key});

  @override
  State createState() => _FormInspeksiPageState();
}

class _FormInspeksiPageState extends State {
  final _ptCtrl = TextEditingController(text: 'PT Kencana Agri - Plasma Wanggarasi');
  final _ancakCtrl = TextEditingController();
  final _pokokCtrl = TextEditingController(text: '25');
  final _tapakCtrl = TextEditingController(text: '10');
  final _bjrCtrl = TextEditingController(text: '16.0');
  final _beratButirCtrl = TextEditingController(text: '12');
  final _pemanenCtrl = TextEditingController();
  final _asistenCtrl = TextEditingController(text: 'Sukri');
  final _catatanCtrl = TextEditingController();

  var _listAfdeling = ['Plasma BSP', 'Plasma MSM', 'PT. STN'];
  var _listBlok = ['D001A', 'E0015', 'E0013', 'E0018A'];
  var _listMandor = ['Albar Mooduto', 'Mas Budi', 'Pak Candra', 'Pak Ramin', 'Bang Edi'];
  var _listKerani = ['Firman Hulopi', 'Aldrianto Eka Putra'];
  var _listPemanen = [];

  String _selectedAfd = 'Plasma BSP';
  String _selectedBlok = 'D001A';
  String _selectedMandor = 'Albar Mooduto';
  String _selectedKerani = 'Firman Hulopi';

  DateTime _tanggal = DateTime.now();
  Position? _posisiGps;
  bool _sedangAmbilGps = false;
  bool _sedangProsesFoto = false;

  final _jumlahTemuan = {
    for (var item in daftarParameterSop) item.kode: 0
  };
  final _fotoPaths = [];

  @override
  void initState() {
    super.initState();
    _muatMasterData();
    _ambilGps();
  }

  Future _muatMasterData() async {
    final afd = List.from(await DatabaseHelper.instance.getMasterByTipe('AFDELING'));
    final blok = List.from(await DatabaseHelper.instance.getMasterByTipe('BLOK'));
    final mandor = List.from(await DatabaseHelper.instance.getMasterByTipe('MANDOR'));
    final kerani = List.from(await DatabaseHelper.instance.getMasterByTipe('KERANI'));
    final pemanen = List.from(await DatabaseHelper.instance.getMasterByTipe('PEMANEN'));
    final asisten = (await DatabaseHelper.instance.getSetting('asisten_default')).toString();

    if (mounted) {
      setState(() {
        if (afd.isNotEmpty) {
          _listAfdeling = afd.map((e) => e.toString()).toList();
          if (!_listAfdeling.contains(_selectedAfd)) _selectedAfd = _listAfdeling.first;
        }
        if (blok.isNotEmpty) {
          _listBlok = blok.map((e) => e.toString()).toList();
          if (!_listBlok.contains(_selectedBlok)) _selectedBlok = _listBlok.first;
        }
        if (mandor.isNotEmpty) {
          _listMandor = mandor.map((e) => e.toString()).toList();
          if (!_listMandor.contains(_selectedMandor)) _selectedMandor = _listMandor.first;
        }
        if (kerani.isNotEmpty) {
          _listKerani = kerani.map((e) => e.toString()).toList();
          if (!_listKerani.contains(_selectedKerani)) _selectedKerani = _listKerani.first;
        }
        _listPemanen = pemanen.map((e) => e.toString()).toList();
        if (asisten.isNotEmpty) _asistenCtrl.text = asisten;
      });
      _muatBjrBlok(_selectedBlok);
    }
  }

  Future _muatBjrBlok(String blok) async {
    final bjr = await DatabaseHelper.instance.getBjrBlok(blok);
    if (mounted) {
      setState(() {
        _bjrCtrl.text = bjr.toString();
      });
    }
  }

  Future _ambilGps() async {
    setState(() => _sedangAmbilGps = true);
    final pos = await InputHelper.ambilGpsSekarang();
    if (mounted) {
      setState(() {
        if (pos != null) _posisiGps = pos as Position;
        _sedangAmbilGps = false;
      });
    }
  }

  Future _ambilFoto(ImageSource source) async {
    setState(() => _sedangProsesFoto = true);
    final hasilPath = await InputHelper.prosesFotoWatermark(
      source: source,
      afdeling: _selectedAfd,
      blok: _selectedBlok,
      ancak: _ancakCtrl.text.trim(),
      pemanen: _pemanenCtrl.text.trim(),
      mandor: _selectedMandor,
      gps: _posisiGps,
    );
    if (mounted) {
      setState(() {
        if (hasilPath != null) _fotoPaths.add(hasilPath.toString());
        _sedangProsesFoto = false;
      });
    }
  }

  double get _lossesBrondolanKg {
    final int btr = _jumlahTemuan['P9'] ?? 0;
    final double gr = double.tryParse(_beratButirCtrl.text) ?? 12.0;
    return (btr * gr) / 1000.0;
  }

  double get _lossesBuahKg {
    final int btp = _jumlahTemuan['P2'] ?? 0;
    final int btg = _jumlahTemuan['P3'] ?? 0;
    final double bjr = double.tryParse(_bjrCtrl.text) ?? 15.0;
    return (btp + btg) * bjr;
  }

  double get _totalLossesKg => _lossesBrondolanKg + _lossesBuahKg;

  double get _persenLosses {
    final int tapak = int.tryParse(_tapakCtrl.text) ?? 0;
    final int buahTinggal = (_jumlahTemuan['P2'] ?? 0) + (_jumlahTemuan['P3'] ?? 0);
    final double bjr = double.tryParse(_bjrCtrl.text) ?? 15.0;
    final double totalPotensiKg = (tapak + buahTinggal) * bjr;
    if (totalPotensiKg <= 0) return 0.0;
    return (_totalLossesKg / totalPotensiKg) * 100.0;
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

  Future _simpanInspeksi() async {
    if (_pemanenCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi Nama Pemanen terlebih dahulu!')),
      );
      return;
    }

    final namaPemanen = _pemanenCtrl.text.trim();
    if (!_listPemanen.any((e) => e.toString().toLowerCase() == namaPemanen.toLowerCase())) {
      await DatabaseHelper.instance.addMaster('PEMANEN', namaPemanen, extra: 0.0);
      _muatMasterData();
    }

    final bjr = double.tryParse(_bjrCtrl.text) ?? 15.0;
    final beratBtr = double.tryParse(_beratButirCtrl.text) ?? 12.0;

    final data = {
      'tanggal': DateFormat('yyyy-MM-dd').format(_tanggal),
      'pt': _ptCtrl.text.trim(),
      'afdeling': _selectedAfd,
      'blok': _selectedBlok,
      'no_ancak': _ancakCtrl.text.trim(),
      'pokok_sampel': int.tryParse(_pokokCtrl.text) ?? 25,
      'tapak_panen': int.tryParse(_tapakCtrl.text) ?? 0,
      'bjr_blok': bjr,
      'berat_brondolan_gr': beratBtr,
      'losses_brondolan_kg': double.parse(_lossesBrondolanKg.toStringAsFixed(2)),
      'losses_buah_kg': double.parse(_lossesBuahKg.toStringAsFixed(2)),
      'total_losses_kg': double.parse(_totalLossesKg.toStringAsFixed(2)),
      'persen_losses': double.parse(_persenLosses.toStringAsFixed(2)),
      'pemanen': namaPemanen,
      'mandor': _selectedMandor,
      'kerani': _selectedKerani,
      'asisten': _asistenCtrl.text.trim(),
      'lat': _posisiGps?.latitude,
      'lng': _posisiGps?.longitude,
      'temuan_json': jsonEncode(_jumlahTemuan),
      'total_denda': _totalDenda,
      'nilai_mutu': _nilaiMutu,
      'foto_paths': jsonEncode(_fotoPaths),
      'catatan': _catatanCtrl.text.trim(),
      'synced': 0,
    };

    await DatabaseHelper.instance.insertInspeksi(data);

    if (_posisiGps != null) {
      final sesi = 'Temuan_${DateFormat('yyyyMMdd').format(_tanggal)}';
      if ((_jumlahTemuan['P2'] ?? 0) > 0 || (_jumlahTemuan['P3'] ?? 0) > 0) {
        await DatabaseHelper.instance.insertGpsPoint(
          sesi,
          _posisiGps!.latitude,
          _posisiGps!.longitude,
          tipePin: 'MERAH',
          keterangan: 'Blok $_selectedBlok ($namaPemanen): Buah Tinggal',
        );
      }
      if ((_jumlahTemuan['P9'] ?? 0) > 0) {
        await DatabaseHelper.instance.insertGpsPoint(
          sesi,
          _posisiGps!.latitude,
          _posisiGps!.longitude,
          tipePin: 'ORANYE',
          keterangan: 'Blok $_selectedBlok ($namaPemanen): Brondolan Tidak Kutip (${_jumlahTemuan['P9']} btr)',
        );
      }
      if ((_jumlahTemuan['P6'] ?? 0) > 0) {
        await DatabaseHelper.instance.insertGpsPoint(
          sesi,
          _posisiGps!.latitude,
          _posisiGps!.longitude,
          tipePin: 'KUNING',
          keterangan: 'Blok $_selectedBlok ($namaPemanen): Pelepah Tidak Susun (${_jumlahTemuan['P6']} pkk)',
        );
      }
    }

    setState(() {
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
          content: Text('Data IPD, Losses & Pin Peta tersimpan!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmtRp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            KencanaLogoWidget(size: 36),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IPD PLASMA - KENCANA AGRI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('Tim Plasma Area 4 • Wanggarasi', style: TextStyle(fontSize: 11, color: Color(0xFFFBC02D))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _ambilGps,
            icon: _sedangAmbilGps
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(
                    _posisiGps != null ? Icons.gps_fixed : Icons.gps_off,
                    color: _posisiGps != null ? const Color(0xFFFBC02D) : Colors.redAccent,
                  ),
            tooltip: 'Kunci Koordinat GPS',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
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
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField(
                          value: _selectedAfd,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Afdeling', border: OutlineInputBorder()),
                          items: _listAfdeling.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _selectedAfd = v.toString()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField(
                          value: _selectedBlok,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Blok', border: OutlineInputBorder()),
                          items: _listBlok.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) {
                            final blokBaru = v.toString();
                            setState(() => _selectedBlok = blokBaru);
                            _muatBjrBlok(blokBaru);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _ancakCtrl,
                          decoration: const InputDecoration(labelText: 'Ancak', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Autocomplete(
                    optionsBuilder: (TextEditingValue val) {
                      final semua = _listPemanen.map((e) => e.toString()).toList();
                      if (val.text.isEmpty) return semua;
                      return semua.where((e) => e.toLowerCase().contains(val.text.toLowerCase()));
                    },
                    onSelected: (selection) => _pemanenCtrl.text = selection.toString(),
                    fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
                      ctrl.text = _pemanenCtrl.text;
                      ctrl.addListener(() => _pemanenCtrl.text = ctrl.text);
                      return TextField(
                        controller: ctrl,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Nama Pemanen *', border: OutlineInputBorder(), isDense: true),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField(
                          value: _selectedMandor,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Mandor Panen', border: OutlineInputBorder()),
                          items: _listMandor.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _selectedMandor = v.toString()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField(
                          value: _selectedKerani,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Kerani Buah', border: OutlineInputBorder()),
                          items: _listKerani.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _selectedKerani = v.toString()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _asistenCtrl,
                    decoration: const InputDecoration(labelText: 'Asisten Afdeling', border: OutlineInputBorder(), isDense: true),
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
          KartuKalkulasiLosses(
            bjrCtrl: _bjrCtrl,
            beratButirCtrl: _beratButirCtrl,
            pokokCtrl: _pokokCtrl,
            tapakCtrl: _tapakCtrl,
            lossesBrondolanKg: _lossesBrondolanKg,
            lossesBuahKg: _lossesBuahKg,
            totalLossesKg: _totalLossesKg,
            persenLosses: _persenLosses,
            onUbahInput: () => setState(() {}),
          ),
          const SizedBox(height: 10),
          KartuParameterSop(
            jumlahTemuan: _jumlahTemuan,
            onUbahNilai: (kode, nilaiBaru) {
              setState(() => _jumlahTemuan[kode] = nilaiBaru);
            },
          ),
          const SizedBox(height: 10),
          KartuFotoDanCatatan(
            sedangProsesFoto: _sedangProsesFoto,
            fotoPaths: _fotoPaths,
            catatanCtrl: _catatanCtrl,
            onAmbilFoto: _ambilFoto,
            onHapusFoto: (index) {
              setState(() => _fotoPaths.removeAt(index));
            },
          ),
          const SizedBox(height: 12),
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
                    Text(
                      'Total Denda: ${fmtRp.format(_totalDenda)}',
                      style: const TextStyle(color: Color(0xFFFBC02D), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Mutu: ${_nilaiMutu.toStringAsFixed(1)}% | Losses: ${_persenLosses.toStringAsFixed(2)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
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
