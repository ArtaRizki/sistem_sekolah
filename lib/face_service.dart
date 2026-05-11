import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as d;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class FaceService {
  static const _channel = MethodChannel('com.artarizki.sistem_sekolah/face');

  final ApiService _apiService = ApiService();
  String? _modelPath;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelFile = File('${dir.path}/model/vggface.tflite');

    // If file exists but is too small (e.g. interrupted download), delete it
    if (modelFile.existsSync() && modelFile.lengthSync() < 10 * 1024 * 1024) {
      d.log("Model file too small (${modelFile.lengthSync()} bytes), deleting...");
      await modelFile.delete();
    }

    if (!modelFile.existsSync()) {
      d.log("Model missing, downloading...");
      await _downloadModel(modelFile);
    }

    if (modelFile.existsSync()) {
      _modelPath = modelFile.path;
      try {
        await _channel.invokeMethod('initFaceHelper', {'modelPath': _modelPath});
      } on PlatformException catch (e) {
        if (e.code == 'INIT_ERROR' || e.message?.contains('flatbuffer') == true) {
          d.log("Model initialization failed, file might be corrupted. Deleting...");
          await modelFile.delete();
        }
        rethrow;
      }
    } else {
      throw Exception("Gagal mengunduh model wajah.");
    }
  }

  Future<void> _downloadModel(File file) async {
    try {
      final byteData = await rootBundle.load('assets/vggface2.tflite');
      final buffer = byteData.buffer;
      
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      
      await file.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
    } catch (e) {
      throw Exception("Gagal menyalin model dari assets: $e");
    }
  }

  Future<String?> captureFace() async {
    return await _channel.invokeMethod('startFaceCapture');
  }

  Future<List<double>?> getEmbedding(String imagePath) async {
    final List<dynamic>? result = await _channel.invokeMethod('getEmbedding', {
      'imagePath': imagePath,
    });
    return result?.map((e) => (e as num).toDouble()).toList();
  }

  Future<void> saveRegisteredFace(List<double> embedding, {String? userId}) async {
    // Sync to server
    await _apiService.registerFace(embedding, id: userId);
  }

  Future<Map<String, dynamic>> syncAttendance(List<double> embedding, double similarity, {String? name, String? sekolah}) async {
    return await _apiService.submitAttendance(embedding, similarity, name: name, sekolah: sekolah);
  }

  Future<List<double>?> getRegisteredFace() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('registered_face');
    if (data == null) return null;
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => (e as num).toDouble()).toList();
  }

  double calculateSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) {
      d.log('Embedding lengths do not match: ${v1.length} vs ${v2.length}');
      return 0.0;
    }
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      normA += v1[i] * v1[i];
      normB += v2[i] * v2[i];
    }
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
