import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard_screen.dart';

class LoginAdminScreen extends StatefulWidget {
  const LoginAdminScreen({super.key});

  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends State<LoginAdminScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradasi yang selaras dengan seluruh aplikasi
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        size: 80, color: Colors.redAccent),
                    const SizedBox(height: 20),
                    const Text("Login Admin",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent)),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          labelText: "Email Admin",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email)),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock)),
                      obscureText: true,
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _login,
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        child:
                            const Text("LOGIN", style: TextStyle(fontSize: 16)),
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
}
