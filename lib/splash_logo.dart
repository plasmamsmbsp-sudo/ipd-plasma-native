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
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: const Color(0xFFFBC02D), width: size * 0.06),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.eco, color: const Color(0xFFFBC02D), size: size * 0.65),
            Positioned(
              bottom: size * 0.1,
              child: Text(
                'KA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D3B12),
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const KencanaLogoWidget(size: 115),
              const SizedBox(height: 22),
              const Text(
                'PT. KENCANA AGRI Tbk',
                style: TextStyle(
                  color: Color(0xFFFBC02D),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'SISTEM INSPEKSI PANEN (IPD PLASMA)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBC02D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '"KENCANA AGRI, KITA BISA!"',
                  style: TextStyle(
                    color: Color(0xFF0D3B12),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              const CircularProgressIndicator(color: Color(0xFFFBC02D)),
              const SizedBox(height: 18),
              const Text(
                'Powered By Tim Plasma Area 4',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
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
