import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL DEPLOYMENT GOOGLE APPS SCRIPT USER
  static const String baseUrl = 'https://script.google.com/macros/s/AKfycbwBN4DkmIy4slzlFd703utieZl1RGh8jhrEOkxZ4JbMvnEfH6hp-keA9MApQSahWidZoQ/exec';

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl?action=getDashboard'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getGuru() async {
    final response = await http.get(Uri.parse('$baseUrl?action=getGuru'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getSiswa(String kelas) async {
    final response = await http.get(Uri.parse('$baseUrl?action=getSiswa&kelas=$kelas'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getNilai(String mapel) async {
    final response = await http.get(Uri.parse('$baseUrl?action=getNilai&mapel=$mapel'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getRekap(String bulan) async {
    final response = await http.get(Uri.parse('$baseUrl?action=getRekap&bulan=$bulan'));
    return jsonDecode(response.body);
  }

  Future<bool> registerFace(List<double> embedding) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: jsonEncode({
          'action': 'registerFace',
          'embedding': embedding,
        }),
      );
      final result = jsonDecode(response.body);
      return result['status'] == 'success';
    } catch (e) {
      print("Error register face: $e");
      return false;
    }
  }

  Future<bool> submitAttendance(List<double> embedding, double similarity) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: jsonEncode({
          'action': 'submitAttendance',
          'embedding': embedding,
          'similarity': similarity,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      final result = jsonDecode(response.body);
      return result['status'] == 'success';
    } catch (e) {
      print("Error submit attendance: $e");
      return false;
    }
  }
}
