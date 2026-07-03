import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'privacy_provider.dart';

class RiwayatPasienScreen extends StatelessWidget {
  // Ganti ini dengan logika pengecekan role dokter Anda yang sebenarnya
  // Contoh: Anda bisa mengambil ini dari AuthService atau UserProvider
  final bool isDokter = true;

  const RiwayatPasienScreen({super.key});

  // Logika: Jika isDokter true, fungsi ini mengembalikan data asli tanpa masking
  String maskData(String data, bool isPrivate) {
    if (isDokter) return data; // Dokter selalu melihat data asli
    if (!isPrivate || data.length < 2) return data;
    return "${data.substring(0, 1)}****";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Kunjungan",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          // Jika dokter, kita bisa sembunyikan toggle privasi atau tetap tampilkan
          Consumer<PrivacyProvider>(
            builder: (context, privacy, _) => IconButton(
              icon: Icon(
                  privacy.isPrivate ? Icons.visibility_off : Icons.visibility),
              onPressed: () => privacy.togglePrivacy(),
              tooltip: "Toggle Privasi",
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1F0), Color(0xFFFFCDD2)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('riwayat')
              .orderBy('selesaiAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(child: Text("Error: ${snapshot.error}"));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Belum ada riwayat kunjungan."));
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final item = docs[index].data() as Map<String, dynamic>;

                return Consumer<PrivacyProvider>(
                  builder: (context, privacy, _) {
                    String nama =
                        maskData(item['nama'] ?? 'Pasien', privacy.isPrivate);
                    String keluhan =
                        maskData(item['keluhan'] ?? '-', privacy.isPrivate);
                    Timestamp? t = item['selesaiAt'] as Timestamp?;
                    String dateStr = t != null
                        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                            .format(t.toDate())
                        : "-";

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check_circle, color: Colors.white),
                        ),
                        title: Text(nama,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Keluhan: $keluhan"),
                            Text("Selesai: $dateStr",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _showDetailDialog(context, item, privacy.isPrivate),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showDetailDialog(
      BuildContext context, Map<String, dynamic> item, bool isPrivate) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detail Kunjungan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nama: ${maskData(item['nama'] ?? '-', isPrivate)}"),
            const Divider(),
            Text("Diagnosa: ${item['diagnosa'] ?? '-'}"),
            const SizedBox(height: 10),
            Text("Resep: ${item['resep'] ?? '-'}"),
            const SizedBox(height: 10),
            Text("Saran: ${item['saran'] ?? '-'}"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"))
        ],
      ),
    );
  }
}
