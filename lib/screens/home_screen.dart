import 'dart:convert';

class KriteriaIpd {
  final String kode;
  final String nama;
  final String satuan;
  final int denda;
  final bool isLosses;

  const KriteriaIpd({
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.denda,
    this.isLosses = false,
  });
}

const List<KriteriaIpd> kDaftarKriteria = [
  KriteriaIpd(kode: 'brondolan', nama: 'Berondolan Tidak Dikutip', satuan: 'Butir', denda: 200, isLosses: true),
  KriteriaIpd(kode: 'buah_mentah', nama: 'Buah Mentah Dipanen', satuan: 'Janjang', denda: 10000),
  KriteriaIpd(kode: 'buah_tinggal_pokok', nama: 'Buah Matang Tidak Dipanen', satuan: 'Janjang', denda: 10000, isLosses: true),
  KriteriaIpd(kode: 'buah_tinggal_piringan', nama: 'Buah Tinggal di Piringan/Pasar Pikul', satuan: 'Janjang', denda: 10000, isLosses: true),
  KriteriaIpd(kode: 'buah_peram', nama: 'Buah Mentah Diperam/Disembunyikan', satuan: 'Janjang', denda: 10000),
  KriteriaIpd(kode: 'tangkai_panjang', nama: 'Tangkai Panjang (> 3 cm)', satuan: 'Janjang', denda: 500),
  KriteriaIpd(kode: 'pelepah_tidak_susun', nama: 'Pelepah Tidak Dipotong / Tidak Disusun', satuan: 'Pokok', denda: 2000),
  KriteriaIpd(kode: 'over_pruning', nama: 'Over Pruning (Songgo Kurang)', satuan: 'Pokok', denda: 5000),
  KriteriaIpd(kode: 'pelepah_sengkleh', nama: 'Pelepah Sengkleh Tidak Diturunkan', satuan: 'Pelepah', denda: 5000),
  KriteriaIpd(kode: 'tph_kotor', nama: 'TPH Kotor / Tidak Diberi Nomor', satuan: 'TPH', denda: 1000),
];

class InspeksiItem {
  final String id;
  final String tanggal;
  final String pt;
  final String kebun;
  final String afdeling;
  final String asisten;
  final String mandor;
  final String pemanen;
  final String nikPemanen;
  final String blok;
  final String noTph;
  final int pokokSampel;
  final double bjr;
  final int janjangPanen;
  final Map<String, int> temuan;
  final List<String> fotoPaths;
  final String? mapScreenshotPath;
  final double? lat;
  final double? lng;

  InspeksiItem({
    required this.id,
    required this.tanggal,
    this.pt = 'PT Kencana Agri (PT. STN)',
    this.kebun = 'Kebun Plasma Wanggarasi',
    this.afdeling = 'Afdeling Plasma BSP',
    this.asisten = 'Sukri',
    required this.mandor,
    required this.pemanen,
    this.nikPemanen = '',
    required this.blok,
    this.noTph = '01',
    this.pokokSampel = 10,
    required this.bjr,
    required this.janjangPanen,
    required this.temuan,
    this.fotoPaths = const [],
    this.mapScreenshotPath,
    this.lat,
    this.lng,
  });

  int get totalDenda {
    int total = 0;
    for (final k in kDaftarKriteria) {
      final jml = temuan[k.kode] ?? 0;
      total += jml * k.denda;
    }
    return total;
  }

  double get beratBrondolanKg => (temuan['brondolan'] ?? 0) * 0.012;

  double get beratBuahTinggalKg {
    final jjgTinggal = (temuan['buah_tinggal_pokok'] ?? 0) +
        (temuan['buah_tinggal_piringan'] ?? 0);
    return jjgTinggal * bjr;
  }

  double get totalLossesKg => beratBrondolanKg + beratBuahTinggalKg;

  double get persentaseLosses {
    final totalProduksiKg = (janjangPanen * bjr) + totalLossesKg;
    if (totalProduksiKg <= 0) return 0.0;
    return (totalLossesKg / totalProduksiKg) * 100.0;
  }

  String get tingkatRisiko {
    if (persentaseLosses >= 3.0 || totalDenda >= 50000) return 'MERAH';
    if (persentaseLosses >= 1.5 || totalDenda >= 20000) return 'ORANYE';
    return 'KUNING';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': tanggal,
        'pt': pt,
        'kebun': kebun,
        'afdeling': afdeling,
        'asisten': asisten,
        'mandor': mandor,
        'pemanen': pemanen,
        'nikPemanen': nikPemanen,
        'blok': blok,
        'noTph': noTph,
        'pokokSampel': pokokSampel,
        'bjr': bjr,
        'janjangPanen': janjangPanen,
        'temuan': temuan,
        'fotoPaths': fotoPaths,
        'mapScreenshotPath': mapScreenshotPath,
        'lat': lat,
        'lng': lng,
      };

  factory InspeksiItem.fromJson(Map<String, dynamic> map) {
    final rawTemuan = map['temuan'] as Map? ?? {};
    final parsedTemuan = <String, int>{};
    rawTemuan.forEach((key, val) {
      parsedTemuan[key.toString()] = (val as num?)?.toInt() ?? 0;
    });

    return InspeksiItem(
      id: map['id']?.toString() ?? '',
      tanggal: map['tanggal']?.toString() ?? '',
      pt: map['pt']?.toString() ?? 'PT Kencana Agri (PT. STN)',
      kebun: map['kebun']?.toString() ?? 'Kebun Plasma Wanggarasi',
      afdeling: map['afdeling']?.toString() ?? 'Afdeling Plasma BSP',
      asisten: map['asisten']?.toString() ?? 'Sukri',
      mandor: map['mandor']?.toString() ?? '',
      pemanen: map['pemanen']?.toString() ?? '',
      nikPemanen: map['nikPemanen']?.toString() ?? '',
      blok: map['blok']?.toString() ?? '',
      noTph: map['noTph']?.toString() ?? '01',
      pokokSampel: (map['pokokSampel'] as num?)?.toInt() ?? 10,
      bjr: (map['bjr'] as num?)?.toDouble() ?? 16.0,
      janjangPanen: (map['janjangPanen'] as num?)?.toInt() ?? 0,
      temuan: parsedTemuan,
      fotoPaths: List<String>.from(map['fotoPaths'] ?? []),
      mapScreenshotPath: map['mapScreenshotPath']?.toString(),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }
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
