import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_dokter_screen.dart';

class LoginDokterScreen extends StatefulWidget {
  const LoginDokterScreen({super.key});

  @override
  State<LoginDokterScreen> createState() => _LoginDokterScreenState();
}

class _LoginDokterScreenState extends State<LoginDokterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginDokter() async {
    setState(() => _isLoading = true);
    try {
      // 1. Autentikasi Firebase
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Cek apakah user tersebut memiliki role 'dokter' di Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists && userDoc.get('role') == 'dokter') {
        if (!mounted) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const DashboardDokterScreen()));
      } else {
        // Jika bukan dokter, log out kembali
        await FirebaseAuth.instance.signOut();
        throw Exception("Akun ini tidak memiliki akses sebagai Dokter.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Gagal: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Dokter")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services,
                size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email Dokter")),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _loginDokter,
                    child: const Text("Masuk Dashboard Dokter")),
          ],
        ),
      ),
    );
  }
}
