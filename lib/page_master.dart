import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class MasterDanSyncPage extends StatefulWidget {
  const MasterDanSyncPage({super.key});

  @override
  State createState() => _MasterDanSyncPageState();
}

class _MasterDanSyncPageState extends State {
  final _urlCtrl = TextEditingController();
  final _asistenCtrl = TextEditingController();
  final _tambahItemCtrl = TextEditingController();
  final _bjrItemCtrl = TextEditingController(text: '16.0');
  String _tipeDipilih = 'BLOK';
  var _daftarRows = [];

  @override
  void initState() {
    super.initState();
    _muatSemua();
  }

  Future _muatSemua() async {
    final url = (await DatabaseHelper.instance.getSetting('gsheet_url')).toString();
    final asisten = (await DatabaseHelper.instance.getSetting('asisten_default')).toString();
    final rows = List.from(await DatabaseHelper.instance.getMasterRowsByTipe(_tipeDipilih));
    if (mounted) {
      setState(() {
        _urlCtrl.text = url;
        _asistenCtrl.text = asisten;
        _daftarRows = rows;
      });
    }
  }

  Future _kirimAtauUnduhMaster() async {
    final semuaMaster = await DatabaseHelper.instance.exportAllMasterJson();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(semuaMaster);

    final dir = await getTemporaryDirectory();
    final tgl = DateFormat('yyyyMMdd').format(DateTime.now());
    final filePath = p.join(dir.path, 'MASTER_IPD_KENCANA_$tgl.json');
    await File(filePath).writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'File Master Data IPD PLASMA (Blok, BJR, Afdeling, Mandor, Kerani) - PT Kencana Agri',
    );
  }

  Future _uploadMasterDariFile() async {
    FilePickerResult? res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'txt'],
    );
    if (res != null && res.files.single.path != null) {
      try {
        final isi = await File(res.files.single.path!).readAsString();
        final decoded = jsonDecode(isi);
        if (decoded is List) {
          await DatabaseHelper.instance.importMasterList(decoded);
          await _muatSemua();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF1B5E20),
                content: Text('Berhasil memuat ${decoded.length} item Master Data!'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text('Format file master tidak valid: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Data, BJR & Share WA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            color: const Color(0xFFF1F8E9),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BAGIKAN / UNDUH / UPLOAD MASTER DATA (WA)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 6),
                  const Text(
                    'Kirim seluruh daftar Blok, BJR, Mandor, Kerani, & Pemanen ke tim lewat WhatsApp atau muat file master dari rekan kerja.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _kirimAtauUnduhMaster,
                          icon: const Icon(Icons.share),
                          label: const Text('Kirim WA / Unduh'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _uploadMasterDariFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Master'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBC02D), foregroundColor: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('KELOLA BLOK (BJR), AFDELING, MANDOR & KERANI', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  DropdownButtonFormField(
                    value: _tipeDipilih,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Kategori Master', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'BLOK', child: Text('Daftar Blok & BJR (kg)')),
                      DropdownMenuItem(value: 'AFDELING', child: Text('Daftar Afdeling')),
                      DropdownMenuItem(value: 'MANDOR', child: Text('Daftar Mandor Panen')),
                      DropdownMenuItem(value: 'KERANI', child: Text('Daftar Kerani Buah')),
                      DropdownMenuItem(value: 'PEMANEN', child: Text('Daftar Pemanen')),
                    ],
                    onChanged: (v) {
                      setState(() => _tipeDipilih = v.toString());
                      _muatSemua();
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _tambahItemCtrl,
                          decoration: InputDecoration(labelText: 'Nama $_tipeDipilih', border: const OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      if (_tipeDipilih == 'BLOK') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _bjrItemCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'BJR (kg)', border: OutlineInputBorder(), isDense: true),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (_tambahItemCtrl.text.trim().isEmpty) return;
                          final bjrVal = double.tryParse(_bjrItemCtrl.text) ?? 15.0;
                          await DatabaseHelper.instance.addMaster(_tipeDipilih, _tambahItemCtrl.text.trim(), extra: bjrVal);
                          _tambahItemCtrl.clear();
                          _muatSemua();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _daftarRows.map((row) {
                      final nama = row['nama'].toString();
                      final label = _tipeDipilih == 'BLOK' ? '$nama (BJR ${row['extra']} kg)' : nama;
                      return Chip(
                        label: Text(label, style: const TextStyle(fontSize: 12)),
                        onDeleted: () async {
                          await DatabaseHelper.instance.deleteMaster(_tipeDipilih, nama);
                          _muatSemua();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ASISTEN & GOOGLE SHEETS SYNC', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _asistenCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Asisten Afdeling', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL Web App Google Apps Script',
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
        ],
      ),
    );
  }
}
