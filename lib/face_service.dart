import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FaceService {
  static const _channel = MethodChannel('com.artarizki.sistem_sekolah/face');
  
  String? _modelPath;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelFile = File('${dir.path}/model/vggface.tflite');
    
    if (!modelFile.existsSync()) {
      await _downloadModel(modelFile);
    }
    
    _modelPath = modelFile.path;
    await _channel.invokeMethod('initFaceHelper', {'modelPath': _modelPath});
  }

  Future<void> _downloadModel(File file) async {
    file.createSync(recursive: true);
    final response = await http.get(Uri.parse('https://janissari.id/api/modelling'));
    final json = jsonDecode(response.body);
    final modelUrl = json['data']['model_location'];
    
    final modelRes = await http.get(Uri.parse(modelUrl));
    await file.writeAsBytes(modelRes.bodyBytes);
  }

  Future<String?> captureFace() async {
    return await _channel.invokeMethod('startFaceCapture');
  }

  Future<List<double>?> getEmbedding(String imagePath) async {
    final List<dynamic>? result = await _channel.invokeMethod('getEmbedding', {'imagePath': imagePath});
    return result?.cast<double>();
  }

  Future<void> saveRegisteredFace(List<double> embedding) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registered_face', jsonEncode(embedding));
  }

  Future<List<double>?> getRegisteredFace() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('registered_face');
    if (data == null) return null;
    final List<dynamic> list = jsonDecode(data);
    return list.cast<double>();
  }

  double calculateSimilarity(List<double> v1, List<double> v2) {
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
