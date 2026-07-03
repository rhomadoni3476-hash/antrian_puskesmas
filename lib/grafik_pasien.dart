import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GrafikPasien extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: PieChart(PieChartData(sections: [
        PieChartSectionData(value: 40, color: Colors.blue, title: 'Umum'),
        PieChartSectionData(value: 30, color: Colors.green, title: 'Gigi'),
        PieChartSectionData(value: 30, color: Colors.red, title: 'Anak'),
      ])),
    );
  }
}
