import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatAntrianScreen extends StatelessWidget {
  const RiwayatAntrianScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Riwayat Antrian",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Sesuaikan collection dengan database Anda
        stream: FirebaseFirestore.instance
            .collection('riwayat_diagnosis')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.redAccent));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text("Belum ada riwayat",
                    style: GoogleFonts.poppins(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    child: const Icon(Icons.history, color: Colors.redAccent),
                  ),
                  title: Text(data['poli'] ?? 'Poli Umum',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['keluhan'] ?? '-',
                          style: GoogleFonts.poppins(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("Status: ${data['status']}",
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  trailing: Text(data['nomor_antrian'] ?? '-',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
