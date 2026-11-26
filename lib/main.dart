import 'package:flutter/material.dart';
import 'page_input.dart';
import 'page_rekap_peta.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IpdPlasmaApp());
}

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
          seedColor: const Color(0xFF1B5E20),
          primary: const Color(0xFF1B5E20),
          secondary: const Color(0xFFFBC02D),
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
      const MasterDanSyncPage(),
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
            label: 'Rekap & Sync',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF1B5E20)),
            label: 'Peta & Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF1B5E20)),
            label: 'Master & Sheet',
          ),
        ],
      ),
    );
  }
}

