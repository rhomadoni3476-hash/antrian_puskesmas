import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Provider & Screens
import '../theme_provider.dart';
import '../edit_profile_screen.dart';
import '../reward_screen.dart';
import '../ringkasan_riwayat_screen.dart';
import '../health_tracker_screen.dart';
import '../riwayat_kesehatan_screen.dart';
import '../faq_screen.dart';
import '../dashboard_dokter_screen.dart';
import '../admin_dashboard_screen.dart';
import '../daftar_stok_screen.dart';
import '../input_stok_masuk_screen.dart';
import '../log_transaksi_screen.dart';
import '../login_pasien_screen.dart';
import '../usability_survey_screen.dart'; // <--- IMPORT SURVEI DITAMBAHKAN

class HomeDrawer extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(BuildContext, Widget) navigateWithFade;
  final Color primaryColor;

  const HomeDrawer({
    super.key,
    required this.data,
    required this.navigateWithFade,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final String role = data?['role'] ?? 'pasien';
    final bool isAdmin = role == 'admin';
    final bool isDokter = role == 'dokter';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            accountName: Text(data?['nama'] ?? "Pasien",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10)),
              child: Text("Poin: ${data?['poin'] ?? 0}",
                  style: const TextStyle(color: Colors.white)),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.redAccent),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                _buildDrawerItem(context, Icons.edit_rounded, "Edit Profil",
                    const EditProfileScreen()),
                _buildDrawerItem(context, Icons.card_giftcard_rounded,
                    "Reward Poin", const RewardScreen()),
                _buildDrawerItem(context, Icons.medical_information_rounded,
                    "Rekam Medis Digital", const RingkasanRiwayatScreen()),
                const Divider(indent: 20, endIndent: 20),
                _buildDrawerItem(context, Icons.monitor_heart_rounded,
                    "Input Data Kesehatan", const HealthTrackerScreen()),
                _buildDrawerItem(context, Icons.history_rounded,
                    "Riwayat Kesehatan", const RiwayatKesehatanScreen()),
                _buildDrawerItem(context, Icons.help_outline_rounded,
                    "Pusat Bantuan / FAQ", const FaqScreen()),

                // --- MENU SURVEY SUS ---
                _buildDrawerItem(context, Icons.star_rate_rounded,
                    "Survei Kepuasan (SUS)", const UsabilitySurveyScreen()),

                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SwitchListTile(
                      secondary: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: primaryColor),
                      title: Text("Dark Mode",
                          style: GoogleFonts.poppins(fontSize: 14)),
                      value: themeProvider.isDarkMode,
                      onChanged: (val) => themeProvider.toggleTheme(),
                    );
                  },
                ),

                if (isAdmin || isDokter) ...[
                  const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text("ADMIN & DOKTER",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey))),
                  if (isDokter)
                    _buildDrawerItem(context, Icons.medical_services_rounded,
                        "Dashboard Dokter", const DashboardDokterScreen()),
                  if (isAdmin) ...[
                    _buildDrawerItem(
                        context,
                        Icons.admin_panel_settings_rounded,
                        "Dashboard Admin",
                        const AdminDashboardScreen()),
                    _buildDrawerItem(context, Icons.inventory_2_rounded,
                        "Manajemen Stok Obat", const DaftarStokScreen()),
                    _buildDrawerItem(context, Icons.add_box_rounded,
                        "Input Stok Masuk", const InputStokMasukScreen()),
                    _buildDrawerItem(context, Icons.history_edu_rounded,
                        "Log Transaksi Obat", const LogTransaksiScreen()),
                  ]
                ],
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text("Logout",
                style: GoogleFonts.poppins(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginPasienScreen()),
                    (route) => false);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(title,
          style:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        navigateWithFade(context, screen);
      },
    );
  }
}
