import 'package:flutter/material.dart';

class PrivacyProvider extends ChangeNotifier {
  bool _isPrivate = true; // Status privasi saat ini
  bool _isForceDisabled = false; // Flag untuk memaksa privasi mati

  bool get isPrivate => _isForceDisabled ? false : _isPrivate;
  bool get isForceDisabled => _isForceDisabled;

  // Toggle untuk user biasa (pasien/admin non-medis)
  void togglePrivacy() {
    if (_isForceDisabled) return; // Tidak bisa toggle jika dipaksa mati
    _isPrivate = !_isPrivate;
    notifyListeners();
  }

  // Fungsi untuk memaksa privasi mati (misal saat login sebagai Dokter)
  void setForceDisable(bool value) {
    _isForceDisabled = value;
    notifyListeners();
  }
}
