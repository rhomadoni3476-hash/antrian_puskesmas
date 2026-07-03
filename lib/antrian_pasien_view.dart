import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AntrianPasienView extends StatelessWidget {
  const AntrianPasienView({super.key});

  int _hitungEstimasiWaktu(int posisi) => posisi * 10;

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
          body: Center(child: Text("Silakan login terlebih dahulu")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Status Antrian Saya")),
      // Kita ambil antrian terbaru milik user, tanpa memfilter status agar data selalu muncul
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('antrian')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("Anda tidak memiliki data antrian."));
          }

          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Menunggu';

          // Logika estimasi:
          // Jika status sudah selesai, kita tidak perlu tampilkan estimasi waktu
          final bool isWaiting = status == 'Menunggu';

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor(status)),
                ),
                child: Column(
                  children: [
                    Text("STATUS ANTRIAN",
                        style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(status.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w900)),
                    if (isWaiting) ...[
                      const Divider(height: 30),
                      const Text(
                        "Sedang dalam antrian...",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Pantau terus status kunjungan Anda di sini.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              )
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Selesai') return Colors.green;
    if (status == 'Sedang Diperiksa') return Colors.orange;
    return Colors.blue;
  }
}
