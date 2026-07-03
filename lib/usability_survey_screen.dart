import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsabilitySurveyScreen extends StatefulWidget {
  const UsabilitySurveyScreen({super.key});

  @override
  State<UsabilitySurveyScreen> createState() => _UsabilitySurveyScreenState();
}

class _UsabilitySurveyScreenState extends State<UsabilitySurveyScreen> {
  final Map<int, int> _answers = {};
  bool _isLoading = false;

  final List<String> _questions = [
    "Saya rasa saya akan sering menggunakan sistem ini.",
    "Saya merasa sistem ini terlalu rumit.",
    "Saya merasa sistem ini mudah digunakan.",
    "Saya rasa saya perlu bantuan orang lain untuk bisa menggunakan sistem ini.",
    "Saya merasa fitur-fitur dalam sistem ini terintegrasi dengan baik.",
    "Saya merasa ada terlalu banyak hal yang tidak konsisten dalam sistem ini.",
    "Saya rasa kebanyakan orang akan cepat belajar menggunakan sistem ini.",
    "Saya merasa sistem ini sangat membingungkan untuk digunakan.",
    "Saya merasa sangat percaya diri saat menggunakan sistem ini.",
    "Saya perlu mempelajari banyak hal sebelum bisa menggunakan sistem ini."
  ];

  Future<void> _submitSurvey() async {
    if (_answers.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Mohon isi semua pertanyaan sebelum mengirim!"),
          backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);

    double score = 0;
    for (int i = 0; i < 10; i++) {
      int val = _answers[i + 1]!;
      if ((i + 1) % 2 != 0)
        score += (val - 1); // Pertanyaan ganjil (1-5)
      else
        score += (5 - val); // Pertanyaan genap (balik skala)
    }
    score *= 2.5;

    try {
      await FirebaseFirestore.instance.collection('sus_results').add({
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        'final_score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Terima kasih! Skor Usability Anda: ${score.toStringAsFixed(1)}"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Evaluasi Sistem (SUS)",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${index + 1}. ${_questions[index]}",
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: List.generate(5, (i) => i + 1).map((val) {
                            return SizedBox(
                              width: MediaQuery.of(context).size.width * 0.17,
                              child: RadioListTile<int>(
                                contentPadding: EdgeInsets.zero,
                                title: Text(val.toString(),
                                    style: const TextStyle(fontSize: 12)),
                                value: val,
                                groupValue: _answers[index + 1],
                                onChanged: (v) =>
                                    setState(() => _answers[index + 1] = v!),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        onPressed: _isLoading ? null : _submitSurvey,
        icon: const Icon(Icons.send_rounded),
        label: const Text("Kirim Hasil Evaluasi"),
      ),
    );
  }
}
