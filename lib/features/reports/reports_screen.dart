import 'package:flutter/material.dart';
import 'package:walt/features/reports/widgets/barchart.dart';
import 'package:walt/features/reports/widgets/piechart.dart';
import 'package:walt/features/reports/widgets/secondary_cards.dart';
import 'package:walt/features/reports/widgets/summary_ui.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SummaryReportUi(),
            const SizedBox(height: 16),
            BarChartWidget(),
            const SizedBox(height: 20),
            SecondaryReportCardUi(),
            const SizedBox(height: 20),
            const PieChartWidget(),
          ],
        ),
      ),
    );
  }
}
