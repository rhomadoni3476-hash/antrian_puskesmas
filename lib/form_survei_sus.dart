import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SusSurveyScreen extends StatefulWidget {
  const SusSurveyScreen({super.key});

  @override
  State<SusSurveyScreen> createState() => _SusSurveyScreenState();
}

class _SusSurveyScreenState extends State<SusSurveyScreen> {
  // 10 Pertanyaan standar SUS
  final List<String> questions = [
    "Saya pikir saya akan sering menggunakan sistem ini.",
    "Saya merasa sistem ini tidak perlu rumit.",
    "Saya merasa sistem ini mudah digunakan.",
    "Saya butuh bantuan orang lain untuk menggunakan sistem ini.",
    "Saya merasa fitur-fitur di sistem ini terintegrasi dengan baik.",
    "Saya merasa sistem ini terlalu banyak hal yang tidak konsisten.",
    "Saya membayangkan orang lain akan cepat belajar sistem ini.",
    "Saya merasa sistem ini sangat sulit digunakan.",
    "Saya merasa percaya diri saat menggunakan sistem ini.",
    "Saya perlu belajar banyak hal sebelum bisa menggunakan sistem ini."
  ];

  Map<int, int> answers = {}; // Menyimpan skor 1-5

  void _submitSurvey() async {
    if (answers.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mohon jawab semua pertanyaan")));
      return;
    }

    // Kalkulasi skor SUS (Rumus Standar)
    double score = 0;
    for (int i = 0; i < 10; i++) {
      int val = answers[i]!;
      // Pertanyaan ganjil (1,3,5,7,9): skor = nilai - 1
      if (i % 2 == 0)
        score += (val - 1);
      // Pertanyaan genap (2,4,6,8,10): skor = 5 - nilai
      else
        score += (5 - val);
    }
    double finalScore = score * 2.5;

    await FirebaseFirestore.instance.collection('survei_sus').add({
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'skorTotal': finalScore,
      'jawaban': answers,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Survei Kepuasan (SUS)")),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) => ListTile(
          title: Text("${index + 1}. ${questions[index]}"),
          subtitle: Slider(
            value: (answers[index] ?? 3).toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: answers[index]?.toString() ?? "3",
            onChanged: (v) => setState(() => answers[index] = v.toInt()),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitSurvey,
        child: const Icon(Icons.check),
      ),
    );
  }
}
