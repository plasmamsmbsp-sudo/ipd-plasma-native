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
