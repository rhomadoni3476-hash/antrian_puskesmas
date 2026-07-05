import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'main.dart';
import 'config.dart';
import 'pasien_rekam_medis_screen.dart';

class ApiService {
  static const String baseUrl = AppConfig.baseUrl;
  static const Duration timeoutDuration = Duration(seconds: 20);

  /// Mendapatkan Header dengan Firebase ID Token
  static Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User tidak ditemukan. Silakan login kembali.");
    }

    try {
      final token = await user.getIdToken(true);
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      debugPrint("[API ERROR] Token Error: $e");
      rethrow;
    }
  }

  /// Menangani respons server secara seragam
  static Future<http.Response> _handleResponse(http.Response response) async {
    debugPrint(
        "[API DEBUG] Status: ${response.statusCode}, Body: ${response.body}");

    if (response.statusCode == 401) {
      await AuthService.logout();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
      throw Exception("Sesi Anda telah berakhir.");
    } else if (response.statusCode == 403) {
      // Menangkap error akses ditolak dari server (Role tidak cukup)
      throw Exception(
          "Akses ditolak: Anda tidak memiliki izin untuk melakukan aksi ini.");
    } else if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      String errorMsg;
      try {
        errorMsg = json.decode(response.body)['detail'] ??
            'Terjadi kesalahan pada server';
      } catch (_) {
        errorMsg = 'Server merespon dengan status: ${response.statusCode}';
      }
      throw Exception(errorMsg);
    }
  }

  // --- API OPERATIONS ---

  static Future<List<RekamMedisPasien>> getRiwayatMedis() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/rekam-medis-pasien'), headers: headers)
          .timeout(timeoutDuration);

      final res = await _handleResponse(response);
      final List<dynamic> body = json.decode(res.body);
      return body.map((item) => RekamMedisPasien.fromJson(item)).toList();
    } on TimeoutException {
      throw Exception("Koneksi ke server terlalu lama.");
    } on SocketException {
      throw Exception("Tidak dapat terhubung ke server.");
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<dynamic>> getRekamMedis() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/daftar-rekam-medis'), headers: headers)
          .timeout(timeoutDuration);
      final res = await _handleResponse(response);
      return json.decode(res.body);
    } catch (e) {
      rethrow;
    }
  }

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
      rethrow;
    }
  }

  static Future<bool> hapusRekamMedis(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/hapus-rekam-medis/$id'), headers: headers)
          .timeout(timeoutDuration);
      await _handleResponse(response);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> updateStatus(String id, String newStatus) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/update-status/$id'),
            headers: headers,
            body: json.encode({"status": newStatus}),
          )
          .timeout(timeoutDuration);
      await _handleResponse(response);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getSusStatistics() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/api/sus-statistics'), headers: headers)
          .timeout(timeoutDuration);
      final res = await _handleResponse(response);
      return json.decode(res.body);
    } catch (e) {
      rethrow;
    }
  }

  static Future<UserCredential> login(String email, String password) async {
    return await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password)
        .timeout(const Duration(seconds: 15));
  }
}
