import 'package:flutter/material.dart';

class HasilAnalisisScreen extends StatelessWidget {
  final String namaPenyakit;
  final double skor;
  final VoidCallback onDaftarAntrian;

  const HasilAnalisisScreen({
    super.key,
    required this.namaPenyakit,
    required this.skor,
    required this.onDaftarAntrian,
  });

  @override
  Widget build(BuildContext context) {
    final persentase = (skor * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(title: const Text("Hasil Diagnosis")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medical_services,
                  size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text("Hasil Analisis:", style: TextStyle(fontSize: 18)),
              Text(
                namaPenyakit.toUpperCase(),
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text("Tingkat Keyakinan: $persentase%",
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 30),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.blue),
                  title: const Text("Saran",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "Berdasarkan analisis, disarankan segera melakukan pemeriksaan lanjut terkait $namaPenyakit."),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: onDaftarAntrian,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("DAFTAR ANTRIAN",
                    style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Kembali"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
