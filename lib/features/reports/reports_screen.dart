import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/widgets/walt_chrome.dart';
import 'package:walt/features/reports/widgets/export_button.dart';
import 'package:walt/features/reports/widgets/report_chart_section.dart';
import 'package:walt/features/reports/widgets/secondary_cards.dart';
import 'package:walt/features/reports/widgets/summary_ui.dart';
import 'package:walt/shared/profile_app_bar_action.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Reports'),
            actions: [ProfileAppBarAction(), ExportPdfButton()],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: WaltChrome.constrain(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SummaryReportUi(),
                    const SizedBox(height: AppSpacing.lg),
                    const SecondaryReportCardUi(),
                    const SizedBox(height: AppSpacing.lg),
                    const ReportChartSection(),
                    SizedBox(
                      height:
                          WaltChrome.scrollBottomPadding(context) -
                          AppSpacing.lg,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
