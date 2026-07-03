import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminKonsultasiScreen extends StatefulWidget {
  const AdminKonsultasiScreen({super.key});

  @override
  State<AdminKonsultasiScreen> createState() => _AdminKonsultasiScreenState();
}

class _AdminKonsultasiScreenState extends State<AdminKonsultasiScreen> {
  final TextEditingController _replyController = TextEditingController();

  void _balasPesan(String docId) {
    _replyController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Balas Konsultasi"),
        content: TextField(
          controller: _replyController,
          decoration: const InputDecoration(
            hintText: "Tuliskan diagnosa atau saran medis...",
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          FilledButton(
            onPressed: () async {
              if (_replyController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('chat_konsultasi')
                    .doc(docId)
                    .update({
                  'jawabanDokter': _replyController.text,
                  'status': "Selesai",
                  'tanggalBalas': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Kirim Balasan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Dashboard Konsultasi"),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: "Menunggu"),
              Tab(icon: Icon(Icons.check_circle), text: "Selesai"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList("Menunggu"),
            _buildList("Selesai"),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_konsultasi')
          .where('status', isEqualTo: status)
          .orderBy('tanggalKirim', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text("Tidak ada pesan dengan status $status"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final timestamp = data['tanggalKirim'] as Timestamp?;
            final dateStr = timestamp != null
                ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
                : "";

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: ListTile(
                title: Text(data['namaPasien'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Keluhan: ${data['pertanyaan']}"),
                    const SizedBox(height: 5),
                    Text(dateStr,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                trailing: status == "Menunggu"
                    ? IconButton(
                        icon: const Icon(Icons.reply, color: Colors.blueAccent),
                        onPressed: () => _balasPesan(docs[index].id),
                      )
                    : const Icon(Icons.check, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }
}
