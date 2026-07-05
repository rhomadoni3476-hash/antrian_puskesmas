import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import Screen dependencies
import '../health_tracker_screen.dart';
import '../reward_screen.dart';
import '../ringkasan_riwayat_screen.dart';
import '../faq_screen.dart';
import '../diagnosis_screen.dart';
import '../article_detail_screen.dart';
import '../admin_dashboard_screen.dart';
import '../usability_survey_screen.dart';
import '../antrian_pasien_view.dart';

class HomeDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(BuildContext, Widget) navigateWithFade;

  const HomeDashboard({
    super.key,
    required this.userData,
    required this.navigateWithFade,
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.userData?['role'] == 'admin';
    final bool tampilkanRating = !isAdmin &&
        (widget.userData?['sudah_selesai_antrian'] ?? false) &&
        !(widget.userData?['sudah_memberi_rating'] ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_survey",
        onPressed: () =>
            widget.navigateWithFade(context, const UsabilitySurveyScreen()),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.analytics_outlined),
        label: const Text("Beri Masukan"),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _animation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isAdmin),
                const SizedBox(height: 30),
                if (!isAdmin) _buildMiniStatusAntrian(context),
                if (tampilkanRating) ...[
                  _buildRatingCard(context),
                  const SizedBox(height: 30),
                ],
                if (isAdmin) ...[
                  _buildSectionTitle("Statistik Kunjungan"),
                  const SizedBox(height: 15),
                  _buildGrafikStatistik(),
                  const SizedBox(height: 30),
                ],
                _buildHeroCard(context),
                const SizedBox(height: 30),
                _buildSectionTitle("Info Kesehatan"),
                const SizedBox(height: 15),
                _buildInfoList(context),
                const SizedBox(height: 30),
                _buildSectionTitle("Menu Layanan"),
                const SizedBox(height: 15),
                _buildMenuGrid(context, isAdmin),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET KOMPONEN ---

  Widget _buildMiniStatusAntrian(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('antrian')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        return GestureDetector(
          onTap: () =>
              widget.navigateWithFade(context, const AntrianPasienView()),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.blueAccent),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Status Antrian Saya",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(data['status'] ?? 'Menunggu',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isAdmin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAdmin ? "Selamat Datang," : "Halo,",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: Colors.grey.shade600)),
            Text(
                widget.userData?['nama'] ??
                    (isAdmin ? "Admin Puskesmas" : "Pasien"),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 24, fontWeight: FontWeight.w800)),
          ],
        ),
        const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.person, color: Colors.white)),
      ],
    );
  }

  Widget _buildMenuGrid(BuildContext context, bool isAdmin) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildMenuCard(
            Icons.monitor_heart,
            "Health Tracker",
            Colors.purple,
            () =>
                widget.navigateWithFade(context, const HealthTrackerScreen())),
        _buildMenuCard(Icons.card_giftcard, "Reward Poin", Colors.orange,
            () => widget.navigateWithFade(context, const RewardScreen())),
        _buildMenuCard(
            Icons.medical_information,
            "Rekam Medis",
            Colors.teal,
            () => widget.navigateWithFade(
                context, const RingkasanRiwayatScreen())),
        _buildMenuCard(
            Icons.queue_play_next,
            "Antrian Saya",
            Colors.indigoAccent,
            () => widget.navigateWithFade(context, const AntrianPasienView())),
        _buildMenuCard(Icons.help_outline, "Pusat Bantuan", Colors.blue,
            () => widget.navigateWithFade(context, const FaqScreen())),
        if (isAdmin)
          _buildMenuCard(
              Icons.admin_panel_settings,
              "Admin Panel",
              Colors.redAccent,
              () => widget.navigateWithFade(
                  context, const AdminDashboardScreen())),
      ],
    );
  }

  Widget _buildMenuCard(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _buildRatingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.amber.shade200)),
      child: Column(children: [
        Text("Beri Penilaian Layanan",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              shape: const StadiumBorder()),
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .update({'sudah_memberi_rating': true});
          },
          child: const Text("KIRIM",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildGrafikStatistik() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
          height: 180,
          child: PieChart(PieChartData(sections: [
            PieChartSectionData(
                value: 45,
                color: Colors.blue.shade400,
                title: '45%',
                radius: 50),
            PieChartSectionData(
                value: 30,
                color: Colors.green.shade400,
                title: '30%',
                radius: 50),
            PieChartSectionData(
                value: 25,
                color: Colors.orange.shade400,
                title: '25%',
                radius: 50),
          ]))),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)]),
          borderRadius: BorderRadius.circular(28)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Diagnosis Mandiri",
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.redAccent,
              shape: const StadiumBorder()),
          onPressed: () =>
              widget.navigateWithFade(context, const DiagnosisScreen()),
          child: const Text("MULAI DIAGNOSIS",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildInfoList(BuildContext context) {
    return SizedBox(
        height: 160,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          _buildArticleCard(
              "Pola Hidup",
              "Pola Hidup Sehat adalah Investasi terbaik anda.",
              Icons.favorite_outline,
              Colors.blue,
              () => widget.navigateWithFade(
                  context,
                  const ArticleDetailScreen(
                      title: "Pola Hidup",
                      subtitle: "Tips",
                      themeColor: Colors.blue,
                      content:
                          "Kesehatan bukan hanya tentang tidak sakit, tapi tentang bagaimana menjaga pola hidup agar selalu bugar dan prima setiap hari, mulailah dari makanan dan minuman yang di konsumsi serta rucin cek kesehatan di puskesmas terdekat"))),
          _buildArticleCard(
              "Vaksinasi",
              "Perisai Kuat Anda Dan Keluarga Anda.",
              Icons.shield_outlined,
              Colors.green,
              () => widget.navigateWithFade(
                  context,
                  const ArticleDetailScreen(
                      title: "Vaksinasi",
                      subtitle: "Jadwal",
                      themeColor: Colors.green,
                      content:
                          "Mencegah selalu lebih baik dari pada mengobati, makanya itu sebelum jatuh sakit alangkah baik nya melakukan vaksinasi sesuai yang di anjurkan di puskesmas"))),
          _buildArticleCard(
              "Manajemen",
              "Seni Mengelola Pikiran Dan Emosi.",
              Icons.psychology_outlined,
              Colors.purple,
              () => widget.navigateWithFade(
                  context,
                  const ArticleDetailScreen(
                      title: "Manajemen",
                      subtitle: "Cara",
                      themeColor: Colors.purple,
                      content:
                          "Jika kita ingin hidup sehat maka dimulai dari pikiran kita yang jernih, pikiran jernih tercipta oleh aktivitas yang bersih juga. Seperti rajin berolahraga, makan makanan sehat, dan jaga pola tidur."))),
        ]));
  }

  Widget _buildArticleCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
        onTap: onTap,
        child: Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: color, size: 28),
              const Spacer(),
              Text(title,
                  style:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: Colors.grey))
            ])));
  }
}
