import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class RekamMedisDetailScreen extends StatelessWidget {
  final Map<String, dynamic> dataPasien;

  const RekamMedisDetailScreen({super.key, required this.dataPasien});

  Future<void> _downloadRekamMedisPDF(BuildContext context) async {
    try {
      final pdf = pw.Document();

      // Memuat font standar untuk menghindari error karakter
      final font = await PdfGoogleFonts.robotoRegular();

      final dateVal = dataPasien['tanggal'];
      final String formattedDate = (dateVal is Timestamp)
          ? DateFormat('dd/MM/yyyy').format(dateVal.toDate())
          : (dateVal?.toString() ?? '-');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                    child: pw.Text("PUSKESMAS DIGITAL",
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold))),
                pw.Center(
                    child: pw.Text("Laporan Rekam Medis Pasien",
                        style: const pw.TextStyle(fontSize: 14))),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),
                _buildPdfRow("Nama Pasien", dataPasien['nama'] ?? '-'),
                _buildPdfRow("Tanggal", formattedDate),
                pw.SizedBox(height: 20),
                pw.Text("DETAIL MEDIS:",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.SizedBox(height: 10),
                _buildPdfSection("Keluhan", dataPasien['keluhan'] ?? '-'),
                _buildPdfSection("Diagnosa", dataPasien['diagnosa'] ?? '-'),
                _buildPdfSection(
                    "Tindakan / Resep", dataPasien['tindakan'] ?? '-'),
                pw.Spacer(),
                pw.Divider(),
                pw.Text(
                    "Dicetak pada: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}",
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal membuat PDF: $e"),
            backgroundColor: Colors.red));
      }
    }
  }

  pw.Widget _buildPdfRow(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(children: [
        pw.Text("$label : ",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(value)
      ]));

  pw.Widget _buildPdfSection(String title, String content) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline)),
        pw.SizedBox(height: 4),
        pw.Text(content)
      ]));

  @override
  Widget build(BuildContext context) {
    final dateVal = dataPasien['tanggal'];
    // Gunakan try-catch saat parsing tanggal untuk UI agar aplikasi tidak crash jika format salah
    String displayDate = '-';
    try {
      displayDate = (dateVal is Timestamp)
          ? DateFormat('dd MMMM yyyy').format(dateVal.toDate())
          : (dateVal?.toString() ?? '-');
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Rekam Medis"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoCard("Nama Pasien", dataPasien['nama'] ?? '-'),
            _buildInfoCard("Tanggal", displayDate),
            _buildInfoCard("Keluhan", dataPasien['keluhan'] ?? '-'),
            _buildInfoCard("Diagnosa", dataPasien['diagnosa'] ?? '-'),
            _buildInfoCard("Tindakan/Resep", dataPasien['tindakan'] ?? '-'),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("DOWNLOAD PDF",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _downloadRekamMedisPDF(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value,
              style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ),
      ),
    );
  }
}
