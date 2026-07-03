import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

import 'admin_dashboard_screen.dart';
import 'dashboard_pasien_screen.dart';
import 'login_pasien_screen.dart';
import 'input_diagnosa_screen.dart';
import 'riwayat_pasien_screen.dart';
import 'log_aktivitas_screen.dart';
import 'admin_chat_screen.dart'; // Import file chat baru

class DashboardDokterScreen extends StatefulWidget {
  const DashboardDokterScreen({super.key});

  @override
  State<DashboardDokterScreen> createState() => _DashboardDokterScreenState();
}

class _DashboardDokterScreenState extends State<DashboardDokterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlertPlayed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- FITUR NOTIFIKASI PESAN (BADGE) ---
  Widget _buildUnreadChatBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('unreadCount', isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox();

        int totalUnread = 0;
        for (var doc in snapshot.data!.docs) {
          totalUnread +=
              (doc.data() as Map<String, dynamic>)['unreadCount'] as int;
        }

        return Positioned(
          right: 5,
          top: 5,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Text("$totalUnread",
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  // --- FITUR LOG AKTIVITAS (AUDIT TRAIL) ---
  Future<void> _catatLog(String aksi, String namaPasien) async {
    await FirebaseFirestore.instance.collection('log_aktivitas').add({
      'aksi': aksi,
      'nama_pasien': namaPasien,
      'dokter': 'Dr. Puskesmas',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- FITUR GENERATE SURAT SAKIT ---
  Future<void> _generateSuratSakit(String namaPasien, int durasi) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw
          .Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Text("SURAT KETERANGAN SAKIT",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Divider(),
        pw.SizedBox(height: 20),
        pw.Text("Nama: $namaPasien",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text("Perlu beristirahat selama $durasi hari."),
        pw.SizedBox(height: 50),
        pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text("Dokter Pemeriksa,\n\n\n(_____________________)")),
      ]);
    }));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _tampilkanDialogSuratSakit(
      String userId, String namaPasien) async {
    final TextEditingController durasiController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Buat Surat Sakit"),
        content: TextField(
            controller: durasiController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Durasi (hari)")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              int durasi = int.tryParse(durasiController.text) ?? 1;
              await FirebaseFirestore.instance.collection('surat_sakit').add({
                'userId': userId,
                'nama_pasien': namaPasien,
                'durasi_hari': durasi,
                'timestamp': Timestamp.now(),
              });
              await _catatLog("Membuat Surat Sakit ($durasi hari)", namaPasien);
              if (mounted) Navigator.pop(context);
              _generateSuratSakit(namaPasien, durasi);
            },
            child: const Text("Cetak"),
          ),
        ],
      ),
    );
  }

  void _playEmergencyAlert() async {
    if (!_isAlertPlayed) {
      await _audioPlayer.play(AssetSource('audio/alert.mp3'));
      _isAlertPlayed = true;
    }
  }

  Color getPrioritasColor(String? prioritas) {
    switch (prioritas) {
      case 'Merah':
        return Colors.red;
      case 'Kuning':
        return Colors.amber.shade700;
      case 'Hijau':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFD32F2F);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
          title: const Text("Dashboard Dokter",
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminChatScreen())),
                ),
                _buildUnreadChatBadge(),
              ],
            )
          ]),
      drawer: _buildDrawer(context, primaryRed),
      body: Column(
        children: [
          _buildStatistikAntrian(primaryRed),
          Expanded(child: _buildListAntrian(primaryRed)),
        ],
      ),
    );
  }

  Widget _buildStatistikAntrian(Color primaryRed) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('antrian')
          .where('status', isNotEqualTo: 'Selesai')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 120);
        final docs = snapshot.data!.docs;
        int menunggu = docs
            .where((d) =>
                (d.data() as Map<String, dynamic>)['status'] == 'Menunggu')
            .length;
        bool adaDarurat = docs.any(
            (d) => (d.data() as Map<String, dynamic>)['prioritas'] == 'Merah');
        if (adaDarurat) _playEmergencyAlert();
        if (!adaDarurat) _isAlertPlayed = false;

        return Container(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                  child: _infoCard(
                      "Menunggu", "$menunggu", Colors.orange.shade800, false)),
              const SizedBox(width: 15),
              Expanded(
                  child: _infoCard(
                      "Total Aktif", "${docs.length}", primaryRed, false))
            ]));
      },
    );
  }

  Widget _infoCard(String title, String value, Color color, bool isPulsing) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(children: [
            Text(title,
                style: TextStyle(
                    color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: color))
          ])),
    );
  }

  Widget _buildListAntrian(Color primaryRed) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('antrian')
          .where('status', whereIn: ['Menunggu', 'Sedang Diperiksa'])
          .orderBy('prioritas_level', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator(color: primaryRed));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildPasienCard(doc, data, primaryRed);
          },
        );
      },
    );
  }

  Widget _buildPasienCard(
      DocumentSnapshot doc, Map<String, dynamic> data, Color primaryRed) {
    String prioritas = data['prioritas'] ?? 'Hijau';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
            backgroundColor: getPrioritasColor(prioritas),
            child: Text("${data['nomor_antrian'] ?? '?'}")),
        title: Text(data['nama'] ?? 'Pasien',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                IconButton(
                    icon: Icon(Icons.description, color: primaryRed),
                    onPressed: () => _tampilkanDialogSuratSakit(
                        data['userId'] ?? '', data['nama'] ?? '')),
                if (data['status'] == 'Menunggu')
                  IconButton(
                      icon: Icon(Icons.play_circle_fill,
                          color: primaryRed, size: 32),
                      onPressed: () => _updateStatus(
                          doc.id, 'Sedang Diperiksa', data['nama'])),
              ])),
        ],
      ),
    );
  }

  void _updateStatus(String id, String statusBaru, String namaPasien) async {
    await FirebaseFirestore.instance
        .collection('antrian')
        .doc(id)
        .update({'status': statusBaru});
    await _catatLog("Mengubah status ke $statusBaru", namaPasien);
  }

  Widget _buildDrawer(BuildContext context, Color primaryRed) {
    return Drawer(
      child: ListView(children: [
        const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFD32F2F)),
            accountName: Text("Dr. Puskesmas"),
            accountEmail: Text("Mode Dokter")),
        ListTile(
            leading: const Icon(Icons.chat),
            title: const Text("Pesan Pasien"),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminChatScreen()))),
        ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Audit Log Aktivitas"),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LogAktivitasScreen()))),
        ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPasienScreen()),
                  (route) => false);
            }),
      ]),
    );
  }
}
