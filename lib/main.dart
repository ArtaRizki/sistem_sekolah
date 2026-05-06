import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/guru_screen.dart';
import 'screens/siswa_screen.dart';
import 'screens/nilai_screen.dart';
import 'screens/rekap_screen.dart';
import 'screens/absensi_wajah_screen.dart';

void main() {
  runApp(const SistemSekolahApp());
}

class SistemSekolahApp extends StatelessWidget {
  const SistemSekolahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistem Sekolah',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const GuruScreen(),
    const SiswaScreen(),
    const NilaiScreen(),
    const RekapScreen(),
    const AbsensiWajahScreen(),
  ];

  final List<NavigationRailDestination> _navDestinations = const [
    NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
    NavigationRailDestination(icon: Icon(Icons.people), label: Text('Guru')),
    NavigationRailDestination(icon: Icon(Icons.school), label: Text('Siswa & Kelas')),
    NavigationRailDestination(icon: Icon(Icons.menu_book), label: Text('Mapel & Nilai')),
    NavigationRailDestination(icon: Icon(Icons.picture_as_pdf), label: Text('Rekap Bulanan')),
    NavigationRailDestination(icon: Icon(Icons.face), label: Text('Absensi Wajah')),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(
        title: const Text('Sistem Sekolah'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      drawer: isDesktop ? null : Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: const Text('Sistem Sekolah', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            for (int i = 0; i < _navDestinations.length; i++)
              ListTile(
                leading: _navDestinations[i].icon,
                title: _navDestinations[i].label,
                selected: _selectedIndex == i,
                onTap: () {
                  setState(() => _selectedIndex = i);
                  Navigator.pop(context); // Close drawer
                },
              ),
          ],
        ),
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: _navDestinations,
              extended: MediaQuery.of(context).size.width >= 1000,
              leading: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.account_balance, size: 40, color: Colors.blueAccent),
              ),
            ),
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
