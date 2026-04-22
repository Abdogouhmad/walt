import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/text_ui.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/features/reports/widgets/export_button.dart';

class SummaryReportUi extends ConsumerWidget {
  const SummaryReportUi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);
    final selectedIndex = ref.watch(reportFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            summaryAmountByMonth(context, report.totalSpending),
            const ExportPdfButton(),
          ],
        ),
        const SizedBox(height: 16),
        buttonFilter(context, ref, selectedIndex),
        const SizedBox(height: 24),
      ],
    );
  }
}

Widget summaryAmountByMonth(
  BuildContext ctx,
  AsyncValue<double> totalSpending,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start, // Fixed alignment
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
          text: "${amount.toStringAsFixed(2)} MAD",
          type: UiTextType.headlineSmall,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (err, _) =>
            const UiText(text: "Error", type: UiTextType.headlineSmall),
      ),
    ],
  );
}

Widget buttonFilter(BuildContext ctx, WidgetRef ref, int selectedIndex) {
  return Row(
    children: [
      AppButton(
        onPressed: () => ref.read(reportProvider.notifier).changeFilter(0),
        label: "6 Months",
        size: ButtonSize.small,
        backgroundColor: selectedIndex == 0
            ? ctx.primaryButton
            : Colors.transparent,
        foregroundColor: selectedIndex == 0
            ? ctx.primaryTextButton
            : ctx.summaryCardTextSecondary,
      ),
      const SizedBox(width: 8),
      AppButton(
        onPressed: () => ref.read(reportProvider.notifier).changeFilter(1),
        label: "Yearly",
        size: ButtonSize.small,
        backgroundColor: selectedIndex == 1
            ? ctx.primaryButton
            : Colors.transparent,
        foregroundColor: selectedIndex == 1
            ? ctx.primaryTextButton
            : ctx.summaryCardTextSecondary,
      ),
    ],
  );
}
