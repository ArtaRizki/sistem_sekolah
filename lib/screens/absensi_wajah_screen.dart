import 'package:flutter/material.dart';
import '../face_service.dart';
import '../api_service.dart';

class AbsensiWajahScreen extends StatefulWidget {
  const AbsensiWajahScreen({super.key});

  @override
  State<AbsensiWajahScreen> createState() => _AbsensiWajahScreenState();
}

class _AbsensiWajahScreenState extends State<AbsensiWajahScreen>
    with SingleTickerProviderStateMixin {
  final FaceService _faceService = FaceService();
  bool _isInitializing = true;
  bool _isProcessing = false;
  String _status = "Siap";
  late AnimationController _animationController;
  bool _isTripodMode = false;
  List<dynamic> _registeredFaces = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _initService();
    _loadRegisteredFaces();
  }

  Future<void> _loadRegisteredFaces() async {
    try {
      final faces = await _apiService.getSiswaWajah();
      setState(() => _registeredFaces = faces);
    } catch (e) {
      debugPrint("Error loading faces: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initService() async {
    try {
      await _faceService.init();
    } catch (e) {
      debugPrint("Init error: $e");
      if (mounted) {
        _showErrorSnackBar("Gagal menginisialisasi sistem wajah: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _registerFace() async {
    setState(() {
      _isProcessing = true;
      _status = "Mengambil data siswa...";
    });
    
    // Show student picker first
    final List<dynamic> siswaList = await _apiService.getSiswa();
    
    setState(() {
      _isProcessing = false;
      _status = "Siap";
    });
    if (siswaList.isEmpty) {
      _showErrorSnackBar("Data siswa kosong. Silakan tambah siswa dulu.");
      return;
    }

    String? selectedNis;
    if (mounted) {
      selectedNis = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Pilih Siswa"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: siswaList.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(siswaList[i]['nama']),
                subtitle: Text(
                  "NIS: ${siswaList[i]['nis']} • ${siswaList[i]['kelas']}",
                ),
                onTap: () => Navigator.pop(ctx, siswaList[i]['nis'].toString()),
              ),
            ),
          ),
        ),
      );
    }

    if (selectedNis == null) return;

    setState(() {
      _isProcessing = true;
      _status = "Membuka Kamera...";
    });

    try {
      final path = await _faceService.captureFace();
      if (path != null) {
        setState(() => _status = "Memproses Wajah...");
        final embedding = await _faceService.getEmbedding(path);
        if (embedding != null) {
          await _faceService.saveRegisteredFace(embedding, userId: selectedNis);
          await _loadRegisteredFaces();
          _showSuccessDialog(
            "Wajah Berhasil Didaftarkan!",
            "Wajah siswa dengan NIS $selectedNis telah tersimpan.",
            Icons.check_circle_rounded,
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar("Gagal daftar wajah: $e");
    } finally {
      setState(() {
        _isProcessing = false;
        _status = "Siap";
      });
    }
  }

  Future<void> _verifyAttendance() async {
    if (_registeredFaces.isEmpty) {
      setState(() {
        _isProcessing = true;
        _status = "Memuat data wajah...";
      });
      await _loadRegisteredFaces();
      setState(() {
        _isProcessing = false;
        _status = "Siap";
      });
      if (_registeredFaces.isEmpty) {
        _showErrorSnackBar("Tidak ada data wajah terdaftar!");
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _status = _isTripodMode
          ? "Scanning... (Tripod Mode)"
          : "Membuka Kamera...";
    });

    try {
      do {
        final path = await _faceService.captureFace();
        if (path == null) break;

        setState(() => _status = "Memverifikasi...");
        final embedding = await _faceService.getEmbedding(path);
        if (embedding != null) {
          Map<String, dynamic>? bestMatch;
          double maxSimilarity = 0.0;

          for (var reg in _registeredFaces) {
            final List<double> regEmbedding = (reg['embedding'] as List)
                .map((e) => (e as num).toDouble())
                .toList();
            final similarity = _faceService.calculateSimilarity(
              regEmbedding,
              embedding,
            );
            if (similarity > maxSimilarity) {
              maxSimilarity = similarity;
              bestMatch = reg;
            }
          }

          if (maxSimilarity > 0.75 && bestMatch != null) {
            final name = bestMatch['nama'];
            final sekolah = bestMatch['sekolah'];

            final result = await _faceService.syncAttendance(
              embedding,
              maxSimilarity,
              name: name,
              sekolah: sekolah,
            );

            if (result['status'] == 'duplicate') {
              // Already attended today
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("$name sudah absen hari ini!"),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }

              if (!_isTripodMode) {
                _showSuccessDialog(
                  "Sudah Absen!",
                  "$name sudah tercatat absen hari ini. Tidak perlu absen lagi.",
                  Icons.info_rounded,
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Hadir: $name"),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }

              if (!_isTripodMode) {
                _showSuccessDialog(
                  "Absensi Berhasil!",
                  "Kehadiran $name telah tercatat.",
                  Icons.face_rounded,
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Wajah tidak dikenali."),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          }
        }

        if (_isTripodMode) {
          setState(() => _status = "Scanning...");
          await Future.delayed(
            const Duration(seconds: 2),
          ); // Pause before next scan
        }
      } while (_isTripodMode);
    } catch (e) {
      _showErrorSnackBar("Gagal verifikasi: $e");
    } finally {
      setState(() {
        _isProcessing = false;
        _status = "Siap";
      });
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: const Color(0xFF10B981), size: 80),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w300,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualAbsensiDialog() async {
    setState(() {
      _isProcessing = true;
      _status = "Mengambil data sekolah dan siswa...";
    });

    final siswaList = await _apiService.getSiswa();
    final sekolahList = await _apiService.getSekolah();

    setState(() {
      _isProcessing = false;
      _status = "Siap";
    });

    if (siswaList.isEmpty) {
      _showErrorSnackBar("Data siswa kosong. Silakan tambah siswa dulu.");
      return;
    }

    String sekolah = sekolahList.isNotEmpty ? sekolahList.first['nama'] ?? '' : '';
    String? selectedNis;
    String selectedNama = '';
    String selectedStatus = 'Izin';
    String selectedSekolah = '';
    final now = DateTime.now();
    String tanggal =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filteredSiswa = sekolah.isEmpty
              ? List<dynamic>.from(siswaList)
              : siswaList.where((s) => s['sekolah'] == sekolah).toList();

          return AlertDialog(
            title: const Text('Input Manual Absensi'),
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
                          initialDate: DateTime.tryParse(tanggal) ?? now,
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
                          suffixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                        ),
                        child: Text(tanggal),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sekolah
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Sekolah',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: sekolah.isNotEmpty ? sekolah : null,
                          hint: const Text('Pilih Sekolah'),
                          items: sekolahList
                              .map<DropdownMenuItem<String>>(
                                (s) => DropdownMenuItem(
                                  value: s['nama'],
                                  child: Text(s['nama'], overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setDialogState(() {
                            sekolah = v!;
                            selectedNis = null;
                            selectedNama = '';
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Siswa
                    InputDecorator(
                      key: ValueKey('siswa_manual_$sekolah'),
                      decoration: const InputDecoration(
                        labelText: 'Siswa',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          onChanged: (v) {
                            final siswa = filteredSiswa.firstWhere(
                              (s) => s['nis'].toString() == v,
                            );
                            setDialogState(() {
                              selectedNis = v;
                              selectedNama = siswa['nama'];
                              selectedSekolah = siswa['sekolah'] ?? sekolah;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Status
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Status Kehadiran',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedStatus,
                          items: const [
                            DropdownMenuItem(value: 'Izin', child: Text('Izin')),
                            DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
                            DropdownMenuItem(value: 'Alpa', child: Text('Alpa')),
                          ],
                          onChanged: (v) => setDialogState(() => selectedStatus = v!),
                        ),
                      ),
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
                  if (selectedNama.isEmpty || tanggal.isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() {
                    _isProcessing = true;
                    _status = "Menyimpan data...";
                  });

                  final result = await _apiService.addManualAbsensi(
                    nama: selectedNama,
                    status: selectedStatus,
                    sekolah: selectedSekolah,
                    tanggal: tanggal,
                  );

                  setState(() {
                    _isProcessing = false;
                    _status = "Siap";
                  });

                  if (mounted) {
                    if (result['status'] == 'duplicate') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Sudah absen'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    } else if (result['status'] == 'success') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Berhasil'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      _showErrorSnackBar(result['message'] ?? 'Gagal');
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: Tween(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.face_rounded,
                    size: 60,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
              const SizedBox(height: 24),
              const Text(
                "Menginisialisasi Model Wajah...",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verifikasi Wajah',
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 100,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Absensi Wajah",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Gunakan teknologi pengenalan wajah untuk absensi yang lebih cepat dan aman",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w300,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildMenuButton(
                  onPressed: _isProcessing ? null : _registerFace,
                  icon: Icons.person_add_rounded,
                  label: "Daftar Wajah Siswa",
                  color: const Color(0xFF6366F1),
                  subtitle: "Simpan wajah siswa ke database",
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  onPressed: _isProcessing ? null : _verifyAttendance,
                  icon: Icons.camera_front_rounded,
                  label: "Mulai Absensi",
                  color: const Color(0xFF06B6D4),
                  subtitle: _isTripodMode
                      ? "Mode Tripod Aktif (Otomatis)"
                      : "Verifikasi kehadiran siswa",
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      "Mode Tripod",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      "Kamera akan terus menyala untuk absensi otomatis",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    value: _isTripodMode,
                    activeThumbColor: const Color(0xFF6366F1),
                    activeTrackColor: const Color(
                      0xFF6366F1,
                    ).withValues(alpha: 0.3),
                    onChanged: _isProcessing
                        ? null
                        : (v) => setState(() => _isTripodMode = v),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  onPressed: _isProcessing ? null : _showManualAbsensiDialog,
                  icon: Icons.edit_note_rounded,
                  label: "Input Manual",
                  color: const Color(0xFFF59E0B),
                  subtitle: "Input Izin, Sakit, atau Alpa",
                ),
                const SizedBox(height: 32),
                if (_isProcessing)
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _status,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required String subtitle,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
