import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ipd_models.dart';

class SheetsService {
  static Future<bool> syncRingkasanToSheets({
    required String webhookUrl,
    required MasterDatabase master,
    required List<InspeksiItem> items,
  }) async {
    if (webhookUrl.trim().isEmpty) return false;

    // Agregasi per pemanen untuk Ranking Losses & Mutu Ancak
    final Map<String, Map<String, dynamic>> rekapPemanen = {};
    int totalKeseluruhanDenda = 0;

    for (final item in items) {
      totalKeseluruhanDenda += item.totalDenda;
      final key = '${item.pemanen}_${item.nikPemanen}';
      rekapPemanen.putIfAbsent(key, () => {
            'pemanen': item.pemanen,
            'nik': item.nikPemanen,
            'mandor': item.mandor,
            'blok': item.blok,
            'totalJanjang': 0,
            'sumLosses': 0.0,
            'count': 0,
            'totalDenda': 0,
          });
      rekapPemanen[key]!['totalJanjang'] += item.janjangPanen;
      rekapPemanen[key]!['sumLosses'] += item.persentaseLosses;
      rekapPemanen[key]!['count'] += 1;
      rekapPemanen[key]!['totalDenda'] += item.totalDenda;
    }

    final rankingList = rekapPemanen.values.map((e) {
      final avgLoss = (e['count'] as int) > 0 ? (e['sumLosses'] as double) / (e['count'] as int) : 0.0;
      String predikatMutu = 'SANGAT BAIK';
      if (avgLoss > 3.0 || (e['totalDenda'] as int) >= 25000) {
        predikatMutu = 'KURANG (PERLU PEMBINAAN)';
      } else if (avgLoss > 1.0 || (e['totalDenda'] as int) >= 10000) {
        predikatMutu = 'CUKUP';
      }
      return {
        'pemanen': e['pemanen'],
        'nik': e['nik'],
        'mandor': e['mandor'],
        'blok': e['blok'],
        'totalJanjang': e['totalJanjang'],
        'rataLosses': double.parse(avgLoss.toStringAsFixed(2)),
        'mutuAncak': predikatMutu,
        'totalDenda': e['totalDenda'],
      };
    }).toList();

    // Urutkan ranking dari losses tertinggi / denda terbesar ke terendah
    rankingList.sort((a, b) => (b['rataLosses'] as double).compareTo(a['rataLosses'] as double));

    final payload = {
      'pt': master.pt,
      'kebun': master.kebun,
      'afdeling': master.afdeling,
      'asisten': master.asisten,
      'totalKeseluruhanDenda': totalKeseluruhanDenda,
      'rankingPemanen': rankingList,
    };

    try {
      final res = await http
          .post(
            Uri.parse(webhookUrl.trim()),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200 || res.statusCode == 302;
    } catch (_) {
      return false;
    }
  }
}
