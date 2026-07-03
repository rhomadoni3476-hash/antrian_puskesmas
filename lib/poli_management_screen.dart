import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PoliManagementScreen extends StatelessWidget {
  const PoliManagementScreen({super.key});

  // Fungsi untuk menambah poli baru
  Future<void> _showAddPoliDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Poli Baru"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nama Poli"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('poli').add({
                  'nama_poli': controller.text,
                  'status': 'buka',
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manajemen Data Poli"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('poli').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                child: SwitchListTile(
                  title: Text(data['nama_poli'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Status: ${data['status'].toUpperCase()}"),
                  value: data['status'] == 'buka',
                  activeColor: Colors.green,
                  onChanged: (val) {
                    FirebaseFirestore.instance
                        .collection('poli')
                        .doc(doc.id)
                        .update({'status': val ? 'buka' : 'tutup'});
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () => _showAddPoliDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
