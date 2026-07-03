import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DaftarDaruratScreen extends StatelessWidget {
  const DaftarDaruratScreen({super.key});

  // Fungsi untuk menyelesaikan status darurat
  Future<void> _selesaikanBantuan(BuildContext context, String docId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text(
            "Apakah bantuan sudah diberikan dan masalah darurat selesai?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Selesai", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('darurat')
          .doc(docId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Laporan darurat diselesaikan.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Panggilan Darurat"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('darurat')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
                child: Text("Tidak ada laporan darurat saat ini."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child:
                        Icon(Icons.warning_amber_rounded, color: Colors.white),
                  ),
                  title: Text(data['nama'] ?? "Pasien Anonim",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${data['status']}"),
                      Text(
                          "Waktu: ${timestamp != null ? DateFormat('HH:mm, dd MMM yyyy').format(timestamp) : '-'}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle,
                        color: Colors.green, size: 30),
                    onPressed: () =>
                        _selesaikanBantuan(context, docs[index].id),
                    tooltip: "Tandai Selesai",
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
