import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'antrian_provider.dart';
import 'export_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  String _filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AntrianProvider>(context, listen: false).fetchPasien();
    });
  }

  // Dialog Pemilihan Tanggal yang sudah diperbarui agar mengirim context ke ExportService
  Future<void> _pilihRentangTanggal(BuildContext context, List data) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: "PILIH RENTANG LAPORAN",
      initialDateRange:
          DateTimeRange(start: DateTime.now(), end: DateTime.now()),
    );

    if (picked != null) {
      // Sekarang mengirim context agar ExportService bisa menampilkan SnackBar
      await ExportService.cetakLaporan(context, data, picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Admin",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: "Ekspor PDF",
            onPressed: () {
              var data = Provider.of<AntrianProvider>(context, listen: false)
                  .daftarPasien;
              _pilihRentangTanggal(context, data);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: DropdownButton<String>(
              value: _filterStatus,
              isExpanded: true,
              underline: const SizedBox(),
              items: ['Semua', 'Menunggu', 'Sedang Diperiksa', 'Selesai']
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
              onChanged: (val) => setState(() => _filterStatus = val!),
            ),
          ),
        ),
      ),
      body: Consumer<AntrianProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.redAccent));
          }

          List listAntrian = provider.daftarPasien.where((data) {
            if (_filterStatus == 'Semua') return true;
            return data['status'] == _filterStatus;
          }).toList();

          if (listAntrian.isEmpty) {
            return const Center(
                child: Text("Tidak ada data antrian untuk status ini."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: listAntrian.length,
            itemBuilder: (context, index) {
              var data = listAntrian[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    child: const Icon(Icons.medical_services,
                        color: Colors.redAccent),
                  ),
                  title: Text(data['nama_pasien'] ?? 'Tanpa Nama',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "Status: ${data['status']}\nTanggal: ${data['tanggal_pemeriksaan'] ?? '-'}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onSelected: (val) =>
                            provider.updateStatusAntrian(data['id'], val),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                              value: 'Menunggu', child: Text('Menunggu')),
                          PopupMenuItem(
                              value: 'Sedang Diperiksa',
                              child: Text('Sedang Diperiksa')),
                          PopupMenuItem(
                              value: 'Selesai', child: Text('Selesai')),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () =>
                            _konfirmasiHapus(context, provider, data['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _konfirmasiHapus(
      BuildContext context, AntrianProvider provider, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Hapus Data"),
        content: const Text(
            "Yakin ingin menghapus rekam medis ini secara permanen?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final response = await http.delete(
                    Uri.parse("http://10.0.2.2:8000/hapus-rekam-medis/$id"));
                if (response.statusCode == 200) {
                  provider.fetchPasien();
                  if (mounted) Navigator.pop(context);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal menghapus data")));
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
