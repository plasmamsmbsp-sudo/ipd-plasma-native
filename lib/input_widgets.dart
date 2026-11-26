import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

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
    final fmtRp = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2. TEMUAN 10 PARAMETER DENDA SOP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const Divider(),
            ...daftarParameterSop.map((item) {
              final int nilai = (jumlahTemuan[item.kode] ?? 0) as int;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.kode}. ${item.nama}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${fmtRp.format(item.dendaPerUnit)} / ${item.satuan} (${item.kategori})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: nilai > 0
                          ? () => onUbahNilai(item.kode, nilai - 1)
                          : null,
                      icon: const Icon(
                        Icons.remove_circle,
                        color: Colors.redAccent,
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$nilai',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onUbahNilai(item.kode, nilai + 1),
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF1B5E20),
                      ),
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
              '3. FOTO BUKTI LAPANGAN (AUTO-WATERMARK GPS)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: sedangProsesFoto
                      ? null
                      : () => onAmbilFoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    sedangProsesFoto ? 'Memproses...' : 'Kamera + Cap GPS',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: sedangProsesFoto
                      ? null
                      : () => onAmbilFoto(ImageSource.gallery),
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
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
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
                labelText: 'Catatan / Tindak Lanjut Mandor',
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
