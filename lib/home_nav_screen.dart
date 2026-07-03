import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'components/home_dashboard.dart';
import 'components/home_drawer.dart';
import 'pendaftaran_screen.dart';
import 'antrian_aktif_screen.dart';
import 'riwayat_diagnosis_screen.dart';
import 'tele_konsultasi_screen.dart';
import 'login_pasien_screen.dart';
import 'input_rekam_medis_screen.dart';
import 'admin_rekam_medis_screen.dart';
import 'usability_survey_screen.dart';

class HomeNavScreen extends StatefulWidget {
  const HomeNavScreen({super.key});
  @override
  State<HomeNavScreen> createState() => _HomeNavScreenState();
}

class _HomeNavScreenState extends State<HomeNavScreen> {
  int _currentIndex = 0;
  final User? _user = FirebaseAuth.instance.currentUser;
  final Color primaryColor = Colors.redAccent;

  // Menggunakan Map untuk menyimpan data user sementara
  Map<String, dynamic>? _userData;

  void navigateWithFade(BuildContext context, Widget screen) {
    Navigator.of(context).push(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim, secAnim) => screen,
        transitionsBuilder: (context, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child)));
  }

  // --- FUNGSI DARURAT ---
  Future<void> _kirimSinyalDarurat(BuildContext context) async {
    if (_user == null) return;

    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: const Text("Panggilan Darurat"),
              content: const Text("Kirim sinyal bantuan darurat ke admin?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Batal")),
                ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true),
                    child:
                        const Text("YA", style: TextStyle(color: Colors.white)))
              ],
            ));

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.redAccent)),
    );

    try {
      await FirebaseFirestore.instance.collection('darurat').add({
        'userId': _user!.uid,
        'status': 'Butuh Bantuan',
        'timestamp': FieldValue.serverTimestamp()
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Sinyal darurat terkirim!"),
          backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }

  Future<void> _onTabTapped(int index) async {
    HapticFeedback.lightImpact();
    // Proteksi: Hanya bisa akses menu Daftar (index 2) jika NIK ada
    if (index == 2 &&
        (_userData == null || (_userData!['nik'] ?? '').isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Lengkapi profil NIK di Drawer sebelum mendaftar!"),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const LoginPasienScreen();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          _userData = snapshot.data!.data() as Map<String, dynamic>?;
        }

        // Tampilkan loading HANYA saat data benar-benar belum ada
        if (_userData == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final bool isAdmin = _userData?['role'] == 'admin';

        final List<Widget> pages = [
          HomeDashboard(
              userData: _userData, navigateWithFade: navigateWithFade),
          const TeleKonsultasiScreen(),
          const PendaftaranScreen(),
          const AntrianAktifScreen(),
          const RiwayatDiagnosisScreen(),
        ];

        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            title: Text(isAdmin ? "Admin Dashboard" : "Puskesmas Digital"),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.history_edu),
                  tooltip: "Data Rekam Medis",
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminRekamMedisScreen())),
                )
            ],
          ),
          floatingActionButton: _buildFAB(isAdmin),
          drawer: HomeDrawer(
              data: _userData,
              navigateWithFade: navigateWithFade,
              primaryColor: primaryColor),
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }

  Widget? _buildFAB(bool isAdmin) {
    if (isAdmin) {
      return FloatingActionButton.extended(
        backgroundColor: Colors.green,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const InputRekamMedisScreen())),
        label: const Text("Input Data"),
        icon: const Icon(Icons.add),
      );
    } else if (_currentIndex == 0) {
      return FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => _kirimSinyalDarurat(context),
        child: const Icon(Icons.emergency),
      );
    }
    return null;
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_filled), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded), label: "Tele"),
            BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_rounded), label: "Daftar"),
            BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_rounded), label: "Antrian"),
            BottomNavigationBarItem(
                icon: Icon(Icons.assignment_turned_in_rounded),
                label: "Riwayat"),
          ],
        ),
      ),
    );
  }
}
