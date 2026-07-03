import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'antrian_provider.dart';
import 'api_service.dart';

class InputRekamMedisScreen extends StatefulWidget {
  const InputRekamMedisScreen({super.key});

  @override
  State<InputRekamMedisScreen> createState() => _InputRekamMedisScreenState();
}

class _InputRekamMedisScreenState extends State<InputRekamMedisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _keluhanController = TextEditingController();
  final _nikController = TextEditingController();
  final _tanggalController = TextEditingController();

  final _namaFocus = FocusNode();
  final _nikFocus = FocusNode();
  final _keluhanFocus = FocusNode();

  String _statusTerpilih = "Menunggu";
  bool _isSubmitting = false;

  @override
  void dispose() {
    _namaController.dispose();
    _keluhanController.dispose();
    _nikController.dispose();
    _tanggalController.dispose();
    _namaFocus.dispose();
    _nikFocus.dispose();
    _keluhanFocus.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    // Menutup keyboard sebelum memunculkan DatePicker
    FocusScope.of(context).unfocus();

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.redAccent)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() =>
          _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _konfirmasiDanSimpan() async {
    if (!_formKey.currentState!.validate()) return;

    // Menutup keyboard sebelum dialog muncul
    FocusScope.of(context).unfocus();

    bool? yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Konfirmasi Data"),
        content:
            Text("Simpan rekam medis untuk pasien: ${_namaController.text}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text("Ya, Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (yakin == true) _submitData();
  }

  Future<void> _submitData() async {
    setState(() => _isSubmitting = true);

    try {
      final data = {
        "nama_pasien": _namaController.text.trim(),
        "nik": _nikController.text.trim(),
        "keluhan": _keluhanController.text.trim(),
        "status": _statusTerpilih,
        "tanggal_pemeriksaan": _tanggalController.text,
      };

      // Memanggil API FastAPI melalui ApiService
      await ApiService.tambahRekamMedis(data);

      if (mounted) {
        // Refresh provider data
        Provider.of<AntrianProvider>(context, listen: false).fetchPasien();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Berhasil: Rekam medis tersimpan ke server!"),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Gagal menyimpan ke server: ${e.toString()}"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Rekam Medis"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextFormField(
                  controller: _namaController,
                  label: "Nama Pasien",
                  icon: Icons.person,
                  focusNode: _namaFocus,
                  nextFocus: _nikFocus),
              const SizedBox(height: 15),
              _buildTextFormField(
                  controller: _tanggalController,
                  label: "Tanggal Pemeriksaan (YYYY-MM-DD)",
                  icon: Icons.calendar_today,
                  readOnly: true,
                  onTap: _pilihTanggal),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nikController,
                focusNode: _nikFocus,
                decoration: const InputDecoration(
                    labelText: "NIK (16 Digit)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge)),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16)
                ],
                validator: (val) => (val == null || val.length != 16)
                    ? "NIK harus tepat 16 digit"
                    : null,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_keluhanFocus),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _statusTerpilih,
                    decoration: const InputDecoration(
                        labelText: "Status Awal", border: InputBorder.none),
                    items: ['Menunggu', 'Sedang Diperiksa', 'Selesai']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _statusTerpilih = val!),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _keluhanController,
                focusNode: _keluhanFocus,
                decoration: const InputDecoration(
                    labelText: "Keluhan Pasien",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medical_services)),
                maxLines: 4,
                validator: (val) => (val == null || val.length < 5)
                    ? "Deskripsi keluhan terlalu singkat"
                    : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: _isSubmitting ? null : _konfirmasiDanSimpan,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("SIMPAN REKAM MEDIS",
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
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      onTap: onTap,
      onFieldSubmitted: nextFocus != null
          ? (_) => FocusScope.of(context).requestFocus(nextFocus)
          : null,
      decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon)),
      validator: (val) => val!.isEmpty ? "$label wajib diisi" : null,
    );
  }
}
