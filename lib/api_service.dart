import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ApiService {
  // Switch this to your production URL when ready
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Keep the old GAS URL for reference
  // static const String gasUrl = 'https://script.google.com/macros/s/AKfycbwBN4DkmIy4slzlFd703utieZl1RGh8jhrEOkxZ4JbMvnEfH6hp-keA9MApQSahWidZoQ/exec';

  void _log(String method, Uri url, {String? requestBody, http.Response? response, Object? error}) {
    log('🚀 [API REQUEST] $method: $url');
    if (requestBody != null) log('📦 Body: $requestBody');
    if (response != null) {
      log('✅ [API RESPONSE] Status: ${response.statusCode}');
      log('📄 Content: ${response.body}');
    }
    if (error != null) log('❌ [API ERROR] $error');
    log('-----------------------------------');
  }

  // ==========================================
  // READ (GET) ENDPOINTS
  // ==========================================
  Future<Map<String, dynamic>> getDashboard({String? sekolah}) async {
    final s = sekolah != null ? '?sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl/dashboard$s');
    try {
      final response = await http.get(url);
      _log('GET', url, response: response);
      return jsonDecode(response.body);
    } catch (e) {
      _log('GET', url, error: e);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getGuru({String? sekolah}) async {
    final s = sekolah != null ? '?sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl/gurus$s');
    try {
      final response = await http.get(url);
      _log('GET', url, response: response);
      return jsonDecode(response.body);
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getSiswa({String? kelas, String? sekolah}) async {
    var params = [];
    if (kelas != null && kelas.isNotEmpty) params.add('kelas=${Uri.encodeComponent(kelas)}');
    if (sekolah != null) params.add('sekolah=${Uri.encodeComponent(sekolah)}');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final url = Uri.parse('$baseUrl/siswas$query');
    try {
      final response = await http.get(url);
      _log('GET', url, response: response);
      return jsonDecode(response.body);
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getMapel({String? sekolah}) async {
    final s = sekolah != null ? '?sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl/mapels$s');
    try {
      final response = await http.get(url);
      _log('GET', url, response: response);
      return jsonDecode(response.body);
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getSekolah() async {
    final url = Uri.parse('$baseUrl/sekolahs');
    try {
      final response = await http.get(url);
      _log('GET', url, response: response);
      return jsonDecode(response.body);
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getKelas({String? sekolah}) async {
    final s = sekolah != null ? '?sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl/kelas$s');
    try {
      final response = await http.get(url);
      _log('GET', url, response: response);
      return jsonDecode(response.body);
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getSiswaWajah({String? sekolah}) async {
    final s = sekolah != null ? '?sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl/faces/registered$s');
    try {
      final response = await http.get(url);
      _log('GET', url, response: response);
      return jsonDecode(response.body);
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getNilai(String mapel, {String? sekolah}) async {
    // Note: this might need adjustment if mapel is an ID or Name
    final s = sekolah != null ? '&sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl/nilais?mapel=${Uri.encodeComponent(mapel)}$s');
    try {
      final response = await http.get(url);
      _log('GET', url, response: response);
      return jsonDecode(response.body);
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getRekap(String bulan, {String? sekolah}) async {
    final s = sekolah != null ? '&sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl/attendance/rekap?bulan=${Uri.encodeComponent(bulan)}$s');
    try {
      final response = await http.get(url);
      _log('GET', url, response: response);
      return jsonDecode(response.body);
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  // ==========================================
  // CRUD OPERATIONS
  // ==========================================

  Future<Map<String, dynamic>> addGuru(String nama, String nip, String mapel, String sekolah) async {
    final url = Uri.parse('$baseUrl/gurus');
    final body = jsonEncode({'nama': nama, 'nip': nip, 'mapel': mapel, 'sekolah': sekolah});
    final response = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateGuru(String id, String nama, String nip, String mapel, String sekolah) async {
    final url = Uri.parse('$baseUrl/gurus/$id');
    final body = jsonEncode({'nama': nama, 'nip': nip, 'mapel': mapel, 'sekolah': sekolah});
    final response = await http.put(url, body: body, headers: {'Content-Type': 'application/json'});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteGuru(String id) async {
    final url = Uri.parse('$baseUrl/gurus/$id');
    final response = await http.delete(url);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> addSiswa(String nama, String nis, String jk, String kelas, String sekolah) async {
    final url = Uri.parse('$baseUrl/siswas');
    final body = jsonEncode({'nama': nama, 'nis': nis, 'jk': jk, 'kelas': kelas, 'sekolah': sekolah});
    final response = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateSiswa(String id, String nama, String nis, String jk, String kelas, String sekolah) async {
    final url = Uri.parse('$baseUrl/siswas/$id');
    final body = jsonEncode({'nama': nama, 'nis': nis, 'jk': jk, 'kelas': kelas, 'sekolah': sekolah});
    final response = await http.put(url, body: body, headers: {'Content-Type': 'application/json'});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteSiswa(String id) async {
    final url = Uri.parse('$baseUrl/siswas/$id');
    final response = await http.delete(url);
    return jsonDecode(response.body);
  }

  // Mapel, Sekolah, Nilai CRUD follow similar pattern...
  // For brevity, I'll implement only what's used in the UI screens we checked.

  Future<bool> registerFace(List<double> embedding, {String? id}) async {
    final url = Uri.parse('$baseUrl/faces/register');
    final body = jsonEncode({'nis': id, 'embedding': embedding});
    final response = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
    final result = jsonDecode(response.body);
    return result['status'] == 'success';
  }

  Future<bool> submitAttendance(List<double> embedding, double similarity, {String? name, String? sekolah}) async {
    // Note: name here is used as NIS in our new controller, or we need to resolve it.
    // Assuming 'name' contains NIS or we use a separate field.
    final url = Uri.parse('$baseUrl/attendance/submit');
    final body = jsonEncode({
      'nis': name, // In Laravel we prefer NIS
      'embedding': embedding,
      'similarity': similarity,
      'timestamp': DateTime.now().toIso8601String(),
    });
    final response = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
    final result = jsonDecode(response.body);
    return result['status'] == 'success';
  }
}
