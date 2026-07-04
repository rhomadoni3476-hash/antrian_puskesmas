import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'main.dart';
import 'config.dart';
import 'pasien_rekam_medis_screen.dart';

class ApiService {
  static const String baseUrl = AppConfig.baseUrl;
  static const Duration timeoutDuration = Duration(seconds: 15);

  /// Mendapatkan Header dengan Firebase ID Token
  static Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    // Mengambil token terbaru, memberikan string kosong jika user null (tapi harusnya dicek di level UI)
    final token = await user?.getIdToken() ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fungsi Login menggunakan Firebase Auth SDK
  static Future<UserCredential> login(String email, String password) async {
    try {
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint("Error Firebase Login: $e");
      rethrow;
    }
  }

  static Future<http.Response> _handleResponse(http.Response response) async {
    // 401 Unauthorized berarti token kadaluwarsa atau tidak valid
    if (response.statusCode == 401) {
      await AuthService.logout();
      // Menggunakan navigatorKey untuk navigasi global tanpa context
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
      throw Exception("Sesi berakhir, silakan login kembali.");
    }

    // Status 200-299 dianggap berhasil
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      debugPrint("Server Error: ${response.statusCode} - ${response.body}");
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // --- API OPERATIONS ---

  // 1. Mengambil Riwayat Medis Spesifik (GET)
  static Future<List<RekamMedisPasien>> getRiwayatMedis() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/rekam-medis-pasien'), headers: headers)
          .timeout(timeoutDuration);

      final res = await _handleResponse(response);
      final List<dynamic> body = json.decode(res.body);
      return body.map((item) => RekamMedisPasien.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Error getRiwayatMedis: $e");
      rethrow;
    }
  }

  // 2. Mengambil daftar rekam medis (GET)
  static Future<List<dynamic>> getRekamMedis() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/daftar-rekam-medis'), headers: headers)
          .timeout(timeoutDuration);
      final res = await _handleResponse(response);
      return json.decode(res.body);
    } catch (e) {
      debugPrint("Error getRekamMedis: $e");
      rethrow;
    }
  }

  // 3. Menambah rekam medis (POST)
  static Future<Map<String, dynamic>> tambahRekamMedis(
      Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse('$baseUrl/tambah-rekam-medis'),
              headers: headers, body: json.encode(data))
          .timeout(timeoutDuration);
      final res = await _handleResponse(response);
      return json.decode(res.body);
    } catch (e) {
      debugPrint("Error tambahRekamMedis: $e");
      rethrow;
    }
  }

  // 4. Menghapus rekam medis (DELETE)
  static Future<bool> hapusRekamMedis(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/hapus-rekam-medis/$id'), headers: headers)
          .timeout(timeoutDuration);
      final res = await _handleResponse(response);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Error hapusRekamMedis: $e");
      rethrow;
    }
  }

  // 5. Mengupdate status rekam medis (PUT)
  static Future<bool> updateStatus(String id, String newStatus) async {
    try {
      final headers = await _getHeaders();
      // Mengirimkan JSON dengan key "status" sesuai dengan model UpdateStatusRequest di FastAPI
      final response = await http
          .put(
            Uri.parse('$baseUrl/update-status/$id'),
            headers: headers,
            body: json.encode({"status": newStatus}),
          )
          .timeout(timeoutDuration);
      final res = await _handleResponse(response);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Error updateStatus: $e");
      rethrow;
    }
  }

  // 6. Mendapatkan statistik SUS (GET)
  static Future<Map<String, dynamic>> getSusStatistics() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/api/sus-statistics'), headers: headers)
          .timeout(timeoutDuration);
      final res = await _handleResponse(response);
      return json.decode(res.body);
    } catch (e) {
      debugPrint("Error getSusStatistics: $e");
      rethrow;
    }
  }
}
