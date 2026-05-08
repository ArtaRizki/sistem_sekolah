import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../api_service.dart';

class NilaiScreen extends StatefulWidget {
  final String? sekolah;
  const NilaiScreen({super.key, this.sekolah});

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _selectedMapel = 'PJOK';
  List<String> _mapelList = ['PJOK', 'TIK'];
  List<dynamic> _nilaiData = [];
  List<dynamic> _sekolahList = [];

  @override
  void initState() {
    super.initState();
    _loadMapelAndNilai();
  }

  @override
  void didUpdateWidget(covariant NilaiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sekolah != widget.sekolah) {
      _loadMapelAndNilai();
    }
  }

  Future<void> _loadMapelAndNilai() async {
    setState(() => _isLoading = true);
    try {
      final mapelData = await _apiService.getMapel();
      final sekolahData = await _apiService.getSekolah();
      if (mapelData.isNotEmpty) {
        _mapelList = mapelData.map<String>((e) => e['nama'].toString()).toList();
        if (!_mapelList.contains(_selectedMapel) && _mapelList.isNotEmpty) {
          _selectedMapel = _mapelList.first;
        }
      }
      final data = await _apiService.getNilai(_selectedMapel, sekolah: widget.sekolah);
      setState(() {
        _nilaiData = data;
        _sekolahList = sekolahData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading nilai: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showNilaiDialog({Map<String, dynamic>? nilai}) {
    final namaC = TextEditingController(text: nilai?['nama'] ?? '');
    final nisC = TextEditingController(text: nilai?['nis'] ?? '');
    final nilaiC = TextEditingController(text: nilai?['nilai']?.toString() ?? '');
    String mapel = nilai?['mapel'] ?? _selectedMapel;
    String sekolah = nilai?['sekolah'] ?? widget.sekolah ?? (_sekolahList.isNotEmpty ? _sekolahList.first['nama'] : '');
    final isEdit = nilai != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Nilai' : 'Tambah Nilai'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: namaC, decoration: const InputDecoration(labelText: 'Nama Siswa', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                TextField(controller: nisC, decoration: const InputDecoration(labelText: 'NIS', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: mapel,
                  decoration: const InputDecoration(labelText: 'Mata Pelajaran', border: OutlineInputBorder()),
                  items: _mapelList.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setDialogState(() => mapel = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: nilaiC, decoration: const InputDecoration(labelText: 'Nilai', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: sekolah.isNotEmpty ? sekolah : null,
                  decoration: const InputDecoration(labelText: 'Sekolah', border: OutlineInputBorder()),
                  items: _sekolahList.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(value: s['nama'], child: Text(s['nama'], overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setDialogState(() => sekolah = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                if (namaC.text.isEmpty || nisC.text.isEmpty || nilaiC.text.isEmpty || sekolah.isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                final n = num.tryParse(nilaiC.text) ?? 0;
                if (isEdit) {
                  await _apiService.updateNilai(nilai['rowKey'], namaC.text, nisC.text, mapel, n, sekolah);
                } else {
                  await _apiService.addNilai(namaC.text, nisC.text, mapel, n, sekolah);
                }
                _loadMapelAndNilai();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Nilai diperbarui' : 'Nilai ditambahkan')));
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
        title: const Text('Hapus Nilai'),
        content: Text('Yakin ingin menghapus nilai "$nama"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await _apiService.deleteNilai(rowKey);
              _loadMapelAndNilai();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nilai dihapus')));
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Rekap Nilai Harian - $_selectedMapel', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (widget.sekolah != null) pw.Text('Sekolah: ${widget.sekolah}', style: const pw.TextStyle(fontSize: 14)),
          pw.Text('Tanggal: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 24),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: ['No', 'Nama Siswa', 'NIS', 'Mapel', 'Nilai', 'Sekolah'],
            data: List<List<String>>.generate(_nilaiData.length, (i) {
              final d = _nilaiData[i];
              return ['${i + 1}', d['nama'] ?? '-', d['nis'] ?? '-', d['mapel'] ?? '-', '${d['nilai'] ?? 0}', d['sekolah'] ?? '-'];
            }),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.center,
            cellAlignments: {1: pw.Alignment.centerLeft, 5: pw.Alignment.centerLeft},
          ),
        ],
      ),
    ));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Nilai_$_selectedMapel.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai Harian Siswa', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 24)),
        elevation: 0, backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf_rounded), tooltip: 'Export PDF', onPressed: _generatePdf),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!, width: 1)),
              child: DropdownButton<String>(
                isExpanded: true, value: _selectedMapel,
                underline: const SizedBox(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                items: _mapelList.map((m) => DropdownMenuItem(value: m, child: Row(children: [
                  const Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFF6366F1)),
                  const SizedBox(width: 12),
                  Text(m, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ]))).toList(),
                onChanged: (v) { if (v != null) { setState(() => _selectedMapel = v); _loadMapelAndNilai(); } },
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMapelAndNilai,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _nilaiData.isEmpty
                      ? Center(child: Text('Belum ada data nilai', style: TextStyle(color: Colors.grey[600])))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _nilaiData.length,
                          itemBuilder: (context, index) {
                            final data = _nilaiData[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[200]!, width: 1)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Center(child: Text('${data['nilai'] ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)))),
                                ),
                                title: Text(data['nama'] ?? '-', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('NIS: ${data['nis']} • ${data['mapel']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    Text(data['sekolah'] ?? '-', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showNilaiDialog(nilai: Map<String, dynamic>.from(data));
                                    }
                                    if (value == 'delete') {
                                      _confirmDelete(data['rowKey'], data['nama']);
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNilaiDialog(),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Nilai'),
      ),
    );
  }
}
