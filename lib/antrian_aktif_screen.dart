import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'form_daftar_antrian_screen.dart';
import 'chat_detail_screen.dart';

// --- Theme Global ---
class AppTheme {
  static const Color primary = Colors.redAccent;
  static const Color statusSelesai = Color(0xFF009688);
  static const Color statusPeriksa = Color(0xFF1976D2);
  static const Color statusMenunggu = Color(0xFFF57C00);
  static const Color textMain = Color(0xFF263238);
  static const Color background = Color(0xFFF8F9FA);
}

// --- Animasi Berdenyut (Untuk Bar Antrian) ---
class PulsingContainer extends StatefulWidget {
  final Widget child;
  const PulsingContainer({super.key, required this.child});
  @override
  State<PulsingContainer> createState() => _PulsingContainerState();
}

class _PulsingContainerState extends State<PulsingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: Tween(begin: 0.6, end: 1.0).animate(_controller),
      child: widget.child);
}

// --- Widget Utility ---
Widget buildEmptyState(String message, IconData icon) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 80, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(message, style: TextStyle(fontSize: 16, color: Colors.grey.shade500))
    ]));

Widget buildShimmerList() => Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.white,
    child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 100,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20)))));

class AntrianAktifScreen extends StatelessWidget {
  const AntrianAktifScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 2,
      child: Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
              title: const Text("Puskesmas Digital",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              bottom: const TabBar(
                  indicatorColor: Colors.white,
                  indicatorWeight: 4,
                  tabs: [
                    Tab(icon: Icon(Icons.list_alt), text: "Antrian Anda"),
                    Tab(icon: Icon(Icons.calendar_month), text: "Jadwal Dokter")
                  ])),
          body: const TabBarView(children: [AntrianContent(), JadwalContent()]),
          floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FormDaftarAntrianScreen())),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Daftar Antrian"))));
}

class AntrianContent extends StatefulWidget {
  const AntrianContent({super.key});
  @override
  State<AntrianContent> createState() => _AntrianContentState();
}

class _AntrianContentState extends State<AntrianContent> {
  final TextEditingController _nikController = TextEditingController();
  String _searchNik = "";
  final Map<String, String> _lastStatusMap = {};
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() async {
    await _notificationsPlugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')));
  }

  // --- Widget Nomor Berjalan ---
  Widget _buildNomorBerjalan() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('antrian')
          .where('status', isEqualTo: 'Sedang Diperiksa')
          .snapshots(),
      builder: (context, snapshot) {
        String nomorSedangDilayani = "---";
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          nomorSedangDilayani =
              snapshot.data!.docs.first['nomor_antrian'] ?? "-";
        }
        return PulsingContainer(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, Colors.orangeAccent]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ]),
            child: Row(children: [
              const Icon(Icons.record_voice_over,
                  color: Colors.white, size: 40),
              const SizedBox(width: 20),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Sedang Dilayani",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text("Antrian: $nomorSedangDilayani",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold))
              ])
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildNomorBerjalan(),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: TextField(
              controller: _nikController,
              decoration: InputDecoration(
                  hintText: "Masukkan NIK Anda",
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner,
                          color: AppTheme.primary),
                      onPressed: () async {
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const QrScannerScreen()));
                        if (result != null) {
                          setState(() {
                            _nikController.text = result;
                            _searchNik = result.trim();
                          });
                        }
                      }),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none)),
              onSubmitted: (val) => setState(() => _searchNik = val.trim()))),
      Expanded(
          child: StreamBuilder<QuerySnapshot>(
              stream: _searchNik.isEmpty
                  ? FirebaseFirestore.instance
                      .collection('antrian')
                      .orderBy('createdAt', descending: true)
                      .limit(10)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('antrian')
                      .where('nik', isEqualTo: _searchNik)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return buildShimmerList();
                if (snapshot.hasError)
                  return buildEmptyState("Error memuat data", Icons.error);
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return buildEmptyState(
                      "Data tidak ditemukan", Icons.person_off);

                return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) => AntrianCardItem(
                        data: snapshot.data!.docs[index].data()
                            as Map<String, dynamic>));
              })),
    ]);
  }
}

// --- Lanjutan dari Bagian 2 (Tambahkan ini di file yang sama) ---

class AntrianCardItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const AntrianCardItem({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final String status = (data['status'] ?? 'Menunggu').toString();
    Color statusColor = status == 'Selesai'
        ? AppTheme.statusSelesai
        : (status == 'Sedang Diperiksa'
            ? AppTheme.statusPeriksa
            : AppTheme.statusMenunggu);
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Row(children: [
          CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              radius: 25,
              child: Text(data['nomor_antrian']?.toString() ?? '-',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 18))),
          const SizedBox(width: 15),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(data['nama'] ?? 'Pasien',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Status: $status",
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12))
              ])),
          Icon(
              status == 'Selesai' ? Icons.check_circle : Icons.medical_services,
              color: statusColor)
        ]));
  }
}

class QrScannerScreen extends StatelessWidget {
  const QrScannerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text("Scan NIK")),
      body: MobileScanner(onDetect: (cap) {
        if (cap.barcodes.isNotEmpty)
          Navigator.pop(context, cap.barcodes.first.rawValue);
      }));
}

class JadwalContent extends StatefulWidget {
  const JadwalContent({super.key});
  @override
  State<JadwalContent> createState() => _JadwalContentState();
}

class _JadwalContentState extends State<JadwalContent> {
  final List<String> _hari = [
    'senin',
    'selasa',
    'rabu',
    'kamis',
    'jumat',
    'sabtu',
    'minggu'
  ];
  String _selectedHari = 'senin';

  // Fungsi untuk mendeteksi apakah dokter sedang praktek sekarang
  bool isSedangBerlangsung(String jam, String hariPraktek) {
    try {
      final now = DateTime.now();
      final mapHari = {
        'senin': 1,
        'selasa': 2,
        'rabu': 3,
        'kamis': 4,
        'jumat': 5,
        'sabtu': 6,
        'minggu': 7
      };

      if (now.weekday != mapHari[hariPraktek.toLowerCase()]) return false;

      final menitSekarang = now.hour * 60 + now.minute;
      final cleanJam = jam.replaceAll(RegExp(r'[–—\s]'), '');
      final parts = cleanJam.split('-');
      if (parts.length < 2) return false;

      final start = parts[0].split(':');
      final end = parts[1].split(':');
      final startMnt = int.parse(start[0]) * 60 + int.parse(start[1]);
      final endMnt = int.parse(end[0]) * 60 + int.parse(end[1]);

      return menitSekarang >= startMnt && menitSekarang <= endMnt;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        // Selector Hari
        SizedBox(
            height: 70,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _hari.length,
                itemBuilder: (c, i) {
                  final isSel = _selectedHari == _hari[i];
                  return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 15),
                      child: ChoiceChip(
                          label: Text(_hari[i].toUpperCase()),
                          selected: isSel,
                          selectedColor: AppTheme.primary,
                          labelStyle: TextStyle(
                              color: isSel ? Colors.white : Colors.black),
                          onSelected: (v) =>
                              setState(() => _selectedHari = _hari[i])));
                })),
        // List Dokter
        Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('jadwal_dokter')
                    .doc(_selectedHari)
                    .collection('daftar_dokter')
                    .snapshots(),
                builder: (c, snap) {
                  if (!snap.hasData) return buildShimmerList();
                  if (snap.data!.docs.isEmpty)
                    return buildEmptyState(
                        "Tidak ada jadwal", Icons.calendar_today);

                  return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snap.data!.docs.length,
                      itemBuilder: (c, i) {
                        var d =
                            snap.data!.docs[i].data() as Map<String, dynamic>;
                        bool p = isSedangBerlangsung(
                            d['jam_praktek'] ?? '00:00-00:00', _selectedHari);

                        return AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: p
                                    ? Border.all(color: Colors.green, width: 2)
                                    : null),
                            child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                    leading: Icon(Icons.person,
                                        color:
                                            p ? Colors.green : AppTheme.primary,
                                        size: 30),
                                    title: Text(d['nama_dokter'] ?? 'Dokter',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        "${d['poli']} • ${d['jam_praktek']}"),
                                    trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.chat_bubble_outline),
                                              onPressed: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) => ChatDetailScreen(
                                                          userId: FirebaseAuth
                                                                  .instance
                                                                  .currentUser
                                                                  ?.uid ??
                                                              'guest',
                                                          namaPasien: d[
                                                              'nama_dokter'])))),
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.app_registration,
                                                  color: AppTheme.primary),
                                              onPressed: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          FormDaftarAntrianScreen(
                                                              namaDokter: d[
                                                                  'nama_dokter'],
                                                              poli:
                                                                  d['poli']))))
                                        ]))));
                      });
                }))
      ]);
}
