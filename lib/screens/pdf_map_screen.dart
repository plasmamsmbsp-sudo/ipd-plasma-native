import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import '../models/ipd_models.dart';
import '../services/storage_service.dart';

class PdfMapScreen extends StatefulWidget {
  final List<InspeksiItem> items;
  final Function(String screenshotPath) onMapScreenshotSaved;

  const PdfMapScreen({
    super.key,
    required this.items,
    required this.onMapScreenshotSaved,
  });

  @override
  State<PdfMapScreen> createState() => _PdfMapScreenState();
}

class _PdfMapScreenState extends State<PdfMapScreen> {
  PdfController? _pdfController;
  String? _pdfPath;
  final TransformationController _transformController = TransformationController();
  final GlobalKey _mapRepaintKey = GlobalKey();

  bool _isTracking = false;
  StreamSubscription<Position>? _posSub;
  Position? _currentPos;
  final List<Offset> _trackCanvasPoints = [];
  bool _isZoomedIn = false;

  @override
  void initState() {
    super.initState();
    _initSavedPdf();
    _locateMe(autoZoom: false);
  }

  Future<void> _initSavedPdf() async {
    final saved = await StorageService.loadPdfMapPath();
    if (saved != null && File(saved).existsSync()) {
      setState(() {
        _pdfPath = saved;
        _pdfController = PdfController(document: PdfDocument.openFile(saved));
      });
    }
  }

  Future<void> _pickPdfMap() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      await StorageService.savePdfMapPath(path);
      _pdfController?.dispose();
      setState(() {
        _pdfPath = path;
        _pdfController = PdfController(document: PdfDocument.openFile(path));
      });
    }
  }

  Future<void> _locateMe({bool autoZoom = true}) async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => _currentPos = pos);

    if (autoZoom) {
      setState(() {
        _isZoomedIn = !_isZoomedIn;
        if (_isZoomedIn) {
          _transformController.value = Matrix4.identity()
            ..translate(-180.0, -240.0)
            ..scale(2.6);
        } else {
          _transformController.value = Matrix4.identity();
        }
      });
    }
  }

  void _toggleTracking() {
    if (_isTracking) {
      _posSub?.cancel();
      setState(() => _isTracking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rekam Trek GPS dihentikan')),
      );
    } else {
      setState(() => _isTracking = true);
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3,
        ),
      ).listen((pos) {
        setState(() {
          _currentPos = pos;
          _trackCanvasPoints.add(_gpsToCanvasOffset(pos.latitude, pos.longitude));
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rekam Trek GPS aktif (berjalan lancar offline)')),
      );
    }
  }

  /// Konversi koordinat GPS ke posisi relatif di kanvas peta
  Offset _gpsToCanvasOffset(double lat, double lng) {
    final refLat = _currentPos?.latitude ?? lat;
    final refLng = _currentPos?.longitude ?? lng;
    final dx = 180.0 + ((lng - refLng) * 120000);
    final dy = 260.0 - ((lat - refLat) * 120000);
    return Offset(dx.clamp(24.0, 340.0), dy.clamp(24.0, 500.0));
  }

  Future<void> _captureMapScreenshot() async {
    try {
      final boundary = _mapRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/ss_map_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      widget.onMapScreenshotSaved(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1B5E20),
            content: Text('Screenshot Peta tersimpan & siap masuk ke Sheet 3 Excel!'),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _pdfController?.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Blok PDF & GPS Trek'),
        actions: [
          IconButton(
            tooltip: 'Impor Peta PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _pickPdfMap,
          ),
          IconButton(
            tooltip: 'Simpan SS Peta ke Excel',
            icon: const Icon(Icons.camera_alt),
            onPressed: _captureMapScreenshot,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFFE8F5E9),
            child: Row(
              children: [
                Icon(
                  _isTracking ? Icons.fiber_manual_record : Icons.gps_fixed,
                  color: _isTracking ? Colors.red : const Color(0xFF1B5E20),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentPos != null
                        ? 'GPS: ${_currentPos!.latitude.toStringAsFixed(6)}, ${_currentPos!.longitude.toStringAsFixed(6)} | Titik Trek: ${_trackCanvasPoints.length}'
                        : 'Mencari sinyal satelit GPS (Offline)...',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RepaintBoundary(
              key: _mapRepaintKey,
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.8,
                    maxScale: 6.0,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey.shade200,
                          child: _pdfController != null
                              ? PdfView(controller: _pdfController!)
                              : Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickPdfMap,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Pilih File Peta Blok (.PDF)'),
                                  ),
                                ),
                        ),
                        if (_trackCanvasPoints.length > 1)
                          CustomPaint(
                            size: Size.infinite,
                            painter: _TrackPainter(_trackCanvasPoints),
                          ),
                        ...widget.items
                            .where((InspeksiItem e) => e.lat != null && e.lng != null)
                            .map<Widget>((InspeksiItem item) {
                          final offset = _gpsToCanvasOffset(item.lat!, item.lng!);
                          Color pinColor = Colors.amber;
                          if (item.tingkatRisiko == 'MERAH') pinColor = Colors.red;
                          if (item.tingkatRisiko == 'ORANYE') pinColor = Colors.deepOrange;

                          return Positioned(
                            left: offset.dx - 14,
                            top: offset.dy - 28,
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text('Temuan Blok ${item.blok}'),
                                    content: Text(
                                      'Pemanen: ${item.pemanen}\n'
                                      'Mandor: ${item.mandor}\n'
                                      'Losses: ${item.persentaseLosses.toStringAsFixed(2)}%\n'
                                      'Total Denda: Rp ${item.totalDenda}',
                                    ),
                                  ),
                                );
                              },
                              child: Icon(Icons.location_on, color: pinColor, size: 32),
                            ),
                          );
                        }),
                        if (_currentPos != null)
                          Positioned(
                            left: 170,
                            top: 250,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red.shade700 : const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _toggleTracking,
                  icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_isTracking ? 'STOP TREK' : 'TREK ON'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A825),
                  foregroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onPressed: () => _locateMe(autoZoom: true),
                icon: Icon(_isZoomedIn ? Icons.zoom_out_map : Icons.my_location),
                label: Text(_isZoomedIn ? 'Zoom Out' : 'Lokasi Saya'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  final List<Offset> points;
  _TrackPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) => true;
}
