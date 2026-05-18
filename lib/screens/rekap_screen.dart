import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../api_service.dart';

class RekapScreen extends StatefulWidget {
  final String? sekolah;
  const RekapScreen({super.key, this.sekolah});

  @override
  State<RekapScreen> createState() => _RekapScreenState();
}

class _RekapScreenState extends State<RekapScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _selectedBulan = 'Mei 2026';
  final List<String> _bulanList = [
    'Januari 2026',
    'Februari 2026',
    'Maret 2026',
    'April 2026',
    'Mei 2026',
  ];

  String? _selectedKelas;
  List<String> _kelasList = [];

  List<dynamic> _rekapData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant RekapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sekolah != widget.sekolah) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final kelasFilter = (_selectedKelas != null && _selectedKelas != 'Semua Kelas') ? _selectedKelas : null;
      final results = await Future.wait([
        _apiService.getKelas(sekolah: widget.sekolah),
        _apiService.getRekap(_selectedBulan, sekolah: widget.sekolah, kelas: kelasFilter),
      ]);

      final kelasData = results[0];
      final rekapData = results[1];

      setState(() {
        _kelasList = ['Semua Kelas', ...kelasData.map((e) => e.toString())];
        if (_selectedKelas == null || !_kelasList.contains(_selectedKelas)) {
          _selectedKelas = 'Semua Kelas';
        }
        _rekapData = rekapData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading rekap data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final formattedDate = '${now.day} ${months[now.month]} ${now.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text(
            'Rekapitulasi Kehadiran Bulanan',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Sekolah: ${widget.sekolah ?? "Semua Sekolah"}',
            style: const pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Kelas: ${_selectedKelas ?? "Semua Kelas"}',
            style: const pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Bulan: $_selectedBulan',
            style: const pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 24),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Nama', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Hadir', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Izin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Sakit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Alpa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Kehadiran (%)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                ],
              ),
              // Data
              if (_rekapData.isEmpty)
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Data Kosong (Belum dimuat)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', textAlign: pw.TextAlign.center)),
                  ],
                )
              else
                ...List<pw.TableRow>.generate(_rekapData.length, (index) {
                  final data = _rekapData[index];
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${index + 1}', textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['nama']?.toString() ?? '-', textAlign: pw.TextAlign.left)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['hadir']?.toString() ?? '0', textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['izin']?.toString() ?? '0', textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['sakit']?.toString() ?? '0', textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['alpa']?.toString() ?? '0', textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${data['persen'] ?? 0}%', textAlign: pw.TextAlign.center)),
                    ],
                  );
                }),
            ],
          ),
          pw.SizedBox(height: 48),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Purwakarta, $formattedDate'),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Dheri Rama Permadhi, S.Pd',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rekap_Bulanan_$_selectedBulan.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rekap Kehadiran',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Bulan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
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
                              value: _selectedBulan,
                              underline: const SizedBox(),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              items: _bulanList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF6366F1)),
                                      const SizedBox(width: 8),
                                      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedBulan = newValue);
                                  _loadData();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Kelas',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
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
                              hint: const Text('Semua Kelas', style: TextStyle(fontSize: 12)),
                              underline: const SizedBox(),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              items: _kelasList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.class_rounded, size: 16, color: Color(0xFF6366F1)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedKelas = newValue);
                                  _loadData();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _rekapData.isEmpty 
                  ? Center(
                      child: Text(
                        'Data tidak tersedia',
                        style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w300),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _rekapData.length,
                      itemBuilder: (context, index) {
                        final data = _rekapData[index];
                        return _buildRekapCard(context, data);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generatePdf,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
        label: const Text(
          'Export PDF',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRekapCard(BuildContext context, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.class_rounded,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nama'] ?? '-',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                      ),
                      if (data['sekolah'] != null && data['sekolah'].toString().isNotEmpty)
                        Text(data['sekolah'], style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937), fontWeight: FontWeight.w300)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${data['persen'] ?? 0}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
              children: [
                _buildStatBubble('Hadir', '${data['hadir'] ?? 0}', Colors.green),
                _buildStatBubble('Izin', '${data['izin'] ?? 0}', Colors.blue),
                _buildStatBubble('Sakit', '${data['sakit'] ?? 0}', Colors.orange),
                _buildStatBubble('Alpa', '${data['alpa'] ?? 0}', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBubble(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 11,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
