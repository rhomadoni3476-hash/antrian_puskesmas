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
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureData = ApiService.getRiwayatMedis();
    });
  }

  Future<void> _refresh() async {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Medis Saya"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<RekamMedisPasien>>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      Text("Gagal: ${snapshot.error}",
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: _loadData, child: const Text("Coba Lagi"))
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Belum ada riwayat rekam medis"));
            }

            final data = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DetailRekamMedisScreen(item: item)),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: item.status.toLowerCase() == 'selesai'
                          ? Colors.green
                          : Colors.orange,
                      child: const Icon(Icons.medical_services,
                          color: Colors.white),
                    ),
                    title: Text(item.diagnosa,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "Tanggal: ${item.tanggal} • Status: ${item.status}"),
                    trailing: const Icon(Icons.chevron_right),
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

// Widget Detail untuk navigasi saat diklik
class DetailRekamMedisScreen extends StatelessWidget {
  final RekamMedisPasien item;
  const DetailRekamMedisScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Rekam Medis")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("Diagnosa", item.diagnosa),
            _buildInfoRow("Keluhan", item.keluhan),
            _buildInfoRow("Tanggal", item.tanggal),
            _buildInfoRow("Status", item.status),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const Divider(),
        ],
      ),
    );
  }
}

// Model RekamMedisPasien
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
      id: json['id']?.toString() ?? '',
      diagnosa: json['diagnosa'] ?? '-',
      keluhan: json['keluhan'] ?? '-',
      tanggal: json['tanggal'] ?? '-',
      status: json['status'] ?? 'Proses',
    );
  }
}
