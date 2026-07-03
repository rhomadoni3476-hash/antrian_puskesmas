import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RingkasanRiwayatScreen extends StatelessWidget {
  const RingkasanRiwayatScreen({super.key});

  // Fungsi untuk Generate PDF
  Future<void> _generatePdf(BuildContext context, Map<String, dynamic>? profil,
      List<QueryDocumentSnapshot> riwayat) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                  child: pw.Text("LAPORAN REKAM MEDIS DIGITAL",
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 20),
              pw.Text("INFORMASI PROFIL KESEHATAN",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text("Golongan Darah : ${profil?['golonganDarah'] ?? '-'}"),
              pw.Text("Alergi         : ${profil?['alergi'] ?? '-'}"),
              pw.Text("Penyakit Kronis: ${profil?['penyakitKronis'] ?? '-'}"),
              pw.SizedBox(height: 30),
              pw.Text("RIWAYAT DIAGNOSIS",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              ...riwayat.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                String tgl = data['tanggal'] != null
                    ? DateFormat('dd MMM yyyy')
                        .format((data['tanggal'] as Timestamp).toDate())
                    : '-';
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Text(
                      "• ${data['penyakit'] ?? 'Diagnosis'} | Tgl: $tgl"),
                );
              }),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Rekam Medis Digital"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('profil_kesehatan')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.hasData
                  ? snapshot.data!.data() as Map<String, dynamic>?
                  : null;
              return _buildInfoVital(context, data);
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('riwayat_diagnosis')
                  .where('userId', isEqualTo: userId)
                  .orderBy('tanggal', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada riwayat medis."));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final tgl = (data['tanggal'] as Timestamp?)?.toDate() ??
                        DateTime.now();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ExpansionTile(
                        leading:
                            const Icon(Icons.history, color: Colors.redAccent),
                        title: Text(data['penyakit'] ?? 'Diagnosis',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(tgl)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                Text("Akurasi: ${data['keyakinan'] ?? '-'}"),
                                const SizedBox(height: 8),
                                const Text(
                                    "Catatan: Tetap jaga pola makan dan istirahat."),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Ambil data terbaru untuk PDF
          final profilSnap = await FirebaseFirestore.instance
              .collection('profil_kesehatan')
              .doc(userId)
              .get();
          final riwayatSnap = await FirebaseFirestore.instance
              .collection('riwayat_diagnosis')
              .where('userId', isEqualTo: userId)
              .orderBy('tanggal', descending: true)
              .get();
          if (context.mounted) {
            await _generatePdf(context,
                profilSnap.data() as Map<String, dynamic>?, riwayatSnap.docs);
          }
        },
        label: const Text("Unduh PDF"),
        icon: const Icon(Icons.picture_as_pdf),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildInfoVital(BuildContext context, Map<String, dynamic>? data) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Colors.redAccent, Colors.orangeAccent]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Info Vital",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _showEditDialog(context, data),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoItem(
                  label: "Gol. Darah", value: data?['golonganDarah'] ?? '-'),
              _InfoItem(label: "Alergi", value: data?['alergi'] ?? '-'),
              _InfoItem(
                  label: "Penyakit", value: data?['penyakitKronis'] ?? '-'),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic>? data) {
    final golController =
        TextEditingController(text: data?['golonganDarah'] ?? '');
    final alergiController = TextEditingController(text: data?['alergi'] ?? '');
    final penyakitController =
        TextEditingController(text: data?['penyakitKronis'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isLoading = false;
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Edit Info Kesehatan",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextField(
                    controller: golController,
                    decoration:
                        const InputDecoration(labelText: "Golongan Darah")),
                TextField(
                    controller: alergiController,
                    decoration: const InputDecoration(labelText: "Alergi")),
                TextField(
                    controller: penyakitController,
                    decoration:
                        const InputDecoration(labelText: "Penyakit Kronis")),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setModalState(() => isLoading = true);
                            try {
                              await FirebaseFirestore.instance
                                  .collection('profil_kesehatan')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .set({
                                'golonganDarah': golController.text.trim(),
                                'alergi': alergiController.text.trim(),
                                'penyakitKronis':
                                    penyakitController.text.trim(),
                                'updatedAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              setModalState(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Gagal menyimpan data")));
                            }
                          },
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Simpan Perubahan"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label, value;
  const _InfoItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }
}
