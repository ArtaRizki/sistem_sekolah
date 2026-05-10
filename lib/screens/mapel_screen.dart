import 'package:flutter/material.dart';
import '../api_service.dart';

class MapelScreen extends StatefulWidget {
  final String? sekolah;
  const MapelScreen({super.key, this.sekolah});

  @override
  State<MapelScreen> createState() => _MapelScreenState();
}

class _MapelScreenState extends State<MapelScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _mapelList = [];
  List<dynamic> _sekolahList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant MapelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sekolah != widget.sekolah) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getMapel(sekolah: widget.sekolah),
        _apiService.getSekolah(),
      ]);
      setState(() {
        _mapelList = results[0];
        _sekolahList = results[1];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMapel() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getMapel(sekolah: widget.sekolah);
      setState(() {
        _mapelList = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showDialog({Map<String, dynamic>? mapel}) {
    final namaC = TextEditingController(text: mapel?['nama']?.toString() ?? '');
    final kodeC = TextEditingController(text: mapel?['kode']?.toString() ?? '');
    final isEdit = mapel != null;

    // School assignment state
    String currentSekolahString = mapel?['sekolah'] ?? 'Semua';
    List<String> selectedSchools = currentSekolahString == 'Semua'
        ? ['Semua']
        : currentSekolahString.split(', ');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: namaC,
                    decoration: const InputDecoration(
                      labelText: 'Nama Mapel',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: kodeC,
                    decoration: const InputDecoration(
                      labelText: 'Kode',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Assign ke Sekolah:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text(
                      'Semua Sekolah (Global)',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: selectedSchools.contains('Semua'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() {
                        if (val == true) {
                          selectedSchools = ['Semua'];
                        } else {
                          selectedSchools.remove('Semua');
                        }
                      });
                    },
                  ),
                  const Divider(),
                  ..._sekolahList.map((s) {
                    final nama = s['nama'] ?? '';
                    return CheckboxListTile(
                      title: Text(nama, style: const TextStyle(fontSize: 13)),
                      value: selectedSchools.contains(nama),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedSchools.remove('Semua');
                            if (!selectedSchools.contains(nama))
                              selectedSchools.add(nama);
                          } else {
                            selectedSchools.remove(nama);
                            if (selectedSchools.isEmpty)
                              selectedSchools.add('Semua');
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (namaC.text.isEmpty) return;
                final schoolsToSave = selectedSchools.join(', ');
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                if (isEdit) {
                  await _apiService.updateMapel(
                    mapel['nama'],
                    namaC.text,
                    kodeC.text,
                    schoolsToSave,
                  );
                } else {
                  await _apiService.addMapel(
                    namaC.text,
                    kodeC.text,
                    schoolsToSave,
                  );
                }
                _loadMapel();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit ? 'Mapel diperbarui' : 'Mapel ditambahkan',
                    ),
                  ),
                );
              },
              child: Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mapel'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await _apiService.deleteMapel(nama);
              _loadMapel();
              if (mounted)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Mapel dihapus')));
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mata Pelajaran',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            fontSize: 22,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMapel,
              child: _mapelList.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada data mapel',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _mapelList.length,
                      itemBuilder: (context, index) {
                        final mapel = _mapelList[index];
                        final assigned = mapel['sekolah'] ?? 'Semua';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            title: Text(
                              mapel['nama'] ?? '-',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kode: ${mapel['kode'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1F2937),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                Text(
                                  'Sekolah: $assigned',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1F2937),
                                    fontWeight: FontWeight.w300,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit')
                                  _showDialog(
                                    mapel: Map<String, dynamic>.from(mapel),
                                  );
                                if (value == 'delete')
                                  _confirmDelete(mapel['nama']);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_rounded,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Mapel',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}
