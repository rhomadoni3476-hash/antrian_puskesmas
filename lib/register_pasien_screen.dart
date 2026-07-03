import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPasienScreen extends StatefulWidget {
  const RegisterPasienScreen({super.key});

  @override
  State<RegisterPasienScreen> createState() => _RegisterPasienScreenState();
}

class _RegisterPasienScreenState extends State<RegisterPasienScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _alamatController = TextEditingController();
  final _telpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    // 1. Validasi Input
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _namaController.text.isEmpty ||
        _nikController.text.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Mohon isi data dengan lengkap (NIK harus 16 digit)")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Buat user di Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Simpan profil lengkap ke Firestore dengan role default 'pasien'
      // dan createdAt agar Dashboard Admin bisa membaca tanggal daftar.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'nama': _namaController.text.trim(),
        'nik': _nikController.text.trim(),
        'alamat': _alamatController.text.trim(),
        'telepon': _telpController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'pasien', // PENTING: Role default untuk user baru
        'createdAt':
            FieldValue.serverTimestamp(), // PENTING: Untuk filter Admin
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Registrasi berhasil! Silakan login.")));
        Navigator.pop(context); // Kembali ke halaman Login
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? "Terjadi kesalahan";
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal Daftar: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1F0), Color(0xFFFFCDD2)],
          ),
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
                    const Text("Registrasi Pasien",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildTextField(
                        _namaController, "Nama Lengkap", Icons.person),
                    _buildTextField(_emailController, "Email", Icons.email),
                    _buildTextField(_passwordController, "Password", Icons.lock,
                        obscure: true),
                    _buildTextField(_nikController, "NIK (KTP)", Icons.badge,
                        isNumber: true),
                    _buildTextField(
                        _alamatController, "Alamat Lengkap", Icons.home),
                    _buildTextField(_telpController, "Nomor HP", Icons.phone,
                        isNumber: true),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton(
                              onPressed: _register,
                              style: FilledButton.styleFrom(
                                  backgroundColor: Colors.redAccent),
                              child: const Text("DAFTAR AKUN"),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool obscure = false, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}
