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
  final List<String> _bulanList = ['Januari 2026', 'Februari 2026', 'Maret 2026', 'April 2026', 'Mei 2026'];

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
              pw.Text('Rekapitulasi Kehadiran Bulanan', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Bulan: $_selectedBulan', style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 24),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['No', 'Kelas', 'Hadir (%)', 'Izin (%)', 'Sakit (%)', 'Alpa (%)'],
                data: List<List<String>>.generate(
                  _rekapData.length,
                  (index) {
                    final data = _rekapData[index];
                    return [
                      '${index + 1}',
                      data['kelas'].toString(),
                      '${data['hadir']}%',
                      '${data['izin']}%',
                      '${data['sakit']}%',
                      '${data['alpa']}%',
                    ];
                  },
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: .5))),
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
                    pw.Text('Kepala Sekolah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
      appBar: AppBar(title: const Text('Rekap Bulanan (Kehadiran)')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Text('Pilih Bulan: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBulan,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _bulanList.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedBulan = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _rekapData.length,
              itemBuilder: (context, index) {
                final data = _rekapData[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['kelas'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('Hadir', '${data['hadir']}%', Colors.green),
                            _buildStatColumn('Izin', '${data['izin']}%', Colors.blue),
                            _buildStatColumn('Sakit', '${data['sakit']}%', Colors.orange),
                            _buildStatColumn('Alpa', '${data['alpa']}%', Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generatePdf,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Download PDF'),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
