import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      // 1. Cek dukungan hardware
      final bool isDeviceSupported = await auth.isDeviceSupported();
      if (!isDeviceSupported) {
        print("Perangkat tidak mendukung biometrik.");
        return false;
      }

      // 2. Cek apakah ada biometrik yang terdaftar
      final List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        print("Tidak ada biometrik terdaftar di perangkat ini.");
        return false;
      }

      // 3. Lakukan otentikasi
      return await auth.authenticate(
        localizedReason: 'Gunakan biometrik untuk masuk',
        options: const AuthenticationOptions(
          biometricOnly:
              false, // false mengizinkan PIN/Pattern jika biometrik gagal
          stickyAuth: true,
          useErrorDialogs: true, // Akan menampilkan dialog sistem otomatis
        ),
      );
    } on PlatformException catch (e) {
      // Menangani error spesifik
      if (e.code == auth_error.notEnrolled) {
        print("Pengguna belum mendaftarkan biometrik.");
      } else if (e.code == auth_error.lockedOut) {
        print("Terlalu banyak percobaan, biometrik terkunci sementara.");
      } else {
        print("Error lain: ${e.message}");
      }
      return false;
    } catch (e) {
      print("Error tidak terduga: $e");
      return false;
    }
  }
}
