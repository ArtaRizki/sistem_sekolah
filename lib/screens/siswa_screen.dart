import 'package:flutter/material.dart';

class SiswaScreen extends StatefulWidget {
  const SiswaScreen({super.key});

  @override
  State<SiswaScreen> createState() => _SiswaScreenState();
}

class _SiswaScreenState extends State<SiswaScreen> {
  String _selectedKelas = 'Kelas 1A';
  final List<String> _kelasList = ['Kelas 1A', 'Kelas 1B', 'Kelas 2A', 'Kelas 3A', 'Kelas 4A', 'Kelas 5A', 'Kelas 6A'];

  // Dummy Data
  final Map<String, List<Map<String, String>>> siswaData = {
    'Kelas 1A': [
      {'nama': 'Andi Susanto', 'nis': '2023001', 'jk': 'L'},
      {'nama': 'Budi Setiawan', 'nis': '2023002', 'jk': 'L'},
      {'nama': 'Citra Kirana', 'nis': '2023003', 'jk': 'P'},
    ],
    'Kelas 1B': [
      {'nama': 'Deni Ramadhan', 'nis': '2023004', 'jk': 'L'},
      {'nama': 'Eka Putri', 'nis': '2023005', 'jk': 'P'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> currentSiswa = siswaData[_selectedKelas] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Data Siswa & Kelas')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Text('Pilih Kelas: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedKelas,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _kelasList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedKelas = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: currentSiswa.isEmpty
                ? const Center(child: Text('Tidak ada data siswa untuk kelas ini.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: currentSiswa.length,
                    itemBuilder: (context, index) {
                      final siswa = currentSiswa[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: siswa['jk'] == 'L' ? Colors.blue[100] : Colors.pink[100],
                            child: Icon(
                              siswa['jk'] == 'L' ? Icons.boy : Icons.girl,
                              color: siswa['jk'] == 'L' ? Colors.blue : Colors.pink,
                            ),
                          ),
                          title: Text(siswa['nama']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('NIS: ${siswa['nis']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {},
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
