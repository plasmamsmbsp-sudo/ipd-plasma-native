import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ipd_models.dart';
import '../services/storage_service.dart';

class MasterDataScreen extends StatefulWidget {
  final MasterDatabase master;
  final Function(MasterDatabase updated) onSave;

  const MasterDataScreen({super.key, required this.master, required this.onSave});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> {
  late TextEditingController _ptCtrl;
  late TextEditingController _kebunCtrl;
  late TextEditingController _afdCtrl;
  late TextEditingController _asistenCtrl;
  late TextEditingController _gasCtrl;
  final TextEditingController _importCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ptCtrl = TextEditingController(text: widget.master.pt);
    _kebunCtrl = TextEditingController(text: widget.master.kebun);
    _afdCtrl = TextEditingController(text: widget.master.afdeling);
    _asistenCtrl = TextEditingController(text: widget.master.asisten);
    _gasCtrl = TextEditingController(text: widget.master.gasWebhookUrl);
  }

  Future<void> _simpanPengaturan() async {
    final updated = MasterDatabase(
      pt: _ptCtrl.text.trim(),
      kebun: _kebunCtrl.text.trim(),
      afdeling: _afdCtrl.text.trim(),
      asisten: _asistenCtrl.text.trim(),
      gasWebhookUrl: _gasCtrl.text.trim(),
      daftarMandor: widget.master.daftarMandor,
      daftarPemanen: widget.master.daftarPemanen,
      daftarBlok: widget.master.daftarBlok,
    );
    await StorageService.saveMaster(updated);
    widget.onSave(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Master Data berhasil disimpan secara offline!')),
      );
    }
  }

  void _shareMasterKeWhatsApp() {
    final text = widget.master.toShareableText();
    Share.share(text, subject: 'Master Database IPD PLASMA');
  }

  Future<void> _prosesImporMaster() async {
    final parsed = MasterDatabase.fromShareableText(_importCtrl.text);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Format pesan Master Data tidak valid! Pastikan menyalin seluruh blok pesan WA.'),
        ),
      );
      return;
    }
    await StorageService.saveMaster(parsed);
    widget.onSave(parsed);
    setState(() {
      _ptCtrl.text = parsed.pt;
      _kebunCtrl.text = parsed.kebun;
      _afdCtrl.text = parsed.afdeling;
      _asistenCtrl.text = parsed.asisten;
      _gasCtrl.text = parsed.gasWebhookUrl;
    });
    _importCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1B5E20),
          content: Text('Master Database berhasil diimpor dari WhatsApp!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Data & Sinkronisasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Identitas Kebun & Google Sheets',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  TextField(controller: _ptCtrl, decoration: const InputDecoration(labelText: 'Nama Perusahaan (PT)')),
                  const SizedBox(height: 10),
                  TextField(controller: _kebunCtrl, decoration: const InputDecoration(labelText: 'Nama Kebun')),
                  const SizedBox(height: 10),
                  TextField(controller: _afdCtrl, decoration: const InputDecoration(labelText: 'Afdeling')),
                  const SizedBox(height: 10),
                  TextField(controller: _asistenCtrl, decoration: const InputDecoration(labelText: 'Asisten Afdeling')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _gasCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL Web App Google Sheets (Apps Script)',
                      hintText: 'https://script.google.com/macros/s/.../exec',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _simpanPengaturan,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Pengaturan Offline'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: const Color(0xFFE8F5E9),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Berbagi Master Database via WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text(
                    'Bagikan daftar Mandor, Pemanen, Blok, dan BJR ke HP Kerani/Mandor tanpa internet server.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                      onPressed: _shareMasterKeWhatsApp,
                      icon: const Icon(Icons.share),
                      label: const Text('Ekspor & Share Master Data ke WhatsApp'),
                    ),
                  ),
                  const Divider(height: 24),
                  TextField(
                    controller: _importCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Tempel Pesan Master Data dari WhatsApp',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _prosesImporMaster,
                      icon: const Icon(Icons.download),
                      label: const Text('Impor Master Data Sekarang'),
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
