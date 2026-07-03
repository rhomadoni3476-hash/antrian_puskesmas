import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InputStokMasukScreen extends StatefulWidget {
  const InputStokMasukScreen({super.key});

  @override
  State<InputStokMasukScreen> createState() => _InputStokMasukScreenState();
}

class _InputStokMasukScreenState extends State<InputStokMasukScreen> {
  String? _selectedObatId;
  String? _selectedObatNama;
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  bool _isLoading = false;
  bool _isChecking = true; // Status loading untuk pengecekan akses

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  // Fungsi Penjaga Keamanan (Guard)
  Future<void> _checkAdminAccess() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pop(context);
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data() as Map<String, dynamic>?;

    if (data?['role'] == 'admin') {
      if (mounted) setState(() => _isChecking = false);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Akses ditolak: Hanya Admin yang dapat mengelola stok."),
        backgroundColor: Colors.red,
      ));
      Navigator.pop(context);
    }
  }

  Future<void> _tambahStok() async {
    if (_selectedObatId == null || _jumlahController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih obat dan isi jumlah!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      int jumlah = int.parse(_jumlahController.text);
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Update stok di koleksi stok_obat
      DocumentReference obatRef = FirebaseFirestore.instance
          .collection('stok_obat')
          .doc(_selectedObatId);
      batch.update(obatRef, {'stok_tersedia': FieldValue.increment(jumlah)});

      // 2. Catat log transaksi masuk
      DocumentReference logRef =
          FirebaseFirestore.instance.collection('transaksi_obat').doc();
      batch.set(logRef, {
        'id_obat': _selectedObatId,
        'nama_obat': _selectedObatNama,
        'jumlah': jumlah,
        'jenis_transaksi': 'MASUK',
        'tanggal': FieldValue.serverTimestamp(),
        'keterangan': _keteranganController.text.isEmpty
            ? 'Restock Manual'
            : _keteranganController.text,
      });

      await batch.commit();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stok berhasil ditambah!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menunggu proses pengecekan admin selesai
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text("Restock Obat"),
          backgroundColor: Colors.green.shade700),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stok_obat')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var items = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: "Pilih Obat", border: OutlineInputBorder()),
                  items: items.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                        value: doc.id, child: Text(data['nama_obat']));
                  }).toList(),
                  onChanged: (val) {
                    var selected = items.firstWhere((d) => d.id == val);
                    setState(() {
                      _selectedObatId = val;
                      _selectedObatNama = (selected.data() as Map)['nama_obat'];
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 15),
            TextField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Jumlah Masuk", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(
                controller: _keteranganController,
                decoration: const InputDecoration(
                    labelText: "Keterangan (Contoh: Beli dari supplier)",
                    border: OutlineInputBorder())),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _tambahStok,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("TAMBAH STOK"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
