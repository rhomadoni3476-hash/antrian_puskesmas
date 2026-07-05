import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

// Ganti nama class sesuai dengan nama file Anda (misal: UsabilitySurveyScreen)
class UsabilitySurveyScreen extends StatefulWidget {
  const UsabilitySurveyScreen({super.key});

  @override
  State<UsabilitySurveyScreen> createState() => _UsabilitySurveyScreenState();
}

class _UsabilitySurveyScreenState extends State<UsabilitySurveyScreen> {
  final PageController _pageController = PageController();
  final Map<int, int> _answers = {};
  int _currentPage = 0;
  bool _isSubmitting = false;

  final List<String> _questions = [
    "Saya pikir saya akan sering menggunakan sistem ini.",
    "Saya merasa sistem ini terlalu rumit.",
    "Saya pikir sistem ini mudah digunakan.",
    "Saya butuh bantuan orang lain untuk menggunakan sistem ini.",
    "Saya merasa fitur-fitur di sistem ini terintegrasi dengan baik.",
    "Saya merasa ada banyak hal yang tidak konsisten dalam sistem ini.",
    "Saya merasa orang lain akan cepat belajar sistem ini.",
    "Saya merasa sistem ini sangat sulit digunakan.",
    "Saya merasa percaya diri saat menggunakan sistem ini.",
    "Saya butuh banyak waktu untuk belajar sebelum bisa menggunakan sistem ini."
  ];

  double _calculateScore() {
    double total = 0;
    for (int i = 0; i < 10; i++) {
      int val = _answers[i] ?? 3;
      // Rumus SUS: Item ganjil (posisi 0, 2, 4...) skor - 1. Item genap (posisi 1, 3, 5...) 5 - skor.
      if (i % 2 == 0) {
        total += (val - 1);
      } else {
        total += (5 - val);
      }
    }
    return total * 2.5;
  }

  void _submitSurvey() async {
    setState(() => _isSubmitting = true);
    double score = _calculateScore();

    try {
      await FirebaseFirestore.instance.collection('survei_sus').add({
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'skorTotal': score,
        'jawaban':
            _answers.map((key, value) => MapEntry(key.toString(), value)),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResultScreen(score: score)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Survei Kepuasan (SUS)")),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_currentPage + 1) / 5),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemBuilder: (context, pageIndex) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildQuestionCard(pageIndex * 2),
                  const SizedBox(height: 16),
                  _buildQuestionCard(pageIndex * 2 + 1),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentPage > 0
                      ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease)
                      : null,
                  child: const Text("Kembali"),
                ),
                ElevatedButton(
                  onPressed: (_answers.containsKey(_currentPage * 2) &&
                          _answers.containsKey(_currentPage * 2 + 1))
                      ? () {
                          if (_currentPage == 4) {
                            _submitSurvey();
                          } else {
                            _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease);
                          }
                        }
                      : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_currentPage == 4 ? "Selesai" : "Selanjutnya"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text("${index + 1}. ${_questions[index]}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                int value = i + 1;
                return IconButton(
                  icon: Icon(_answers[index] == value
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off),
                  color: _answers[index] == value ? Colors.blue : Colors.grey,
                  onPressed: () => setState(() => _answers[index] = value),
                );
              }),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("Sangat Tidak Setuju"), Text("Sangat Setuju")],
            )
          ],
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final double score;
  const ResultScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 100,
              lineWidth: 15,
              percent: (score / 100).clamp(0.0, 1.0),
              center: Text(score.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold)),
              progressColor: score > 68 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
                "Kualitas Sistem: ${score > 80 ? 'Excellent' : score > 68 ? 'Good' : 'Fair/Poor'}",
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 30),
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup"))
          ],
        ),
      ),
    );
  }
}
