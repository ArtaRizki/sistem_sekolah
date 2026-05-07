import 'package:flutter/material.dart';
import '../face_service.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _initService();
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
      _status = "Membuka Kamera...";
    });

    try {
      final path = await _faceService.captureFace();
      if (path != null) {
        setState(() => _status = "Memproses Wajah...");
        final embedding = await _faceService.getEmbedding(path);
        if (embedding != null) {
          await _faceService.saveRegisteredFace(embedding);
          _showSuccessDialog("Wajah Berhasil Didaftarkan!",
              "Wajah Anda telah tersimpan dan siap untuk verifikasi.",
              Icons.check_circle_rounded);
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
    final registered = await _faceService.getRegisteredFace();
    if (registered == null) {
      _showErrorSnackBar(
          "Silakan daftar wajah terlebih dahulu!");
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = "Membuka Kamera...";
    });

    try {
      final path = await _faceService.captureFace();
      if (path != null) {
        setState(() => _status = "Memverifikasi...");
        final embedding = await _faceService.getEmbedding(path);
        if (embedding != null) {
          final similarity =
              _faceService.calculateSimilarity(registered, embedding);
          debugPrint("Similarity: $similarity");

          if (similarity > 0.75) {
            // Kirim data ke backend GAS
            _faceService.syncAttendance(embedding, similarity);

            _showSuccessDialog(
                "Absensi Berhasil!",
                "Kehadiran Anda telah tercatat dengan persentase kecocokan ${(similarity * 100).toStringAsFixed(1)}%",
                Icons.face_rounded);
          } else {
            _showErrorSnackBar(
                "Wajah tidak cocok! (Score: ${(similarity * 100).toStringAsFixed(1)}%)");
          }
        }
      }
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
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
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

  void _showSuccessDialog(
      String title, String message, IconData icon) {
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
              child: Icon(icon,
                  color: const Color(0xFF10B981),
                  size: 80),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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
                    horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
              const CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
              const SizedBox(height: 24),
              const Text(
                "Menginisialisasi Model Wajah...",
                style: TextStyle(
                  fontSize: 16,
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
        title: const Text('Verifikasi Wajah',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                fontSize: 24)),
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
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Gunakan teknologi pengenalan wajah untuk absensi yang lebih cepat dan aman",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildMenuButton(
                  onPressed: _isProcessing ? null : _registerFace,
                  icon: Icons.person_add_rounded,
                  label: "Daftar Wajah Baru",
                  color: const Color(0xFF6366F1),
                  subtitle: "Simpan wajah Anda untuk pertama kali",
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  onPressed: _isProcessing ? null : _verifyAttendance,
                  icon: Icons.camera_front_rounded,
                  label: "Absen Masuk/Pulang",
                  color: const Color(0xFF06B6D4),
                  subtitle: "Verifikasi kehadiran Anda",
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
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}