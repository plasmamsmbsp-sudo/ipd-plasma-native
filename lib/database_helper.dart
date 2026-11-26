import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class SopDendaItem {
  final String kode;
  final String singkatan;
  final String nama;
  final String satuan;
  final int dendaPerUnit;
  final String kategori;

  const SopDendaItem({
    required this.kode,
    required this.singkatan,
    required this.nama,
    required this.satuan,
    required this.dendaPerUnit,
    required this.kategori,
  });
}

const daftarParameterSop = [
  SopDendaItem(kode: 'P1', singkatan: 'BM', nama: 'Memotong Buah Mentah', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'TPH'),
  SopDendaItem(kode: 'P2', singkatan: 'BTP', nama: 'Buah Tinggal di Pokok', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P3', singkatan: 'BTG', nama: 'Buah Tinggal di Gawangan / Piringan', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P4', singkatan: 'BPM', nama: 'Buah Mentah Diperam', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P5', singkatan: 'TP', nama: 'Tangkai Panjang (> 3 cm)', satuan: 'Jjg', dendaPerUnit: 500, kategori: 'TPH'),
  SopDendaItem(kode: 'P6', singkatan: 'SP', nama: 'Susunan Pelepah & Tidak Potong 2', satuan: 'Pkk', dendaPerUnit: 2000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P7', singkatan: 'OP', nama: 'Over Pruning', satuan: 'Pkk', dendaPerUnit: 5000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P8', singkatan: 'PS', nama: 'Pelepah Sengkleh', satuan: 'Plp', dendaPerUnit: 5000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P9', singkatan: 'BRDT', nama: 'Berondolan Tinggal Ancak & TPH', satuan: 'Btr', dendaPerUnit: 200, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P10', singkatan: 'ALT', nama: 'Alas TPH', satuan: 'TPH', dendaPerUnit: 1000, kategori: 'TPH'),
];

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ipd_plasma_kencana_v3.db');
    return _database!;
  }

  Future _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inspeksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        pt TEXT NOT NULL,
        afdeling TEXT NOT NULL,
        blok TEXT NOT NULL,
        no_ancak TEXT NOT NULL,
        pokok_sampel INTEGER NOT NULL,
        tapak_panen INTEGER NOT NULL,
        bjr_blok REAL NOT NULL,
        berat_brondolan_gr REAL NOT NULL,
        losses_brondolan_kg REAL NOT NULL,
        losses_buah_kg REAL NOT NULL,
        total_losses_kg REAL NOT NULL,
        persen_losses REAL NOT NULL,
        pemanen TEXT NOT NULL,
        mandor TEXT NOT NULL,
        kerani TEXT NOT NULL,
        asisten TEXT NOT NULL,
        lat REAL,
        lng REAL,
        temuan_json TEXT NOT NULL,
        total_denda INTEGER NOT NULL,
        nilai_mutu REAL NOT NULL,
        foto_paths TEXT NOT NULL,
        catatan TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE master_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipe TEXT NOT NULL,
        nama TEXT NOT NULL,
        extra REAL DEFAULT 15.0
      )
    ''');

    await db.execute('''
      CREATE TABLE gps_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sesi TEXT NOT NULL,
        waktu TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        tipe_pin TEXT NOT NULL,
        keterangan TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        kunci TEXT PRIMARY KEY,
        nilai TEXT NOT NULL
      )
    ''');

    final defaultMasters = [
      {'tipe': 'AFDELING', 'nama': 'Plasma BSP', 'extra': 0.0},
      {'tipe': 'AFDELING', 'nama': 'Plasma MSM', 'extra': 0.0},
      {'tipe': 'AFDELING', 'nama': 'PT. STN', 'extra': 0.0},
      {'tipe': 'BLOK', 'nama': 'D001A', 'extra': 16.5},
      {'tipe': 'BLOK', 'nama': 'E0015', 'extra': 15.8},
      {'tipe': 'BLOK', 'nama': 'E0013', 'extra': 16.0},
      {'tipe': 'BLOK', 'nama': 'E0018A', 'extra': 15.5},
      {'tipe': 'MANDOR', 'nama': 'Albar Mooduto', 'extra': 0.0},
      {'tipe': 'MANDOR', 'nama': 'Mas Budi', 'extra': 0.0},
      {'tipe': 'MANDOR', 'nama': 'Pak Candra', 'extra': 0.0},
      {'tipe': 'MANDOR', 'nama': 'Pak Ramin', 'extra': 0.0},
      {'tipe': 'MANDOR', 'nama': 'Bang Edi', 'extra': 0.0},
      {'tipe': 'KERANI', 'nama': 'Firman Hulopi', 'extra': 0.0},
      {'tipe': 'KERANI', 'nama': 'Aldrianto Eka Putra', 'extra': 0.0},
    ];
    for (var m in defaultMasters) {
      await db.insert('master_data', m);
    }

    await db.insert('settings', {'kunci': 'gsheet_url', 'nilai': ''});
    await db.insert('settings', {'kunci': 'asisten_default', 'nilai': 'Sukri'});
    await db.insert('settings', {'kunci': 'saved_pdf_path', 'nilai': ''});
    await db.insert('settings', {'kunci': 'saved_map_ss', 'nilai': ''});
  }

  Future insertInspeksi(Map<String, dynamic> row) async {
    final Database db = await instance.database;
    return await db.insert('inspeksi', row);
  }

  Future getAllInspeksi() async {
    final Database db = await instance.database;
    return await db.query('inspeksi', orderBy: 'id DESC');
  }

  Future markSynced(int id) async {
    final Database db = await instance.database;
    await db.update('inspeksi', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future deleteInspeksi(int id) async {
    final Database db = await instance.database;
    return await db.delete('inspeksi', where: 'id = ?', whereArgs: [id]);
  }

  Future getMasterRowsByTipe(String tipe) async {
    final Database db = await instance.database;
    return await db.query('master_data', where: 'tipe = ?', whereArgs: [tipe], orderBy: 'nama ASC');
  }

  Future getMasterByTipe(String tipe) async {
    final rows = List.from(await getMasterRowsByTipe(tipe));
    return rows.map((e) => e['nama'].toString()).toList();
  }

  Future getBjrBlok(String namaBlok) async {
    final Database db = await instance.database;
    final res = await db.query('master_data', where: 'tipe = ? AND nama = ?', whereArgs: ['BLOK', namaBlok]);
    if (res.isNotEmpty) return (res.first['extra'] as num).toDouble();
    return 15.0;
  }

  Future addMaster(String tipe, String nama, {double extra = 15.0}) async {
    final Database db = await instance.database;
    await db.delete('master_data', where: 'tipe = ? AND nama = ?', whereArgs: [tipe, nama.trim()]);
    await db.insert('master_data', {'tipe': tipe, 'nama': nama.trim(), 'extra': extra});
  }

  Future deleteMaster(String tipe, String nama) async {
    final Database db = await instance.database;
    await db.delete('master_data', where: 'tipe = ? AND nama = ?', whereArgs: [tipe, nama]);
  }

  Future exportAllMasterJson() async {
    final Database db = await instance.database;
    return await db.query('master_data', orderBy: 'tipe ASC, nama ASC');
  }

  Future importMasterList(List items) async {
    final Database db = await instance.database;
    for (var item in items) {
      final tipe = item['tipe'].toString();
      final nama = item['nama'].toString();
      final extra = (item['extra'] ?? 15.0) as num;
      await addMaster(tipe, nama, extra: extra.toDouble());
    }
  }

  Future getSetting(String kunci) async {
    final Database db = await instance.database;
    final res = await db.query('settings', where: 'kunci = ?', whereArgs: [kunci]);
    if (res.isNotEmpty) return res.first['nilai'].toString();
    return '';
  }

  Future saveSetting(String kunci, String nilai) async {
    final Database db = await instance.database;
    await db.insert('settings', {'kunci': kunci, 'nilai': nilai}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future insertGpsPoint(String sesi, double lat, double lng, {String tipePin = 'TREK', String keterangan = ''}) async {
    final Database db = await instance.database;
    await db.insert('gps_tracks', {
      'sesi': sesi,
      'waktu': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'lat': lat,
      'lng': lng,
      'tipe_pin': tipePin,
      'keterangan': keterangan,
    });
  }

  Future getGpsTracks() async {
    final Database db = await instance.database;
    return await db.query('gps_tracks', orderBy: 'id DESC', limit: 300);
  }
}
