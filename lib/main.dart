import 'package:flutter/material.dart';
import 'api_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/guru_screen.dart';
import 'screens/siswa_screen.dart';
import 'screens/mapel_screen.dart';
import 'screens/sekolah_screen.dart';
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
      title: 'DRP Absensi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
          surface: const Color(0xFFFAFAFA),
        ),
        useMaterial3: true,
        fontFamily: 'Nunito',
        textTheme: const TextTheme(
          // Display
          displayLarge: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          ),
          // Headline
          headlineLarge: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          ),
          // Title
          titleLarge: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
          // Body
          bodyLarge: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w300,
          ),
          // Label
          labelLarge: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w300,
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1F2937),
          titleTextStyle: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Color(0xFF1F2937),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF1F2937),
          ),
          contentTextStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: Color(0xFF1F2937),
          ),
          barrierColor: Colors.black54,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          labelStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
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
  String? _selectedSekolah; // Global sekolah filter
  List<dynamic> _sekolahList = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSekolahList();
  }

  Future<void> _loadSekolahList() async {
    try {
      final data = await _apiService.getSekolah();
      debugPrint('📋 Loaded ${data.length} sekolah: $data');
      if (mounted) {
        setState(() {
          _sekolahList = data;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading sekolah list: $e');
    }
  }

  List<Widget> _buildPages() => [
    DashboardScreen(sekolah: _selectedSekolah),
    MapelScreen(sekolah: _selectedSekolah),
    GuruScreen(sekolah: _selectedSekolah),
    SekolahScreen(onSekolahChanged: _loadSekolahList),
    SiswaScreen(sekolah: _selectedSekolah),
    NilaiScreen(sekolah: _selectedSekolah),
    RekapScreen(sekolah: _selectedSekolah),
    const AbsensiWajahScreen(),
  ];

  final List<NavigationRailDestination> _navDestinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.home_rounded),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.menu_book_rounded),
      label: Text('Mapel'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_rounded),
      label: Text('Guru'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.school_rounded),
      label: Text('Sekolah'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_rounded),
      label: Text('Siswa'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.assessment_rounded),
      label: Text('Nilai'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.bar_chart_rounded),
      label: Text('Rekap'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.face_rounded),
      label: Text('Absensi'),
    ),
  ];

  void _showSekolahPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        List<dynamic> sheetList = List.from(_sekolahList);
        bool isLoadingSheet = sheetList.isEmpty;

        // If list is empty, fetch fresh data inside the sheet
        return StatefulBuilder(
          builder: (ctx2, setSheetState) {
            if (isLoadingSheet) {
              _apiService.getSekolah().then((data) {
                setSheetState(() {
                  sheetList = data;
                  isLoadingSheet = false;
                });
                // Also update parent state
                setState(() => _sekolahList = data);
              });
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Pilih Sekolah',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.all_inclusive_rounded,
                      color: Color(0xFF6366F1),
                    ),
                    title: const Text(
                      'Semua Sekolah',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: _selectedSekolah == null
                        ? const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF6366F1),
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedSekolah = null);
                      Navigator.pop(ctx);
                    },
                  ),
                  if (isLoadingSheet)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ...sheetList.map(
                    (s) => ListTile(
                      leading: const Icon(
                        Icons.school_rounded,
                        color: Color(0xFF8B5CF6),
                      ),
                      title: Text(s['nama'] ?? '-'),
                      subtitle: Text(
                        s['alamat'] ?? '-',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      trailing: _selectedSekolah == s['nama']
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF6366F1),
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedSekolah = s['nama']);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSekolahSelector() {
    return GestureDetector(
      onTap: _showSekolahPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_rounded,
              size: 16,
              color: Color(0xFF6366F1),
            ),
            const SizedBox(width: 6),
            Text(
              _selectedSekolah ?? 'Semua Sekolah',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6366F1),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final pages = _buildPages();

    return Scaffold(
      appBar: isDesktop
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(
                MediaQuery.of(context).size.width < 400 ? 88 : 56,
              ),
              child: AppBar(
                title: const Text(
                  'DRP Absensi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF1F2937),
                  ),
                ),
                toolbarHeight: MediaQuery.of(context).size.width < 400
                    ? 44
                    : 56,
                elevation: 0,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                actions: MediaQuery.of(context).size.width >= 400
                    ? [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildSekolahSelector(),
                        ),
                      ]
                    : null,
                bottom: MediaQuery.of(context).size.width < 400
                    ? PreferredSize(
                        preferredSize: const Size.fromHeight(40),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 12,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildSekolahSelector(),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'DRP Absensi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedSekolah ?? 'Semua Sekolah',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (int i = 0; i < _navDestinations.length; i++)
                    ListTile(
                      leading: _navDestinations[i].icon,
                      title: _navDestinations[i].label,
                      selected: _selectedIndex == i,
                      selectedTileColor: const Color(
                        0xFF6366F1,
                      ).withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        setState(() => _selectedIndex = i);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366F1),
                                const Color(0xFF8B5CF6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'DRP Absensi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Sekolah selector in sidebar
                        _buildSekolahSelector(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _navDestinations.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedIndex = index),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: const Color(0xFF6366F1),
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getIconData(index),
                                      size: 20,
                                      color: isSelected
                                          ? const Color(0xFF6366F1)
                                          : const Color(0xFF1F2937),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _getLabel(index),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? const Color(0xFF6366F1)
                                              : const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }

  IconData _getIconData(int index) {
    const icons = [
      Icons.home_rounded,
      Icons.menu_book_rounded,
      Icons.person_rounded,
      Icons.school_rounded,
      Icons.people_rounded,
      Icons.assessment_rounded,
      Icons.bar_chart_rounded,
      Icons.face_rounded,
    ];
    return icons[index];
  }

  String _getLabel(int index) {
    const labels = [
      'Dashboard',
      'Mapel',
      'Guru',
      'Sekolah',
      'Siswa',
      'Nilai',
      'Rekap',
      'Absensi',
    ];
    return labels[index];
  }
}
