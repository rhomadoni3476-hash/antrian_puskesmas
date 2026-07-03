import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonitorAntrianScreen extends StatelessWidget {
  const MonitorAntrianScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monitor Antrian Pasien")),
      // Menggunakan StreamBuilder agar data update otomatis saat ada antrian baru
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('antrian')
            .where('status', isEqualTo: 'Menunggu')
            .orderBy('waktu_daftar', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text("Belum ada antrian."));

          // Menampilkan nomor antrian teratas (yang sedang dipanggil)
          var current = docs.first;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Nomor yang Dipanggil:",
                style: TextStyle(fontSize: 24),
              ),
              Text(
                current['nomor_antrian'],
                style: const TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Dokter: ${current['dokter']}",
                style: const TextStyle(fontSize: 20),
              ),
              const Divider(),
              const Text("Antrian Berikutnya:", style: TextStyle(fontSize: 18)),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length > 1 ? docs.length - 1 : 0,
                  itemBuilder: (context, index) {
                    var next = docs[index + 1];
                    return ListTile(
                      title: Text("Nomor: ${next['nomor_antrian']}"),
                      subtitle: Text("Poli: ${next['poli']}"),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
