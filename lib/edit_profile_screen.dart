import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Untuk InputFormatter

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _telpController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _namaController.text = data['nama'] ?? '';
        _alamatController.text = data['alamat'] ?? '';
        _telpController.text = data['telepon'] ?? '';
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .update({
        'nama': _namaController.text.trim(),
        'alamat': _alamatController.text.trim(),
        'telepon': _telpController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profil berhasil diperbarui")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _telpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                        labelText: "Nama Lengkap",
                        border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Nama wajib diisi" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _alamatController,
                    decoration: const InputDecoration(
                        labelText: "Alamat", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Alamat wajib diisi" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _telpController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(13),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Nomor HP",
                      border: OutlineInputBorder(),
                      prefixText: "+62 ",
                    ),
                    validator: (v) =>
                        (v!.length < 10) ? "Nomor tidak valid" : null,
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("SIMPAN PERUBAHAN"),
                  ),
                ],
              ),
            ),
    );
  }
}
