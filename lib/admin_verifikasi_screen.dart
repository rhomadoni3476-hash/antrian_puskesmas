import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminVerifikasiScreen extends StatelessWidget {
  const AdminVerifikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verifikasi Pasien")),
      body: StreamBuilder<QuerySnapshot>(
        // Hanya ambil user yang belum diverifikasi
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'pasien')
            .where('isVerified', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("Tidak ada pasien menunggu verifikasi"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var user = snapshot.data!.docs[index];
              return ListTile(
                title: Text(user['nama']),
                subtitle: Text("Status: Belum Verifikasi"),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _verifikasiPasien(user.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Fungsi Logic Verifikasi
  Future<void> _verifikasiPasien(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isVerified': true,
    });
  }
}
