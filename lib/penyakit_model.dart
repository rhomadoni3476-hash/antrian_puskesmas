class PenyakitModel {
  final String id;
  final String name;
  final String advice;
  final Map<String, double> symptoms;

  PenyakitModel({
    required this.id,
    required this.name,
    required this.advice,
    required this.symptoms,
  });

  factory PenyakitModel.fromMap(String id, Map<String, dynamic> map) {
    // Memastikan gejala diambil dari Map<String, dynamic> dan dikonversi ke Map<String, double>
    final rawSymptoms = map['symptoms'] as Map<String, dynamic>? ?? {};
    final symptomsMap = rawSymptoms.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return PenyakitModel(
      id: id,
      name: map['name'] ?? 'Penyakit Tidak Dikenal',
      advice: map['advice'] ?? 'Tidak ada saran',
      symptoms: symptomsMap,
    );
  }
}
