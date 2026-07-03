import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

// Import file pendukung Anda
import 'user_management_screen.dart';
import 'admin_chat_screen.dart';
import 'admin_verifikasi_screen.dart';
import 'login_pasien_screen.dart';
import 'admin_review_screen.dart';
import 'home_nav_screen.dart';
import 'dashboard_dokter_screen.dart';
import 'log_aktivitas_screen.dart';
import 'daftar_darurat_screen.dart';
import 'usability_survey_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  // --- KEAMANAN AKSES ADMIN ---
  Future<void> _checkAdminAccess() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted)
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginPasienScreen()));
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() as Map<String, dynamic>?;

    if (data?['role'] == 'admin') {
      if (mounted) setState(() => _isChecking = false);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Akses Ditolak!"), backgroundColor: Colors.red));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Super Dashboard",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pengaturan')
                .doc('layanan')
                .snapshots(),
            builder: (context, snapshot) {
              bool isBuka = (snapshot.data?.data()
                      as Map<String, dynamic>?)?['status_buka'] ??
                  true;
              return Switch(
                value: isBuka,
                activeColor: Colors.white,
                onChanged: (val) => FirebaseFirestore.instance
                    .collection('pengaturan')
                    .doc('layanan')
                    .update({'status_buka': val}),
              );
            },
          )
        ],
      ),
      drawer: const AdminCustomDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInputPasienOffline(context),
        icon: const Icon(Icons.person_add),
        label: const Text("Pasien Offline"),
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          _buildEmergencyAlert(),
          const Expanded(
              child: AdminAntrianView()), // Menggunakan view antrian yang ada
        ],
      ),
    );
  }

  Widget _buildEmergencyAlert() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('darurat').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Container(
            color: Colors.red.shade700,
            child: ListTile(
              leading:
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
              title: Text("${snapshot.data!.docs.length} PASIEN BUTUH BANTUAN!",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DaftarDaruratScreen())),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  void _showInputPasienOffline(BuildContext context) {
    final namaCtrl = TextEditingController();
    final keluhanCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Input Pasien Offline"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: namaCtrl,
                    decoration:
                        const InputDecoration(labelText: "Nama Pasien")),
                TextField(
                    controller: keluhanCtrl,
                    decoration: const InputDecoration(labelText: "Keluhan")),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Batal")),
                ElevatedButton(
                    onPressed: () async {
                      if (namaCtrl.text.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('antrian')
                            .add({
                          'nama': namaCtrl.text,
                          'keluhan': keluhanCtrl.text,
                          'status': 'Menunggu',
                          'tanggal': Timestamp.now()
                        });
                        if (mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text("Simpan")),
              ],
            ));
  }
}

// ... [Sertakan kelas AdminAntrianView, AdminCustomDrawer, dan fungsi pendukung lainnya di bawah sini tanpa mengubah logika aslinya]

class AdminCustomDrawer extends StatelessWidget {
  const AdminCustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.redAccent),
            accountName: Text("Admin Puskesmas"),
            accountEmail: Text("Mode Supervisi"),
            currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child:
                    Icon(Icons.admin_panel_settings, color: Colors.redAccent)),
          ),
          ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Log Aktivitas"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LogAktivitasScreen()));
              }),
          ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text("Mode Dokter"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DashboardDokterScreen()));
              }),
          ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Mode Pasien"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const HomeNavScreen()));
              }),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text("Verifikasi Pasien"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminVerifikasiScreen()));
              }),
          ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text("Manajemen User"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UserManagementScreen()));
              }),
          ListTile(
              leading: const Icon(Icons.chat_bubble),
              title: const Text("Balas Konsultasi"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminChatScreen()));
              }),
          ListTile(
              leading: const Icon(Icons.star_rate),
              title: const Text("Ulasan Pasien"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminReviewScreen()));
              }),
          const Spacer(),
          ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginPasienScreen()),
                      (route) => false);
                }
              }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class AdminAntrianView extends StatefulWidget {
  const AdminAntrianView({super.key});
  @override
  State<AdminAntrianView> createState() => _AdminAntrianViewState();
}

class _AdminAntrianViewState extends State<AdminAntrianView> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _filterHariIni = false;

  // --- SEMUA FUNGSI LOGIKA ---
  DateTime _getValidDate(Map<String, dynamic> data) {
    if (data['createdAt'] is Timestamp)
      return (data['createdAt'] as Timestamp).toDate();
    if (data['tanggal'] is Timestamp)
      return (data['tanggal'] as Timestamp).toDate();
    return DateTime.now();
  }

  Future<void> _catatLog(String aksi, String namaPasien) async {
    await FirebaseFirestore.instance.collection('log_aktivitas').add({
      'aksi': aksi,
      'nama_pasien': namaPasien,
      'dokter': 'Admin Sistem',
      'timestamp': FieldValue.serverTimestamp()
    });
  }

  // --- FUNGSI UPDATE STATUS DENGAN PENCATATAN WAKTU ---
  Future<void> _updateStatus(
      String docId, String newStatus, String nama) async {
    Map<String, dynamic> updateData = {'status': newStatus};
    if (newStatus == 'Sedang Diperiksa') {
      updateData['diperiksa_at'] = FieldValue.serverTimestamp();
    } else if (newStatus == 'Selesai') {
      updateData['selesai_at'] = FieldValue.serverTimestamp();
    }
    await FirebaseFirestore.instance
        .collection('antrian')
        .doc(docId)
        .update(updateData);
    await _catatLog("Ubah Status ke $newStatus", nama);
  }

  // --- FUNGSI ESTIMASI WAKTU ---
  Future<int> hitungEstimasiWaktu(int antrianDiDepan) async {
    final snap = await FirebaseFirestore.instance
        .collection('antrian')
        .where('status', isEqualTo: 'Selesai')
        .orderBy('selesai_at', descending: true)
        .limit(10)
        .get();

    if (snap.docs.length < 3) return antrianDiDepan * 10;

    double totalDurasi = 0;
    for (var doc in snap.docs) {
      final data = doc.data();
      if (data['diperiksa_at'] != null && data['selesai_at'] != null) {
        final start = (data['diperiksa_at'] as Timestamp).toDate();
        final end = (data['selesai_at'] as Timestamp).toDate();
        totalDurasi += end.difference(start).inMinutes;
      }
    }
    double rataRata = totalDurasi / snap.docs.length;
    return (antrianDiDepan * rataRata).round();
  }

  Future<double> _getSusScore() async {
    final snap =
        await FirebaseFirestore.instance.collection('sus_results').get();
    if (snap.docs.isEmpty) return 0.0;
    double total = snap.docs.fold(
        0, (sum, doc) => sum + ((doc.data()['final_score'] ?? 0).toDouble()));
    return total / snap.docs.length;
  }

  Future<void> _berikanPoinSetelahSelesai(String? userId, String nama) async {
    if (userId == null || userId.isEmpty) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;
      int poinLama = (snapshot.data() as Map<String, dynamic>)['poin'] ?? 0;
      transaction.update(userRef, {
        'poin': poinLama + 10,
        'riwayat_poin': FieldValue.arrayUnion([
          {
            'tanggal': Timestamp.now(),
            'aksi': 'Selesai Konsultasi',
            'jumlah': 10
          }
        ])
      });
    });
  }

  Future<void> _resetAntrian(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Konfirmasi Reset"),
              content: const Text("Hapus SEMUA data antrian?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Batal")),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Reset",
                        style: TextStyle(color: Colors.red))),
              ],
            ));
    if (confirm == true) {
      final snapshot =
          await FirebaseFirestore.instance.collection('antrian').get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) batch.delete(doc.reference);
      await batch.commit();
      await _catatLog("Reset Antrian", "Seluruh Data Antrian");
    }
  }

  Future<void> _exportToPDF(List<QueryDocumentSnapshot> docs) async {
    final image = !kIsWeb ? await _screenshotController.capture() : null;
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
        build: (pw.Context context) => pw.Column(children: [
              pw.Text("Laporan Antrian",
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              if (image != null) pw.Image(pw.MemoryImage(image)),
              pw.Table.fromTextArray(context: context, data: [
                ['Nama', 'Keluhan', 'Status'],
                ...docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return [
                    data['nama'] ?? '-',
                    data['keluhan'] ?? '-',
                    data['status'] ?? '-'
                  ];
                })
              ])
            ])));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportToExcel(List<QueryDocumentSnapshot> docs) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Laporan Antrian'];
    sheetObject.appendRow([
      TextCellValue('Nama'),
      TextCellValue('Keluhan'),
      TextCellValue('Status')
    ]);
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      sheetObject.appendRow([
        TextCellValue(data['nama']?.toString() ?? '-'),
        TextCellValue(data['keluhan']?.toString() ?? '-'),
        TextCellValue(data['status']?.toString() ?? '-')
      ]);
    }
    var directory = await getApplicationDocumentsDirectory();
    String filePath =
        "${directory.path}/Laporan_Antrian_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      await OpenFilex.open(filePath);
    }
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _getSusScore(),
      builder: (context, susSnapshot) {
        double susScore = susSnapshot.data ?? 0.0;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('antrian')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            final filteredDocs = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              bool matchesSearch = data['nama']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
              bool matchesDate = !_filterHariIni ||
                  DateFormat('yyyy-MM-dd').format(_getValidDate(data)) ==
                      DateFormat('yyyy-MM-dd').format(DateTime.now());
              return matchesSearch && matchesDate;
            }).toList();

            final sedangDiperiksa = docs
                .where((d) =>
                    (d.data() as Map<String, dynamic>)['status'] ==
                    'Sedang Diperiksa')
                .toList();
            Map<String, int> keluhanMap = {};
            for (var doc in docs) {
              String k =
                  (doc.data() as Map<String, dynamic>)['keluhan'] ?? 'Lainnya';
              keluhanMap[k] = (keluhanMap[k] ?? 0) + 1;
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Sedang Dilayani:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              sedangDiperiksa.isEmpty
                                  ? const Card(
                                      child: ListTile(
                                          title: Text("Ruang periksa kosong")))
                                  : Card(
                                      color: Colors.orange.shade100,
                                      child: ListTile(
                                          leading: const Icon(Icons.person_pin,
                                              color: Colors.orange),
                                          title: Text(
                                              (sedangDiperiksa.first.data()
                                                      as Map<String,
                                                          dynamic>)['nama'] ??
                                                  '-'))),
                              const SizedBox(height: 10),
                              Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                          color: Colors.grey.shade200)),
                                  color: Colors.grey.shade50,
                                  child: ExpansionTile(
                                      leading: const Icon(Icons.analytics,
                                          color: Colors.redAccent),
                                      title: const Text(
                                          "Dashboard Statistik & Alat"),
                                      children: [
                                        Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(children: [
                                              Row(children: [
                                                Expanded(
                                                    child: SizedBox(
                                                        height: 100,
                                                        child: BarChart(BarChartData(
                                                            barGroups: keluhanMap
                                                                .entries
                                                                .map((e) =>
                                                                    BarChartGroupData(
                                                                        x: 0,
                                                                        barRods: [
                                                                          BarChartRodData(
                                                                              toY: e.value.toDouble(),
                                                                              color: Colors.redAccent)
                                                                        ]))
                                                                .toList())))),
                                                Expanded(
                                                    child: SizedBox(
                                                        height: 100,
                                                        child: PieChart(
                                                            PieChartData(
                                                                sections: [
                                                              PieChartSectionData(
                                                                  value:
                                                                      susScore,
                                                                  color: susScore > 68
                                                                      ? Colors
                                                                          .green
                                                                      : Colors
                                                                          .orange,
                                                                  title:
                                                                      'SUS: ${susScore.toInt()}',
                                                                  radius: 30),
                                                              PieChartSectionData(
                                                                  value: 100 -
                                                                      susScore,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  title: '',
                                                                  radius: 20)
                                                            ]))))
                                              ]),
                                              const Divider(),
                                              GridView.count(
                                                  shrinkWrap: true,
                                                  crossAxisCount: 3,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  children: [
                                                    _buildActionButton(
                                                        Icons.picture_as_pdf,
                                                        "PDF",
                                                        Colors.red,
                                                        () => _exportToPDF(
                                                            filteredDocs)),
                                                    _buildActionButton(
                                                        Icons.table_chart,
                                                        "Excel",
                                                        Colors.green,
                                                        () => _exportToExcel(
                                                            filteredDocs)),
                                                    _buildActionButton(
                                                        Icons.delete_forever,
                                                        "Reset",
                                                        Colors.redAccent,
                                                        () => _resetAntrian(
                                                            context)),
                                                  ])
                                            ]))
                                      ])),
                              const SizedBox(height: 10),
                              TextField(
                                  controller: _searchController,
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  decoration: const InputDecoration(
                                      labelText: "Cari Pasien",
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder())),
                              SwitchListTile(
                                  title: const Text("Filter: Hari Ini"),
                                  value: _filterHariIni,
                                  onChanged: (v) =>
                                      setState(() => _filterHariIni = v)),
                            ]))),
                SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                  final doc = filteredDocs[index];
                  return PasienCard(
                      data: doc.data() as Map<String, dynamic>,
                      docId: doc.id,
                      index: index,
                      hitungEstimasi: hitungEstimasiWaktu,
                      onUpdateStatus: _updateStatus,
                      onFinish: _berikanPoinSetelahSelesai);
                }, childCount: filteredDocs.length)),
              ],
            );
          },
        );
      },
    );
  }
}

// --- WIDGET PASIEN DENGAN ANIMASI DENYUT TEBAL & ESTIMASI ---
class PasienCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final int index;
  final Function(int) hitungEstimasi;
  final Function(String, String, String) onUpdateStatus;
  final Function(String?, String) onFinish;

  const PasienCard(
      {super.key,
      required this.data,
      required this.docId,
      required this.index,
      required this.hitungEstimasi,
      required this.onUpdateStatus,
      required this.onFinish});
  @override
  State<PasienCard> createState() => _PasienCardState();
}

class _PasienCardState extends State<PasienCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] ?? 'Menunggu';
    final nama = widget.data['nama'] ?? 'Pasien';
    final color = status == 'Selesai'
        ? Colors.green
        : (status == 'Sedang Diperiksa' ? Colors.orange : Colors.blueAccent);

    return FadeTransition(
      opacity: Tween(begin: 0.7, end: 1.0).animate(_animation),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: color, width: 8)),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 0))
            ]),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Text(nama[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          title:
              Text(nama, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.data['keluhan'] ?? '-'),
            const SizedBox(height: 5),
            FutureBuilder<int>(
              future: widget.hitungEstimasi(widget.index),
              builder: (ctx, snap) => Text(
                  snap.hasData
                      ? "Estimasi: ${snap.data} mnt lagi"
                      : "Menghitung...",
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold)),
            )
          ]),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                icon: const Icon(Icons.play_circle_fill,
                    color: Colors.blueAccent),
                onPressed: () => widget.onUpdateStatus(
                    widget.docId, 'Sedang Diperiksa', nama)),
            IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () {
                  widget.onUpdateStatus(widget.docId, 'Selesai', nama);
                  widget.onFinish(widget.data['userId'], nama);
                }),
          ]),
        ),
      ),
    );
  }
}
