import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InputDiagnosaScreen extends StatefulWidget {
  final String idAntrian;
  final String namaPasien;

  const InputDiagnosaScreen({
    super.key,
    required this.idAntrian,
    required this.namaPasien,
  });

  @override
  State<InputDiagnosaScreen> createState() => _InputDiagnosaScreenState();
}

class _InputDiagnosaScreenState extends State<InputDiagnosaScreen> {
  final TextEditingController _resepController = TextEditingController();
  final TextEditingController _saranController = TextEditingController();

  String? _selectedDiagnosa;
  bool _isLoading = false;

  // --- LOGIKA PERINGATAN INTERAKSI OBAT ---
  Future<bool> _cekInteraksiObat(List<String> daftarObatBaru) async {
    for (String namaObat in daftarObatBaru) {
      var query = await FirebaseFirestore.instance
          .collection('data_obat')
          .where('nama_obat', isEqualTo: namaObat.trim())
          .get();

      if (query.docs.isNotEmpty) {
        List<dynamic> interaksiNegatif =
            query.docs.first['interaksi_negatif'] ?? [];
        for (String obatTerpilih in daftarObatBaru) {
          if (interaksiNegatif.contains(obatTerpilih.trim())) {
            _tampilkanPeringatanInteraksi(namaObat, obatTerpilih);
            return true;
          }
        }
      }
    }
    return false;
  }

  void _tampilkanPeringatanInteraksi(String obatA, String obatB) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Peringatan Interaksi Obat",
            style: TextStyle(color: Colors.red)),
        content: Text(
            "Obat '$obatA' dan '$obatB' memiliki interaksi negatif. Harap tinjau kembali resep Anda."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tinjau Ulang"))
        ],
      ),
    );
  }

  Future<void> _simpanRekamMedis() async {
    if (_selectedDiagnosa == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Diagnosa wajib dipilih!"),
          backgroundColor: Colors.red));
      return;
    }

    List<String> daftarObat = _resepController.text
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    bool adaInteraksi = await _cekInteraksiObat(daftarObat);
    if (adaInteraksi) return;

    setState(() => _isLoading = true);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference riwayatRef =
          FirebaseFirestore.instance.collection('riwayat').doc();
      batch.set(riwayatRef, {
        'id_antrian': widget.idAntrian,
        'nama': widget.namaPasien,
        'diagnosa': _selectedDiagnosa,
        'resep': _resepController.text,
        'saran': _saranController.text,
        'selesaiAt': FieldValue.serverTimestamp(),
      });

      batch.update(
          FirebaseFirestore.instance
              .collection('antrian')
              .doc(widget.idAntrian),
          {'status': 'Selesai'});

      for (String namaObat in daftarObat) {
        var querySnapshot = await FirebaseFirestore.instance
            .collection('stok_obat')
            .where('nama_obat', isEqualTo: namaObat.trim())
            .get();
        for (var doc in querySnapshot.docs) {
          batch.update(
              doc.reference, {'stok_tersedia': FieldValue.increment(-1)});
          DocumentReference transaksiRef =
              FirebaseFirestore.instance.collection('transaksi_obat').doc();
          batch.set(transaksiRef, {
            'nama_obat': namaObat.trim(),
            'jumlah': 1,
            'jenis_transaksi': 'KELUAR',
            'tanggal': FieldValue.serverTimestamp(),
            'keterangan': 'Resep: ${widget.namaPasien}',
          });
        }
      }

      await batch.commit();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Diagnosa: ${widget.namaPasien}"),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('template_diagnosa')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          var templates = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: "Pilih Diagnosa",
                      border: OutlineInputBorder()),
                  value: _selectedDiagnosa,
                  items: templates.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                        value: data['namaTemplate'],
                        child: Text(data['namaTemplate']));
                  }).toList(),
                  onChanged: (val) {
                    var selected = templates.firstWhere((d) =>
                        (d.data() as Map<String, dynamic>)['namaTemplate'] ==
                        val);
                    var data = selected.data() as Map<String, dynamic>;
                    setState(() {
                      _selectedDiagnosa = val;
                      _saranController.text = data['saran_kesehatan'] ?? '';
                      _resepController.text =
                          (data['resep_default'] as List).join("\n");
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                    controller: _resepController,
                    decoration: const InputDecoration(
                        labelText: "Resep Obat (Pisahkan per baris)",
                        border: OutlineInputBorder()),
                    maxLines: 4),
                const SizedBox(height: 15),
                TextField(
                    controller: _saranController,
                    decoration: const InputDecoration(
                        labelText: "Saran Kesehatan",
                        border: OutlineInputBorder()),
                    maxLines: 3),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white),
                    onPressed: _isLoading ? null : _simpanRekamMedis,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SIMPAN & SELESAI"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
