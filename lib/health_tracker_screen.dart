import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthTrackerScreen extends StatefulWidget {
  const HealthTrackerScreen({super.key});

  @override
  State<HealthTrackerScreen> createState() => _HealthTrackerScreenState();
}

class _HealthTrackerScreenState extends State<HealthTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tekananDarahController = TextEditingController();
  final _gulaDarahController = TextEditingController();
  final _beratBadanController = TextEditingController();
  final _catatanController = TextEditingController();
  bool _isLoading = false;

  Future<void> _simpanData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      // 1. Simpan ke sub-koleksi 'logs'
      final docRef = await FirebaseFirestore.instance
          .collection('health_records')
          .doc(user!.uid)
          .collection('logs')
          .add({
        'tekananDarah': _tekananDarahController.text,
        'gulaDarah': int.parse(_gulaDarahController.text),
        'beratBadan': double.parse(_beratBadanController.text),
        'catatan': _catatanController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Increment totalLogs di dokumen utama
      await FirebaseFirestore.instance
          .collection('health_records')
          .doc(user.uid)
          .set({'totallogs': FieldValue.increment(1)}, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data berhasil disimpan!")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Data Kesehatan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tekananDarahController,
                decoration: const InputDecoration(
                    labelText: "Tekanan Darah (cth: 120/80)"),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              TextFormField(
                controller: _gulaDarahController,
                decoration:
                    const InputDecoration(labelText: "Gula Darah (mg/dL)"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              TextFormField(
                controller: _beratBadanController,
                decoration:
                    const InputDecoration(labelText: "Berat Badan (kg)"),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(labelText: "Catatan"),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _simpanData,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Simpan Data"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
