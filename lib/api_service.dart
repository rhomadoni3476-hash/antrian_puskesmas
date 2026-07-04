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

  /// Mendapatkan Header dengan Firebase ID Token yang valid
  static Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("[API DEBUG] User tidak terautentikasi (Null)");
      throw Exception("User tidak ditemukan. Silakan login kembali.");
    }

    try {
      // Force refresh token untuk memastikan token tidak kedaluwarsa di sisi backend
      final token = await user.getIdToken(true);

      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      debugPrint("[API DEBUG] Gagal mendapatkan/refresh token: $e");
      rethrow;
    }
  }

  /// Menangani respons server secara seragam
  static Future<http.Response> _handleResponse(http.Response response) async {
    debugPrint(
        "[API DEBUG] Status Code: ${response.statusCode} | Body: ${response.body}");

    if (response.statusCode == 401) {
      debugPrint(
          "[API DEBUG] 401 Unauthorized: Token tidak valid atau kedaluwarsa.");
      await AuthService.logout();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
      throw Exception("Sesi berakhir, silakan login kembali.");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      throw Exception(
          'Server error (${response.statusCode}): ${response.body}');
    }
  }

  // --- API OPERATIONS ---

  static Future<List<RekamMedisPasien>> getRiwayatMedis() async {
    final headers = await _getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/rekam-medis-pasien'), headers: headers)
        .timeout(timeoutDuration);

    final res = await _handleResponse(response);
    final List<dynamic> body = json.decode(res.body);
    return body.map((item) => RekamMedisPasien.fromJson(item)).toList();
  }

  static Future<List<dynamic>> getRekamMedis() async {
    final headers = await _getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/daftar-rekam-medis'), headers: headers)
        .timeout(timeoutDuration);
    final res = await _handleResponse(response);
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> tambahRekamMedis(
      Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http
        .post(Uri.parse('$baseUrl/tambah-rekam-medis'),
            headers: headers, body: json.encode(data))
        .timeout(timeoutDuration);
    final res = await _handleResponse(response);
    return json.decode(res.body);
  }

  static Future<bool> hapusRekamMedis(String id) async {
    final headers = await _getHeaders();
    final response = await http
        .delete(Uri.parse('$baseUrl/hapus-rekam-medis/$id'), headers: headers)
        .timeout(timeoutDuration);
    final res = await _handleResponse(response);
    return res.statusCode == 200;
  }

  static Future<bool> updateStatus(String id, String newStatus) async {
    final headers = await _getHeaders();
    final response = await http
        .put(
          Uri.parse('$baseUrl/update-status/$id'),
          headers: headers,
          body: json.encode({"status": newStatus}),
        )
        .timeout(timeoutDuration);
    final res = await _handleResponse(response);
    return res.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getSusStatistics() async {
    final headers = await _getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/api/sus-statistics'), headers: headers)
        .timeout(timeoutDuration);
    final res = await _handleResponse(response);
    return json.decode(res.body);
  }

  /// Login menggunakan Firebase Auth SDK (Tidak melalui backend)
  static Future<UserCredential> login(String email, String password) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
