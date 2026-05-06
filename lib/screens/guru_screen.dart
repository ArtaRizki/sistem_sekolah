import 'package:flutter/material.dart';

class GuruScreen extends StatelessWidget {
  const GuruScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data
    final List<Map<String, String>> guruList = [
      {'nama': 'Budi Santoso, S.Pd', 'nip': '198001012005011001', 'mapel': 'Matematika'},
      {'nama': 'Siti Aminah, S.Ag', 'nip': '198205122008012003', 'mapel': 'Pend. Agama Islam'},
      {'nama': 'Ahmad Fauzi, M.Pd', 'nip': '197508172000031002', 'mapel': 'Bahasa Indonesia'},
      {'nama': 'Rina Wati, S.Pd', 'nip': '198811222010012005', 'mapel': 'Ilmu Pengetahuan Alam'},
      {'nama': 'Joko Widodo, S.Kom', 'nip': '199003042015041001', 'mapel': 'TIK'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Data Guru')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: guruList.length,
        itemBuilder: (context, index) {
          final guru = guruList[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(guru['nama']![0], style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ),
              title: Text(guru['nama']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('NIP: ${guru['nip']}\nMapel: ${guru['mapel']}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  // Detail action
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detail ${guru['nama']}')));
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add action
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
