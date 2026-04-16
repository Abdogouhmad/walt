import 'package:flutter/material.dart';
import 'package:walt/features/reports/widgets/summary_ui.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // SafeArea is helpful if you don't have an AppBar
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0), // Increased padding for better UI
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SummaryReportUi(),
              // Your chart will go here
            ],
          ),
        ),
      ),
    );
  }
}
