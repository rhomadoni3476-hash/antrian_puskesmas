// welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login_pasien_screen.dart';
import 'register_pasien_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF1F0), Color(0xFFFFCDD2)]),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animasi_utama.json', height: 250),
            const Text("PUSKESMAS DIGITAL",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent)),
            const Text("Melayani dengan Hati",
                style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 50),
            FilledButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginPasienScreen())),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text("LOGIN"),
            ),
            const SizedBox(height: 15),
            OutlinedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RegisterPasienScreen())),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text("DAFTAR",
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
