import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class KartuKalkulasiLosses extends StatelessWidget {
  final TextEditingController bjrCtrl;
  final TextEditingController beratButirCtrl;
  final TextEditingController pokokCtrl;
  final TextEditingController tapakCtrl;
  final double lossesBrondolanKg;
  final double lossesBuahKg;
  final double totalLossesKg;
  final double persenLosses;
  final VoidCallback onUbahInput;

  const KartuKalkulasiLosses({
    super.key,
    required this.bjrCtrl,
    required this.beratButirCtrl,
    required this.pokokCtrl,
    required this.tapakCtrl,
    required this.lossesBrondolanKg,
    required this.lossesBuahKg,
    required this.totalLossesKg,
    required this.persenLosses,
    required this.onUbahInput,
  });

  @override
  Widget build(BuildContext context) {
    final warnaPersen = persenLosses > 2.0 ? Colors.red.shade800 : const Color(0xFF1B5E20);

    return Card(
      elevation: 2,
      color: const Color(0xFFF1F8E9),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2. PARAMETER LOSSES (KG & PERSENTASE)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: bjrCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onUbahInput(),
                    decoration: const InputDecoration(
                      labelText: 'BJR Blok (kg)',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: beratButirCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onUbahInput(),
                    decoration: const InputDecoration(
                      labelText: '1 Btr Brondol (gr)',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pokokCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onUbahInput(),
                    decoration: const InputDecoration(
                      labelText: 'Pokok Sampel',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: tapakCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onUbahInput(),
                    decoration: const InputDecoration(
                      labelText: 'Tapak Panen (Jjg)',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Losses Brondol', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      Text('${lossesBrondolanKg.toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Losses Buah', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      Text('${lossesBuahKg.toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Total Losses', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      Text('${totalLossesKg.toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: warnaPersen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        const Text('% Losses', style: TextStyle(fontSize: 10, color: Colors.white70)),
                        Text(
                          '${persenLosses.toStringAsFixed(2)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFBC02D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KartuParameterSop extends StatelessWidget {
  final Map jumlahTemuan;
  final Function(String kode, int nilaiBaru) onUbahNilai;

  const KartuParameterSop({
    super.key,
    required this.jumlahTemuan,
    required this.onUbahNilai,
  });

  @override
  Widget build(BuildContext context) {
    final fmtRp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3. TEMUAN 10 PARAMETER DENDA SOP',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
            const Divider(),
            ...daftarParameterSop.map((item) {
              final int nilai = (jumlahTemuan[item.kode] ?? 0) as int;
              Color? warnaPin;
              if (item.kode == 'P2' || item.kode == 'P3') warnaPin = Colors.red;
              if (item.kode == 'P9') warnaPin = Colors.orange;
              if (item.kode == 'P6') warnaPin = Colors.amber.shade700;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    if (warnaPin != null)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(color: warnaPin, shape: BoxShape.circle),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.singkatan} - ${item.nama}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            '${fmtRp.format(item.dendaPerUnit)} / ${item.satuan} (${item.kategori})',
                            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: nilai > 0 ? () => onUbahNilai(item.kode, nilai - 1) : null,
                      icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                    ),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$nilai',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onUbahNilai(item.kode, nilai + 1),
                      icon: const Icon(Icons.add_circle, color: Color(0xFF1B5E20)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class KartuFotoDanCatatan extends StatelessWidget {
  final bool sedangProsesFoto;
  final List fotoPaths;
  final TextEditingController catatanCtrl;
  final Function(ImageSource source) onAmbilFoto;
  final Function(int index) onHapusFoto;

  const KartuFotoDanCatatan({
    super.key,
    required this.sedangProsesFoto,
    required this.fotoPaths,
    required this.catatanCtrl,
    required this.onAmbilFoto,
    required this.onHapusFoto,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4. FOTO BUKTI LAPANGAN (AUTO-WATERMARK GPS)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: sedangProsesFoto ? null : () => onAmbilFoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(sedangProsesFoto ? 'Memproses...' : 'Kamera + Cap GPS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: sedangProsesFoto ? null : () => onAmbilFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                ),
              ],
            ),
            if (fotoPaths.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: fotoPaths.length,
                  itemBuilder: (ctx, i) {
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(fotoPaths[i].toString()),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => onHapusFoto(i),
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: catatanCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan / Keterangan Tambahan',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
