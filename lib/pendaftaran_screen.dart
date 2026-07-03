import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'privacy_provider.dart';
import 'tiket_antrian_screen.dart';
import 'api_service.dart'; // Pastikan file ini ada

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

  // Variabel lokal untuk menyimpan nama asli agar tidak hilang saat masking
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
      final response = await http.post(
        Uri.parse('http://192.168.100.25:8000/deteksi-poli'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'keluhan': keluhan}),
      );
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
      debugPrint("FastAPI tidak merespon: $e");
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nikController.text = data['nik'] ?? '';
          _namaAsli = data['nama'] ?? '';
          _namaController.text = _namaAsli;
        });
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
      // 1. Kirim ke FastAPI
      final dataBackend = {
        'nik': _nikController.text,
        'nama_pasien': _namaAsli,
        'keluhan': _keluhanController.text,
        'status': 'Menunggu',
      };
      await ApiService.tambahRekamMedis(dataBackend);

      // 2. Kirim ke Firebase
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal mendaftar: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pendaftaran"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          Consumer<PrivacyProvider>(
              builder: (context, p, _) => IconButton(
                    icon: Icon(
                        p.isPrivate ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => p.togglePrivacy(),
                  )),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFFFF1F0), Color(0xFFFFCDD2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.redAccent))
            : ListView(padding: const EdgeInsets.all(20), children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      if (!_isPuskesmasOpen)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Text("Puskesmas tutup saat ini.",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ),
                      TextFormField(
                          controller: _nikController,
                          readOnly: true,
                          decoration: const InputDecoration(
                              labelText: "NIK",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge))),
                      const SizedBox(height: 15),
                      Consumer<PrivacyProvider>(builder: (context, p, _) {
                        // Update controller teks berdasarkan mode privasi
                        _namaController.text =
                            p.isPrivate && _namaAsli.isNotEmpty
                                ? "${_namaAsli[0]}****"
                                : _namaAsli;

                        return TextFormField(
                            controller: _namaController,
                            readOnly: true,
                            decoration: const InputDecoration(
                                labelText: "Nama Lengkap",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person)));
                      }),
                      const SizedBox(height: 15),
                      _buildPoliDropdown(),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _keluhanController,
                        onChanged: (val) => _deteksiPoliViaFastAPI(val),
                        decoration: const InputDecoration(
                            labelText: "Keluhan",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.medical_services)),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 25),
                      FilledButton(
                        onPressed: _isPuskesmasOpen ? _submitPendaftaran : null,
                        style: FilledButton.styleFrom(
                            backgroundColor: _isPuskesmasOpen
                                ? Colors.redAccent
                                : Colors.grey,
                            minimumSize: const Size(double.infinity, 50)),
                        child: Text(_isPuskesmasOpen
                            ? "DAFTAR SEKARANG"
                            : "PUSKESMAS TUTUP"),
                      ),
                    ]),
                  ),
                ),
              ]),
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
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final items = snapshot.data!.docs
            .map((d) => (d.data() as Map)['nama_poli'] as String)
            .toList();
        return DropdownButtonFormField<String>(
          value: items.contains(_selectedPoli) ? _selectedPoli : null,
          items: items
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (val) => setState(() {
            _selectedPoli = val;
            _isManuallySelected = true;
          }),
          decoration: const InputDecoration(
              labelText: "Pilih Poli Tujuan",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_hospital)),
        );
      },
    );
  }
}
