import 'package:flutter/material.dart';
import 'api_service.dart';

class AntrianProvider extends ChangeNotifier {
  List _daftarPasien = [];
  bool _isLoading = false;
  String? _errorMessage; // Menambahkan variabel pesan error

  List get daftarPasien => _daftarPasien;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 1. Ambil data dari FastAPI
  Future<void> fetchPasien() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _daftarPasien = await ApiService.getRekamMedis();
    } catch (e) {
      _errorMessage = "Gagal memuat data: $e";
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // 2. Update status antrian ke FastAPI
  Future<void> updateStatusAntrian(int id, String newStatus) async {
    try {
      // Memanggil fungsi update dari ApiService
      await ApiService.updateStatus(id, newStatus);

      debugPrint("Status ID $id berhasil diupdate ke $newStatus");

      // Refresh daftar setelah update agar UI sinkron
      await fetchPasien();
    } catch (e) {
      debugPrint("Error saat mengupdate status ke server: $e");
      // Anda bisa set _errorMessage di sini jika ingin ditampilkan ke user
    }
  }
}
