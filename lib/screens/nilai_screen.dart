import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class NilaiScreen extends StatefulWidget {
  const NilaiScreen({super.key});

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  String _selectedMapel = 'Matematika';
  final List<String> _mapelList = [
    'Matematika',
    'Bahasa Indonesia',
    'IPA',
    'IPS',
    'Pend. Agama Islam',
  ];

  final List<Map<String, dynamic>> _nilaiData = [
    {'nama': 'Andi Susanto', 'tugas1': 85, 'tugas2': 90, 'uh': 88},
    {'nama': 'Budi Setiawan', 'tugas1': 75, 'tugas2': 80, 'uh': 78},
    {'nama': 'Citra Kirana', 'tugas1': 95, 'tugas2': 92, 'uh': 96},
    {'nama': 'Deni Ramadhan', 'tugas1': 80, 'tugas2': 85, 'uh': 82},
    {'nama': 'Eka Putri', 'tugas1': 90, 'tugas2': 88, 'uh': 91},
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
                'Rekap Nilai Harian',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Mata Pelajaran: $_selectedMapel',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                'Tanggal: ${DateTime.now().toString().split(' ')[0]}',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 24),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: [
                  'No',
                  'Nama Siswa',
                  'Tugas 1',
                  'Tugas 2',
                  'Ulangan Harian',
                  'Rata-rata',
                ],
                data: List<List<String>>.generate(_nilaiData.length, (index) {
                  final data = _nilaiData[index];
                  final rata =
                      (data['tugas1'] + data['tugas2'] + data['uh']) / 3;
                  return [
                    '${index + 1}',
                    data['nama'].toString(),
                    data['tugas1'].toString(),
                    data['tugas2'].toString(),
                    data['uh'].toString(),
                    rata.toStringAsFixed(2),
                  ];
                }),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey400, width: .5),
                  ),
                ),
                cellAlignment: pw.Alignment.center,
                cellAlignments: {1: pw.Alignment.centerLeft},
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rekap_Nilai_Harian_$_selectedMapel.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nilai Siswa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            fontSize: 24,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _generatePdf,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PDF',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mata Pelajaran',
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
                    value: _selectedMapel,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    items: _mapelList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
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
                        setState(() => _selectedMapel = newValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: DataTable(
                    columns: const [
                      DataColumn(
                        label: Text(
                          'No',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Nama Siswa',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Tugas 1',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Tugas 2',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Ulangan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Rata-rata',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        numeric: true,
                      ),
                    ],
                    rows: List<DataRow>.generate(_nilaiData.length, (index) {
                      final data = _nilaiData[index];
                      final rata =
                          (data['tugas1'] + data['tugas2'] + data['uh']) / 3;
                      return DataRow(
                        color: WidgetStateProperty.resolveWith<Color?>((
                          Set<WidgetState> states,
                        ) {
                          return index.isEven ? Colors.grey[50] : Colors.white;
                        }),
                        cells: [
                          DataCell(
                            Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              data['nama'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${data['tugas1']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${data['tugas2']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${data['uh']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              rata.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    headingRowColor: WidgetStatePropertyAll(Colors.grey[100]),
                    dividerThickness: 0.5,
                  ),
                ),
              ),
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
}
