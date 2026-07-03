import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqList = [
      {
        "question": "Bagaimana cara mendaftar antrian?",
        "answer":
            "Buka menu Beranda, klik tombol daftar antrian, isi keluhan Anda, lalu simpan. Bukti antrian akan muncul."
      },
      {
        "question": "Apakah saya bisa membatalkan antrian?",
        "answer":
            "Ya, Anda bisa menghubungi admin melalui fitur chat jika ingin melakukan pembatalan."
      },
      {
        "question": "Jam berapa operasional Puskesmas?",
        "answer":
            "Puskesmas buka setiap hari Senin - Jumat pukul 08:00 - 14:00 WIB."
      },
      {
        "question": "Bagaimana jika nomor antrian saya terlewat?",
        "answer":
            "Mohon segera konfirmasi ke petugas front office agar nomor Anda bisa dipanggil kembali setelah antrian saat ini selesai."
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pusat Bantuan / FAQ"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqList.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                faqList[index]["question"]!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(faqList[index]["answer"]!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
