import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IpdPlasmaApp());
}

// ============================================================================
// KONSTANTA & 10 PARAMETER DENDA SOP PANEN (PT KENCANA AGRI - PLASMA WANGGARASI)
// ============================================================================
class SopDendaItem {
  final String kode;
  final String nama;
  final String satuan;
  final int dendaPerUnit;
  final String kategori; // 'ANCAK' atau 'TPH'

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

// ============================================================================
// DATABASE OFFLINE SQLITE PERMANEN
// ============================================================================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ipd_plasma_wanggarasi.db');
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
        catatan TEXT
      )
    ''');
  }

  Future<int> insertInspeksi(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('inspeksi', row);
  }

  Future<List>> getAllInspeksi() async {
    final db = await instance.database;
    return await db.query('inspeksi', orderBy: 'id DESC');
  }

  Future<int> deleteInspeksi(int id) async {
    final db = await instance.database;
    return await db.delete('inspeksi', where: 'id = ?', whereArgs: [id]);
  }
}

// ============================================================================
// APLIKASI UTAMA (TEMA HIJAU & EMAS PT KENCANA AGRI)
// ============================================================================
class IpdPlasmaApp extends StatelessWidget {
  const IpdPlasmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPD PLASMA - Kencana Agri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // Forest Green Kencana Agri
          primary: const Color(0xFF1B5E20),
          secondary: const Color(0xFFFBC02D), // Gold/Yellow Kencana Agri
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const FormInspeksiPage(),
      const RiwayatDanEksporPage(),
      const PetaBlokGpsPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        indicatorColor: const Color(0xFFFBC02D).withOpacity(0.35),
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check, color: Color(0xFF1B5E20)),
            label: 'Input IPD',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart, color: Color(0xFF1B5E20)),
            label: 'Rekap & Excel',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF1B5E20)),
            label: 'Peta & GPS',
          ),
        ],
      ),
    );
  }
}
