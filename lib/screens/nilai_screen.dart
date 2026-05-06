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
  final List<String> _mapelList = ['Matematika', 'Bahasa Indonesia', 'IPA', 'IPS', 'Pend. Agama Islam'];

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
              pw.Text('Rekap Nilai Harian', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Mata Pelajaran: $_selectedMapel', style: const pw.TextStyle(fontSize: 16)),
              pw.Text('Tanggal: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 24),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['No', 'Nama Siswa', 'Tugas 1', 'Tugas 2', 'Ulangan Harian', 'Rata-rata'],
                data: List<List<String>>.generate(
                  _nilaiData.length,
                  (index) {
                    final data = _nilaiData[index];
                    final rata = (data['tugas1'] + data['tugas2'] + data['uh']) / 3;
                    return [
                      '${index + 1}',
                      data['nama'].toString(),
                      data['tugas1'].toString(),
                      data['tugas2'].toString(),
                      data['uh'].toString(),
                      rata.toStringAsFixed(2),
                    ];
                  },
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: .5))),
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
        title: const Text('Mata Pelajaran & Nilai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF',
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Text('Mata Pelajaran: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedMapel,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _mapelList.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedMapel = newValue;
                        });
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
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Nama Siswa', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tugas 1', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('Tugas 2', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('Ulangan Harian', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('Rata-rata', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  ],
                  rows: List<DataRow>.generate(
                    _nilaiData.length,
                    (index) {
                      final data = _nilaiData[index];
                      final rata = (data['tugas1'] + data['tugas2'] + data['uh']) / 3;
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(data['nama'])),
                          DataCell(Text('${data['tugas1']}')),
                          DataCell(Text('${data['tugas2']}')),
                          DataCell(Text('${data['uh']}')),
                          DataCell(Text(rata.toStringAsFixed(2))),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generatePdf,
        icon: const Icon(Icons.download),
        label: const Text('Download PDF'),
      ),
    );
  }
}
