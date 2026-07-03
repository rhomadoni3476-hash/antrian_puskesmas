import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Tambahkan dependensi: jwt_decoder

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Mengecek apakah user login dan apakah token masih valid (belum expired)
  static Future<bool> isLoggedIn() async {
    String? token = await getToken();
    if (token == null || token.isEmpty) return false;

    // Cek apakah token sudah expired menggunakan jwt_decoder
    bool isExpired = JwtDecoder.isExpired(token);
    if (isExpired) {
      await logout(); // Hapus token jika sudah expired
      return false;
    }
    return true;
  }

  static Future<void> logout() async {
    await _storage.deleteAll(); // Menghapus semua data yang tersimpan
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    String? token = await getToken();

    final headers = {"Content-Type": "application/json"};
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  /// Tambahan: Mendapatkan data dari klaim token (misal: username/role)
  static Future<Map<String, dynamic>?> getUserData() async {
    String? token = await getToken();
    if (token == null) return null;
    return JwtDecoder.decode(token);
  }
}
