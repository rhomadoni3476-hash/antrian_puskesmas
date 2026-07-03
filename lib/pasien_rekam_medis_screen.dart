import 'package:flutter/material.dart';
import 'api_service.dart';

class PasienRekamMedisScreen extends StatefulWidget {
  const PasienRekamMedisScreen({super.key});

  @override
  State<PasienRekamMedisScreen> createState() => _PasienRekamMedisScreenState();
}

class _PasienRekamMedisScreenState extends State<PasienRekamMedisScreen> {
  late Future<List<RekamMedisPasien>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = ApiService.getRiwayatMedis();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureData = ApiService.getRiwayatMedis();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Medis Saya")),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<RekamMedisPasien>>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
              return const Center(child: Text("Belum ada riwayat rekam medis"));
            }

            final data = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.medical_services, color: Colors.blue),
                    title: Text(item.diagnosa),
                    subtitle: Text(
                        "Tanggal: ${item.tanggal}\nStatus: ${item.status}"),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// DEFINISI MODEL (Pastikan ini ada di file ini atau diimpor dari file lain)
// Pastikan kode ini ada di dalam file pasien_rekam_medis_screen.dart
class RekamMedisPasien {
  final String id;
  final String diagnosa;
  final String keluhan;
  final String tanggal;
  final String status;

  RekamMedisPasien(
      {required this.id,
      required this.diagnosa,
      required this.keluhan,
      required this.tanggal,
      required this.status});

  factory RekamMedisPasien.fromJson(Map<String, dynamic> json) {
    return RekamMedisPasien(
      id: json['id'].toString(),
      diagnosa: json['diagnosa'] ?? '-',
      keluhan: json['keluhan'] ?? '-',
      tanggal: json['tanggal'] ?? '-',
      status: json['status'] ?? 'Proses',
    );
  }
}
