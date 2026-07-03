import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LogTransaksiScreen extends StatefulWidget {
  const LogTransaksiScreen({super.key});

  @override
  State<LogTransaksiScreen> createState() => _LogTransaksiScreenState();
}

class _LogTransaksiScreenState extends State<LogTransaksiScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  // Fungsi Keamanan: Memastikan hanya Admin yang bisa melihat log
  Future<void> _checkAdminAccess() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pop(context);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() as Map<String, dynamic>?;

    if (data?['role'] == 'admin') {
      if (mounted) setState(() => _isChecking = false);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            "Akses Ditolak: Hanya Admin yang dapat melihat log transaksi."),
        backgroundColor: Colors.red,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Log Transaksi Obat"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transaksi_obat')
            .orderBy('tanggal', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var logs = snapshot.data!.docs;

          if (logs.isEmpty) {
            return const Center(child: Text("Belum ada transaksi obat"));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              var data = logs[index].data() as Map<String, dynamic>;
              Timestamp ts = data['tanggal'] ?? Timestamp.now();
              String tanggal =
                  DateFormat('dd MMM yyyy, HH:mm').format(ts.toDate());
              String jenis = data['jenis_transaksi'] ?? 'KELUAR';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(
                    jenis == 'MASUK' ? Icons.add_circle : Icons.remove_circle,
                    color: jenis == 'MASUK' ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    data['nama_obat'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("${data['keterangan'] ?? ''}\n$tanggal"),
                  isThreeLine: true,
                  trailing: Text(
                    "${jenis == 'MASUK' ? '+' : '-'}${data['jumlah'] ?? 0}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: jenis == 'MASUK' ? Colors.green : Colors.red,
                    ),
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
