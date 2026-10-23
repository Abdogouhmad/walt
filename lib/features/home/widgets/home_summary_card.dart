import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/models/walt_account.dart';
import 'package:walt/features/home/widgets/week_dates.dart';
import 'package:walt/providers/account_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Home's summary card: which account is in view, what it is worth, and how
/// the week has been spent.
///
/// The card deliberately reuses the budget card's silhouette — same radius,
/// same tonal gradient header over a quiet body — because both answer the same
/// question ("how much is left?") and should read as members of one family.
/// The account's own colour drives the gradient, the bars and the live accents;
/// it is mixed with the surface instead of painted raw so a neon account colour
/// cannot destroy contrast.
class HomeSummaryCard extends ConsumerWidget {
  const HomeSummaryCard({super.key});

  static const double _chartHeight = 148;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accounts = ref.watch(accountProvider).value ?? const <WaltAccount>[];
    final selectedAccountId = ref.watch(homeAccountIdProvider);
    final summary = ref.watch(homeSummaryProvider);
    final totals = ref.watch(weekSpendingProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));

    WaltAccount? account;
    for (final candidate in accounts) {
      if (candidate.id == selectedAccountId) {
        account = candidate;
        break;
      }
    }
    // A deleted account must not leave Home filtered to nothing. The filter is
    // stored in a provider, so clear it once the account list has loaded and
    // the selected id is gone; the next frame renders "All accounts".
    if (selectedAccountId != null &&
        account == null &&
        ref.watch(accountProvider).hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(homeAccountIdProvider.notifier).state = null;
      });
    }
    final activeId = account?.id;

    final accent = _accountAccent(context, account);
    final headerStart = Color.alphaBlend(
      accent.withValues(alpha: 0.22),
      scheme.surface,
    );
    final headerEnd = Color.alphaBlend(
      accent.withValues(alpha: 0.08),
      scheme.surface,
    );

    final today = weekMidnight(DateTime.now());
    final activeDay = selectedDay ?? today;
    final weekStart = startOfWeek(activeDay);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final amounts = List<double>.generate(7, (i) {
      final index = weekdayIndex(days[i]);
      return index >= 0 && index < totals.length ? totals[index] : 0;
    });
    final weekTotal = amounts.fold<double>(0, (a, b) => a + b);

    void select(DateTime? day) {
      Haptics.selection();
      final notifier = ref.read(selectedDayProvider.notifier);
      if (day == null) {
        notifier.state = null;
        return;
      }
      // Tapping the selected day clears the filter, including today, which is
      // the initial state — so the first tap on it is a real filter rather
      // than a no-op toggle-off.
      final isFiltered = selectedDay != null && sameDay(day, selectedDay);
      notifier.state = isFiltered ? null : day;
    }

    return Semantics(
      container: true,
      label: 'Home summary',
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [headerStart, headerEnd],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AccountChips(
                      accounts: accounts,
                      selectedId: activeId,
                      accent: accent,
                      onSelected: (id) {
                        Haptics.selection();
                        ref.read(homeAccountIdProvider.notifier).state = id;
                        // A day filter from the previous account would keep
                        // hiding rows the user now expects to see.
                        ref.read(selectedDayProvider.notifier).state = null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total balance',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              AmountText(
                                amount: summary.balance,
                                currency: currency,
                                hero: true,
                                showSign: false,
                                color: scheme.onSurface,
                                animate: true,
                                fontSize: 40,
                                style: theme.textTheme.displayMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _AccountBadge(account: account, accent: accent),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: StatPill(
                            label: 'Income',
                            amount: _amount(summary.income, currency),
                            icon: Icons.south_west_rounded,
                            foreground: WaltColors.of(context).income,
                            background: WaltColors.of(context).incomeContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: StatPill(
                            label: 'Expenses',
                            amount: _amount(summary.expenses, currency),
                            icon: Icons.north_east_rounded,
                            foreground: WaltColors.of(context).expense,
                            background: WaltColors.of(context).expenseContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'This week',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedDay == null
                                  ? 'Tap a bar to filter'
                                  : dayLabel(activeDay),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        MoneyFormat.withCode(weekTotal, currency: currency),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    label: _chartSemantics(days, amounts, currency),
                    child: SizedBox(
                      height: _chartHeight,
                      child: BarChart(
                        _chartData(
                          context: context,
                          days: days,
                          amounts: amounts,
                          activeDay: activeDay,
                          accent: accent,
                          currency: currency,
                          onSelect: select,
                        ),
                        duration: AppSpring.isDisabled(context)
                            ? Duration.zero
                            : AppMotion.medium,
                        curve: AppMotion.standard,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _amount(double value, String currency) {
    final text = MoneyFormat.digits(value, fractionDigits: 0);
    return currency.isEmpty ? text : '$text $currency';
  }

  static String _chartSemantics(
    List<DateTime> days,
    List<double> amounts,
    String currency,
  ) {
    final parts = <String>[];
    for (var i = 0; i < days.length; i++) {
      final name = dayLabel(days[i]).split(' ').first;
      parts.add('$name ${MoneyFormat.digits(amounts[i], fractionDigits: 0)}');
    }
    final unit = currency.isEmpty ? '' : ' $currency';
    return 'Weekly spending$unit: ${parts.join(', ')}.';
  }

  Color _accountAccent(BuildContext context, WaltAccount? account) {
    final scheme = Theme.of(context).colorScheme;
    final parsed = CategoryAvatar.parseHex(account?.color);
    if (parsed == null) return scheme.primary;
    return WaltChartColors.of(context).harmonizeCategory(parsed, 0);
  }

  BarChartData _chartData({
    required BuildContext context,
    required List<DateTime> days,
    required List<double> amounts,
    required DateTime activeDay,
    required Color accent,
    required String currency,
    required void Function(DateTime? day) onSelect,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxAmount = amounts.fold<double>(0, (m, a) => a > m ? a : m);
    final maxY = maxAmount <= 0 ? 1.0 : maxAmount * 1.25;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => scheme.inverseSurface,
          getTooltipItem: (group, _, rod, _) {
            final index = group.x;
            if (index < 0 || index >= days.length) return null;
            return BarTooltipItem(
              '${dayLabel(days[index])}\n'
              '${MoneyFormat.withCode(rod.toY, currency: currency)}',
              theme.textTheme.labelSmall!.copyWith(
                color: scheme.onInverseSurface,
              ),
            );
          },
        ),
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions) return;
          final spot = response?.spot;
          if (spot == null) {
            // Tapping the empty plot clears the day filter.
            onSelect(null);
            return;
          }
          final index = spot.touchedBarGroupIndex;
          if (index < 0 || index >= days.length) return;
          onSelect(days[index]);
        },
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= days.length) {
                return const SizedBox.shrink();
              }
              final highlighted = sameDay(days[index], activeDay);
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  _initials[days[index].weekday - 1],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: highlighted ? accent : scheme.onSurfaceVariant,
                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(days.length, (index) {
        final highlighted = sameDay(days[index], activeDay);
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: amounts[index],
              width: 22,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xs),
              ),
              color: highlighted
                  ? accent
                  : Color.alphaBlend(
                      accent.withValues(alpha: 0.28),
                      scheme.surfaceContainerLow,
                    ),
            ),
          ],
        );
      }),
    );
  }

  static const List<String> _initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
}

/// The row of account filters. "All" is a real option, not the absence of a
/// filter, so it gets the same shape as every account chip.
class _AccountChips extends StatelessWidget {
  const _AccountChips({
    required this.accounts,
    required this.selectedId,
    required this.accent,
    required this.onSelected,
  });

  final List<WaltAccount> accounts;
  final int? selectedId;
  final Color accent;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _AccountChip(
            label: 'All accounts',
            selected: selectedId == null,
            accent: accent,
            onTap: () => onSelected(null),
          ),
          for (final account in accounts) ...[
            const SizedBox(width: AppSpacing.sm),
            _AccountChip(
              label: account.name,
              selected: selectedId == account.id,
              accent: accent,
              dotColor: CategoryAvatar.parseHex(account.color),
              onTap: () => onSelected(account.id),
            ),
          ],
          // Keep the last chip clear of the card edge when scrolled to the end.
          const SizedBox(width: 1),
        ],
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Show $label',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? Color.alphaBlend(accent.withValues(alpha: 0.24), scheme.surface)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? accent : Colors.transparent,
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          // A full 48dp target even though the chip's visual weight stays
          // light: the row sits directly under a thumb.
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColor != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The account's initial in a tonal squircle, mirroring a category artwork.
class _AccountBadge extends StatelessWidget {
  const _AccountBadge({required this.account, required this.accent});

  final WaltAccount? account;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = (account?.name.trim().isNotEmpty ?? false)
        ? account!.name.trim().characters.first.toUpperCase()
        : null;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: initial == null
          ? Icon(Icons.account_balance_wallet_rounded, color: accent)
          : Text(
              initial,
              style: theme.textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
