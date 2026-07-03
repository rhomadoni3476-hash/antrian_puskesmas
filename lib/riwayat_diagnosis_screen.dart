import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Helper UI Components ---
Widget buildEmptyState(String message, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(message,
            style:
                GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade500)),
      ],
    ),
  );
}

Widget buildShimmerList() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: ListView.builder(
        itemCount: 4,
        itemBuilder: (_, __) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const SizedBox(height: 80))),
  );
}

class RiwayatDiagnosisScreen extends StatefulWidget {
  const RiwayatDiagnosisScreen({super.key});

  @override
  State<RiwayatDiagnosisScreen> createState() => _RiwayatDiagnosisScreenState();
}

class _RiwayatDiagnosisScreenState extends State<RiwayatDiagnosisScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Riwayat Diagnosis",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => _generatePdf(context)),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari riwayat penyakit...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('riwayat_diagnosis')
                  .where('userId', isEqualTo: userId ?? 'guest')
                  .orderBy('tanggal', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return buildShimmerList();
                if (snapshot.hasError)
                  return buildEmptyState(
                      "Terjadi kesalahan", Icons.error_outline);

                final docs = snapshot.data?.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final penyakit =
                          (data['penyakit'] ?? '').toString().toLowerCase();
                      return penyakit != 'penyakit tidak diketahui' &&
                          penyakit.contains(_searchQuery);
                    }).toList() ??
                    [];

                if (docs.isEmpty)
                  return buildEmptyState(
                      "Tidak ada riwayat ditemukan", Icons.history);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildStatistikSection(docs)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final tgl =
                                (data['tanggal'] as Timestamp?)?.toDate() ??
                                    DateTime.now();
                            final akurasi = data['keyakinan'] ?? '0%';
                            return _buildDiagnosisCard(
                                data, tgl, akurasi, context);
                          },
                          childCount: docs.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard(Map<String, dynamic> data, DateTime tgl,
      String akurasi, BuildContext context) {
    double val = double.tryParse(akurasi.replaceAll('%', '')) ?? 0;
    Color statusColor =
        val > 80 ? Colors.green : (val > 50 ? Colors.orange : Colors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.medical_services, color: Colors.redAccent)),
        title: Text(data['penyakit'] ?? 'Diagnosis',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('dd MMM yyyy').format(tgl),
            style: GoogleFonts.poppins(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Text(akurasi,
              style: GoogleFonts.poppins(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        onTap: () => _showDetailDialog(context, data, tgl),
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('riwayat_diagnosis')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get();
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (pw.Context context) => pw.Column(
        children: [
          pw.Header(level: 0, child: pw.Text("Laporan Riwayat Medis")),
          pw.Table.fromTextArray(
            headers: ['Tanggal', 'Penyakit', 'Akurasi'],
            data: snapshot.docs.map((d) {
              final data = d.data() as Map;
              return [
                DateFormat('dd/MM/yy').format(data['tanggal'].toDate()),
                data['penyakit'],
                data['keyakinan']
              ];
            }).toList(),
          ),
        ],
      ),
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _buildStatistikSection(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return const SizedBox();
    Map<String, double> dataMap = {};
    for (var doc in docs) {
      String p = (doc.data() as Map<String, dynamic>)['penyakit'] ?? 'Lainnya';
      dataMap[p] = (dataMap[p] ?? 0) + 1;
    }
    return Container(
      height: 240,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Column(
        children: [
          Text("Frekuensi Diagnosis",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(BarChartData(
              barGroups: dataMap.entries
                  .map((e) => BarChartGroupData(
                        x: dataMap.keys.toList().indexOf(e.key),
                        barRods: [
                          BarChartRodData(
                              toY: e.value,
                              color: Colors.redAccent,
                              width: 25,
                              borderRadius: BorderRadius.circular(8))
                        ],
                      ))
                  .toList(),
              titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 30))),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
            )),
          ),
        ],
      ),
    );
  }

  Widget _getSaranPenanganan(String penyakit) {
    String p = penyakit.toLowerCase();
    String saran =
        "Harap segera berkonsultasi dengan dokter untuk tindakan medis lebih lanjut.";
    if (p.contains("flu") || p.contains("batuk"))
      saran =
          "• Perbanyak istirahat.\n• Minum air putih hangat (min. 2L/hari).\n• Konsumsi Vitamin C.";
    else if (p.contains("demam"))
      saran =
          "• Kompres dahi dengan air hangat.\n• Gunakan pakaian tipis dan menyerap keringat.\n• Pantau suhu tubuh secara berkala.";
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Saran Penanganan:",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.redAccent)),
        const SizedBox(height: 8),
        Text(saran, style: GoogleFonts.poppins(height: 1.5)),
      ]),
    );
  }

  void _showDetailDialog(
      BuildContext context, Map<String, dynamic> data, DateTime tgl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const Icon(Icons.medical_services_outlined,
              size: 50, color: Colors.redAccent),
          const SizedBox(height: 10),
          Text(data['penyakit'] ?? 'Diagnosis',
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildDetailRow(
              "Tanggal:", DateFormat('dd MMM yyyy, HH:mm').format(tgl)),
          _buildDetailRow("Tingkat Akurasi:", data['keyakinan'] ?? '0%'),
          _getSaranPenanganan(data['penyakit'] ?? ''),
          const Spacer(),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => Share.share(
                        "Hasil diagnosis saya: ${data['penyakit']} dengan akurasi ${data['keyakinan']}"),
                    icon: const Icon(Icons.share),
                    label: const Text("Bagikan"))),
            const SizedBox(width: 15),
            Expanded(
                child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tutup"))),
          ]),
        ]),
      ),
    );
  }

  Widget _buildDetailRow(String l, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: GoogleFonts.poppins(color: Colors.grey)),
        Text(v, style: GoogleFonts.poppins(fontWeight: FontWeight.bold))
      ]));
}
