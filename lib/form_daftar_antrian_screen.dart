import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FormDaftarAntrianScreen extends StatefulWidget {
  final String? namaDokter;
  final String? poli;

  const FormDaftarAntrianScreen({super.key, this.namaDokter, this.poli});

  @override
  State<FormDaftarAntrianScreen> createState() =>
      _FormDaftarAntrianScreenState();
}

class _FormDaftarAntrianScreenState extends State<FormDaftarAntrianScreen> {
  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _dokterController = TextEditingController();

  // Definisi master list poli
  final List<String> _listPoli = ['Poli Umum', 'Poli Gigi', 'Poli Anak'];
  String? _selectedPoli;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.namaDokter != null) {
      _dokterController.text = widget.namaDokter!;
    }

    // LOGIKA PERBAIKAN: Pastikan poli yang diterima valid
    if (widget.poli != null && _listPoli.contains(widget.poli)) {
      _selectedPoli = widget.poli;
    } else {
      _selectedPoli = _listPoli.first; // Default jika null atau tidak cocok
    }
  }

  Widget _buildInput(
      String label, TextEditingController controller, IconData icon,
      {TextInputType type = TextInputType.text, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF546E7A)))),
        TextFormField(
          controller: controller,
          keyboardType: type,
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.redAccent),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 2)),
          ),
        ),
      ],
    );
  }

  void _submitAntrian() async {
    final nama = _namaController.text.trim();
    final nik = _nikController.text.trim();
    final dokter = _dokterController.text.trim();

    if (nama.isEmpty || nik.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mohon lengkapi Nama dan NIK")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final String nomor = 'A-${now.hour}${now.minute}${now.second}';

      await FirebaseFirestore.instance.collection('antrian').add({
        'nama': nama,
        'nik': nik,
        'poli': _selectedPoli,
        'dokter': dokter,
        'status': 'Menunggu',
        'tanggal': FieldValue.serverTimestamp(),
        'nomor_antrian': nomor,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                BuktiPendaftaranScreen(namaPasien: nama, nomorAntrian: nomor)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal mendaftar: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
          title: const Text("Daftar Antrian"),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInput("Nama Lengkap", _namaController, Icons.person_outline),
          const SizedBox(height: 20),
          _buildInput("NIK Pasien", _nikController, Icons.credit_card_outlined,
              type: TextInputType.number),
          const SizedBox(height: 20),
          _buildInput(
              "Dokter Tujuan", _dokterController, Icons.medical_services,
              readOnly: widget.namaDokter != null),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: const Text("Poli Tujuan",
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF546E7A))),
          ),
          DropdownButtonFormField<String>(
            value: _selectedPoli,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.medical_services_outlined,
                  color: Colors.redAccent),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
            // Menggunakan _listPoli agar sinkron dengan initState
            items: _listPoli
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => _selectedPoli = val!),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: _isLoading ? null : _submitAntrian,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("DAFTAR SEKARANG",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// (BuktiPendaftaranScreen tetap sama seperti sebelumnya...)
class BuktiPendaftaranScreen extends StatelessWidget {
  final String namaPasien;
  final String nomorAntrian;

  const BuktiPendaftaranScreen(
      {super.key, required this.namaPasien, required this.nomorAntrian});

  @override
  Widget build(BuildContext context) {
    String tanggal =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text("Bukti Pendaftaran"),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.redAccent.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 80),
                    const SizedBox(height: 20),
                    const Text("Pendaftaran Berhasil",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF263238))),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Divider()),
                    const Text("NOMOR ANTRIAN",
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w600)),
                    Text(nomorAntrian,
                        style: const TextStyle(
                            fontSize: 70,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                            height: 1)),
                    const SizedBox(height: 20),
                    Text(namaPasien.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238))),
                    Text(tanggal,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF263238),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (route) => false),
                  child: const Text("Kembali ke Beranda",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
