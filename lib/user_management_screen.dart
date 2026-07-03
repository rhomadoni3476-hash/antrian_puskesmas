import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  Future<void> _updateRole(
      BuildContext context, String uid, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': newRole,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Role berhasil diubah menjadi $newRole")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengubah role")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi role yang diizinkan agar tidak crash
    final List<String> allowedRoles = ['pasien', 'admin', 'dokter'];

    return Scaffold(
      appBar: AppBar(title: const Text("Manajemen User")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;
              final uid = doc.id;

              // Validasi role: jika role di DB tidak ada di allowedRoles, paksa ke 'pasien'
              String currentRole = data['role'] ?? 'pasien';
              if (!allowedRoles.contains(currentRole)) {
                currentRole = 'pasien';
              }

              final Timestamp? createdAt = data['createdAt'] as Timestamp?;
              final String formattedDate = createdAt != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())
                  : "N/A";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(data['nama'] ?? 'Tanpa Nama',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "Email: ${data['email'] ?? '-'}\nDaftar: $formattedDate"),
                  isThreeLine: true,
                  trailing: DropdownButton<String>(
                    value:
                        currentRole, // Menggunakan variabel yang sudah tervalidasi
                    items: allowedRoles.map((role) {
                      return DropdownMenuItem(
                          value: role, child: Text(role.toUpperCase()));
                    }).toList(),
                    onChanged: (newRole) {
                      if (newRole != null) _updateRole(context, uid, newRole);
                    },
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
