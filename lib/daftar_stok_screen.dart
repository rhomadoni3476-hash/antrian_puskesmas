import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DaftarStokScreen extends StatefulWidget {
  const DaftarStokScreen({super.key});

  @override
  State<DaftarStokScreen> createState() => _DaftarStokScreenState();
}

class _DaftarStokScreenState extends State<DaftarStokScreen> {
  bool _isAuthorized = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  // Fungsi pengecekan role di level halaman
  Future<void> _checkAccess() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() as Map<String, dynamic>?;

      // Hanya izinkan jika role adalah 'admin'
      if (data?['role'] == 'admin') {
        setState(() {
          _isAuthorized = true;
          _isChecking = false;
        });
      } else {
        // Jika bukan admin, tolak akses
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Akses ditolak: Anda bukan Admin."),
          backgroundColor: Colors.red,
        ));
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthorized)
      return const Scaffold(); // Return kosong jika tidak berwenang

    return Scaffold(
      appBar: AppBar(
          title: const Text("Stok Obat"), backgroundColor: Colors.red.shade700),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stok_obat').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          var obatList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: obatList.length,
            itemBuilder: (context, index) {
              var data = obatList[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['nama_obat']),
                subtitle: Text("Sisa: ${data['stok_tersedia']}"),
              );
            },
          );
        },
      ),
    );
  }
}
