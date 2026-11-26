import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ipd_models.dart';

class StorageService {
  static const String _keyData = 'ipd_inspeksi_list_v2';
  static const String _keyMaster = 'ipd_master_db_v2';
  static const String _keyPdfPath = 'ipd_saved_pdf_map_path';

  static Future<List<InspeksiItem>> loadInspeksi() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyData);
    if (raw == null || raw.isEmpty) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => InspeksiItem.fromJson(e)).toList();
  }

  static Future<void> saveInspeksi(List<InspeksiItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyData, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<MasterDatabase> loadMaster() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMaster);
    if (raw == null || raw.isEmpty) return MasterDatabase();
    return MasterDatabase.fromJson(jsonDecode(raw));
  }

  static Future<void> saveMaster(MasterDatabase master) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMaster, jsonEncode(master.toJson()));
  }

  static Future<void> savePdfMapPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPdfPath, path);
  }

  static Future<String?> loadPdfMapPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPdfPath);
  }
}
