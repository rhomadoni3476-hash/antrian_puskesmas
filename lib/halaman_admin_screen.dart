import 'package:flutter/material.dart';

class HalamanAdminScreen extends StatefulWidget {
  const HalamanAdminScreen({super.key});

  @override
  State<HalamanAdminScreen> createState() => _HalamanAdminScreenState();
}

class _HalamanAdminScreenState extends State<HalamanAdminScreen> {
  String _antrianSekarang = "Belum Ada";

  void _panggilBerikutnya() {
    setState(() {
      _antrianSekarang = "A-002";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel Petugas Loket")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Antrian Saat Ini:", style: TextStyle(fontSize: 20)),
            Text(
              _antrianSekarang,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _panggilBerikutnya,
              child: const Text("Panggil Berikutnya"),
            ),
          ],
        ),
      ),
    );
  }
}
