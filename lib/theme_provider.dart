import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // Key konstan untuk menghindari kesalahan pengetikan
  static const String _themeKey = 'isDarkMode';

  bool _isDarkMode = false;

  // Getter untuk mengakses status tema
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  /// Toggle tema dan simpan ke SharedPreferences
  void toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      notifyListeners(); // Update UI segera setelah toggle

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      debugPrint("Gagal menyimpan preferensi tema: $e");
    }
  }

  /// Memuat status tema dari penyimpanan lokal saat aplikasi dimulai
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners(); // Beritahu UI jika tema berubah dari default
    } catch (e) {
      debugPrint("Gagal memuat preferensi tema: $e");
      // Default ke false jika terjadi error
      _isDarkMode = false;
    }
  }
}
