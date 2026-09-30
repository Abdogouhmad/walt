import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/motion.dart';
import 'package:walt/core/utils/money.dart';
import 'package:walt/core/widgets/pill_switcher.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';

/// Whole units only — the recap is a glanceable shape, not a ledger, and the
/// currency code would only crowd the strip. Grouping still applies, so a big
/// day reads `1,730` rather than `1730`.
String _dayAmountLabel(double value) =>
    MoneyFormat.digits(value, fractionDigits: 0);

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
    final scheme = theme.colorScheme;

    final today = _midnight(DateTime.now());
    final selectedDay = selected ?? today;
    // The recap always shows the week that contains the selection, so picking
    // an adjacent day never leaves the user looking at a stale week.
    final weekStart = _startOfWeek(selectedDay);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final amounts = List<double>.generate(7, (i) {
      final index = _weekdayIndex(days[i]);
      return index >= 0 && index < totals.length ? totals[index] : 0;
    });

    final maxAmount = amounts.fold<double>(0, (m, a) => a > m ? a : m);
    final weekTotal = amounts.fold<double>(0, (a, b) => a + b);

    void select(DateTime day) {
      HapticFeedback.selectionClick();
      final notifier = ref.read(selectedDayProvider.notifier);
      // Tapping a day filters Recent activity to that day. Tapping the day
      // that is already showing clears the filter — including today, which is
      // the *initial* state, so the first tap on it is a real filter rather
      // than a no-op toggle-off.
      final isFiltered = selected != null && _sameDay(day, selected);
      notifier.state = isFiltered ? null : day;
    }

    // The strip's height has to cover the *selected* day's amount label as well
    // as its pill, the gap, and the day letter. Measuring the two text rows
    // rather than assuming a height is what keeps this correct at 200% text
    // scale, where both labels roughly double and a hardcoded reserve would
    // overflow again.
    final amountHeight = _measureHeight(
      context,
      '0',
      theme.textTheme.labelSmall,
    );
    final letterHeight = _measureHeight(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('This week', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      selected == null
                          ? 'Tap a day to filter'
                          : _dayLabel(selectedDay),
                      // The hint is longer than the date it is replaced by, and
                      // a second line here would make the whole card jump 16px
                      // the first time a day is selected.
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                MoneyFormat.withCode(weekTotal, currency: currency),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
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
                    child: _DayColumn(
                      day: days[i],
                      amount: amounts[i],
                      fraction: maxAmount > 0 ? amounts[i] / maxAmount : 0,
                      isSelected: _sameDay(days[i], selectedDay),
                      isToday: _sameDay(days[i], today),
                      selectedHeight: _selectedHeight,
                      // The amount row is reserved on *every* day, not just the
                      // selected one, so selecting a different day slides the
                      // pill along a strip whose height never changes.
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

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Height that [text] will occupy once laid out with [style].
  ///
  /// Uses the ambient [TextScaler], so a 200% system text scale is measured
  /// as 200% rather than being silently ignored.
  static double _measureHeight(
    BuildContext context,
    String text,
    TextStyle? style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.height;
  }

  static DateTime _startOfWeek(DateTime day) =>
      _midnight(day).subtract(Duration(days: day.weekday - 1));

  static int _weekdayIndex(DateTime day) => day.weekday - 1;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dayLabel(DateTime day) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${names[day.weekday - 1]} ${day.day}/${day.month}';
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.amount,
    required this.fraction,
    required this.isSelected,
    required this.isToday,
    required this.selectedHeight,
    required this.amountHeight,
    required this.letterHeight,
    required this.dotMax,
    required this.dotMin,
    required this.currency,
    required this.onTap,
  });

  final DateTime day;
  final double amount;
  final double fraction;
  final bool isSelected;
  final bool isToday;
  final double selectedHeight;
  final double amountHeight;
  final double letterHeight;
  final double dotMax;
  final double dotMin;
  final String currency;
  final VoidCallback onTap;

  static const List<String> _initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = AppSpring.isDisabled(context)
        ? Duration.zero
        : AppMotion.long;
    final curve = AppSpring.curve(AppSpring.spatial);

    // Dot diameter scales with the day's share of the week's spending. A day
    // with no spend still renders a visible minimum dot so the row never looks
    // like a rendering failure.
    final dotSize = dotMin + (dotMax - dotMin) * fraction.clamp(0.0, 1.0);

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${_initials[day.weekday - 1]}, '
          '${_dayAmountLabel(amount)} $currency spent',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          // The pill's width animates between the dot size and the full cell
          // width. Both ends have to be finite: `AnimatedContainer` lerps the
          // two, and a `double.infinity` end makes that tween impossible, which
          // throws on every selection change. `LayoutBuilder` hands over the
          // real cell width so the pill can still fill the column.
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Reserved on every day, so selecting one slides the pill along a
                // strip of constant height. `FittedBox` keeps a long amount from
                // being clipped at 200% text scale.
                SizedBox(
                  height: amountHeight,
                  child: AnimatedOpacity(
                    opacity: isSelected ? 1 : 0,
                    duration: duration,
                    curve: curve,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _dayAmountLabel(amount),
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // `Flexible` lets the pill give way instead of overflowing if the
                // text rows somehow still need more room than reserved.
                Flexible(
                  child: AnimatedContainer(
                    duration: duration,
                    curve: curve,
                    height: isSelected ? selectedHeight : dotSize,
                    width: isSelected ? constraints.maxWidth : dotSize,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary
                          : fraction > 0
                          ? scheme.primary.withValues(alpha: 0.35)
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: letterHeight,
                  child: Center(
                    child: Text(
                      _initials[day.weekday - 1],
                      // The filled pill and the ring already carry the state, so
                      // the glyph only shifts colour — no weight override.
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected || isToday
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
