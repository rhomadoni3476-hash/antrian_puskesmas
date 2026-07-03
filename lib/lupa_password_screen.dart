import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LupaPasswordScreen extends StatefulWidget {
  const LupaPasswordScreen({super.key});

  @override
  State<LupaPasswordScreen> createState() => _LupaPasswordScreenState();
}

class _LupaPasswordScreenState extends State<LupaPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Masukkan email Anda")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Link reset password telah dikirim ke email Anda!"),
            backgroundColor: Colors.green));
        Navigator.pop(context); // Kembali ke halaman login
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? "Terjadi kesalahan")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
                "Masukkan email akun Anda untuk mendapatkan link reset password."),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: "Email", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text("Kirim Link Reset")),
          ],
        ),
      ),
    );
  }
}
