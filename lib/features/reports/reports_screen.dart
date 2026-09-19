import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/features/reports/widgets/barchart.dart';
import 'package:walt/features/reports/widgets/piechart.dart';
import 'package:walt/features/reports/widgets/secondary_cards.dart';
import 'package:walt/features/reports/widgets/summary_ui.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SummaryReportUi(),
            const SizedBox(height: AppSpacing.md),
            BarChartWidget(),
            const SizedBox(height: AppSpacing.lg),
            SecondaryReportCardUi(),
            const SizedBox(height: AppSpacing.lg),
            const PieChartWidget(),
          ],
        ),
      ),
    );
  }
}
