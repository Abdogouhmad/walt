import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/shared/text_ui.dart';
import 'package:walt/providers/report_provider.dart';

class SecondaryReportCardUi extends ConsumerWidget {
  const SecondaryReportCardUi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);

    return Row(
      children: [
        Expanded(child: _avargeSpendingPerDay(context, report.averageDailySpending)),
        const SizedBox(width: 12), // Space between cards
        Expanded(child: _savingRate(context, report.savingRate)),
      ],
    );
  }
}

Widget _avargeSpendingPerDay(BuildContext ctx, AsyncValue<double> averageDaily) {
  return M3Ecard(
    variant: M3ECardVariant.filled,
    padding: const EdgeInsets.all(20),
    data: AppCardData(
      title: null,
      colorCard: ctx.colorAppScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: ctx.colorAppScheme.secondary.withAlpha(50),
        ), // 20% opacity border
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align everything to the left
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 30,
            color: ctx.colorAppScheme.primary.withAlpha(179), // 0.7 * 255
          ),
          const SizedBox(height: 16),
          UiText(
            text: "Average daily".toUpperCase(),
            type: UiTextType.labelSmall,
            style: TextStyle(color: ctx.colorAppScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          averageDaily.when(
            data: (amount) => UiText(
              text: "${amount.toStringAsFixed(0)} MAD",
              type: UiTextType.headlineSmall, // Use a larger type for the amount
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (err, _) => const UiText(text: "Error", type: UiTextType.headlineSmall),
          ),
          const SizedBox(height: 4),
          UiText(
            text: "Current Month",
            type: UiTextType.labelSmall,
            style: TextStyle(color: ctx.colorAppScheme.outline),
          ),
        ],
      ),
    ),
  );
}

Widget _savingRate(BuildContext ctx, AsyncValue<double> savingRate) {
  return M3Ecard(
    variant: M3ECardVariant.filled,
    padding: const EdgeInsets.all(20),
    data: AppCardData(
      title: null,
      colorCard: ctx.colorAppScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: ctx.colorAppScheme.secondary.withAlpha(50)),
      ), // 20% opacity border
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.savings_rounded,
            size: 30,
            color: ctx.colorAppScheme.primary,
          ),
          const SizedBox(height: 16),
          UiText(
            text: "saving rate".toUpperCase(),
            type: UiTextType.labelSmall,
            style: TextStyle(color: ctx.colorAppScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          savingRate.when(
            data: (rate) => UiText(
              text: "${rate.toStringAsFixed(0)}%",
              type: UiTextType.headlineSmall, // Use a larger type for the amount
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (err, _) => const UiText(text: "Error", type: UiTextType.headlineSmall),
          ),
          const SizedBox(height: 4),

          UiText(
            text: "Selected Period",
            type: UiTextType.labelSmall,
            style: TextStyle(color: ctx.colorAppScheme.outline),
          ),
        ],
      ),
    ),
  );
}
