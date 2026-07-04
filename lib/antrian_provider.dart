import 'package:flutter/material.dart';
import 'api_service.dart';

class AntrianProvider extends ChangeNotifier {
  List _daftarPasien = [];
  bool _isLoading = false;
  String? _errorMessage;

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
      _errorMessage = "Gagal memuat data: ${e.toString()}";
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Update status antrian ke FastAPI
  // id diubah dari int menjadi String agar sesuai dengan Firestore Document ID
  Future<bool> updateStatusAntrian(String id, String newStatus) async {
    try {
      bool success = await ApiService.updateStatus(id, newStatus);

      if (success) {
        debugPrint("Status ID $id berhasil diupdate ke $newStatus");
        // Refresh daftar agar UI sinkron dengan database
        await fetchPasien();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = "Gagal update status: ${e.toString()}";
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  // 3. Menghapus antrian
  Future<bool> hapusAntrian(String id) async {
    try {
      bool success = await ApiService.hapusRekamMedis(id);
      if (success) {
        await fetchPasien();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = "Gagal menghapus data: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  // 4. Tambah antrian (opsional, jika Anda membutuhkannya)
  Future<bool> tambahAntrian(Map<String, dynamic> data) async {
    try {
      await ApiService.tambahRekamMedis(data);
      await fetchPasien();
      return true;
    } catch (e) {
      _errorMessage = "Gagal menambah data: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
