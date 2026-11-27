import 'dart:convert';

class InspeksiItem {
  final String id;
  final String tanggal;
  final String waktu;
  final String pt;
  final String kebun;
  final String afdeling;
  final String asisten;
  final String blok;
  final double bjr;
  final String mandor;
  final String pemanen;
  final String nikPemanen;
  final int jumlahPokokSampel;
  final int janjangPanen;

  // 10 Parameter Mutu & Losses Panen
  final int brondolanTidakDikutip;
  final int buahMentah;
  final int buahMengkal;
  final int tandanKosong;
  final int buahTinggal;
  final int tangkaiPanjang;
  final int pelepahSengkleh;
  final int pelepahTidakDisusun;
  final int tidakBeriNomor;
  final int tphTidakBersih;

  // GPS, Foto & Screenshot Peta
  final double? lat;
  final double? lng;
  final List<String> fotoPaths;
  final String? mapScreenshotPath;
  final String catatan;

  InspeksiItem({
    required this.id,
    required this.tanggal,
    required this.waktu,
    this.pt = 'PT Kencana Agri (PT. STN)',
    this.kebun = 'Kebun Plasma Wanggarasi',
    this.afdeling = 'Afdeling Plasma BSP',
    this.asisten = 'Sukri',
    required this.blok,
    required this.bjr,
    required this.mandor,
    required this.pemanen,
    this.nikPemanen = '-',
    this.jumlahPokokSampel = 0,
    int? janjangPanen,
    int? jumlahTandanPanen,
    this.brondolanTidakDikutip = 0,
    this.buahMentah = 0,
    this.buahMengkal = 0,
    this.tandanKosong = 0,
    this.buahTinggal = 0,
    this.tangkaiPanjang = 0,
    this.pelepahSengkleh = 0,
    this.pelepahTidakDisusun = 0,
    this.tidakBeriNomor = 0,
    this.tphTidakBersih = 0,
    this.lat,
    this.lng,
    this.fotoPaths = const [],
    this.mapScreenshotPath,
    this.catatan = '',
  }) : janjangPanen = janjangPanen ?? jumlahTandanPanen ?? 0;

  // Alias agar tetap kompatibel jika file lain memanggil jumlahTandanPanen
  int get jumlahTandanPanen => janjangPanen;

  // Berat brondolan tertinggal (1 butir = 12 gram = 0.012 kg)
  double get beratBrondolanKg => brondolanTidakDikutip * 0.012;

  // Berat buah tinggal (janjang x BJR)
  double get beratBuahTinggalKg => buahTinggal * bjr;

  // Total berat produksi sampel (kg)
  double get totalBeratProduksiKg {
    final base = janjangPanen * bjr;
    return base > 0 ? base : bjr;
  }

  // Persentase Losses (%) otomatis
  double get persentaseLosses {
    final totalLossKg = beratBrondolanKg + beratBuahTinggalKg;
    return (totalLossKg / totalBeratProduksiKg) * 100.0;
  }

  // Kategori Warna Pin Peta
  String get tingkatRisiko {
    if (persentaseLosses >= 3.0 || totalDenda >= 100000) return 'MERAH';
    if (persentaseLosses >= 1.5 || totalDenda >= 50000) return 'ORANYE';
    return 'KUNING';
  }

  // Kalkulasi Total Denda SOP Panen (Rp)
  int get totalDenda {
    int denda = 0;
    denda += brondolanTidakDikutip * 500;
    denda += buahMentah * 25000;
    denda += buahMengkal * 15000;
    denda += tandanKosong * 10000;
    denda += buahTinggal * 20000;
    denda += tangkaiPanjang * 5000;
    denda += pelepahSengkleh * 5000;
    denda += pelepahTidakDisusun * 5000;
    denda += tidakBeriNomor * 2000;
    denda += tphTidakBersih * 10000;
    return denda;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': tanggal,
        'waktu': waktu,
        'pt': pt,
        'kebun': kebun,
        'afdeling': afdeling,
        'asisten': asisten,
        'blok': blok,
        'bjr': bjr,
        'mandor': mandor,
        'pemanen': pemanen,
        'nikPemanen': nikPemanen,
        'jumlahPokokSampel': jumlahPokokSampel,
        'janjangPanen': janjangPanen,
        'brondolanTidakDikutip': brondolanTidakDikutip,
        'buahMentah': buahMentah,
        'buahMengkal': buahMengkal,
        'tandanKosong': tandanKosong,
        'buahTinggal': buahTinggal,
        'tangkaiPanjang': tangkaiPanjang,
        'pelepahSengkleh': pelepahSengkleh,
        'pelepahTidakDisusun': pelepahTidakDisusun,
        'tidakBeriNomor': tidakBeriNomor,
        'tphTidakBersih': tphTidakBersih,
        'lat': lat,
        'lng': lng,
        'fotoPaths': fotoPaths,
        'mapScreenshotPath': mapScreenshotPath,
        'catatan': catatan,
      };

  factory InspeksiItem.fromJson(Map<String, dynamic> map) => InspeksiItem(
        id: map['id']?.toString() ?? '',
        tanggal: map['tanggal']?.toString() ?? '',
        waktu: map['waktu']?.toString() ?? '',
        pt: map['pt']?.toString() ?? 'PT Kencana Agri (PT. STN)',
        kebun: map['kebun']?.toString() ?? 'Kebun Plasma Wanggarasi',
        afdeling: map['afdeling']?.toString() ?? 'Afdeling Plasma BSP',
        asisten: map['asisten']?.toString() ?? 'Sukri',
        blok: map['blok']?.toString() ?? '-',
        bjr: (map['bjr'] as num?)?.toDouble() ?? 15.0,
        mandor: map['mandor']?.toString() ?? '-',
        pemanen: map['pemanen']?.toString() ?? '-',
        nikPemanen: map['nikPemanen']?.toString() ?? '-',
        jumlahPokokSampel: (map['jumlahPokokSampel'] as num?)?.toInt() ?? 0,
        janjangPanen: (map['janjangPanen'] ?? map['jumlahTandanPanen'] as num?)?.toInt() ?? 0,
        brondolanTidakDikutip: (map['brondolanTidakDikutip'] as num?)?.toInt() ?? 0,
        buahMentah: (map['buahMentah'] as num?)?.toInt() ?? 0,
        buahMengkal: (map['buahMengkal'] as num?)?.toInt() ?? 0,
        tandanKosong: (map['tandanKosong'] as num?)?.toInt() ?? 0,
        buahTinggal: (map['buahTinggal'] as num?)?.toInt() ?? 0,
        tangkaiPanjang: (map['tangkaiPanjang'] as num?)?.toInt() ?? 0,
        pelepahSengkleh: (map['pelepahSengkleh'] as num?)?.toInt() ?? 0,
        pelepahTidakDisusun: (map['pelepahTidakDisusun'] as num?)?.toInt() ?? 0,
        tidakBeriNomor: (map['tidakBeriNomor'] as num?)?.toInt() ?? 0,
        tphTidakBersih: (map['tphTidakBersih'] as num?)?.toInt() ?? 0,
        lat: (map['lat'] as num?)?.toDouble(),
        lng: (map['lng'] as num?)?.toDouble(),
        fotoPaths: List<String>.from(map['fotoPaths'] ?? []),
        mapScreenshotPath: map['mapScreenshotPath']?.toString(),
        catatan: map['catatan']?.toString() ?? '',
      );
}
typedef DataMap = Map<String, dynamic>;

class MasterDatabase {
  final String pt;
  final String kebun;
  final String afdeling;
  final String asisten;
  final String gasWebhookUrl;
  final List<String> daftarMandor;
  final List<DataMap> daftarPemanen;
  final List<DataMap> daftarBlok;

  MasterDatabase({
    this.pt = 'PT Kencana Agri (PT. STN)',
    this.kebun = 'Kebun Plasma Wanggarasi',
    this.afdeling = 'Afdeling Plasma BSP',
    this.asisten = 'Sukri',
    this.gasWebhookUrl = '',
    this.daftarMandor = const ['Pak Candra', 'Pak Ramin', 'Pak Budi', 'Bang Edi'],
    this.daftarPemanen = const [
      {'nama': 'Pemanen 1', 'nik': 'PMN-001'},
      {'nama': 'Pemanen 2', 'nik': 'PMN-002'},
    ],
    this.daftarBlok = const [
      {'blok': 'BLOK A01', 'bjr': 16.5},
      {'blok': 'BLOK A02', 'bjr': 17.0},
      {'blok': 'BLOK B01', 'bjr': 15.8},
    ],
  });

  String toShareableText() {
    final payload = jsonEncode({
      'app': 'IPD_PLASMA_MASTER',
      'v': 2,
      'pt': pt,
      'kebun': kebun,
      'afdeling': afdeling,
      'asisten': asisten,
      'gasWebhookUrl': gasWebhookUrl,
      'daftarMandor': daftarMandor,
      'daftarPemanen': daftarPemanen,
      'daftarBlok': daftarBlok,
    });
    return '*[MASTER DATA IPD PLASMA]*\n'
        'Perusahaan: $pt\n'
        'Kebun/Afd: $kebun - $afdeling\n'
        'Asisten: $asisten\n'
        'Salin seluruh pesan ini lalu tempel di menu *Impor Master Data* pada aplikasi IPD PLASMA:\n\n'
        '```IPD_MASTER_START\n$payload\nIPD_MASTER_END```';
  }

  static MasterDatabase? fromShareableText(String raw) {
    try {
      String clean = raw.trim();
      if (clean.contains('IPD_MASTER_START') && clean.contains('IPD_MASTER_END')) {
        clean = clean.split('IPD_MASTER_START')[1].split('IPD_MASTER_END')[0].trim();
      }
      final map = jsonDecode(clean);
      if (map['app'] != 'IPD_PLASMA_MASTER') return null;
      return MasterDatabase(
        pt: map['pt'] ?? 'PT Kencana Agri (PT. STN)',
        kebun: map['kebun'] ?? 'Kebun Plasma Wanggarasi',
        afdeling: map['afdeling'] ?? 'Afdeling Plasma BSP',
        asisten: map['asisten'] ?? 'Sukri',
        gasWebhookUrl: map['gasWebhookUrl'] ?? '',
        daftarMandor: List<String>.from(map['daftarMandor'] ?? []),
        daftarPemanen: (map['daftarPemanen'] as List? ?? [])
            .map((e) => DataMap.from(e))
            .toList(),
        daftarBlok: (map['daftarBlok'] as List? ?? [])
            .map((e) => DataMap.from(e))
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'pt': pt,
        'kebun': kebun,
        'afdeling': afdeling,
        'asisten': asisten,
        'gasWebhookUrl': gasWebhookUrl,
        'daftarMandor': daftarMandor,
        'daftarPemanen': daftarPemanen,
        'daftarBlok': daftarBlok,
      };

  factory MasterDatabase.fromJson(Map<String, dynamic> map) => MasterDatabase(
        pt: map['pt'] ?? 'PT Kencana Agri (PT. STN)',
        kebun: map['kebun'] ?? 'Kebun Plasma Wanggarasi',
        afdeling: map['afdeling'] ?? 'Afdeling Plasma BSP',
        asisten: map['asisten'] ?? 'Sukri',
        gasWebhookUrl: map['gasWebhookUrl'] ?? '',
        daftarMandor: List<String>.from(map['daftarMandor'] ?? []),
        daftarPemanen: (map['daftarPemanen'] as List? ?? [])
            .map((e) => DataMap.from(e))
            .toList(),
        daftarBlok: (map['daftarBlok'] as List? ?? [])
            .map((e) => DataMap.from(e))
            .toList(),
      );
}
