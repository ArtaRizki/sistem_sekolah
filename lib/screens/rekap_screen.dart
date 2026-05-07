import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RekapScreen extends StatefulWidget {
  const RekapScreen({super.key});

  @override
  State<RekapScreen> createState() => _RekapScreenState();
}

class _RekapScreenState extends State<RekapScreen> {
  String _selectedBulan = 'Mei 2026';
  final List<String> _bulanList = [
    'Januari 2026',
    'Februari 2026',
    'Maret 2026',
    'April 2026',
    'Mei 2026',
  ];

  final List<Map<String, dynamic>> _rekapData = [
    {'kelas': 'Kelas 1A', 'hadir': 95, 'izin': 3, 'sakit': 2, 'alpa': 0},
    {'kelas': 'Kelas 1B', 'hadir': 92, 'izin': 5, 'sakit': 2, 'alpa': 1},
    {'kelas': 'Kelas 2A', 'hadir': 98, 'izin': 1, 'sakit': 1, 'alpa': 0},
    {'kelas': 'Kelas 3A', 'hadir': 90, 'izin': 4, 'sakit': 4, 'alpa': 2},
    {'kelas': 'Kelas 4A', 'hadir': 96, 'izin': 2, 'sakit': 2, 'alpa': 0},
  ];

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Rekapitulasi Kehadiran Bulanan',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Bulan: $_selectedBulan',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 24),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: [
                  'No',
                  'Kelas',
                  'Hadir (%)',
                  'Izin (%)',
                  'Sakit (%)',
                  'Alpa (%)',
                ],
                data: List<List<String>>.generate(_rekapData.length, (index) {
                  final data = _rekapData[index];
                  return [
                    '${index + 1}',
                    data['kelas'].toString(),
                    '${data['hadir']}%',
                    '${data['izin']}%',
                    '${data['sakit']}%',
                    '${data['alpa']}%',
                  ];
                }),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue100,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey400, width: .5),
                  ),
                ),
                cellAlignment: pw.Alignment.center,
              ),
              pw.SizedBox(height: 48),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Palu, ${DateTime.now().toString().split(' ')[0]}'),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      'Kepala Sekolah',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
                  'Pilih Bulan',
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
                    value: _selectedBulan,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    items: _bulanList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
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
                        setState(() => _selectedBulan = newValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _rekapData.length,
              itemBuilder: (context, index) {
                final data = _rekapData[index];
                return _buildRekapCard(context, data);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generatePdf,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.picture_as_pdf_rounded),
        label: const Text('Export PDF'),
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
                Text(
                  data['kelas'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
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
                _buildStatBubble('Hadir', '${data['hadir']}%', Colors.green),
                _buildStatBubble('Izin', '${data['izin']}%', Colors.blue),
                _buildStatBubble('Sakit', '${data['sakit']}%', Colors.orange),
                _buildStatBubble('Alpa', '${data['alpa']}%', Colors.red),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
