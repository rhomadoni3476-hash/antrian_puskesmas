import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'privacy_provider.dart';
import 'tiket_antrian_screen.dart';
import 'api_service.dart';

const String BASE_URL = "https://antrianpuskesmas-production.up.railway.app";

class PendaftaranScreen extends StatefulWidget {
  final String? keluhan;
  final String? poliSaran;
  const PendaftaranScreen({super.key, this.keluhan, this.poliSaran});

  @override
  State<PendaftaranScreen> createState() => _PendaftaranScreenState();
}

class _PendaftaranScreenState extends State<PendaftaranScreen> {
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _keluhanController = TextEditingController();

  String _namaAsli = "";
  String? _selectedPoli;
  bool _isLoading = false;
  bool _isAutoDetected = false;
  bool _isManuallySelected = false;

  bool get _isPuskesmasOpen {
    final now = DateTime.now();
    return now.hour >= 8 && now.hour < 16;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();

    if (widget.keluhan != null) {
      _keluhanController.text = widget.keluhan!;
      _deteksiPoliViaFastAPI(widget.keluhan!);
    }

    if (widget.poliSaran != null) {
      _selectedPoli = widget.poliSaran;
      _isManuallySelected = true;
      _isAutoDetected = true;
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _keluhanController.dispose();
    super.dispose();
  }

  Future<void> _deteksiPoliViaFastAPI(String keluhan) async {
    if (_isManuallySelected || keluhan.length < 5) return;
    try {
      final response = await http
          .post(
            Uri.parse('$BASE_URL/deteksi-poli'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'keluhan': keluhan}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _selectedPoli = data['poli'];
            _isAutoDetected = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal deteksi poli: $e");
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nikController.text = data['nik'] ?? '';
            _namaAsli = data['nama'] ?? '';
            _namaController.text = _namaAsli;
          });
        }
      } catch (e) {
        debugPrint("Error load user: $e");
      }
    }
  }

  Future<void> _submitPendaftaran() async {
    if (_nikController.text.length < 16) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("NIK harus 16 digit!")));
      return;
    }
    if (_selectedPoli == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pilih poli tujuan!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // BAGIAN PENTING: Jika API Service Anda memicu error Admin,
      // Anda harus memverifikasi apakah endpoint API tersebut memang mewajibkan login Admin.
      // Jika ya, hapus baris `await ApiService.tambahRekamMedis(dataBackend)`
      // atau perbaiki backend untuk mengizinkan user biasa.
      final dataBackend = {
        'nik': _nikController.text,
        'nama_pasien': _namaAsli,
        'keluhan': _keluhanController.text,
        'status': 'Menunggu',
      };

      // Jika Anda yakin error berasal dari sini, comment baris ini untuk testing:
      await ApiService.tambahRekamMedis(dataBackend)
          .timeout(const Duration(seconds: 10));

      final User? user = FirebaseAuth.instance.currentUser;
      String token = !kIsWeb
          ? (await FirebaseMessaging.instance.getToken() ?? "FCM_UNAVAILABLE")
          : "WEB";
      final String strNomor =
          'A-${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}';

      final dataAntrian = {
        'nik': _nikController.text,
        'nama': _namaAsli,
        'poli': _selectedPoli,
        'keluhan': _keluhanController.text,
        'nomor_antrian': strNomor,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Menunggu',
        'token': token,
        'userId': user?.uid ?? "guest",
      };

      final batch = FirebaseFirestore.instance.batch();
      final antrianRef = FirebaseFirestore.instance.collection('antrian').doc();
      final riwayatRef =
          FirebaseFirestore.instance.collection('riwayat_diagnosis').doc();

      batch.set(antrianRef, dataAntrian);
      batch.set(riwayatRef,
          {...dataAntrian, 'hasil_diagnosis': _keluhanController.text});
      await batch.commit();

      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => TiketAntrianScreen(
                    antrianId: antrianRef.id,
                    nomorAntrian: strNomor,
                    namaPasien: _namaAsli)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Debugging: Kita tampilkan error yang lebih detail
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal mendaftar: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Pendaftaran Antrian",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.black87)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          Consumer<PrivacyProvider>(
              builder: (context, p, _) => IconButton(
                    icon: Icon(
                        p.isPrivate
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.black87),
                    onPressed: () => p.togglePrivacy(),
                  )),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!_isPuskesmasOpen)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16)),
                    child: Text(
                        "Puskesmas sedang tutup (Operasional: 08:00 - 16:00)",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      _buildModernInput(_nikController, "NIK Pasien",
                          Icons.badge_outlined, true),
                      const SizedBox(height: 16),
                      Consumer<PrivacyProvider>(builder: (context, p, _) {
                        _namaController.text =
                            p.isPrivate && _namaAsli.isNotEmpty
                                ? "${_namaAsli[0]}****"
                                : _namaAsli;
                        return _buildModernInput(_namaController,
                            "Nama Lengkap", Icons.person_outline, true);
                      }),
                      const SizedBox(height: 16),
                      _buildPoliDropdown(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _keluhanController,
                        onChanged: (val) => _deteksiPoliViaFastAPI(val),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Keluhan",
                          hintText: "Jelaskan keluhan Anda...",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(
                              Icons.medical_services_outlined,
                              color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 55,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (_isPuskesmasOpen && _selectedPoli != null)
                              ? _submitPendaftaran
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                (_isPuskesmasOpen && _selectedPoli != null)
                                    ? Colors.redAccent
                                    : Colors.grey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                              _isPuskesmasOpen
                                  ? "DAFTAR SEKARANG"
                                  : "PUSKESMAS TUTUP",
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModernInput(TextEditingController controller, String label,
      IconData icon, bool isReadOnly) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        prefixIcon: Icon(icon, color: Colors.redAccent),
      ),
    );
  }

  Widget _buildPoliDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('poli')
          .where('status', isEqualTo: 'buka')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LinearProgressIndicator();
        final items = snapshot.hasData
            ? snapshot.data!.docs
                .map((d) =>
                    (d.data() as Map<String, dynamic>)['nama_poli'] as String)
                .toList()
            : <String>[];

        return DropdownButtonFormField<String>(
          value: items.contains(_selectedPoli) ? _selectedPoli : null,
          items: items
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (val) => setState(() {
            _selectedPoli = val;
            _isManuallySelected = true;
          }),
          decoration: InputDecoration(
            labelText: "Pilih Poli Tujuan",
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.local_hospital_outlined,
                color: Colors.redAccent),
          ),
        );
      },
    );
  }
}
