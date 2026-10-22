import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/home/widgets/text_measurement.dart';
import 'package:walt/features/home/widgets/week_dates.dart';
import 'package:walt/features/home/widgets/weekly_day_column.dart';
import 'package:walt/features/home/widgets/weekly_spending_header.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// "This week" recap: seven day columns, one dot per day whose size scales with
/// that day's spend.
///
/// The selected day (today by default) becomes a tall `primary`-filled pill that
/// shows its amount. Tapping a day selects it with a spring; selecting a day
/// filters the Recent activity list below to that day.
class WeeklySpendingChart extends ConsumerWidget {
  const WeeklySpendingChart({super.key});

  static const double _dotMax = 20;
  static const double _dotMin = 6;
  static const double _selectedHeight = 76;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(weekSpendingProvider);
    final selected = ref.watch(selectedDayProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));

    final theme = Theme.of(context);

    final today = weekMidnight(DateTime.now());
    final selectedDay = selected ?? today;
    // The recap always shows the week that contains the selection, so picking
    // an adjacent day never leaves the user looking at a stale week.
    final weekStart = startOfWeek(selectedDay);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final amounts = List<double>.generate(7, (i) {
      final index = weekdayIndex(days[i]);
      return index >= 0 && index < totals.length ? totals[index] : 0;
    });

    final maxAmount = amounts.fold<double>(0, (m, a) => a > m ? a : m);
    final weekTotal = amounts.fold<double>(0, (a, b) => a + b);

    void select(DateTime day) {
      Haptics.selection();
      final notifier = ref.read(selectedDayProvider.notifier);
      // Tapping a day filters Recent activity to that day. Tapping the day
      // that is already showing clears the filter — including today, which is
      // the *initial* state, so the first tap on it is a real filter rather
      // than a no-op toggle-off.
      final isFiltered = selected != null && sameDay(day, selected);
      notifier.state = isFiltered ? null : day;
    }

    // The strip's height has to cover the *selected* day's amount label as well
    // as its pill, the gap, and the day letter. Measuring the two text rows
    // rather than assuming a height is what keeps this correct at 200% text
    // scale, where both labels roughly double and a hardcoded reserve would
    // overflow again.
    final amountHeight = measureTextHeight(
      context,
      '0',
      theme.textTheme.labelSmall,
    );
    final letterHeight = measureTextHeight(
      context,
      'W',
      theme.textTheme.labelMedium,
    );
    final rowHeight =
        AppSpacing.xs * 2 + // Padding on each day column
        amountHeight +
        AppSpacing.xs + // amount -> pill
        _selectedHeight +
        AppSpacing.sm + // pill -> letter
        letterHeight;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          WeeklySpendingHeader(
            subtitle: selected == null
                ? 'Tap a day to filter'
                : dayLabel(selectedDay),
            total: MoneyFormat.withCode(weekTotal, currency: currency),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            key: const ValueKey('week-recap-strip'),
            height: rowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: WeeklyDayColumn(
                      day: days[i],
                      amount: amounts[i],
                      fraction: maxAmount > 0 ? amounts[i] / maxAmount : 0,
                      isSelected: sameDay(days[i], selectedDay),
                      isToday: sameDay(days[i], today),
                      selectedHeight: _selectedHeight,
                      amountHeight: amountHeight,
                      letterHeight: letterHeight,
                      dotMax: _dotMax,
                      dotMin: _dotMin,
                      currency: currency,
                      onTap: () => select(days[i]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
