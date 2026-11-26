import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class KencanaLogoWidget extends StatelessWidget {
  final double size;
  const KencanaLogoWidget({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F9),
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: const Color(0xFFB38E0C), width: size * 0.03),
      ),
      child: CustomPaint(
        painter: _KencanaLogoPainter(),
      ),
    );
  }
}

class _KencanaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.62;
    final radius = w * 0.46;

    final greenPaint = Paint()
      ..color = const Color(0xFF0A6836)
      ..style = PaintingStyle.fill;

    final bgPaint = Paint()
      ..color = const Color(0xFFF2F5F9)
      ..style = PaintingStyle.fill;

    final yellowPaint = Paint()
      ..color = const Color(0xFFF7E300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.038
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    canvas.drawArc(rect, math.pi * 1.05, math.pi * 0.90, true, greenPaint);

    // Celah daun kipas
    final gapPaint = Paint()
      ..color = const Color(0xFFF2F5F9)
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;

    for (final deg in [-62.0, -24.0, 24.0, 62.0]) {
      final rad = (deg - 90) * math.pi / 180;
      canvas.drawLine(
        Offset(cx + math.cos(rad) * radius * 0.45, cy + math.sin(rad) * radius * 0.45),
        Offset(cx + math.cos(rad) * radius * 1.05, cy + math.sin(rad) * radius * 1.05),
        gapPaint,
      );
    }

    // Lengkungan bawah kipas
    canvas.drawCircle(Offset(cx - w * 0.22, cy + h * 0.08), w * 0.16, bgPaint);
    canvas.drawCircle(Offset(cx + w * 0.22, cy + h * 0.08), w * 0.16, bgPaint);

    // 5 Tulang daun kuning menyebar dari pangkal
    for (final deg in [-68.0, -36.0, 0.0, 36.0, 68.0]) {
      final rad = (deg - 90) * math.pi / 180;
      final path = Path();
      path.moveTo(cx, cy + h * 0.02);
      path.quadraticBezierTo(
        cx + math.cos(rad) * radius * 0.42,
        cy + math.sin(rad) * radius * 0.55,
        cx + math.cos(rad) * radius * 0.82,
        cy + math.sin(rad) * radius * 0.82,
      );
      canvas.drawPath(path, yellowPaint);
    }

    // Pita Emas KENCANA di bawah
    final ribbonRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.66, w * 0.88, h * 0.26),
      Radius.circular(w * 0.03),
    );
    final goldPaint = Paint()..color = const Color(0xFFB38E0C);
    canvas.drawRRect(ribbonRect, goldPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'KENCANA',
        style: TextStyle(
          color: Colors.white,
          fontSize: w * 0.155,
          fontWeight: FontWeight.w500,
          letterSpacing: w * 0.02,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((w - textPainter.width) / 2, h * 0.66 + (h * 0.26 - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SplashScreenKencana extends StatefulWidget {
  final Widget nextPage;
  const SplashScreenKencana({super.key, required this.nextPage});

  @override
  State createState() => _SplashScreenKencanaState();
}

class _SplashScreenKencanaState extends State<SplashScreenKencana> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _putarSuaraDanPindah();
  }

  Future _putarSuaraDanPindah() async {
    try {
      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.05);
      await _tts.speak('KENCANA AGRI, KITA BISA!');
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 3400));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.nextPage),
      );
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const KencanaLogoWidget(size: 165),
              const SizedBox(height: 22),
              const Text(
                'SISTEM INSPEKSI PANEN (IPD PLASMA)',
                style: TextStyle(
                  color: Color(0xFF0A6836),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A6836),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFB38E0C), width: 1.5),
                ),
                child: const Text(
                  '"KENCANA AGRI, KITA BISA!"',
                  style: TextStyle(
                    color: Color(0xFFF7E300),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              const CircularProgressIndicator(color: Color(0xFF0A6836)),
              const SizedBox(height: 16),
              const Text(
                'Powered By Tim Plasma Area 4',
                style: TextStyle(
                  color: Color(0xFF0A6836),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
