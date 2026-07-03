import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class LogAktivitasScreen extends StatefulWidget {
  const LogAktivitasScreen({super.key});

  @override
  State<LogAktivitasScreen> createState() => _LogAktivitasScreenState();
}

class _LogAktivitasScreenState extends State<LogAktivitasScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Semua";
  final List<String> _filters = ["Semua", "Tambah", "Update", "Reset"];

  // Helper untuk menentukan warna berdasarkan aksi
  Color _getAksiColor(String aksi) {
    if (aksi.contains("Reset")) return Colors.red;
    if (aksi.contains("Tambah")) return Colors.green;
    if (aksi.contains("Update")) return Colors.orange;
    return Colors.blueGrey;
  }

  // Fungsi Export ke CSV
  Future<void> _exportLogToCSV(List<QueryDocumentSnapshot> logs) async {
    String csvData = "Aksi,Nama Pasien,Dokter,Timestamp\n";
    for (var doc in logs) {
      final d = doc.data() as Map<String, dynamic>;
      csvData +=
          "${d['aksi']},${d['nama_pasien']},${d['dokter']},${(d['timestamp'] as Timestamp).toDate()}\n";
    }
    final directory = await getTemporaryDirectory();
    final file = File(
        '${directory.path}/Log_Audit_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(file.path)],
        text: 'Laporan Audit Log Aktivitas');
  }

  // Fungsi Hapus Semua Log
  Future<void> _hapusSemuaLog(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content:
            const Text("Hapus SEMUA riwayat log aktivitas secara permanen?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text("Hapus Semua", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final collection = FirebaseFirestore.instance.collection('log_aktivitas');
      final snapshots = await collection.get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Log dibersihkan.")));
    }
  }

  // Tampilan Detail Modal
  void _showDetailLog(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.drag_handle, color: Colors.grey)),
            const SizedBox(height: 15),
            Text("Detail Audit",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.edit),
                title: Text(data['aksi'] ?? '-'),
                subtitle: const Text("Aksi")),
            ListTile(
                leading: const Icon(Icons.person),
                title: Text(data['nama_pasien'] ?? '-'),
                subtitle: const Text("Nama Pasien")),
            ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(data['dokter'] ?? '-'),
                subtitle: const Text("Operator")),
            ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(DateFormat('dd MMMM yyyy, HH:mm')
                    .format((data['timestamp'] as Timestamp).toDate())),
                subtitle: const Text("Waktu")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log Aktivitas (Audit Trail)"),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('log_aktivitas')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final allLogs = snapshot.data!.docs;
          final filteredLogs = allLogs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final matchesSearch = (data['nama_pasien'] ?? "")
                .toString()
                .toLowerCase()
                .contains(_searchQuery);
            final matchesFilter = _selectedFilter == "Semua" ||
                (data['aksi'] as String).contains(_selectedFilter);
            return matchesSearch && matchesFilter;
          }).toList();

          return Column(
            children: [
              // Pencarian & Filter
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Cari nama pasien...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filters.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, i) => ChoiceChip(
                                label: Text(_filters[i]),
                                selected: _selectedFilter == _filters[i],
                                onSelected: (selected) => setState(
                                    () => _selectedFilter = _filters[i]),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.ios_share),
                            onPressed: () => _exportLogToCSV(filteredLogs),
                            tooltip: "Export CSV"),
                        IconButton(
                            icon: const Icon(Icons.delete_forever),
                            onPressed: () => _hapusSemuaLog(context),
                            tooltip: "Hapus Semua"),
                      ],
                    ),
                  ],
                ),
              ),

              // List Data
              Expanded(
                child: filteredLogs.isEmpty
                    ? const Center(child: Text("Data log tidak ditemukan"))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          var data = filteredLogs[index].data()
                              as Map<String, dynamic>;
                          var time =
                              (data['timestamp'] as Timestamp?)?.toDate();
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              onTap: () => _showDetailLog(context, data),
                              leading: CircleAvatar(
                                backgroundColor: _getAksiColor(data['aksi'])
                                    .withOpacity(0.1),
                                child: Icon(Icons.history,
                                    color: _getAksiColor(data['aksi'])),
                              ),
                              title: Text(data['aksi'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text("Pasien: ${data['nama_pasien']}"),
                              trailing: Text(
                                  time != null
                                      ? DateFormat('HH:mm\ndd/MM').format(time)
                                      : '-',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 10)),
                            ),
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
