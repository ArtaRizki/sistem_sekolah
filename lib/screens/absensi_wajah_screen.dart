import 'package:flutter/material.dart';
import '../face_service.dart';

class AbsensiWajahScreen extends StatefulWidget {
  const AbsensiWajahScreen({super.key});

  @override
  State<AbsensiWajahScreen> createState() => _AbsensiWajahScreenState();
}

class _AbsensiWajahScreenState extends State<AbsensiWajahScreen> {
  final FaceService _faceService = FaceService();
  bool _isInitializing = true;
  bool _isProcessing = false;
  String _status = "Siap";

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    try {
      await _faceService.init();
    } catch (e) {
      debugPrint("Init error: $e");
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
          _showSnackBar("Wajah berhasil didaftarkan!", Colors.green);
        }
      }
    } catch (e) {
      _showSnackBar("Gagal daftar wajah: $e", Colors.red);
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
      _showSnackBar("Silakan daftar wajah terlebih dahulu!", Colors.orange);
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
          final similarity = _faceService.calculateSimilarity(registered, embedding);
          debugPrint("Similarity: $similarity");
          
          if (similarity > 0.75) {
            _showSuccessDialog();
          } else {
            _showSnackBar("Wajah tidak cocok! (Score: ${(similarity * 100).toStringAsFixed(1)}%)", Colors.red);
          }
        }
      }
    } catch (e) {
      _showSnackBar("Gagal verifikasi: $e", Colors.red);
    } finally {
      setState(() {
        _isProcessing = false;
        _status = "Siap";
      });
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Berhasil!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text("Absensi Anda telah tercatat secara lokal.", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Menginisialisasi Model Wajah..."),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Wajah')),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.face_retouching_natural, size: 100, color: Colors.blueAccent),
                const SizedBox(height: 32),
                Text(
                  "Absensi Wajah",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Pastikan wajah Anda terlihat jelas",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildMenuButton(
                  onPressed: _isProcessing ? null : _registerFace,
                  icon: Icons.person_add,
                  label: "Daftar Wajah Baru",
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  onPressed: _isProcessing ? null : _verifyAttendance,
                  icon: Icons.camera_front,
                  label: "Absen Masuk/Pulang",
                  color: Colors.teal,
                ),
                const SizedBox(height: 32),
                if (_isProcessing)
                  Text(
                    _status,
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    textAlign: TextAlign.center,
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
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
