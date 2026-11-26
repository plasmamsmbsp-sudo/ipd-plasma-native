import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import 'excel_sap_helper.dart';

class RiwayatDanEksporPage extends StatefulWidget {
  const RiwayatDanEksporPage({super.key});

  @override
  State createState() => _RiwayatDanEksporPageState();
}

class _RiwayatDanEksporPageState extends State {
  var _dataInspeksi = [];
  bool _sedangSync = false;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future _muatData() async {
    final rows = List.from(await DatabaseHelper.instance.getAllInspeksi());
    if (mounted) {
      setState(() {
        _dataInspeksi = rows;
      });
    }
  }

  Future _sinkronKeGoogleSheets() async {
    final url = (await DatabaseHelper.instance.getSetting('gsheet_url')).toString();
    if (url.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Isi URL Google Apps Script di tab "Master & WA"!')),
        );
      }
      return;
    }

    final belumSync = _dataInspeksi.where((e) => (e['synced'] ?? 0) == 0).toList();
    if (belumSync.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua data sudah tersinkron ke Google Sheets.')),
        );
      }
      return;
    }

    setState(() => _sedangSync = true);
    int berhasil = 0;

    try {
      for (var row in belumSync) {
        final resp = await http.post(
          Uri.parse(url.trim()),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(row),
        );

        if (resp.statusCode == 200 || resp.statusCode == 302) {
          await DatabaseHelper.instance.markSynced(row['id'] as int);
          berhasil++;
        }
      }
      await _muatData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B5E20),
            content: Text('Berhasil sinkron $berhasil data ke Google Sheets!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Gagal sync: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sedangSync = false);
    }
  }

  void _bagikanKeWhatsApp() {
    if (_dataInspeksi.isEmpty) return;
    final fmtRp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final hariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dataHariIni = _dataInspeksi.where((e) => e['tanggal'] == hariIni).toList();
    final sumber = dataHariIni.isNotEmpty ? dataHariIni : _dataInspeksi;

    int totalDenda = sumber.fold(0, (s, item) => s + ((item['total_denda'] ?? 0) as int));
    double totalLossesKg = sumber.fold(0.0, (s, item) => s + ((item['total_losses_kg'] ?? 0.0) as num).toDouble());
    double avgLossesPct = sumber.fold(0.0, (s, item) => s + ((item['persen_losses'] ?? 0.0) as num).toDouble()) / sumber.length;
    double avgMutu = sumber.fold(0.0, (s, item) => s + ((item['nilai_mutu'] ?? 0.0) as num).toDouble()) / sumber.length;

    final first = sumber.first;
    StringBuffer sb = StringBuffer();
    sb.writeln('*LAPORAN IPD PLASMA - KENCANA AGRI*');
    sb.writeln('${first['afdeling']} | ${DateFormat('dd/MM/yyyy').format(DateTime.now())}');
    sb.writeln('Asisten: ${first['asisten']} | Mandor: ${first['mandor']}');
    sb.writeln('----------------------------------');
    sb.writeln('Sampel: *${sumber.length} Ancak* | Mutu: *${avgMutu.toStringAsFixed(1)}%*');
    sb.writeln('Losses: *${totalLossesKg.toStringAsFixed(2)} kg (${avgLossesPct.toStringAsFixed(2)}%)*');
    sb.writeln('Total Denda: *${fmtRp.format(totalDenda)}*');
    sb.writeln('----------------------------------');

    for (int i = 0; i < sumber.length; i++) {
      final r = sumber[i];
      final temuan = Map.from(jsonDecode(r['temuan_json'].toString()));
      var detailItem = [];
      for (var sop in daftarParameterSop) {
        int qty = (temuan[sop.kode] ?? 0) as int;
        if (qty > 0) detailItem.add('${sop.singkatan}:$qty');
      }
      final rincianStr = detailItem.isEmpty ? 'Nihil' : detailItem.join(', ');
      sb.writeln('${i + 1}. *${r['pemanen']}* (${r['blok']}/A.${r['no_ancak']})');
      sb.writeln('   Losses: ${r['total_losses_kg']}kg (${r['persen_losses']}%) | Denda: ${fmtRp.format(r['total_denda'])}');
      sb.writeln('   Temuan: $rincianStr');
    }

    sb.writeln('----------------------------------');
    sb.writeln('_Powered By Tim Plasma Area 4_');
    Share.share(sb.toString());
  }

  @override
  Widget build(BuildContext context) {
    final fmtRp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final belumSyncCount = _dataInspeksi.where((e) => (e['synced'] ?? 0) == 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap SAP, Excel & WA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _sedangSync ? null : _sinkronKeGoogleSheets,
            icon: _sedangSync
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.cloud_upload, color: Color(0xFFFBC02D)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sedangSync ? null : _sinkronKeGoogleSheets,
                    icon: const Icon(Icons.cloud_sync),
                    label: Text('Sync ke Google Sheets ($belumSyncCount belum terkirim)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => ExcelSapHelper.eksporExcelFormatResmi(_dataInspeksi),
                        icon: const Icon(Icons.table_view),
                        label: const Text('Excel Denda SAP'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _bagikanKeWhatsApp,
                        icon: const Icon(Icons.send),
                        label: const Text('Kirim WA Detail'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBC02D), foregroundColor: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _dataInspeksi.isEmpty
                ? const Center(child: Text('Belum ada riwayat inspeksi tersimpan.'))
                : ListView.builder(
                    itemCount: _dataInspeksi.length,
                    itemBuilder: (ctx, i) {
                      final r = _dataInspeksi[i];
                      final isSynced = (r['synced'] ?? 0) == 1;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1B5E20),
                            child: Text(r['blok'].toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text('${r['pemanen']} (A.${r['no_ancak']})', style: const TextStyle(fontWeight: FontWeight.bold))),
                              Icon(isSynced ? Icons.cloud_done : Icons.cloud_off, size: 16, color: isSynced ? Colors.green : Colors.orange),
                            ],
                          ),
                          subtitle: Text(
                            'Losses: ${r['total_losses_kg']} kg (${r['persen_losses']}%) | Denda: ${fmtRp.format(r['total_denda'])}\n${r['tanggal']} • Mandor: ${r['mandor']}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await DatabaseHelper.instance.deleteInspeksi(r['id'] as int);
                              _muatData();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
