import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final List<String> gejala;
  final String poli;

  const ResultScreen({super.key, required this.gejala, required this.poli});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hasil Analisis")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gejala Anda:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(gejala.join(", ")),
            const SizedBox(height: 20),
            Text("Saran Tindakan: Segera ke $poli",
                style: const TextStyle(fontSize: 18, color: Colors.redAccent)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Logika pindah ke halaman antrean
                Navigator.popUntil(context, (route) => route.isFirst);
                // Tambahkan kode untuk pindah ke tab/halaman antrean di sini
              },
              child: const Text("Daftar Antrean Sekarang"),
            )
          ],
        ),
      ),
    );
  }
}
