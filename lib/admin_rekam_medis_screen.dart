import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api_service.dart';

class AdminRekamMedisScreen extends StatefulWidget {
  const AdminRekamMedisScreen({super.key});

  @override
  State<AdminRekamMedisScreen> createState() => _AdminRekamMedisScreenState();
}

class _AdminRekamMedisScreenState extends State<AdminRekamMedisScreen> {
  bool _isLoading = true;
  List<dynamic> _allData = [];
  List<dynamic> _filteredData = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getRekamMedis();
      setState(() {
        _allData = data;
        _filteredData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data: ${e.toString()}")),
        );
      }
    }
  }

  void _filterData(String query) {
    setState(() {
      _filteredData = _allData
          .where((item) =>
              item['nama_pasien'].toLowerCase().contains(query.toLowerCase()) ||
              item['nik'].toString().contains(query))
          .toList();
    });
  }

  // --- FITUR EXPORT PDF ---
  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(children: [
              pw.Header(
                  level: 0, child: pw.Text("Laporan Rekam Medis Puskesmas")),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Nama', 'NIK', 'Status', 'Keluhan'],
                  ..._filteredData.map((e) => [
                        e['nama_pasien'],
                        e['nik'].toString(),
                        e['status'],
                        e['keluhan']
                      ])
                ],
              ),
            ]);
          }),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  void _showUpdateDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Status"),
        content:
            Text("Ubah status pasien ${item['nama_pasien']} menjadi Selesai?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.updateStatus(item['id'], "Selesai");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Status berhasil diupdate")),
                  );
                }
                _refreshData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal update: $e")),
                  );
                }
              }
            },
            child: const Text("Ya, Selesai"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Rekam Medis"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf), onPressed: _exportToPDF),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                  labelText: "Cari Pasien (Nama/NIK)",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder()),
              onChanged: _filterData,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredData.isEmpty
                    ? const Center(child: Text("Data tidak ditemukan"))
                    : ListView.builder(
                        itemCount: _filteredData.length,
                        itemBuilder: (context, index) {
                          final item = _filteredData[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              title: Text(item['nama_pasien'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  "NIK: ${item['nik']}\nKeluhan: ${item['keluhan']}"),
                              isThreeLine: true,
                              trailing: item['status'] != 'Selesai'
                                  ? IconButton(
                                      icon: const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green),
                                      onPressed: () => _showUpdateDialog(item))
                                  : const Icon(Icons.check_circle,
                                      color: Colors.green),
                              leading: CircleAvatar(
                                  backgroundColor: item['status'] == 'Selesai'
                                      ? Colors.green
                                      : Colors.orange,
                                  child: const Icon(Icons.medical_services,
                                      color: Colors.white)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _refreshData, child: const Icon(Icons.refresh)),
    );
  }
}
