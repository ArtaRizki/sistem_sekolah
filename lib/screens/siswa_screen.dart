import 'package:flutter/material.dart';
import '../api_service.dart';

class SiswaScreen extends StatefulWidget {
  final String? sekolah;
  const SiswaScreen({super.key, this.sekolah});

  @override
  State<SiswaScreen> createState() => _SiswaScreenState();
}

class _SiswaScreenState extends State<SiswaScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _selectedKelas;
  List<String> _kelasList = [];
  List<dynamic> _siswaList = [];
  List<dynamic> _sekolahList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant SiswaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sekolah != widget.sekolah) {
      _selectedKelas = null;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final kelasList = await _apiService.getKelas(sekolah: widget.sekolah);
      final siswaList = await _apiService.getSiswa(kelas: _selectedKelas, sekolah: widget.sekolah);
      final sekolahList = await _apiService.getSekolah();
      setState(() {
        _kelasList = kelasList.map<String>((e) => e.toString()).toList();
        _siswaList = siswaList;
        _sekolahList = sekolahList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showSiswaDialog({Map<String, dynamic>? siswa}) {
    final namaC = TextEditingController(text: siswa?['nama']?.toString() ?? '');
    final nisC = TextEditingController(text: siswa?['nis']?.toString() ?? '');
    String selectedKelas = siswa?['kelas']?.toString() ?? '';
    String jk = siswa?['jk']?.toString() ?? 'L';
    String sekolah = siswa?['sekolah']?.toString() ?? widget.sekolah ?? (_sekolahList.isNotEmpty ? _sekolahList.first['nama'] : '');
    final isEdit = siswa != null;

    List<String> getClassesForSekolah(String sekolahNama) {
      final s = _sekolahList.where((element) => element['nama'] == sekolahNama).firstOrNull;
      if (s == null) return [];
      String tingkat = (s['tingkat']?.toString() ?? '').toUpperCase();
      if (tingkat.isEmpty) {
        final nameLower = sekolahNama.toLowerCase();
        if (nameLower.contains('sma') || nameLower.contains('ma ') || nameLower.startsWith('ma')) {
          tingkat = 'SMA';
        } else if (nameLower.contains('smp') || nameLower.contains('mts')) {
          tingkat = 'SMP';
        }
      }

      if (tingkat == 'SMP' || tingkat == 'MTS') return ['7', '8', '9'];
      if (tingkat == 'SMA' || tingkat == 'MA') return ['10', '11', '12'];
      if (tingkat == 'SD') return ['1', '2', '3', '4', '5', '6'];
      return ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final classes = getClassesForSekolah(sekolah);
          if (selectedKelas.isNotEmpty && !classes.contains(selectedKelas)) {
             // Keep it if it was manually entered before, but show it in the list if missing
             classes.add(selectedKelas);
          }

          return AlertDialog(
            title: Text(isEdit ? 'Edit Siswa' : 'Tambah Siswa'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: namaC, decoration: const InputDecoration(labelText: 'Nama Siswa', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
                  const SizedBox(height: 12),
                  TextField(controller: nisC, decoration: const InputDecoration(labelText: 'NIS', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: jk,
                    decoration: const InputDecoration(labelText: 'Jenis Kelamin', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                      DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                    ],
                    onChanged: (v) => setDialogState(() => jk = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: sekolah.isNotEmpty ? sekolah : null,
                    decoration: const InputDecoration(labelText: 'Sekolah', border: OutlineInputBorder()),
                    items: _sekolahList.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(value: s['nama'], child: Text(s['nama'], overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setDialogState(() {
                      sekolah = v!;
                      selectedKelas = ''; 
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('kelas_$sekolah'),
                    isExpanded: true,
                    initialValue: selectedKelas.isNotEmpty ? selectedKelas : null,
                    decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
                    items: classes.map((c) {
                      String display = c;
                      if (c == '7') { display = 'Kelas 7 (VII)'; }
                      else if (c == '8') { display = 'Kelas 8 (VIII)'; }
                      else if (c == '9') { display = 'Kelas 9 (IX)'; }
                      else if (c == '10') { display = 'Kelas 10 (X)'; }
                      else if (c == '11') { display = 'Kelas 11 (XI)'; }
                      else if (c == '12') { display = 'Kelas 12 (XII)'; }
                      else { display = 'Kelas $c'; }
                      return DropdownMenuItem(value: c, child: Text(display, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedKelas = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              FilledButton(
                onPressed: () async {
                  if (namaC.text.isEmpty || nisC.text.isEmpty || selectedKelas.isEmpty || sekolah.isEmpty) {
                    return;
                  }
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  if (isEdit) {
                    await _apiService.updateSiswa(siswa['rowKey'], namaC.text, nisC.text, jk, selectedKelas, sekolah);
                  } else {
                    await _apiService.addSiswa(namaC.text, nisC.text, jk, selectedKelas, sekolah);
                  }
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Siswa diperbarui' : 'Siswa ditambahkan')));
                  }
                },
                child: Text(isEdit ? 'Simpan' : 'Tambah'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(String rowKey, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await _apiService.deleteSiswa(rowKey);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siswa dihapus')));
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
        title: const Text('Data Siswa', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937), fontSize: 22)),
        elevation: 0, backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_kelasList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Filter Kelas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!, width: 1)),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedKelas,
                            hint: const Text('Semua Kelas'),
                            underline: const SizedBox(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('Semua Kelas')),
                              ..._kelasList.map((k) {
                                String display = k;
                                if (k == '7') { display = 'Kelas 7 (VII)'; }
                                else if (k == '8') { display = 'Kelas 8 (VIII)'; }
                                else if (k == '9') { display = 'Kelas 9 (IX)'; }
                                else if (k == '10') { display = 'Kelas 10 (X)'; }
                                else if (k == '11') { display = 'Kelas 11 (XI)'; }
                                else if (k == '12') { display = 'Kelas 12 (XII)'; }
                                else { display = 'Kelas $k'; }
                                return DropdownMenuItem(value: k, child: Row(children: [
                                  const Icon(Icons.class_rounded, size: 18, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 12),
                                  Text(display, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ]));
                              }),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedKelas = v);
                              _loadData();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: _siswaList.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.person_off_rounded, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Tidak ada siswa', style: TextStyle(fontSize: 14, color: Color(0xFF1F2937), fontWeight: FontWeight.w300)),
                          ]))
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: _siswaList.length,
                            itemBuilder: (context, index) => _buildSiswaCard(context, _siswaList[index]),
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSiswaDialog(),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Siswa',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSiswaCard(BuildContext context, dynamic siswa) {
    final isLaki = siswa['jk'] == 'L';
    final color = isLaki ? const Color(0xFF3B82F6) : const Color(0xFFEC4899);
    final icon = isLaki ? Icons.boy_rounded : Icons.girl_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[200]!, width: 1)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(siswa['nama'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.badge_rounded, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text('NIS: ${siswa['nis']} • ${siswa['kelas']}', style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937), fontWeight: FontWeight.w300)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.business_rounded, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(child: Text(siswa['sekolah'] ?? '-', style: const TextStyle(fontSize: 11, color: Color(0xFF1F2937), fontWeight: FontWeight.w300))),
            ]),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showSiswaDialog(siswa: Map<String, dynamic>.from(siswa));
            }
            if (value == 'delete') {
              _confirmDelete(siswa['rowKey'], siswa['nama']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ),
    );
  }
}
