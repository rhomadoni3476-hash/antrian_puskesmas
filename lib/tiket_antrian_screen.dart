import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_nav_screen.dart';

class TiketAntrianScreen extends StatefulWidget {
  final String antrianId;
  final String nomorAntrian;
  final String namaPasien;

  const TiketAntrianScreen({
    super.key,
    required this.antrianId,
    required this.nomorAntrian,
    required this.namaPasien,
  });

  @override
  State<TiketAntrianScreen> createState() => _TiketAntrianScreenState();
}

class _TiketAntrianScreenState extends State<TiketAntrianScreen>
    with SingleTickerProviderStateMixin {
  bool _isDialogShowing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Helper untuk menentukan warna berdasarkan prioritas
  Color _getPriorityColor(String? prioritas) {
    switch (prioritas) {
      case 'Merah':
        return Colors.red;
      case 'Kuning':
        return Colors.amber.shade800;
      case 'Hijau':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    String tanggalHariIni =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('antrian')
          .doc(widget.antrianId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator(color: Colors.redAccent)));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final String status = data?['status'] ?? 'Menunggu';
        final String prioritas = data?['prioritas'] ?? 'Hijau';

        if (status == 'Sedang Diperiksa' && !_isDialogShowing) {
          _isDialogShowing = true;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showPanggilanDialog(context));
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getPriorityColor(prioritas),
                  _getPriorityColor(prioritas).withOpacity(0.8)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("BUKTI PENDAFTARAN",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    const SizedBox(height: 30),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 20,
                                  offset: Offset(0, 10))
                            ]),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatusBadge(status),
                            const SizedBox(height: 10),
                            // Tambahan: Badge Prioritas
                            _buildPriorityBadge(prioritas),
                            const SizedBox(height: 20),
                            const Text("NOMOR ANTRIAN",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold)),
                            ScaleTransition(
                              scale: Tween(begin: 0.95, end: 1.05)
                                  .animate(_pulseController),
                              child: Text(widget.nomorAntrian,
                                  style: TextStyle(
                                      fontSize: 90,
                                      fontWeight: FontWeight.w900,
                                      color: _getPriorityColor(prioritas))),
                            ),
                            Text(widget.namaPasien.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF263238))),
                            const SizedBox(height: 10),
                            Text(tanggalHariIni,
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20))),
                        onPressed: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HomeNavScreen()),
                            (route) => false),
                        child: const Text("KEMBALI KE BERANDA",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'Selesai'
        ? Colors.green
        : (status == 'Sedang Diperiksa' ? Colors.orange : Colors.blue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30)),
      child: Text("STATUS: ${status.toUpperCase()}",
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  // Tambahan: Badge untuk menampilkan level prioritas (Merah/Kuning/Hijau)
  Widget _buildPriorityBadge(String prioritas) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
          color: _getPriorityColor(prioritas).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10)),
      child: Text("PRIORITAS: ${prioritas.toUpperCase()}",
          style: TextStyle(
              color: _getPriorityColor(prioritas),
              fontWeight: FontWeight.bold,
              fontSize: 12)),
    );
  }

  void _showPanggilanDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.notifications_active,
            color: Colors.orange, size: 50),
        content: const Text(
            "Panggilan Antrian!\nMohon segera menuju ruang periksa.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16)),
        actions: [
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              onPressed: () {
                setState(() => _isDialogShowing = false);
                Navigator.pop(context);
              },
              child: const Text("SAYA MENGERTI"),
            ),
          ),
        ],
      ),
    );
  }
}
