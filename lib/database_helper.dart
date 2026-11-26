import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class SopDendaItem {
  final String kode;
  final String nama;
  final String satuan;
  final int dendaPerUnit;
  final String kategori;

  const SopDendaItem({
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.dendaPerUnit,
    required this.kategori,
  });
}

const List<SopDendaItem> daftarParameterSop = [
  SopDendaItem(kode: 'P1', nama: 'Buah Mentah Dipanen', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'TPH'),
  SopDendaItem(kode: 'P2', nama: 'Buah Matang Tinggal di Pokok', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P3', nama: 'Buah Tinggal di Gawangan/Piringan', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P4', nama: 'Buah Mentah Diperam/Disembunyikan', satuan: 'Jjg', dendaPerUnit: 10000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P5', nama: 'Tangkai Panjang (> 3 cm)', satuan: 'Jjg', dendaPerUnit: 500, kategori: 'TPH'),
  SopDendaItem(kode: 'P6', nama: 'Susunan Pelepah / Tidak Potong 2', satuan: 'Plp', dendaPerUnit: 2000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P7', nama: 'Over Pruning (Pelepah Sengkleh/Habis)', satuan: 'Pkk', dendaPerUnit: 5000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P8', nama: 'Pelepah Sengkleh Tidak Dipotong', satuan: 'Plp', dendaPerUnit: 5000, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P9', nama: 'Berondolan Tinggal di Piringan/Pasar Pikul', satuan: 'Btr', dendaPerUnit: 200, kategori: 'ANCAK'),
  SopDendaItem(kode: 'P10', nama: 'Tidak Pakai Alas TPH / Berondolan Kotor', satuan: 'TPH', dendaPerUnit: 1000, kategori: 'TPH'),
];

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ipd_plasma_wanggarasi_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
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
        pemanen TEXT NOT NULL,
        mandor TEXT NOT NULL,
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
        nama TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE gps_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sesi TEXT NOT NULL,
        waktu TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        kunci TEXT PRIMARY KEY,
        nilai TEXT NOT NULL
      )
    ''');

    final defaultMasters = [
      {'tipe': 'AFDELING', 'nama': 'AFD BSP'},
      {'tipe': 'AFDELING', 'nama': 'AFD MSM'},
      {'tipe': 'AFDELING', 'nama': 'PT. STN'},
      {'tipe': 'BLOK', 'nama': 'A01'},
      {'tipe': 'BLOK', 'nama': 'A02'},
      {'tipe': 'BLOK', 'nama': 'B01'},
      {'tipe': 'BLOK', 'nama': 'B02'},
      {'tipe': 'BLOK', 'nama': 'C01'},
      {'tipe': 'MANDOR', 'nama': 'Mas Budi'},
      {'tipe': 'MANDOR', 'nama': 'Pak Candra'},
      {'tipe': 'MANDOR', 'nama': 'Pak Ramin'},
      {'tipe': 'MANDOR', 'nama': 'Bang Edi'},
      {'tipe': 'MANDOR', 'nama': 'Aldrianto Eka Putra'},
    ];
    for (var m in defaultMasters) {
      await db.insert('master_data', m);
    }

    await db.insert('settings', {'kunci': 'gsheet_url', 'nilai': ''});
    await db.insert('settings', {'kunci': 'asisten_default', 'nilai': 'Sukri'});
  }

  Future<int> insertInspeksi(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('inspeksi', row);
  }

  Future<List>> getAllInspeksi() async {
    final db = await instance.database;
    return await db.query('inspeksi', orderBy: 'id DESC');
  }

  Future<void> markSynced(int id) async {
    final db = await instance.database;
    await db.update('inspeksi', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteInspeksi(int id) async {
    final db = await instance.database;
    return await db.delete('inspeksi', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getMasterByTipe(String tipe) async {
    final db = await instance.database;
    final res = await db.query('master_data', where: 'tipe = ?', whereArgs: [tipe], orderBy: 'nama ASC');
    return res.map((e) => e['nama'] as String).toList();
  }

  Future<void> addMaster(String tipe, String nama) async {
    final db = await instance.database;
    await db.insert('master_data', {'tipe': tipe, 'nama': nama.trim()});
  }

  Future<void> deleteMaster(String tipe, String nama) async {
    final db = await instance.database;
    await db.delete('master_data', where: 'tipe = ? AND nama = ?', whereArgs: [tipe, nama]);
  }

  Future<String> getSetting(String kunci) async {
    final db = await instance.database;
    final res = await db.query('settings', where: 'kunci = ?', whereArgs: [kunci]);
    if (res.isNotEmpty) return res.first['nilai'] as String;
    return '';
  }

  Future<void> saveSetting(String kunci, String nilai) async {
    final db = await instance.database;
    await db.insert('settings', {'kunci': kunci, 'nilai': nilai}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertGpsPoint(String sesi, double lat, double lng) async {
    final db = await instance.database;
    await db.insert('gps_tracks', {
      'sesi': sesi,
      'waktu': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'lat': lat,
      'lng': lng,
    });
  }

  Future<List>> getGpsTracks() async {
    final db = await instance.database;
    return await db.query('gps_tracks', orderBy: 'id DESC', limit: 200);
  }
}
