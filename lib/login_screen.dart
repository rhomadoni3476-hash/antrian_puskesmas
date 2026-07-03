import 'package:flutter/material.dart';
import 'riwayat_screen.dart'; // Arahkan ke dashboard setelah login

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  void _login() {
    if (_userController.text == "admin" && _passController.text == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RiwayatScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Username atau Password salah!"),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services,
                size: 100, color: Colors.redAccent),
            const Text("PUSKESMAS DIGITAL",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
                controller: _userController,
                decoration: const InputDecoration(
                    labelText: "Username", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Password", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: _login,
                child:
                    const Text("LOGIN", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
