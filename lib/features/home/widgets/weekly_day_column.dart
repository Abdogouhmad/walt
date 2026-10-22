import 'package:flutter/material.dart';
import 'package:walt_ui/walt_ui.dart';

/// One day of the weekly recap strip.
///
/// A column holds a reserved amount row, a pill that grows into the selected
/// day's bar, and the day's initial. The amount row is reserved on *every* day,
/// not just the selected one, so selecting a different day slides the pill
/// along a strip whose height never changes.
class WeeklyDayColumn extends StatelessWidget {
  const WeeklyDayColumn({
    super.key,
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

  /// Whole units only — the recap is a glanceable shape, not a ledger, and the
  /// currency code would only crowd the strip. Grouping still applies, so a big
  /// day reads `1,730` rather than `1730`.
  static String amountLabel(double value) =>
      MoneyFormat.digits(value, fractionDigits: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = AppSpring.isDisabled(context)
        ? Duration.zero
        : AppMotion.long;
    final curve = AppSpring.spatialCurve;

    // Dot diameter scales with the day's share of the week's spending. A day
    // with no spend still renders a visible minimum dot so the row never looks
    // like a rendering failure.
    final dotSize = dotMin + (dotMax - dotMin) * fraction.clamp(0.0, 1.0);

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${_initials[day.weekday - 1]}, '
          '${amountLabel(amount)} $currency spent',
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
                SizedBox(
                  height: amountHeight,
                  child: AnimatedOpacity(
                    opacity: isSelected ? 1 : 0,
                    duration: duration,
                    curve: curve,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        amountLabel(amount),
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
