import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'api_service.dart';

class SusGaugeChart extends StatefulWidget {
  const SusGaugeChart({super.key});

  @override
  State<SusGaugeChart> createState() => _SusGaugeChartState();
}

class _SusGaugeChartState extends State<SusGaugeChart>
    with SingleTickerProviderStateMixin {
  double _avgScore = 0;
  bool _isLoading = true;
  String _errorMessage = "";
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Controller untuk animasi "tumbuh" grafik
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fetchSusStats();
  }

  Future<void> _fetchSusStats() async {
    try {
      final data = await ApiService.getSusStatistics();
      if (mounted) {
        setState(() {
          _avgScore = (data['data']['rata_rata_sus'] as num).toDouble();
          _isLoading = false;
        });
        _controller.forward(); // Jalankan animasi
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Gagal memuat statistik";
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator.adaptive()));
    }

    if (_errorMessage.isNotEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
            child:
                Text(_errorMessage, style: const TextStyle(color: Colors.red))),
      );
    }

    bool isGood = _avgScore > 68;
    final primaryColor =
        isGood ? const Color(0xFF66BB6A) : const Color(0xFFFFA726);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text("User Satisfaction (SUS)",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                          value: _avgScore,
                          color: primaryColor,
                          radius: 12,
                          showTitle: false),
                      PieChartSectionData(
                          value: 100 - _avgScore,
                          color: const Color(0xFFF5F5F5),
                          radius: 12,
                          showTitle: false),
                    ],
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_avgScore.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333))),
                    const SizedBox(height: 4),
                    Icon(isGood ? Icons.check_circle : Icons.warning_rounded,
                        color: primaryColor, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
