import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'main.dart';
import 'config.dart';
// PENTING: Impor file tempat class RekamMedisPasien berada
// Jika berada di file lain, sesuaikan path-nya
import 'pasien_rekam_medis_screen.dart';

class ApiService {
  static const String baseUrl = AppConfig.baseUrl;
  static const Duration timeoutDuration = Duration(seconds: 15);

  static Future<Map<String, String>> _getHeaders() async {
    final headers = await AuthService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';
    headers['ngrok-skip-browser-warning'] = 'true';
    return headers;
  }

  static Future<String> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'ngrok-skip-browser-warning': 'true',
        },
        body: {
          'username': username,
          'password': password,
          'grant_type': 'password',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? "Login Gagal");
      }
    } catch (e) {
      debugPrint("Error Login: $e");
      rethrow;
    }
  }

  static Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await AuthService.logout();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
      throw Exception("Sesi berakhir, silakan login kembali.");
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // --- API OPERATIONS ---

  // Diperbaiki: Mengembalikan List<RekamMedisPasien> bukan List<dynamic>
  static Future<List<RekamMedisPasien>> getRiwayatMedis() async {
    final headers = await _getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/rekam-medis-pasien'), headers: headers)
        .timeout(timeoutDuration);

    final res = await _handleResponse(response);

    // Melakukan konversi dari dynamic ke model RekamMedisPasien
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

  static Future<bool> hapusRekamMedis(int id) async {
    final headers = await _getHeaders();
    final response = await http
        .delete(Uri.parse('$baseUrl/hapus-rekam-medis/$id'), headers: headers)
        .timeout(timeoutDuration);
    final res = await _handleResponse(response);
    return res.statusCode == 200;
  }

  static Future<bool> updateStatus(int id, String status) async {
    final headers = await _getHeaders();
    final response = await http
        .put(
          Uri.parse('$baseUrl/update-status/$id'),
          headers: headers,
          body: json.encode({"status": status}),
        )
        .timeout(timeoutDuration);
    final res = await _handleResponse(response);
    return res.statusCode == 200;
  }
}
