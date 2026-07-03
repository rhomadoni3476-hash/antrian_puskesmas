import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart'; // Import dashboard yang sudah kita buat

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _passwordController = TextEditingController();

  final String _adminPassword = "admin123";

  void _login() {
    if (_passwordController.text == _adminPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Password salah!"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Admin")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings,
                size: 100, color: Colors.redAccent),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true, // Menyembunyikan teks password
              decoration: const InputDecoration(
                labelText: "Masukkan Password Admin",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _login,
                style:
                    FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text("LOGIN"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
