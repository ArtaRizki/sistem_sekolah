import 'package:flutter/material.dart';
import '../api_service.dart';

class SekolahScreen extends StatefulWidget {
  final VoidCallback? onSekolahChanged;
  const SekolahScreen({super.key, this.onSekolahChanged});

  @override
  State<SekolahScreen> createState() => _SekolahScreenState();
}

class _SekolahScreenState extends State<SekolahScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _sekolahList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSekolah();
  }

  Future<void> _loadSekolah() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getSekolah();
      setState(() { _sekolahList = data; _isLoading = false; });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _notifyParent() {
    widget.onSekolahChanged?.call();
  }

  void _showDialog({Map<String, dynamic>? sekolah}) {
    final namaC = TextEditingController(text: sekolah?['nama'] ?? '');
    final alamatC = TextEditingController(text: sekolah?['alamat'] ?? '');
    final isEdit = sekolah != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Sekolah' : 'Tambah Sekolah'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaC, decoration: const InputDecoration(labelText: 'Nama Sekolah', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: alamatC, decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (namaC.text.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              if (isEdit) {
                await _apiService.updateSekolah(sekolah['nama'], namaC.text, alamatC.text);
              } else {
                await _apiService.addSekolah(namaC.text, alamatC.text);
              }
              _loadSekolah();
              _notifyParent();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Sekolah diperbarui' : 'Sekolah ditambahkan')));
              }
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Sekolah'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await _apiService.deleteSekolah(nama);
              _loadSekolah();
              _notifyParent();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sekolah dihapus')));
              }
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
        title: const Text('Data Sekolah', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 24)),
        elevation: 0, backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSekolah,
              child: _sekolahList.isEmpty
                  ? Center(child: Text('Belum ada data sekolah', style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _sekolahList.length,
                      itemBuilder: (context, index) {
                        final sekolah = _sekolahList[index];
                        final iconColors = [const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFF59E0B)];
                        final c = iconColors[index % iconColors.length];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[200]!, width: 1)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.school_rounded, color: c),
                            ),
                            title: Text(sekolah['nama'] ?? '-', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                            subtitle: Row(children: [
                              Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(child: Text(sekolah['alamat'] ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                            ]),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showDialog(sekolah: Map<String, dynamic>.from(sekolah));
                                }
                                if (value == 'delete') {
                                  _confirmDelete(sekolah['nama']);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Sekolah'),
      ),
    );
  }
}
