import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SusGaugeChart extends StatefulWidget {
  const SusGaugeChart({super.key});

  @override
  State<SusGaugeChart> createState() => _SusGaugeChartState();
}

class _SusGaugeChartState extends State<SusGaugeChart> {
  double _avgScore = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSusStats();
  }

  Future<void> _fetchSusStats() async {
    // Ganti URL dengan IP server backend Anda
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8000/api/sus-statistics'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _avgScore = data['rata_rata_sus'].toDouble();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const CircularProgressIndicator();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
                value: _avgScore,
                color: _avgScore > 68 ? Colors.green : Colors.orange,
                title: '${_avgScore.toStringAsFixed(1)}',
                radius: 60),
            PieChartSectionData(
                value: 100 - _avgScore,
                color: Colors.grey.shade200,
                title: '',
                radius: 60),
          ],
          sectionsSpace: 0,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}
