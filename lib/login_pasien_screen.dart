import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'register_pasien_screen.dart';
import 'lupa_password_screen.dart';
import 'api_service.dart';
import 'auth_service.dart';

class LoginPasienScreen extends StatefulWidget {
  const LoginPasienScreen({super.key});

  @override
  State<LoginPasienScreen> createState() => _LoginPasienScreenState();
}

class _LoginPasienScreenState extends State<LoginPasienScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final LocalAuthentication _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Email & Password harus diisi", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Auth menangani autentikasi
      UserCredential userCredential = await ApiService.login(email, password);
      User? user = userCredential.user;

      // 2. Gunakan pengecekan null yang aman
      if (user != null) {
        // getIdToken mengembalikan String?, kita pastikan tidak null sebelum disimpan
        String? token = await user.getIdToken(true);

        if (token != null) {
          await AuthService.saveToken(token);
          await _storage.write(key: 'user_email', value: email);
          await _storage.write(key: 'user_password', value: password);

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          }
        } else {
          throw Exception("Token autentikasi gagal dihasilkan.");
        }
      }
    } on FirebaseAuthException catch (e) {
      _showMessage("Auth Error: ${e.message}", Colors.red);
    } catch (e) {
      _showMessage("Login Gagal: Periksa koneksi Anda", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _authenticateBiometric() async {
    if (kIsWeb) return;

    String? email = await _storage.read(key: 'user_email');
    String? password = await _storage.read(key: 'user_password');

    if (email == null || password == null) {
      _showMessage(
          "Login manual sekali untuk mengaktifkan biometrik", Colors.orange);
      return;
    }

    try {
      bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Gunakan sidik jari/wajah untuk login',
        options:
            const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );

      if (didAuthenticate) {
        setState(() => _isLoading = true);
        UserCredential userCredential = await ApiService.login(email, password);
        User? user = userCredential.user;

        if (user != null) {
          String? token = await user.getIdToken(true);
          if (token != null) {
            await AuthService.saveToken(token);
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
            }
          }
        }
      }
    } catch (e) {
      _showMessage("Biometrik gagal/dibatalkan", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF1F0), Color(0xFFFFCDD2)]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Icon(Icons.medical_services,
                        size: 80, color: Colors.redAccent),
                    const SizedBox(height: 20),
                    const Text("Login Pasien",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email))),
                    const SizedBox(height: 15),
                    TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock))),
                    if (!kIsWeb) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                          onPressed: _authenticateBiometric,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text("Login dengan Biometrik")),
                    ],
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const LupaPasswordScreen())),
                            child: const Text("Lupa Password?"))),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _login,
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("LOGIN",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterPasienScreen())),
                        child: const Text("Belum punya akun? Daftar")),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
