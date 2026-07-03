import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LaporanDashboardScreen extends StatelessWidget {
  const LaporanDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Laporan & Statistik"),
          backgroundColor: Colors.indigo.shade700),
      body: FutureBuilder<List<int>>(
        future: _hitungData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final totalPasien = snapshot.data![0];
          final totalTransaksi = snapshot.data![1];
          final stokTipis = snapshot.data![2];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatCard("Total Pasien Dilayani", "$totalPasien",
                  Icons.people, Colors.blue),
              _buildStatCard("Total Mutasi Obat", "$totalTransaksi",
                  Icons.sync_alt, Colors.orange),
              _buildStatCard(
                  "Obat Stok Tipis", "$stokTipis", Icons.warning, Colors.red),
            ],
          );
        },
      ),
    );
  }

  // Logika sederhana mengambil jumlah dokumen dari Firestore
  Future<List<int>> _hitungData() async {
    var p = await FirebaseFirestore.instance.collection('riwayat').get();
    var t = await FirebaseFirestore.instance.collection('transaksi_obat').get();
    var s = await FirebaseFirestore.instance
        .collection('stok_obat')
        .where('stok_tersedia', isLessThanOrEqualTo: 5)
        .get();
    return [p.docs.length, t.docs.length, s.docs.length];
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
