import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Screens
import 'pendaftaran_screen.dart';
import 'riwayat_screen.dart';
import 'antrian_aktif_screen.dart';
import 'diagnosis_screen.dart';
import 'riwayat_diagnosis_screen.dart';
import 'tele_konsultasi_screen.dart';
import 'admin_dashboard_screen.dart';
import 'dashboard_dokter_screen.dart';
import 'login_pasien_screen.dart';
import 'usability_survey_screen.dart'; // Import layar survei

class DashboardPasienScreen extends StatelessWidget {
  const DashboardPasienScreen({super.key});

  Future<void> _switchRole(BuildContext context, String role) async {
    Navigator.pop(context);
    Widget target = role == 'admin'
        ? const AdminDashboardScreen()
        : const DashboardDokterScreen();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => target));
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Dashboard Pasien"),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderProfile(),
            const SizedBox(height: 25),

            const Text("Diagnosis Terakhir Anda:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildLastDiagnosisCard(userId),
            const SizedBox(height: 25),

            // Grid Menu
            SizedBox(
              height: 350, // Ditingkatkan tingginya untuk memuat menu survei
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.5,
                children: [
                  _buildMenuCard(
                      context,
                      "Antrian",
                      Icons.list_alt,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AntrianAktifScreen()))),
                  _buildMenuCard(
                      context,
                      "Diagnosis",
                      Icons.medical_services,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DiagnosisScreen()))),
                  _buildMenuCard(
                      context,
                      "Tele-Konsul",
                      Icons.chat_bubble_outline,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TeleKonsultasiScreen()))),
                  _buildMenuCard(
                      context,
                      "Riwayat",
                      Icons.history,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RiwayatDiagnosisScreen()))),
                  // Shortcut Survei SUS
                  _buildMenuCard(
                      context,
                      "Beri Masukan (SUS)",
                      Icons.star_rate,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UsabilitySurveyScreen()))),
                ],
              ),
            ),

            _buildEdukasiSection(),
          ],
        ),
      ),
    );
  }

  // ... [Fungsi _buildEdukasiSection, _buildHeaderProfile, _buildLastDiagnosisCard, _buildMenuCard tetap sama]

  Widget _buildEdukasiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tips Kesehatan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tips_kesehatan')
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.amber),
                        const SizedBox(height: 5),
                        Text(data['judul'] ?? 'Tips',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF00796B),
          borderRadius: BorderRadius.circular(15)),
      child: const Row(
        children: [
          CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF00796B))),
          SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Selamat Datang,", style: TextStyle(color: Colors.white70)),
            Text("Pasien Digital",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ])
        ],
      ),
    );
  }

  Widget _buildLastDiagnosisCard(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('riwayat_diagnosis')
          .where('userId', isEqualTo: userId ?? 'guest')
          .orderBy('tanggal', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Card(
              child: ListTile(title: Text("Belum ada diagnosis.")));
        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.favorite, color: Colors.redAccent),
            title: Text(data['penyakit'] ?? '-',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Akurasi: ${data['keyakinan'] ?? '0%'}"),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 30, color: const Color(0xFF00796B)),
          const SizedBox(height: 5),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF00796B)),
            accountName: Text("User Pasien"),
            accountEmail: Text("Mode Pasien"),
            currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF00796B))),
          ),
          ListTile(
              leading: const Icon(Icons.star_rate, color: Colors.amber),
              title: const Text("Beri Masukan (Survei SUS)"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UsabilitySurveyScreen()));
              }),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Ke Admin"),
              onTap: () => _switchRole(context, 'admin')),
          ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text("Ke Dokter"),
              onTap: () => _switchRole(context, 'dokter')),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted)
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginPasienScreen()),
                    (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
