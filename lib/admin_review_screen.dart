import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReviewScreen extends StatelessWidget {
  const AdminReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Ulasan Pasien"),
          backgroundColor: Colors.redAccent),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final reviews = snapshot.data!.docs;
          if (reviews.isEmpty)
            return const Center(child: Text("Belum ada ulasan."));

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(child: Text("${data['rating']}")),
                  title: Text(data['nama_pasien'] ?? 'Anonim'),
                  subtitle: Text(data['komentar'] ?? '-'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
