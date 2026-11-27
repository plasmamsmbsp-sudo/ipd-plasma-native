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
  final int jumlahTandanPanen;

  // 10 Parameter Mutu & Losses Panen
  final int brondolanTidakDikutip; // butir / piringan & gawangan
  final int buahMentah;            // tandan
  final int buahMengkal;           // tandan
  final int tandanKosong;          // tandan
  final int buahTinggal;           // tandan tidak diangkut ke TPH
  final int tangkaiPanjang;        // tandan (> 2 cm)
  final int pelepahSengkleh;       // pelepah tidak dipotong / sengkleh
  final int pelepahTidakDisusun;   // pokok (tidak disusun di gawangan mati)
  final int tidakBeriNomor;        // tandan tanpa nomor pemanen
  final int tphTidakBersih;        // titik TPH kotor / berondolan tertinggal

  // GPS & Dokumentasi Foto
  final double? lat;
  final double? lng;
  final List<String> fotoPaths;
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
    required this.jumlahPokokSampel,
    required this.jumlahTandanPanen,
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
    this.catatan = '',
  });

  // Berat brondolan tertinggal (estimasi 1 butir = 12 gram = 0.012 kg)
  double get beratBrondolanKg => brondolanTidakDikutip * 0.012;

  // Berat buah tinggal (tandan x BJR)
  double get beratBuahTinggalKg => buahTinggal * bjr;

  // Total berat produksi sampel (kg)
  double get totalBeratProduksiKg {
    final base = jumlahTandanPanen * bjr;
    return base > 0 ? base : bjr;
  }

  // Persentase Losses (%) otomatis dari BJR, brondolan, dan buah tinggal
  double get persentaseLosses {
    final totalLossKg = beratBrondolanKg + beratBuahTinggalKg;
    return (totalLossKg / totalBeratProduksiKg) * 100.0;
  }

  // Kategori Warna Pin Peta (MERAH / ORANYE / KUNING)
  String get tingkatRisiko {
    if (persentaseLosses >= 3.0 || totalDenda >= 100000) return 'MERAH';
    if (persentaseLosses >= 1.5 || totalDenda >= 50000) return 'ORANYE';
    return 'KUNING';
  }

  // Kalkulasi Total Denda SOP Panen (Rp)
  int get totalDenda {
    int denda = 0;
    denda += brondolanTidakDikutip * 500;   // Rp 500 / butir
    denda += buahMentah * 25000;           // Rp 25.000 / tandan
    denda += buahMengkal * 15000;          // Rp 15.000 / tandan
    denda += tandanKosong * 10000;         // Rp 10.000 / tandan
    denda += buahTinggal * 20000;          // Rp 20.000 / tandan
    denda += tangkaiPanjang * 5000;        // Rp 5.000 / tandan
    denda += pelepahSengkleh * 5000;       // Rp 5.000 / pelepah
    denda += pelepahTidakDisusun * 5000;   // Rp 5.000 / pokok
    denda += tidakBeriNomor * 2000;        // Rp 2.000 / tandan
    denda += tphTidakBersih * 10000;       // Rp 10.000 / TPH
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
        'jumlahTandanPanen': jumlahTandanPanen,
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
        jumlahTandanPanen: (map['jumlahTandanPanen'] as num?)?.toInt() ?? 0,
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
        catatan: map['catatan']?.toString() ?? '',
      );
}
class MasterDatabase {
  final String pt;
  final String kebun;
  final String afdeling;
  final String asisten;
  final String gasWebhookUrl;
  final List<String> daftarMandor;
  final List> daftarPemanen;
  final List> daftarBlok;

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
            .map((e) => Map<String, dynamic>.from(e))
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
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        daftarBlok: (map['daftarBlok'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
}
