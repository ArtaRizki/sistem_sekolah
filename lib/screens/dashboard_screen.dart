import 'package:flutter/material.dart';
import '../api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String? sekolah;
  const DashboardScreen({super.key, this.sekolah});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sekolah != widget.sekolah) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getDashboard(sekolah: widget.sekolah);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading dashboard: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Builder(builder: (context) {
                  final now = DateTime.now();
                  const hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
                  const bulanList = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
                  const greetings = {
                    'Senin': 'Semangat',
                    'Selasa': 'Produktif',
                    'Rabu': 'Semangat',
                    'Kamis': 'Luar Biasa',
                    'Jumat': 'Barokah',
                    'Sabtu': 'Semangat',
                    'Minggu': 'Santai',
                  };
                  final hari = hariList[now.weekday - 1];
                  final bulan = bulanList[now.month - 1];
                  final tgl = now.day.toString().padLeft(2, '0');
                  final greeting = '${greetings[hari]} $hari, $tgl $bulan';
                  return Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                // Welcome Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.sekolah ?? 'Semua Sekolah',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            if (widget.sekolah != null &&
                                _data['tingkat'] != null)
                              Text(
                                'Tingkat: ${_data['tingkat']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.school_rounded,
                        size: 60,
                        color: Colors.white30,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Guru Info
                Text(
                  'Informasi Guru',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  Icons.person_rounded,
                  _data['guru'] ?? '-',
                  'Nama Guru',
                  const Color(0xFF6366F1),
                ),
/*
                _buildInfoCard(
                  context,
                  Icons.email_rounded,
                  'dherirama@gmail.com',
                  'Email',
                  const Color(0xFF06B6D4),
                ),
*/

                const SizedBox(height: 24),

                // Statistics Section
                Text(
                  'Statistik',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 4
                      : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      context,
                      'Siswa',
                      _data['totalSiswa']?.toString() ?? '0',
                      const Color(0xFF3B82F6),
                      Icons.people_rounded,
                    ),
                    _buildStatCard(
                      context,
                      'Guru',
                      _data['totalGuru']?.toString() ?? '0',
                      const Color(0xFF8B5CF6),
                      Icons.person_rounded,
                    ),
                    _buildStatCard(
                      context,
                      'Sekolah',
                      _data['totalSekolah']?.toString() ?? '0',
                      const Color(0xFF06B6D4),
                      Icons.school_rounded,
                    ),
                    _buildStatCard(
                      context,
                      'Mapel',
                      _data['totalMapel']?.toString() ?? '0',
                      const Color(0xFF10B981),
                      Icons.menu_book_rounded,
                    ),
                  ],
                ),

                // Sekolah list
                if (_data['sekolah'] is List &&
                    (_data['sekolah'] as List).isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Daftar Sekolah',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...(_data['sekolah'] as List).map(
                    (s) => _buildInfoCard(
                      context,
                      Icons.school_rounded,
                      s['nama'] ?? '-',
                      s['alamat'] ?? '-',
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String value,
    String title,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
