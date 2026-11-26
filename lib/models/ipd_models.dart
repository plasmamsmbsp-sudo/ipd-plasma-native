import 'dart:convert';

class KriteriaDenda {
  final String kode;
  final String nama;
  final String satuan;
  final int tarif;
  final bool isLosses; // Masuk perhitungan losses (buah/brondolan) atau mutu ancak

  const KriteriaDenda({
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.tarif,
    required this.isLosses,
  });
}

const List<KriteriaDenda> kDaftarKriteria = [
  KriteriaDenda(kode: 'BM', nama: 'Buah Mentah', satuan: 'Jjg', tarif: 10000, isLosses: false),
  KriteriaDenda(kode: 'BTP', nama: 'Buah Tinggal di Pokok', satuan: 'Jjg', tarif: 10000, isLosses: true),
  KriteriaDenda(kode: 'BTG', nama: 'Buah Tinggal di Gawangan/Piringan', satuan: 'Jjg', tarif: 10000, isLosses: true),
  KriteriaDenda(kode: 'BMP', nama: 'Buah Mentah Diperam', satuan: 'Jjg', tarif: 10000, isLosses: false),
  KriteriaDenda(kode: 'TPJ', nama: 'Tangkai Panjang > 3 cm', satuan: 'Jjg', tarif: 500, isLosses: false),
  KriteriaDenda(kode: 'SPL', nama: 'Susunan Pelepah / Tdk Potong 2', satuan: 'Plp', tarif: 2000, isLosses: false),
  KriteriaDenda(kode: 'OVP', nama: 'Over Pruning (Sengkleh Atas)', satuan: 'Pkk', tarif: 5000, isLosses: false),
  KriteriaDenda(kode: 'PSG', nama: 'Pelepah Sengkleh', satuan: 'Plp', tarif: 5000, isLosses: false),
  KriteriaDenda(kode: 'BRD', nama: 'Brondolan Tinggal', satuan: 'Btr', tarif: 200, isLosses: true),
  KriteriaDenda(kode: 'TPH', nama: 'Alas TPH / Kebersihan TPH', satuan: 'TPH', tarif: 1000, isLosses: false),
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
  final Map<String, int> temuan; // kode -> jumlah
  final List<String> fotoPaths;
  final String? mapScreenshotPath;
  final double? lat;
  final double? lng;
  final String catatan;

  InspeksiItem({
    required this.id,
    required this.tanggal,
    required this.pt,
    required this.kebun,
    required this.afdeling,
    required this.asisten,
    required this.mandor,
    required this.pemanen,
    required this.nikPemanen,
    required this.blok,
    required this.noTph,
    required this.pokokSampel,
    required this.bjr,
    required this.janjangPanen,
    required this.temuan,
    required this.fotoPaths,
    this.mapScreenshotPath,
    this.lat,
    this.lng,
    this.catatan = '',
  });

  int get totalDenda {
    int sum = 0;
    for (var k in kDaftarKriteria) {
      sum += (temuan[k.kode] ?? 0) * k.tarif;
    }
    return sum;
  }

  /// Perhitungan Persentase Losses (Buah Tinggal + Brondolan Tinggal vs Total Potensi Panen)
  /// Asumsi 1 butir brondolan = 0.015 kg (15 gram)
  double get persentaseLosses {
    final int buahTinggal = (temuan['BTP'] ?? 0) + (temuan['BTG'] ?? 0);
    final int brondolan = temuan['BRD'] ?? 0;
    final double kgLosses = (buahTinggal * bjr) + (brondolan * 0.015);
    final double kgPanen = (janjangPanen + buahTinggal) * bjr + (brondolan * 0.015);
    if (kgPanen <= 0) return 0.0;
    return (kgLosses / kgPanen) * 100;
  }

  /// Kategori Warna Marker Peta (Merah = Kritis, Oranye = Peringatan, Kuning = Ringan)
  String get tingkatRisiko {
    if (persentaseLosses > 3.0 || totalDenda >= 25000) return 'MERAH';
    if (persentaseLosses > 1.0 || totalDenda >= 10000) return 'ORANYE';
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
        'catatan': catatan,
      };

  factory InspeksiItem.fromJson(Map<String, dynamic> json) => InspeksiItem(
        id: json['id'] ?? '',
        tanggal: json['tanggal'] ?? '',
        pt: json['pt'] ?? 'PT Kencana Agri',
        kebun: json['kebun'] ?? 'Plasma Wanggarasi',
        afdeling: json['afdeling'] ?? 'Afdeling BSP',
        asisten: json['asisten'] ?? 'Sukri',
        mandor: json['mandor'] ?? '',
        pemanen: json['pemanen'] ?? '',
        nikPemanen: json['nikPemanen'] ?? '',
        blok: json['blok'] ?? '',
        noTph: json['noTph'] ?? '',
        pokokSampel: json['pokokSampel'] ?? 10,
        bjr: (json['bjr'] ?? 15.0).toDouble(),
        janjangPanen: json['janjangPanen'] ?? 50,
        temuan: Map<String, int>.from(json['temuan'] ?? {}),
        fotoPaths: List<String>.from(json['fotoPaths'] ?? []),
        mapScreenshotPath: json['mapScreenshotPath'],
        lat: json['lat']?.toDouble(),
        lng: json['lng']?.toDouble(),
        catatan: json['catatan'] ?? '',
      );
}

class MasterDatabase {
  String pt;
  String kebun;
  String afdeling;
  String asisten;
  String gasWebhookUrl;
    List<String> daftarMandor;
  List> daftarPemanen; // [{'nama': '...', 'nik': '...'}]
  List> daftarBlok;    // [{'blok': 'A01', 'bjr': 10.5}]
  
  MasterDatabase({
    this.pt = 'PT Kencana Agri (PT. STN)',
    this.kebun = 'Kebun Plasma Wanggarasi',
    this.afdeling = 'Afdeling Plasma BSP',
    this.asisten = 'Sukri',
    this.gasWebhookUrl = '',
    this.daftarMandor = const ['Budi', 'Ramin', 'Candra', 'Edi'],
    this.daftarPemanen = const [
      {'nama': 'Pemanen 01', 'nik': 'BSP-001'},
      {'nama': 'Pemanen 02', 'nik': 'BSP-002'},
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
            .map((e) => Map<String, String>.from(e))
            .toList(),
        daftarBlok: (map['daftarBlok'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
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
            .map((e) => Map<String, String>.from(e))
            .toList(),
        daftarBlok: (map['daftarBlok'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
}

