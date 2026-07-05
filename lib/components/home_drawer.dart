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
import '../usability_survey_screen.dart';
import '../riwayat_antrian_screen.dart';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header Gradient Modern
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.only(topRight: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.person, size: 35, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data?['nama'] ?? "Pasien",
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  "Poin: ${data?['poin'] ?? 0}",
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 15, left: 12, right: 12),
              children: [
                _buildDrawerItem(context, Icons.edit_rounded, "Edit Profil",
                    const EditProfileScreen()),
                _buildDrawerItem(context, Icons.card_giftcard_rounded,
                    "Reward Poin", const RewardScreen()),
                _buildDrawerItem(context, Icons.medical_information_rounded,
                    "Rekam Medis Digital", const RingkasanRiwayatScreen()),
                _buildDrawerItem(context, Icons.history_edu_rounded,
                    "Riwayat Antrian", const RiwayatAntrianScreen()),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider()),
                _buildDrawerItem(context, Icons.monitor_heart_rounded,
                    "Input Data Kesehatan", const HealthTrackerScreen()),
                _buildDrawerItem(context, Icons.history_rounded,
                    "Riwayat Kesehatan", const RiwayatKesehatanScreen()),
                _buildDrawerItem(context, Icons.star_rate_rounded,
                    "Survei Kepuasan (SUS)", const UsabilitySurveyScreen()),
                _buildDrawerItem(context, Icons.help_outline_rounded,
                    "Pusat Bantuan / FAQ", const FaqScreen()),
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
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    child: Text("MANAJEMEN SISTEM",
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                  ),
                  if (isDokter)
                    _buildAdminItem(
                        context,
                        Icons.medical_services_rounded,
                        "Dashboard Dokter",
                        const DashboardDokterScreen(),
                        Colors.teal),
                  if (isAdmin) ...[
                    _buildAdminItem(
                        context,
                        Icons.admin_panel_settings_rounded,
                        "Dashboard Admin",
                        const AdminDashboardScreen(),
                        Colors.purple),
                    _buildAdminItem(
                        context,
                        Icons.inventory_2_rounded,
                        "Manajemen Stok Obat",
                        const DaftarStokScreen(),
                        Colors.orange),
                    _buildAdminItem(
                        context,
                        Icons.add_box_rounded,
                        "Input Stok Masuk",
                        const InputStokMasukScreen(),
                        Colors.green),
                    _buildAdminItem(
                        context,
                        Icons.history_rounded,
                        "Log Transaksi Obat",
                        const LogTransaksiScreen(),
                        Colors.blueGrey),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Icon(icon, color: primaryColor, size: 22),
        title: Text(title,
            style:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        onTap: () {
          Navigator.pop(context);
          navigateWithFade(context, screen);
        },
      ),
    );
  }

  Widget _buildAdminItem(BuildContext context, IconData icon, String title,
      Widget screen, Color iconColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: iconColor.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title,
            style:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        onTap: () {
          Navigator.pop(context);
          navigateWithFade(context, screen);
        },
      ),
    );
  }
}
