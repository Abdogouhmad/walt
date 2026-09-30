import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:walt/core/theme/motion.dart';
import 'package:walt/core/theme/shapes.dart';
import 'package:walt/core/widgets/walt_chrome.dart';

/// One action inside [ExpressiveFabMenu].
@immutable
class FabAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const FabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.foregroundColor,
    this.backgroundColor,
  });
}

/// Walt's primary "add" affordance (spec §2): a rounded-square FAB that, when
/// tapped, unfolds a staggered stack of labelled actions over a scrim.
///
/// This widget must be placed as a full-bleed, topmost child of a [Stack]
/// (`Positioned.fill`) — it positions the scrim, the action list and the FAB
/// itself in that coordinate space, anchored above the floating navigation bar.
class ExpressiveFabMenu extends StatefulWidget {
  final List<FabAction> actions;

  /// Whether the FAB is revealed. The shell hides it in step with the
  /// navigation pill while scrolling.
  final bool visible;

  /// Extra lift above the nav bar (0 keeps the spec default [WaltChrome.fabGap]).
  final double extraBottomGap;

  const ExpressiveFabMenu({
    super.key,
    required this.actions,
    this.visible = true,
    this.extraBottomGap = 0,
  });

  @override
  State<ExpressiveFabMenu> createState() => _ExpressiveFabMenuState();
}

class _ExpressiveFabMenuState extends State<ExpressiveFabMenu>
    with SingleTickerProviderStateMixin {
  static const double _fabSize = 72;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 240),
  );

  /// Whether the menu is expanded. Kept as plain state (rather than read from
  /// the controller) so the scrim's hit-testing state updates synchronously.
  bool _open = false;

  void _expand() {
    if (widget.actions.isEmpty) return;
    if (widget.actions.length == 1) {
      HapticFeedback.lightImpact();
      widget.actions.single.onPressed();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _open = true);
    _controller.forward();
  }

  void _collapse() {
    HapticFeedback.selectionClick();
    setState(() => _open = false);
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = AppSpring.isDisabled(context);

    final bottom =
        WaltChrome.navBottomOffset(context) +
        WaltChrome.navHeight +
        WaltChrome.fabGap +
        widget.extraBottomGap;

    final scrimOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
      reverseCurve: const Interval(0.4, 1, curve: Curves.easeIn),
    );

    return PopScope(
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _open) _collapse();
      },
      child: Stack(
        children: [
          // ── Scrim — always mounted (so its opacity can animate out), but it
          // only intercepts pointers while the menu is open. ────────────────
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_open,
              child: FadeTransition(
                opacity: scrimOpacity,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _collapse,
                  child: ColoredBox(
                    color: scheme.scrim.withValues(alpha: 0.32),
                  ),
                ),
              ),
            ),
          ),

          // ── Actions, nearest-to-FAB first ────────────────────────────────
          for (var i = 0; i < widget.actions.length; i++)
            _ActionButton(
              action: widget.actions[i],
              controller: _controller,
              index: i,
              right: WaltChrome.horizontalMargin,
              bottom: bottom + _fabSize + 12 + i * 60.0,
              reduceMotion: reduceMotion,
              onDismiss: _collapse,
            ),

          // ── The FAB ──────────────────────────────────────────────────────
          Positioned(
            right: WaltChrome.horizontalMargin,
            bottom: bottom,
            child: IgnorePointer(
              ignoring: !widget.visible,
              child: AnimatedSlide(
                offset: widget.visible ? Offset.zero : const Offset(0, 1.6),
                duration: reduceMotion ? Duration.zero : AppMotion.medium,
                curve: AppMotion.emphasized,
                child: AnimatedOpacity(
                  opacity: widget.visible ? 1 : 0,
                  duration: reduceMotion ? Duration.zero : AppMotion.short,
                  child: _FabSurface(
                    size: _fabSize,
                    scheme: scheme,
                    open: _open,
                    turns: reduceMotion ? null : _controller,
                    semanticsLabel: widget.actions.length == 1
                        ? widget.actions.single.label
                        : 'Add',
                    onTap: _expand,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FabSurface extends StatelessWidget {
  final double size;
  final ColorScheme scheme;
  final bool open;
  final Animation<double>? turns;
  final String semanticsLabel;
  final VoidCallback onTap;

  const _FabSurface({
    required this.size,
    required this.scheme,
    required this.open,
    required this.turns,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppShape.extraLarge),
    );

    return Semantics(
      button: true,
      toggled: open,
      label: semanticsLabel,
      child: Material(
        color: scheme.primaryContainer,
        elevation: 3,
        shadowColor: scheme.shadow,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: SizedBox(
            width: size,
            height: size,
            child: turns == null
                ? Icon(
                    open ? Icons.close_rounded : Icons.add_rounded,
                    size: 32,
                    color: scheme.onPrimaryContainer,
                  )
                : AnimatedBuilder(
                    animation: turns!,
                    builder: (context, _) => Transform.rotate(
                      angle: turns!.value * 3.14159265 / 4,
                      child: Icon(
                        turns!.value < 0.5
                            ? Icons.add_rounded
                            : Icons.close_rounded,
                        size: 32,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final FabAction action;
  final AnimationController controller;
  final int index;
  final double right;
  final double bottom;
  final bool reduceMotion;
  final VoidCallback onDismiss;

  const _ActionButton({
    required this.action,
    required this.controller,
    required this.index,
    required this.right,
    required this.bottom,
    required this.reduceMotion,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Stagger: the action closest to the FAB leads, the rest trail by 80 ms.
    final begin = (index * 0.08).clamp(0.0, 0.4);
    final end = (begin + 0.55).clamp(0.0, 1.0);

    final animation = reduceMotion
        ? const AlwaysStoppedAnimation<double>(1)
        : CurvedAnimation(
            parent: controller,
            curve: Interval(
              begin,
              end,
              curve: AppSpring.curve(AppSpring.spatial),
            ),
            reverseCurve: Interval(0, end, curve: Curves.easeIn),
          );

    final scheme = Theme.of(context).colorScheme;
    final fg = action.foregroundColor ?? scheme.onSurface;
    final bg = action.backgroundColor ?? scheme.surfaceContainerHigh;

    return Positioned(
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value.clamp(0.0, 1.2);
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 24),
              child: Transform.scale(
                scale: 0.85 + 0.15 * t,
                alignment: AlignmentDirectional.bottomEnd,
                child: child,
              ),
            ),
          );
        },
        child: Semantics(
          button: true,
          label: action.label,
          child: Material(
            color: bg,
            elevation: 2,
            shadowColor: scheme.shadow,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onDismiss();
                action.onPressed();
              },
              customBorder: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(action.icon, size: 20, color: fg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
