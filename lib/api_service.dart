import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbwBN4DkmIy4slzlFd703utieZl1RGh8jhrEOkxZ4JbMvnEfH6hp-keA9MApQSahWidZoQ/exec';

  void _log(
    String method,
    Uri url, {
    String? requestBody,
    http.Response? response,
    Object? error,
  }) {
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
  // CACHE SYSTEM
  // ==========================================
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  void clearCache() {
    _cache.clear();
    _cacheTime.clear();
    log('🧹 [CACHE] Cleared all cache');
  }

  Future<dynamic> _getCached(Uri url) async {
    final key = url.toString();
    if (_cache.containsKey(key)) {
      final cacheAge = DateTime.now().difference(_cacheTime[key]!);
      if (cacheAge < _cacheDuration) {
        log('⚡ [CACHE HIT] $key');
        return _cache[key];
      }
    }

    final response = await http.get(url);
    _log('GET', url, response: response);
    final decoded = jsonDecode(response.body);

    _cache[key] = decoded;
    _cacheTime[key] = DateTime.now();
    return decoded;
  }

  // ==========================================
  // GENERIC POST HELPER
  // ==========================================
  Future<Map<String, dynamic>> _postAction(Map<String, dynamic> body) async {
    // Clear cache on any modification
    clearCache();
    
    final url = Uri.parse(baseUrl);
    final encoded = jsonEncode(body);
    try {
      // Use http.Request to control redirect behavior
      final request = http.Request('POST', url)
        ..body = encoded
        ..headers['Content-Type'] = 'application/json'
        ..followRedirects = false;
      final streamedResponse = await request.send();

      // Google Apps Script returns 302 redirect — follow it with GET
      if (streamedResponse.statusCode == 302 ||
          streamedResponse.statusCode == 301) {
        final redirectUrl = streamedResponse.headers['location'];
        if (redirectUrl != null) {
          final getResponse = await http.get(Uri.parse(redirectUrl));
          _log(
            'POST→GET',
            Uri.parse(redirectUrl),
            requestBody: encoded,
            response: getResponse,
          );
          return jsonDecode(getResponse.body);
        }
      }

      final response = await http.Response.fromStream(streamedResponse);
      _log('POST', url, requestBody: encoded, response: response);
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        return {
          'status': 'error',
          'message': 'Format response tidak valid dari server'
        };
      }
    } catch (e) {
      _log('POST', url, requestBody: encoded, error: e);
      return {'status': 'error', 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // ==========================================
  // READ (GET) ENDPOINTS — filtered by sekolah
  // ==========================================
  Future<Map<String, dynamic>> getDashboard({String? sekolah}) async {
    final s = sekolah != null ? '&sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl?action=getDashboard$s');
    try {
      final decoded = await _getCached(url);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (e) {
      _log('GET', url, error: e);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getGuru({String? sekolah}) async {
    final s = sekolah != null ? '&sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl?action=getGuru$s');
    try {
      final decoded = await _getCached(url);
      return decoded is List ? decoded : [];
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getSiswa({String? kelas, String? sekolah}) async {
    var params = 'action=getSiswa';
    if (kelas != null && kelas.isNotEmpty) {
      params += '&kelas=${Uri.encodeComponent(kelas)}';
    }
    if (sekolah != null) {
      params += '&sekolah=${Uri.encodeComponent(sekolah)}';
    }
    final url = Uri.parse('$baseUrl?$params');
    try {
      final decoded = await _getCached(url);
      return decoded is List ? decoded : [];
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getMapel({String? sekolah}) async {
    final s = sekolah != null ? '&sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl?action=getMapel$s');
    try {
      final decoded = await _getCached(url);
      return decoded is List ? decoded : [];
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getSekolah() async {
    final url = Uri.parse('$baseUrl?action=getSekolah');
    try {
      final decoded = await _getCached(url);
      return decoded is List ? decoded : [];
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getKelas({String? sekolah}) async {
    final s = sekolah != null ? '&sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl?action=getKelas$s');
    try {
      final decoded = await _getCached(url);
      return decoded is List ? decoded : [];
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getSiswaWajah({String? sekolah}) async {
    final s = sekolah != null ? '&sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final url = Uri.parse('$baseUrl?action=getSiswaWajah$s');
    try {
      final decoded = await _getCached(url);
      return decoded is List ? decoded : [];
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getNilai(
    String mapel, {
    String? sekolah,
    String? tanggal,
    String? kelas,
  }) async {
    final s = sekolah != null ? '&sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final t = tanggal != null && tanggal.isNotEmpty
        ? '&tanggal=${Uri.encodeComponent(tanggal)}'
        : '';
    final k = kelas != null && kelas.isNotEmpty
        ? '&kelas=${Uri.encodeComponent(kelas)}'
        : '';
    final url = Uri.parse(
      '$baseUrl?action=getNilai&mapel=${Uri.encodeComponent(mapel)}$s$t$k',
    );
    try {
      final decoded = await _getCached(url);
      return decoded is List ? decoded : [];
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  Future<List<dynamic>> getRekap(
    String bulan, {
    String? sekolah,
    String? kelas,
  }) async {
    final s = sekolah != null ? '&sekolah=${Uri.encodeComponent(sekolah)}' : '';
    final k = kelas != null && kelas.isNotEmpty
        ? '&kelas=${Uri.encodeComponent(kelas)}'
        : '';
    final url = Uri.parse(
      '$baseUrl?action=getRekap&bulan=${Uri.encodeComponent(bulan)}$s$k',
    );
    try {
      final decoded = await _getCached(url);
      return decoded is List ? decoded : [];
    } catch (e) {
      _log('GET', url, error: e);
      return [];
    }
  }

  // ==========================================
  // GURU CRUD (with sekolah)
  // ==========================================
  Future<Map<String, dynamic>> addGuru(
    String nama,
    String nip,
    String mapel,
    String sekolah,
  ) => _postAction({
    'action': 'addGuru',
    'nama': nama,
    'nip': nip,
    'mapel': mapel,
    'sekolah': sekolah,
  });

  Future<Map<String, dynamic>> updateGuru(
    String rowKey,
    String nama,
    String nip,
    String mapel,
    String sekolah,
  ) => _postAction({
    'action': 'updateGuru',
    'rowKey': rowKey,
    'nama': nama,
    'nip': nip,
    'mapel': mapel,
    'sekolah': sekolah,
  });

  Future<Map<String, dynamic>> deleteGuru(String rowKey) =>
      _postAction({'action': 'deleteGuru', 'rowKey': rowKey});

  // ==========================================
  // SISWA CRUD (with sekolah)
  // ==========================================
  Future<Map<String, dynamic>> addSiswa(
    String nama,
    String nis,
    String jk,
    String kelas,
    String sekolah,
  ) => _postAction({
    'action': 'addSiswa',
    'nama': nama,
    'nis': nis,
    'jk': jk,
    'kelas': kelas,
    'sekolah': sekolah,
  });

  Future<Map<String, dynamic>> updateSiswa(
    String rowKey,
    String nama,
    String nis,
    String jk,
    String kelas,
    String sekolah,
  ) => _postAction({
    'action': 'updateSiswa',
    'rowKey': rowKey,
    'nama': nama,
    'nis': nis,
    'jk': jk,
    'kelas': kelas,
    'sekolah': sekolah,
  });

  Future<Map<String, dynamic>> deleteSiswa(String rowKey) =>
      _postAction({'action': 'deleteSiswa', 'rowKey': rowKey});

  // ==========================================
  // MAPEL CRUD (with sekolah assignment)
  // ==========================================
  Future<Map<String, dynamic>> addMapel(
    String nama,
    String kode,
    String sekolah,
  ) => _postAction({
    'action': 'addMapel',
    'nama': nama,
    'kode': kode,
    'sekolah': sekolah,
  });

  Future<Map<String, dynamic>> updateMapel(
    String oldNama,
    String nama,
    String kode,
    String sekolah,
  ) => _postAction({
    'action': 'updateMapel',
    'oldNama': oldNama,
    'nama': nama,
    'kode': kode,
    'sekolah': sekolah,
  });

  Future<Map<String, dynamic>> deleteMapel(String nama) =>
      _postAction({'action': 'deleteMapel', 'nama': nama});

  // ==========================================
  // SEKOLAH CRUD
  // ==========================================
  Future<Map<String, dynamic>> addSekolah(
    String nama,
    String alamat,
    String tingkat,
  ) => _postAction({
    'action': 'addSekolah',
    'nama': nama,
    'alamat': alamat,
    'tingkat': tingkat,
  });

  Future<Map<String, dynamic>> updateSekolah(
    String oldNama,
    String nama,
    String alamat,
    String tingkat,
  ) => _postAction({
    'action': 'updateSekolah',
    'oldNama': oldNama,
    'nama': nama,
    'alamat': alamat,
    'tingkat': tingkat,
  });

  Future<Map<String, dynamic>> deleteSekolah(String nama) =>
      _postAction({'action': 'deleteSekolah', 'nama': nama});

  // ==========================================
  // NILAI CRUD (with sekolah + tanggal)
  // ==========================================
  Future<Map<String, dynamic>> addNilai(
    String nama,
    String nis,
    String mapel,
    num nilai,
    String sekolah,
    String tanggal,
  ) => _postAction({
    'action': 'addNilai',
    'nama': nama,
    'nis': nis,
    'mapel': mapel,
    'nilai': nilai,
    'sekolah': sekolah,
    'tanggal': tanggal,
  });

  Future<Map<String, dynamic>> updateNilai(
    String rowKey,
    String nama,
    String nis,
    String mapel,
    num nilai,
    String sekolah,
    String tanggal,
  ) => _postAction({
    'action': 'updateNilai',
    'rowKey': rowKey,
    'nama': nama,
    'nis': nis,
    'mapel': mapel,
    'nilai': nilai,
    'sekolah': sekolah,
    'tanggal': tanggal,
  });

  Future<Map<String, dynamic>> deleteNilai(String rowKey) =>
      _postAction({'action': 'deleteNilai', 'rowKey': rowKey});

  // ==========================================
  // FACE & ATTENDANCE
  // ==========================================
  Future<bool> registerFace(List<double> embedding, {String? id}) async {
    final result = await _postAction({
      'action': 'registerFace',
      'embedding': embedding,
      'id': id,
    });
    return result['status'] == 'success';
  }

  Future<Map<String, dynamic>> submitAttendance(
    List<double> embedding,
    double similarity, {
    String? name,
    String? sekolah,
  }) async {
    final result = await _postAction({
      'action': 'submitAttendance',
      'embedding': embedding,
      'similarity': similarity,
      'nama': name ?? 'Unknown',
      'timestamp': DateTime.now().toIso8601String(),
      'sekolah': sekolah ?? '',
    });
    return result;
  }

  Future<Map<String, dynamic>> addManualAbsensi({
    required String nama,
    required String status,
    required String sekolah,
    required String tanggal,
  }) async {
    final result = await _postAction({
      'action': 'addManualAbsensi',
      'nama': nama,
      'status': status,
      'sekolah': sekolah,
      'tanggal': tanggal,
    });
    return result;
  }
}
