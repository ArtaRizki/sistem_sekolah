import 'package:flutter/material.dart';
import '../api_service.dart';

class GuruScreen extends StatefulWidget {
  final String? sekolah;
  const GuruScreen({super.key, this.sekolah});

  @override
  State<GuruScreen> createState() => _GuruScreenState();
}

class _GuruScreenState extends State<GuruScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> guruList = [];
  List<dynamic> _sekolahList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant GuruScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sekolah != widget.sekolah) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getGuru(sekolah: widget.sekolah);
      final sekolah = await _apiService.getSekolah();
      setState(() {
        guruList = data;
        _sekolahList = sekolah;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading guru: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showGuruDialog({Map<String, dynamic>? guru}) {
    final namaC = TextEditingController(text: guru?['nama'] ?? '');
    final nipC = TextEditingController(text: guru?['nip'] ?? '');
    final mapelC = TextEditingController(text: guru?['mapel'] ?? '');
    String sekolah =
        guru?['sekolah'] ??
        widget.sekolah ??
        (_sekolahList.isNotEmpty ? _sekolahList.first['nama'] : '');
    final isEdit = guru != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Guru' : 'Tambah Guru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Guru',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nipC,
                  decoration: const InputDecoration(
                    labelText: 'NIP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mapelC,
                  decoration: const InputDecoration(
                    labelText: 'Mata Pelajaran',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: sekolah.isNotEmpty ? sekolah : null,
                  decoration: const InputDecoration(
                    labelText: 'Sekolah',
                    border: OutlineInputBorder(),
                  ),
                  items: _sekolahList
                      .map<DropdownMenuItem<String>>(
                        (s) => DropdownMenuItem(
                          value: s['nama'],
                          child: Text(
                            s['nama'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => sekolah = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (namaC.text.isEmpty || sekolah.isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                if (isEdit) {
                  await _apiService.updateGuru(
                    guru['rowKey'],
                    namaC.text,
                    nipC.text,
                    mapelC.text,
                    sekolah,
                  );
                } else {
                  await _apiService.addGuru(
                    namaC.text,
                    nipC.text,
                    mapelC.text,
                    sekolah,
                  );
                }
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit ? 'Guru diperbarui' : 'Guru ditambahkan',
                      ),
                    ),
                  );
                }
              },
              child: Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String rowKey, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Guru'),
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
              await _apiService.deleteGuru(rowKey);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Guru dihapus')));
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
    final filteredGuru = guruList
        .where(
          (guru) =>
              guru['nama'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              guru['mapel'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Guru',
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SearchBar(
                    leading: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    hintText: 'Cari guru atau mapel...',
                    backgroundColor: WidgetStatePropertyAll(Colors.grey[100]),
                    elevation: const WidgetStatePropertyAll(0),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: filteredGuru.isEmpty
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
                                  'Guru tidak ditemukan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1F2937),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: filteredGuru.length,
                            itemBuilder: (context, index) => _buildGuruCard(
                              context,
                              filteredGuru[index],
                              index,
                            ),
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGuruDialog(),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Guru',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGuruCard(BuildContext context, dynamic guru, int index) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      (guru['nama'] ?? '?')[0],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guru['nama'] ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guru['mapel'] ?? '-',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showGuruDialog(guru: Map<String, dynamic>.from(guru));
                    }
                    if (value == 'delete') {
                      _confirmDelete(guru['rowKey'], guru['nama']);
                    }
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
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.school_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    guru['sekolah'] ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.badge_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'NIP: ${guru['nip'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
