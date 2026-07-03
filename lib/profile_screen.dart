import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart'; // Import service untuk hapus token API

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nikController = TextEditingController();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _teleponController = TextEditingController();

  bool _isLoading = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _nikController.text = data['nik'] ?? '';
            _namaController.text = data['nama'] ?? '';
            _alamatController.text = data['alamat'] ?? '';
            _teleponController.text = data['telepon'] ?? '';
            _isVerified = data['isVerified'] ?? false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _simpanProfil() async {
    // Validasi NIK (minimal 16 digit)
    if (_nikController.text.length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("NIK harus 16 digit"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nik': _nikController.text.trim(),
          'nama': _namaController.text.trim(),
          'alamat': _alamatController.text.trim(),
          'telepon': _teleponController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Profil berhasil diperbarui!"),
              backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    // 1. Logout dari Firebase Auth
    await FirebaseAuth.instance.signOut();
    // 2. Hapus Token JWT di Secure Storage agar tidak bisa akses API lagi
    await AuthService.logout();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
          title: const Text('Profil Pasien',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.person,
                              size: 60, color: Colors.white)),
                      if (_isVerified)
                        const CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.verified,
                                color: Colors.blue, size: 28)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                      _isVerified
                          ? "Akun Terverifikasi"
                          : "Akun Belum Terverifikasi",
                      style: TextStyle(
                          color: _isVerified ? Colors.blue : Colors.grey,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  _buildTextField("NIK (16 Digit)", _nikController, Icons.badge,
                      keyboardType: TextInputType.number),
                  _buildTextField(
                      "Nama Lengkap", _namaController, Icons.person),
                  _buildTextField("Alamat", _alamatController, Icons.home),
                  _buildTextField(
                      "Nomor Telepon", _teleponController, Icons.phone,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      onPressed: _simpanProfil,
                      child: const Text('Simpan Profil',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text("Keluar Akun",
                          style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.redAccent),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none)),
      ),
    );
  }
}
