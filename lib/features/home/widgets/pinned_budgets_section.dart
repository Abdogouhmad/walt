import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walt/features/budgets/widgets/budget_card.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// The pinned-budget slice of Home.
///
/// Every pinned budget lives in a snap-to-card carousel, so Home still answers
/// "am I on track?" without becoming the Budgets list. Swiping moves between
/// budgets; the cards peek at their neighbours to advertise that. "See all"
/// remains the shortcut to the full list.
class PinnedBudgetsSection extends ConsumerWidget {
  const PinnedBudgetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(pinnedBudgetProgressProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final theme = Theme.of(context);

    if (pinned.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: _PinPrompt(onTap: () => context.go('/budgets')),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: pinned.length == 1 ? 'Pinned budget' : 'Pinned budgets',
            trailing: TextButton(
              onPressed: () => context.go('/budgets'),
              child: const Text('See all'),
            ),
          ),
          _PinnedBudgetCarousel(
            budgets: pinned,
            currency: currency,
            onTap: (progress) =>
                context.push('/budgets/${progress.budget.id}/history'),
            onUnpin: (progress) => _unpin(context, ref, progress),
          ),
          if (pinned.length == 1)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Tap a budget to see its history.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _unpin(BuildContext context, WidgetRef ref, BudgetProgress progress) {
    Haptics.selection();
    ref.read(budgetProvider.notifier).togglePinned(progress.budget.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${progress.displayName} unpinned from Home'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => ref
              .read(budgetProvider.notifier)
              .togglePinned(progress.budget.id),
        ),
      ),
    );
  }
}

/// A horizontal, snapping row of pinned budget cards.
///
/// Not a [PageView]: the cards are taller than a fixed viewport at large text
/// scales, and their height is content-driven. A horizontal scroll view inside
/// Home's vertical scroll lets the row take its natural height, while the
/// scroll-end handler snaps the nearest card back to the centre.
class _PinnedBudgetCarousel extends StatefulWidget {
  const _PinnedBudgetCarousel({
    required this.budgets,
    required this.currency,
    required this.onTap,
    required this.onUnpin,
  });

  final List<BudgetProgress> budgets;
  final String currency;
  final ValueChanged<BudgetProgress> onTap;
  final ValueChanged<BudgetProgress> onUnpin;

  @override
  State<_PinnedBudgetCarousel> createState() => _PinnedBudgetCarouselState();
}

class _PinnedBudgetCarouselState extends State<_PinnedBudgetCarousel> {
  /// Slightly narrower than the viewport so both neighbours peek in, which is
  /// what makes the row read as a carousel rather than a clipped list.
  static const double _viewportFraction = 0.86;
  static const double _maxCardWidth = 460;

  final ScrollController _controller = ScrollController();
  int _index = 0;
  double _step = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PinnedBudgetCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budgets.length != widget.budgets.length) {
      _index = _index.clamp(0, math.max(0, widget.budgets.length - 1));
      _jumpToIndex();
    }
  }

  void _jumpToIndex() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients || _step <= 0) return;
      _controller.jumpTo(
        (_index * _step).clamp(
          _controller.position.minScrollExtent,
          _controller.position.maxScrollExtent,
        ),
      );
    });
  }

  bool _handleScroll(ScrollNotification notification, double step) {
    if (notification.depth != 0) return false;

    if (notification is ScrollUpdateNotification) {
      final next = (notification.metrics.pixels / step).round().clamp(
        0,
        widget.budgets.length - 1,
      );
      if (next != _index) setState(() => _index = next);
    } else if (notification is ScrollEndNotification) {
      final targetIndex = (notification.metrics.pixels / step).round().clamp(
        0,
        widget.budgets.length - 1,
      );
      final target = (targetIndex * step).clamp(
        notification.metrics.minScrollExtent,
        notification.metrics.maxScrollExtent,
      );
      if ((target - notification.metrics.pixels).abs() > 0.5) {
        _controller.animateTo(
          target,
          duration: AppSpring.isDisabled(context)
              ? Duration.zero
              : AppMotion.medium,
          curve: AppMotion.standard,
        );
      }
      if (targetIndex != _index) setState(() => _index = targetIndex);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = math.min(
          constraints.maxWidth * _viewportFraction,
          _maxCardWidth,
        );
        final step = cardWidth + AppSpacing.md;
        // Centre the current card, leaving the neighbours peeking on both
        // sides. The symmetric padding makes the last snap offset line up with
        // the maximum scroll extent exactly.
        final side = math.max(0.0, (constraints.maxWidth - cardWidth) / 2);
        // The row gets an explicit width matching the padded content, so
        // `IntrinsicHeight` measures the cards at their real width instead of
        // at the scroll view's infinite width (which would under-measure
        // wrapping text).
        final contentWidth =
            constraints.maxWidth + (widget.budgets.length - 1) * step;
        _step = step;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) =>
                  _handleScroll(notification, step),
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                physics: widget.budgets.length < 2
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                child: SizedBox(
                  width: contentWidth,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: side),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < widget.budgets.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.md),
                            SizedBox(
                              key: ValueKey(widget.budgets[i].budget.id),
                              width: cardWidth,
                              child: BudgetCard(
                                progress: widget.budgets[i],
                                currency: widget.currency,
                                compact: true,
                                isPinned: true,
                                showPin: true,
                                onTap: () => widget.onTap(widget.budgets[i]),
                                onPinToggle: () =>
                                    widget.onUnpin(widget.budgets[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.budgets.length > 1) ...[
              const SizedBox(height: AppSpacing.sm),
              _CarouselIndicator(count: widget.budgets.length, index: _index),
            ],
          ],
        );
      },
    );
  }
}

/// "Which card am I on?" indicator for the pinned carousel.
///
/// Dots for the usual handful of pins, and a compact counter once the dots
/// would no longer fit or stop being readable.
class _CarouselIndicator extends StatelessWidget {
  const _CarouselIndicator({required this.count, required this.index});

  final int count;
  final int index;

  static const int _maxDots = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduceMotion = AppSpring.isDisabled(context);

    return Semantics(
      label: 'Pinned budget ${index + 1} of $count',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 16,
          child: Center(
            child: count > _maxDots
                ? Text(
                    '${index + 1} / $count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < count; i++)
                        AnimatedContainer(
                          duration: reduceMotion
                              ? Duration.zero
                              : AppMotion.short,
                          curve: AppMotion.standard,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs / 2,
                          ),
                          width: i == index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == index
                                ? scheme.primary
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
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

/// The compact "nothing pinned" state.
///
/// A full budget card would be a fake placeholder; this is an invitation with
/// one action, sized like a row rather than a card so it reads as a prompt.
class _PinPrompt extends StatelessWidget {
  const _PinPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: 'Pin a budget to show it on Home',
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.push_pin_outlined,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pin a budget',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Keep the ones you watch here on Home',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
