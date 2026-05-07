import 'package:flutter/material.dart';

class SiswaScreen extends StatefulWidget {
  const SiswaScreen({super.key});

  @override
  State<SiswaScreen> createState() => _SiswaScreenState();
}

class _SiswaScreenState extends State<SiswaScreen> {
  String _selectedKelas = 'Kelas 1A';
  final List<String> _kelasList = [
    'Kelas 1A',
    'Kelas 1B',
    'Kelas 2A',
    'Kelas 3A',
    'Kelas 4A',
    'Kelas 5A',
    'Kelas 6A',
  ];

  final Map<String, List<Map<String, String>>> siswaData = {
    'Kelas 1A': [
      {'nama': 'Andi Susanto', 'nis': '2023001', 'jk': 'L'},
      {'nama': 'Budi Setiawan', 'nis': '2023002', 'jk': 'L'},
      {'nama': 'Citra Kirana', 'nis': '2023003', 'jk': 'P'},
      {'nama': 'Dani Pratama', 'nis': '2023004', 'jk': 'L'},
    ],
    'Kelas 1B': [
      {'nama': 'Deni Ramadhan', 'nis': '2023005', 'jk': 'L'},
      {'nama': 'Eka Putri', 'nis': '2023006', 'jk': 'P'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> currentSiswa =
        siswaData[_selectedKelas] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Siswa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            fontSize: 24,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Kelas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedKelas,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    items: _kelasList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.class_rounded,
                              size: 18,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedKelas = newValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: currentSiswa.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_rounded,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada siswa di kelas ini',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    itemCount: currentSiswa.length,
                    itemBuilder: (context, index) {
                      final siswa = currentSiswa[index];
                      return _buildSiswaCard(context, siswa);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah Siswa'),
      ),
    );
  }

  Widget _buildSiswaCard(BuildContext context, Map<String, String> siswa) {
    final isLaki = siswa['jk'] == 'L';
    final color = isLaki ? const Color(0xFF3B82F6) : const Color(0xFFEC4899);
    final icon = isLaki ? Icons.boy_rounded : Icons.girl_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          siswa['nama']!,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.badge_rounded, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              'NIS: ${siswa['nis']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Hapus'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
