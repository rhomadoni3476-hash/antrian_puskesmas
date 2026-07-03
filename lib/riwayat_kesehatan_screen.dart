import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RiwayatKesehatanScreen extends StatelessWidget {
  const RiwayatKesehatanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Kesehatan")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('health_records')
            .doc(user!.uid)
            .collection('logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada riwayat kesehatan."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final dateString = timestamp != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp)
                  : "Tanggal tidak tersedia";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text("Tekanan: ${data['tekananDarah']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Gula Darah: ${data['gulaDarah']} | BB: ${data['beratBadan']} kg"),
                      Text("Catatan: ${data['catatan']}",
                          style: const TextStyle(fontStyle: FontStyle.italic)),
                      const SizedBox(height: 5),
                      Text(dateString,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
