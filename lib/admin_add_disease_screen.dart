import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _updateStatus(
      BuildContext context, String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('antrian').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Status diubah ke $newStatus")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sedang Diperiksa':
        return Colors.orange;
      case 'Selesai':
        return Colors.green;
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Dashboard Admin"),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('antrian')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final todayDocs = docs.where((doc) {
            final date = (doc['createdAt'] as Timestamp).toDate();
            return DateFormat('yyyy-MM-dd').format(date) == today;
          }).toList();

          Map<String, int> poliCount = {};
          for (var doc in todayDocs) {
            String poli = doc['poli'] ?? 'Umum';
            poliCount[poli] = (poliCount[poli] ?? 0) + 1;
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Header Statistik
              Card(
                color: Colors.redAccent,
                child: ListTile(
                  title: const Text("Total Pasien Hari Ini",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: Text("${todayDocs.length}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),
              const Text(" Distribusi Pasien per Poli",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: poliCount.entries
                        .map((e) => PieChartSectionData(
                              value: e.value.toDouble(),
                              title: "${e.key}\n(${e.value})",
                              color: Colors.primaries[
                                  poliCount.keys.toList().indexOf(e.key) %
                                      Colors.primaries.length],
                            ))
                        .toList(),
                  ),
                ),
              ),

              const Divider(height: 40),
              ...todayDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: _getStatusColor(data['status']),
                        child: Text(data['nomor_antrian'][0])),
                    title: Text(data['nama'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${data['poli']} • ${data['keluhan']}"),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) => _updateStatus(context, doc.id, val),
                      itemBuilder: (context) => [
                        'Menunggu',
                        'Sedang Diperiksa',
                        'Selesai'
                      ]
                          .map((s) => PopupMenuItem(value: s, child: Text(s)))
                          .toList(),
                      child: Chip(
                          label: Text(data['status'],
                              style: const TextStyle(fontSize: 10)),
                          backgroundColor: Colors.grey[200]),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
