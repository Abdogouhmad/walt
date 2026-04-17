import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/shared/text_ui.dart';

class SecondaryReportCardUi extends ConsumerWidget {
  const SecondaryReportCardUi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(child: _avargeSpendingPerDay(context, ref)),
        SizedBox(width: 12), // Space between cards
        Expanded(child: _savingRate(context, ref)),
      ],
    );
  }
}

Widget _avargeSpendingPerDay(BuildContext ctx, WidgetRef ref) {
  return M3Ecard(
    variant: M3ECardVariant.filled,

    data: AppCardData(
      title: null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: ctx.colorAppScheme.secondary,
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
          UiText(
            text: "50 MAD",
            type: UiTextType.headlineSmall, // Use a larger type for the amount
            style: const TextStyle(fontWeight: FontWeight.bold),
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

Widget _savingRate(BuildContext ctx, WidgetRef ref) {
  return M3Ecard(
    variant: M3ECardVariant.filled,
    data: AppCardData(
      title: null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: ctx.colorAppScheme.secondary),
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

          UiText(
            text: "28%".toUpperCase(),
            type: UiTextType.headlineSmall, // Use a larger type for the amount
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          UiText(
            text: "+2 last month".toUpperCase(),
            type: UiTextType.labelSmall,
            style: TextStyle(color: ctx.colorAppScheme.outline),
          ),
        ],
      ),
    ),
  );
}
