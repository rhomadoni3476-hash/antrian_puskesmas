import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InputLogScreen extends StatefulWidget {
  const InputLogScreen({super.key});

  @override
  State<InputLogScreen> createState() => _InputLogScreenState();
}

class _InputLogScreenState extends State<InputLogScreen> {
  final _controller = TextEditingController();
  String _selectedType = 'Tekanan Darah';

  Future<void> _simpanData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('log_kesehatan').add({
      'userId': userId,
      'jenis': _selectedType,
      'nilai': double.tryParse(_controller.text) ?? 0,
      'tanggal': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Kesehatan")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: _selectedType,
              items: ['Tekanan Darah', 'Gula Darah', 'Berat Badan']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Nilai")),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _simpanData, child: const Text("Simpan Data"))
          ],
        ),
      ),
    );
  }
}
