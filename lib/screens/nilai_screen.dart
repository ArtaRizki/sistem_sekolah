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
  String _selectedTanggal = ''; // empty = show all dates
  String _selectedKelas = 'Semua Kelas';
  List<String> _mapelList = ['PJOK', 'TIK'];
  List<String> _kelasList = [];
  List<dynamic> _nilaiData = [];
  List<dynamic> _sekolahList = [];
  List<dynamic> _siswaList = [];

  @override
  void initState() {
    super.initState();
    _loadKelas();
    _loadMapelAndNilai();
  }

  @override
  void didUpdateWidget(covariant NilaiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sekolah != widget.sekolah) {
      _loadKelas();
      _loadMapelAndNilai();
    }
  }

  Future<void> _loadKelas() async {
    try {
      final kelasData = await _apiService.getKelas(sekolah: widget.sekolah);
      setState(() {
        _kelasList = ['Semua Kelas', ...kelasData.map((e) => e.toString())];
        _selectedKelas = 'Semua Kelas';
      });
    } catch (e) {
      debugPrint("Error loading kelas: $e");
    }
  }

  Future<void> _loadMapelAndNilai() async {
    setState(() => _isLoading = true);
    try {
      final mapelData = await _apiService.getMapel();
      final sekolahData = await _apiService.getSekolah();
      // Fetch ALL siswa (no sekolah filter) so dialog can pick from any school
      final siswaData = await _apiService.getSiswa();
      if (mapelData.isNotEmpty) {
        _mapelList = mapelData.map<String>((e) => e['nama'].toString()).toList();
        if (!_mapelList.contains(_selectedMapel) && _mapelList.isNotEmpty) {
          _selectedMapel = _mapelList.first;
        }
      }
      final kelasFilter =
          (_selectedKelas != 'Semua Kelas') ? _selectedKelas : null;
      final data = await _apiService.getNilai(
        _selectedMapel,
        sekolah: widget.sekolah,
        tanggal: _selectedTanggal,
        kelas: kelasFilter,
      );
      setState(() {
        _nilaiData = data;
        _sekolahList = sekolahData;
        _siswaList = siswaData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading nilai: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatTanggal(String tanggal) {
    if (tanggal.isEmpty) return '-';
    try {
      // Try to parse the date, handles "2026-05-10" and "2026-05-10T00:00:00.000Z"
      DateTime? dt = DateTime.tryParse(tanggal);

      // Fallback for JS string "Sun May 10 2026 00:00:00 GMT+0700 (Waktu Indonesia Barat)"
      if (dt == null) {
        final parts = tanggal.split(' ');
        if (parts.length >= 4) {
          const monthMap = {
            'Jan': 1,
            'Feb': 2,
            'Mar': 3,
            'Apr': 4,
            'May': 5,
            'Jun': 6,
            'Jul': 7,
            'Aug': 8,
            'Sep': 9,
            'Oct': 10,
            'Nov': 11,
            'Dec': 12,
          };
          final m = monthMap[parts[1]];
          final d = int.tryParse(parts[2]);
          final y = int.tryParse(parts[3]);
          if (m != null && d != null && y != null) {
            dt = DateTime(y, m, d);
          }
        }
      }

      if (dt == null) return tanggal;

      const hariList = [
        '',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];

      final hari = hariList[dt.weekday];
      final tanggalNum = dt.day.toString().padLeft(2, '0');
      final bulanNum = dt.month.toString().padLeft(2, '0');
      final tahun = dt.year;

      return '$hari, $tanggalNum-$bulanNum-$tahun';
    } catch (_) {
      return tanggal;
    }
  }

  Future<void> _pickTanggalFilter() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggal.isNotEmpty
          ? DateTime.tryParse(_selectedTanggal) ?? now
          : now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedTanggal =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
      _loadMapelAndNilai();
    }
  }

  void _showNilaiDialog({Map<String, dynamic>? nilai}) {
    String? selectedNis = nilai?['nis']?.toString();
    String selectedNama = nilai?['nama']?.toString() ?? '';
    final nilaiC = TextEditingController(
      text: nilai?['nilai']?.toString() ?? '',
    );
    String mapel = nilai?['mapel']?.toString() ?? _selectedMapel;
    String sekolah = nilai?['sekolah']?.toString() ?? widget.sekolah ?? 'Semua';
    final isEdit = nilai != null;
    // Default to today's date for new entries, or existing date for edit
    String tanggal = nilai?['tanggal'] ?? '';
    if (tanggal.isEmpty && !isEdit) {
      final now = DateTime.now();
      tanggal =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }

    String selectedKelas = 'Semua';
    if (isEdit && selectedNis != null) {
      for (var s in _siswaList) {
        if (s['nis'].toString() == selectedNis &&
            s['kelas'] != null &&
            s['kelas'].toString().isNotEmpty) {
          selectedKelas = s['kelas'].toString();
          break;
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Calculate available classes based on the selected school's tingkat
          List<String> availableKelasList = [];
          if (sekolah != 'Semua' && sekolah.isNotEmpty) {
            String tingkat = '';
            for (var s in _sekolahList) {
              if (s['nama'] == sekolah) {
                tingkat = s['tingkat']?.toString().toUpperCase() ?? '';
                break;
              }
            }
            // Fallback guess based on name if tingkat is empty
            if (tingkat.isEmpty) {
              final nameLower = sekolah.toLowerCase();
              if (nameLower.contains('sma') ||
                  nameLower.contains('ma ') ||
                  nameLower.startsWith('ma')) {
                tingkat = 'SMA';
              } else if (nameLower.contains('smp') ||
                  nameLower.contains('mts')) {
                tingkat = 'SMP';
              }
            }

            if (tingkat == 'SMA' || tingkat == 'MA') {
              availableKelasList = ['10', '11', '12'];
            } else if (tingkat == 'SMP' || tingkat == 'MTS') {
              availableKelasList = ['7', '8', '9'];
            } else {
              // Fallback to dynamic if unknown
              final Set<String> availableKelasSet = {};
              for (var s in _siswaList) {
                if (s['sekolah'] == sekolah &&
                    s['kelas'] != null &&
                    s['kelas'].toString().isNotEmpty) {
                  availableKelasSet.add(s['kelas'].toString());
                }
              }
              availableKelasList = availableKelasSet.toList()..sort();
            }
          } else {
            // If "Semua" is selected, extract all unique classes dynamically
            final Set<String> availableKelasSet = {};
            for (var s in _siswaList) {
              if (s['kelas'] != null && s['kelas'].toString().isNotEmpty) {
                availableKelasSet.add(s['kelas'].toString());
              }
            }
            availableKelasList = availableKelasSet.toList()..sort();
          }

          final availableKelas = ['Semua', ...availableKelasList];

          if (!availableKelas.contains(selectedKelas)) {
            selectedKelas = 'Semua';
          }

          // Filter siswa by currently selected sekolah and kelas
          var filteredSiswa = (sekolah == 'Semua' || sekolah.isEmpty)
              ? List<dynamic>.from(_siswaList)
              : _siswaList.where((s) => s['sekolah'] == sekolah).toList();

          if (selectedKelas != 'Semua') {
            filteredSiswa = filteredSiswa
                .where((s) => s['kelas']?.toString() == selectedKelas)
                .toList();
          }

          return AlertDialog(
            title: Text(isEdit ? 'Edit Nilai' : 'Tambah Nilai'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tanggal
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: tanggal.isNotEmpty
                              ? DateTime.tryParse(tanggal) ?? DateTime.now()
                              : DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tanggal =
                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                          ),
                        ),
                        child: Text(
                          tanggal.isNotEmpty
                              ? _formatTanggal(tanggal)
                              : 'Pilih Tanggal',
                          style: TextStyle(
                            color: tanggal.isNotEmpty
                                ? const Color(0xFF1F2937)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sekolah
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Sekolah',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: sekolah.isNotEmpty ? sekolah : null,
                          hint: const Text('Pilih Sekolah'),
                          items: [
                            const DropdownMenuItem(
                              value: 'Semua',
                              child: Text('Semua Sekolah'),
                            ),
                            ..._sekolahList.map<DropdownMenuItem<String>>(
                              (s) => DropdownMenuItem(
                                value: s['nama'],
                                child: Text(
                                  s['nama'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setDialogState(() {
                            sekolah = v!;
                            selectedKelas = 'Semua';
                            selectedNis = null;
                            selectedNama = '';
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Kelas
                    InputDecorator(
                      key: ValueKey('kelas_$sekolah'),
                      decoration: const InputDecoration(
                        labelText: 'Kelas',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedKelas,
                          items: availableKelas.map((k) {
                            String display = k;
                            if (k == 'Semua') {
                              display = 'Semua Kelas';
                            } else if (k == '7') {
                              display = 'Kelas 7 (VII)';
                            } else if (k == '8') {
                              display = 'Kelas 8 (VIII)';
                            } else if (k == '9') {
                              display = 'Kelas 9 (IX)';
                            } else if (k == '10') {
                              display = 'Kelas 10 (X)';
                            } else if (k == '11') {
                              display = 'Kelas 11 (XI)';
                            } else if (k == '12') {
                              display = 'Kelas 12 (XII)';
                            } else {
                              display = 'Kelas $k';
                            }
                            return DropdownMenuItem(
                              value: k,
                              child: Text(display),
                            );
                          }).toList(),
                          onChanged: (v) => setDialogState(() {
                            selectedKelas = v!;
                            selectedNis = null;
                            selectedNama = '';
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Siswa dropdown
                    InputDecorator(
                      key: ValueKey('siswa_${sekolah}_$selectedKelas'),
                      decoration: const InputDecoration(
                        labelText: 'Siswa',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedNis,
                          hint: const Text('Pilih Siswa'),
                          items: filteredSiswa
                              .map(
                                (s) => DropdownMenuItem<String>(
                                  value: s['nis'].toString(),
                                  child: Text(
                                    '${s['nama']} - ${s['kelas']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setDialogState(() {
                            selectedNis = v;
                            if (v != null) {
                              final match = filteredSiswa.firstWhere(
                                (s) => s['nis'].toString() == v,
                                orElse: () => <String, dynamic>{},
                              );
                              selectedNama = match['nama'] ?? '';
                            }
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Mata Pelajaran
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Mata Pelajaran',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: mapel,
                          items: _mapelList
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    m,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setDialogState(() => mapel = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Nilai
                    TextField(
                      controller: nilaiC,
                      decoration: const InputDecoration(
                        labelText: 'Nilai',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
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
                  if (selectedNis == null ||
                      selectedNama.isEmpty ||
                      nilaiC.text.isEmpty ||
                      sekolah.isEmpty ||
                      tanggal.isEmpty) {
                    return;
                  }
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  final n = num.tryParse(nilaiC.text) ?? 0;
                  // If 'Semua' is selected, use the student's actual school
                  String saveSekolah = sekolah;
                  if (sekolah == 'Semua' && selectedNis != null) {
                    final siswa = _siswaList.firstWhere(
                      (s) => s['nis'].toString() == selectedNis,
                      orElse: () => <String, dynamic>{},
                    );
                    saveSekolah = siswa['sekolah'] ?? '';
                  }
                  Map<String, dynamic> result;
                  if (isEdit) {
                    result = await _apiService.updateNilai(
                      nilai['rowKey'],
                      selectedNama,
                      selectedNis!,
                      mapel,
                      n,
                      saveSekolah,
                      tanggal,
                    );
                  } else {
                    result = await _apiService.addNilai(
                      selectedNama,
                      selectedNis!,
                      mapel,
                      n,
                      saveSekolah,
                      tanggal,
                    );
                  }
                  if (result['status'] == 'error') {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  result['message'] ?? 'Gagal menyimpan nilai',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red[600],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  } else {
                    _loadMapelAndNilai();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit ? 'Nilai diperbarui' : 'Nilai ditambahkan',
                          ),
                        ),
                      );
                    }
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
        title: const Text('Hapus Nilai'),
        content: Text('Yakin ingin menghapus nilai "$nama"?'),
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
              await _apiService.deleteNilai(rowKey);
              _loadMapelAndNilai();
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Nilai dihapus')));
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
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Rekap Nilai Harian - $_selectedMapel',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Sekolah: ${widget.sekolah ?? "Semua Sekolah"}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Kelas: $_selectedKelas',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Tanggal: ${DateTime.now().toString().split(' ')[0]}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: [
                'No',
                'Tanggal',
                'Nama Siswa',
                'Mapel',
                'Nilai',
                'Sekolah',
              ],
              data: List<List<String>>.generate(_nilaiData.length, (i) {
                final d = _nilaiData[i];
                return [
                  '${i + 1}',
                  d['tanggal'] ?? '-',
                  d['nama'] ?? '-',
                  d['mapel'] ?? '-',
                  '${d['nilai'] ?? 0}',
                  d['sekolah'] ?? '-',
                ];
              }),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.center,
              cellAlignments: {
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                5: pw.Alignment.centerLeft,
              },
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Nilai_$_selectedMapel.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nilai Harian Siswa',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            fontSize: 22,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF',
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                // Filter Mapel
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedMapel,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        items: _mapelList
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.menu_book_rounded,
                                      size: 16,
                                      color: Color(0xFF6366F1),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        m,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedMapel = v);
                            _loadMapelAndNilai();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Tanggal
                Expanded(
                  child: InkWell(
                    onTap: _pickTanggalFilter,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedTanggal.isNotEmpty
                                  ? _formatTanggal(_selectedTanggal)
                                  : 'Semua Tgl',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedTanggal.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedTanggal = '');
                                _loadMapelAndNilai();
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _kelasList.contains(_selectedKelas)
                      ? _selectedKelas
                      : null,
                  hint: const Text('Pilih Kelas', style: TextStyle(fontSize: 13)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  items: _kelasList
                      .map(
                        (k) => DropdownMenuItem(
                          value: k,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.class_rounded,
                                size: 16,
                                color: Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  k,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedKelas = v);
                      _loadMapelAndNilai();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMapelAndNilai,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _nilaiData.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada data nilai',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _nilaiData.length,
                      itemBuilder: (context, index) {
                        final data = _nilaiData[index];
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
                              child: Center(
                                child: Text(
                                  '${data['nilai'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              data['nama'] ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NIS: ${data['nis']} • ${data['mapel']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1F2937),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                Text(
                                  data['sekolah'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1F2937),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                if ((data['tanggal'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 12,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatTanggal(
                                          data['tanggal'].toString(),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showNilaiDialog(
                                    nilai: Map<String, dynamic>.from(data),
                                  );
                                }
                                if (value == 'delete') {
                                  _confirmDelete(data['rowKey'], data['nama']);
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNilaiDialog(),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Nilai',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}
