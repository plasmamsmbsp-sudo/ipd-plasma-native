import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class InputHelper {
  static Future ambilGpsSekarang() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
    } catch (_) {}
    return null;
  }

  static Future prosesFotoWatermark({
    required ImageSource source,
    required String afdeling,
    required String blok,
    required String ancak,
    required String pemanen,
    required String mandor,
    required Position? gps,
  }) async {
    final picker = ImagePicker();
    final XFile? foto = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (foto == null) return null;

    final bytes = await File(foto.path).readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);

    final dir = await getApplicationDocumentsDirectory();
    final namaFile = 'IPD_${blok}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = p.join(dir.path, namaFile);

    if (decoded != null) {
      final waktuStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
      final gpsStr = gps != null
          ? 'GPS: ${gps.latitude.toStringAsFixed(6)}, ${gps.longitude.toStringAsFixed(6)}'
          : 'GPS: Offline';
      final pemanenStr = pemanen.trim().isEmpty ? '-' : pemanen.trim();

      final line1 = 'IPD PLASMA | $afdeling - BLOK $blok (Ancak $ancak)';
      final line2 = 'Pemanen: $pemanenStr | Mandor: $mandor';
      final line3 = '$waktuStr | $gpsStr';

      int boxHeight = 95;
      int startY = decoded.height - boxHeight;
      if (startY < 0) startY = 0;

      img.fillRect(
        decoded,
        x1: 0,
        y1: startY,
        x2: decoded.width,
        y2: decoded.height,
        color: img.ColorRgba8(15, 45, 18, 200),
      );

      img.drawString(
        decoded,
        line1,
        font: img.arial24,
        x: 16,
        y: startY + 10,
        color: img.ColorRgb8(251, 192, 45),
      );
      img.drawString(
        decoded,
        line2,
        font: img.arial14,
        x: 16,
        y: startY + 42,
        color: img.ColorRgb8(255, 255, 255),
      );
      img.drawString(
        decoded,
        line3,
        font: img.arial14,
        x: 16,
        y: startY + 64,
        color: img.ColorRgb8(220, 255, 220),
      );

      await File(targetPath).writeAsBytes(img.encodeJpg(decoded, quality: 82));
    } else {
      await File(foto.path).copy(targetPath);
    }

    return targetPath;
  }
}
