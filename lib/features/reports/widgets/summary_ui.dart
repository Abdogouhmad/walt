import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/features/reports/widgets/export_button.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/text_ui.dart';

/// Header block of the Reports screen: the month's total spending, the export
/// button and the 6M/Yearly range filter.
class SummaryReportUi extends ConsumerWidget {
  const SummaryReportUi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);
    final selectedIndex = ref.watch(reportFilterProvider);
    final currency = ref.watch(settingsProvider).currency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _monthlySpending(context, report.totalSpending, currency),
            const ExportPdfButton(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _filterButtons(context, ref, selectedIndex),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _monthlySpending(
    BuildContext ctx,
    AsyncValue<double> totalSpending,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          text: "Monthly Spending",
          type: UiTextType.labelMedium,
          style: TextStyle(
            color: ctx.summaryCardTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        totalSpending.when(
          data: (amount) => UiText(
            text: "${amount.toStringAsFixed(2)} $currency",
            type: UiTextType.headlineSmall,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) =>
              const UiText(text: "Error", type: UiTextType.headlineSmall),
        ),
      ],
    );
  }

  Widget _filterButtons(
    BuildContext ctx,
    WidgetRef ref,
    int selectedIndex,
  ) {
    const filters = ['6 Months', 'Yearly'];

    return Row(
      children: [
        for (var i = 0; i < filters.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          AppButton(
            onPressed: () => ref.read(reportProvider.notifier).changeFilter(i),
            label: filters[i],
            size: ButtonSize.small,
            backgroundColor: selectedIndex == i
                ? ctx.primaryButton
                : Colors.transparent,
            foregroundColor: selectedIndex == i
                ? ctx.primaryTextButton
                : ctx.summaryCardTextSecondary,
          ),
        ],
      ],
    );
  }
}