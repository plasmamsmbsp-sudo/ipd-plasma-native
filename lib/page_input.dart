import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class FormInspeksiPage extends StatefulWidget {
  const FormInspeksiPage({super.key});

  @override
  State<FormInspeksiPage> createState() => _FormInspeksiPageState();
}

class _FormInspeksiPageState extends State<FormInspeksiPage> {
  final _ptCtrl = TextEditingController(text: 'PT Kencana Agri - Plasma Wanggarasi');
  final _ancakCtrl = TextEditingController();
  final _pokokCtrl = TextEditingController(text: '25');
  final _pemanenCtrl = TextEditingController();
  final _asistenCtrl = TextEditingController(text: 'Sukri');
  final _catatanCtrl = TextEditingController();

  List<String> _listAfdeling = ['AFD BSP', 'AFD MSM', 'PT. STN'];
  List<String> _listBlok = ['A01', 'A02', 'B01', 'B02', 'C01'];
  List<String> _listMandor = ['Mas Budi', 'Pak Candra', 'Pak Ramin', 'Bang Edi', 'Aldrianto Eka Putra'];
  List<String> _listPemanen = [];

  String _selectedAfd = 'AFD BSP';
  String _selectedBlok = 'A01';
  String _selectedMandor = 'Mas Budi';

  DateTime _tanggal = DateTime.now();
  Position? _posisiGps;
  bool _sedangAmbilGps = false;
  bool _sedangProsesFoto = false;

  final Map<String, int> _jumlahTemuan = {
    for (var item in daftarParameterSop) item.kode: 0
  };
  final List<String> _fotoPaths = [];

  @override
  void initState() {
    super.initState();
    _muatMasterData();
    _ambilGps();
  }

  Future<void> _muatMasterData() async {
    final afd = await DatabaseHelper.instance.getMasterByTipe('AFDELING');
    final blok = await DatabaseHelper.instance.getMasterByTipe('BLOK');
    final mandor = await DatabaseHelper.instance.getMasterByTipe('MANDOR');
    final pemanen = await DatabaseHelper.instance.getMasterByTipe('PEMANEN');
    final asisten = await DatabaseHelper.instance.getSetting('asisten_default');

    if (mounted) {
      setState(() {
        if (afd.isNotEmpty) {
          _listAfdeling = afd;
          if (!_listAfdeling.contains(_selectedAfd)) _selectedAfd = _listAfdeling.first;
        }
        if (blok.isNotEmpty) {
          _listBlok = blok;
          if (!_listBlok.contains(_selectedBlok)) _selectedBlok = _listBlok.first;
        }
        if (mandor.isNotEmpty) {
          _listMandor = mandor;
          if (!_listMandor.contains(_selectedMandor)) _selectedMandor = _listMandor.first;
        }
        _listPemanen = pemanen;
        if (asisten.isNotEmpty) _asistenCtrl.text = asisten;
      });
    }
  }

  Future<void> _ambilGps() async {
    setState(() => _sedangAmbilGps = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mounted) setState(() => _posisiGps = pos);
      }
    } catch (_) {}
    if (mounted) setState(() => _sedangAmbilGps = false);
  }

  Future<void> _ambilFotoDenganWatermark(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1280);
    if (foto == null) return;

    setState(() => _sedangProsesFoto = true);
    try {
      final bytes = await File(foto.path).readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);

      final dir = await getApplicationDocumentsDirectory();
      final namaFile = 'IPD_${_selectedBlok}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = p.join(dir.path, namaFile);

      if (decoded != null) {
        final waktuStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
        final gpsStr = _posisiGps != null
            ? 'GPS: ${_posisiGps!.latitude.toStringAsFixed(6)}, ${_posisiGps!.longitude.toStringAsFixed(6)}'
            : 'GPS: Offline';
        final pemanenStr = _pemanenCtrl.text.trim().isEmpty ? '-' : _pemanenCtrl.text.trim();
        final infoLine1 = 'IPD PLASMA | $_selectedAfd - BLOK $_selectedBlok (Ancak ${_ancakCtrl.text.trim()})';
        final infoLine2 = 'Pemanen: $pemanenStr | Mandor: $_selectedMandor';
        final infoLine3 = '$waktuStr | $gpsStr';

        int boxHeight = 95;
        int startY = decoded.height - boxHeight;
        if (startY < 0) startY = 0;

        img.fillRect(
          decoded,
          x1: 0,
          y1: startY,
          x2: decoded.width,
          y2: decoded.height,
          color: img.ColorRgba8(15, 45, 18, 200),
        );

        img.drawString(decoded, infoLine1, font: img.arial24, x: 16, y: startY + 10, color: img.ColorRgb8(251, 192, 45));
        img.drawString(decoded, infoLine2, font: img.arial14, x: 16, y: startY + 42, color: img.ColorRgb8(255, 255, 255));
        img.drawString(decoded, infoLine3, font: img.arial14, x: 16, y: startY + 64, color: img.ColorRgb8(220, 255, 220));

        await File(targetPath).writeAsBytes(img.encodeJpg(decoded, quality: 82));
      } else {
        await File(foto.path).copy(targetPath);
      }

      if (mounted) setState(() => _fotoPaths.add(targetPath));
    } finally {
      if (mounted) setState(() => _sedangProsesFoto = false);
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
    if (_pemanenCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi Nama Pemanen terlebih dahulu!')),
      );
      return;
    }

    final namaPemanen = _pemanenCtrl.text.trim();
    if (!_listPemanen.any((e) => e.toLowerCase() == namaPemanen.toLowerCase())) {
      await DatabaseHelper.instance.addMaster('PEMANEN', namaPemanen);
      _muatMasterData();
    }

    final data = {
      'tanggal': DateFormat('yyyy-MM-dd').format(_tanggal),
      'pt': _ptCtrl.text.trim(),
      'afdeling': _selectedAfd,
      'blok': _selectedBlok,
      'no_ancak': _ancakCtrl.text.trim(),
      'pokok_sampel': int.tryParse(_pokokCtrl.text) ?? 25,
      'pemanen': namaPemanen,
      'mandor': _selectedMandor,
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
          content: Text('Data IPD tersimpan ke Database Offline!'),
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
            Text('Plasma Wanggarasi • Native Android', style: TextStyle(fontSize: 11, color: Color(0xFFFBC02D))),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _ambilGps,
            icon: _sedangAmbilGps
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(_posisiGps != null ? Icons.gps_fixed : Icons.gps_off,
                    color: _posisiGps != null ? const Color(0xFFFBC02D) : Colors.redAccent),
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
                        child: DropdownButtonFormField<String>(
                          value: _selectedAfd,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Afdeling', border: OutlineInputBorder()),
                          items: _listAfdeling.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _selectedAfd = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedBlok,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Blok', border: OutlineInputBorder()),
                          items: _listBlok.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _selectedBlok = v!),
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
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue val) {
                            if (val.text.isEmpty) return _listPemanen;
                            return _listPemanen.where((e) => e.toLowerCase().contains(val.text.toLowerCase()));
                          },
                          onSelected: (selection) => _pemanenCtrl.text = selection,
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
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _pokokCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Pokok', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedMandor,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Mandor Panen', border: OutlineInputBorder()),
                          items: _listMandor.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _selectedMandor = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _asistenCtrl,
                          decoration: const InputDecoration(labelText: 'Asisten Afdeling', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
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
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('3. FOTO BUKTI LAPANGAN (AUTO-WATERMARK GPS)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _sedangProsesFoto ? null : () => _ambilFotoDenganWatermark(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_sedangProsesFoto ? 'Memproses...' : 'Kamera + Cap GPS'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _sedangProsesFoto ? null : () => _ambilFotoDenganWatermark(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeri'),
                      ),
                    ],
                  ),
                  if (_fotoPaths.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _fotoPaths.length,
                        itemBuilder: (ctx, i) => Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(_fotoPaths[i]), width: 90, height: 90, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _fotoPaths.removeAt(i)),
                                child: const CircleAvatar(radius: 11, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                      
