import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Perlu untuk memuat asset
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ExportService {
  static Future<void> cetakLaporan(BuildContext context, List dataPasien,
      DateTime mulai, DateTime akhir) async {
    // 1. Filter data
    final filteredData = dataPasien.where((item) {
      try {
        DateTime tgl = DateTime.parse(item['tanggal_pemeriksaan']);
        return (tgl.isAtSameMomentAs(mulai) || tgl.isAfter(mulai)) &&
            (tgl.isAtSameMomentAs(akhir) || tgl.isBefore(akhir));
      } catch (e) {
        return false;
      }
    }).toList();

    if (filteredData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Tidak ada data pada periode yang dipilih!"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // 2. Load Logo
    final pdf = pw.Document();
    final imageLogo = await imageFromAssetBundle('assets/logo_puskesmas.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) => [
          // --- KOP SURAT ---
          pw.Row(
            children: [
              pw.Image(imageLogo, width: 60, height: 60),
              pw.SizedBox(width: 15),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("PUSKESMAS DIGITAL",
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Jl. Kesehatan No. 123, Pekanbaru",
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Text("Telp: (0761) 123456",
                      style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 10),

          // --- JUDUL LAPORAN ---
          pw.Center(
            child: pw.Text("LAPORAN REKAM MEDIS",
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Center(
            child: pw.Text(
                "Periode: ${DateFormat('dd/MM/yyyy').format(mulai)} - ${DateFormat('dd/MM/yyyy').format(akhir)}"),
          ),
          pw.SizedBox(height: 20),

          // --- TABEL DATA ---
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.redAccent),
            headers: ['Nama Pasien', 'NIK', 'Keluhan', 'Status', 'Tanggal'],
            data: filteredData
                .map((item) => [
                      item['nama_pasien'] ?? '-',
                      item['nik'] ?? '-',
                      item['keluhan'] ?? '-',
                      item['status'] ?? '-',
                      item['tanggal_pemeriksaan'] ?? '-'
                    ])
                .toList(),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(4),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
            },
          ),
        ],
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
                'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                style: pw.Theme.of(context)
                    .defaultTextStyle
                    .copyWith(color: PdfColors.grey)),
          );
        },
      ),
    );

    // 3. Tampilkan Preview
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
