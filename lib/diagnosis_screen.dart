import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'penyakit_model.dart';
import 'pendaftaran_screen.dart';
import 'hasil_analisis_screen.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final Map<String, double> userSymptoms = {};
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredSymptoms = [];
  List<String> _allSymptoms = [];
  List<PenyakitModel> _diseaseList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterSymptoms);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSymptoms);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      // Mengambil data dengan opsi cache untuk performa lebih baik
      final snapshot = await FirebaseFirestore.instance
          .collection('diseases')
          .get(const GetOptions(source: Source.serverAndCache));

      final list = snapshot.docs
          .map((doc) => PenyakitModel.fromMap(doc.id, doc.data()))
          .toList();

      if (mounted) {
        setState(() {
          _diseaseList = list;
          // Safety check: Pastikan data gejala tidak null sebelum di-expand
          _allSymptoms = list.expand((d) => d.symptoms.keys).toSet().toList();
          _allSymptoms.sort();
          _filteredSymptoms = _allSymptoms;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching diseases: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data gejala: ${e.toString()}")),
        );
      }
    }
  }

  void _filterSymptoms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSymptoms =
          _allSymptoms.where((s) => s.toLowerCase().contains(query)).toList();
    });
  }

  Future<String> _tentukanPoli(String namaPenyakit) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('data_poli').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Safety check untuk list penyakit
        List<dynamic> penyakitList = data['daftar_penyakit'] ?? [];
        if (penyakitList.contains(namaPenyakit)) {
          return data['nama_poli'] ?? "Poli Umum";
        }
      }
    } catch (e) {
      debugPrint("Error finding poli: $e");
    }
    return "Poli Umum";
  }

  void _calculateDiagnosis(List<PenyakitModel> diseaseList) async {
    FocusScope.of(context).unfocus();

    double maxCF = 0.0;
    String bestDisease = "";

    for (var disease in diseaseList) {
      double cfCombined = 0.0;
      disease.symptoms.forEach((symptom, weight) {
        if (userSymptoms.containsKey(symptom)) {
          // Safety check: pastikan value tidak null
          double userValue = userSymptoms[symptom] ?? 0.0;
          double cfGejala = weight * userValue;
          cfCombined = (cfCombined == 0)
              ? cfGejala
              : cfCombined + (cfGejala * (1 - cfCombined));
        }
      });

      if (cfCombined > maxCF) {
        maxCF = cfCombined;
        bestDisease = disease.name;
      }
    }

    if (bestDisease.isNotEmpty && maxCF > 0.0) {
      String poliSaran = await _tentukanPoli(bestDisease);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HasilAnalisisScreen(
            namaPenyakit: bestDisease,
            skor: maxCF,
            onDaftarAntrian: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PendaftaranScreen(
                    keluhan: bestDisease,
                    poliSaran: poliSaran,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Gejala tidak cukup untuk mendiagnosis penyakit.")),
      );
    }
  }

  void _showConfidenceDialog(String symptom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Tingkat Keparahan: $symptom"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                title: const Text("Ringan"),
                onTap: () => {
                      setState(() => userSymptoms[symptom] = 0.4),
                      Navigator.pop(context)
                    }),
            ListTile(
                title: const Text("Sedang"),
                onTap: () => {
                      setState(() => userSymptoms[symptom] = 0.7),
                      Navigator.pop(context)
                    }),
            ListTile(
                title: const Text("Parah"),
                onTap: () => {
                      setState(() => userSymptoms[symptom] = 1.0),
                      Navigator.pop(context)
                    }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _filteredSymptoms.isEmpty
                      ? const Center(child: Text("Gejala tidak ditemukan"))
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredSymptoms.length,
                          itemBuilder: (context, index) {
                            final s = _filteredSymptoms[index];
                            final isSelected = userSymptoms.containsKey(s);
                            return FilterChip(
                              label: Text(s,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.blueGrey)),
                              selected: isSelected,
                              selectedColor: Colors.redAccent,
                              backgroundColor: Colors.white,
                              onSelected: (val) {
                                if (val) {
                                  _showConfidenceDialog(s);
                                } else {
                                  setState(() => userSymptoms.remove(s));
                                }
                              },
                            );
                          },
                        ),
                ),
                _buildFooter(),
              ],
            ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Diagnosis Mandiri",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari gejala (dipilih: ${userSymptoms.length})...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );

  Widget _buildFooter() => Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: userSymptoms.isEmpty
                    ? Colors.grey
                    : const Color(0xFF263238),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            onPressed: userSymptoms.isEmpty
                ? null
                : () => _calculateDiagnosis(_diseaseList),
            child: const Text("ANALISIS SEKARANG",
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ),
      );
}
