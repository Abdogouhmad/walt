import 'package:flutter/material.dart';

import '../layout/walt_chrome.dart';
import '../tokens/motion.dart';
import '../utils/haptics.dart';
import 'fab_action.dart';
import 'fab_action_button.dart';
import 'fab_menu_button.dart';
import 'fab_scrim.dart';

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
    if (_open || widget.actions.isEmpty) return;
    if (widget.actions.length == 1) {
      Haptics.light();
      widget.actions.single.onPressed();
      return;
    }
    Haptics.light();
    setState(() => _open = true);
    _controller.forward();
  }

  void _collapse() {
    if (!_open) return;
    Haptics.selection();
    setState(() => _open = false);
    _controller.reverse();
  }

  /// The FAB is a toggle: once the close glyph is showing, tapping it again
  /// must put the actions away instead of re-expanding the same menu.
  void _toggle() {
    if (_open) {
      _collapse();
    } else {
      _expand();
    }
  }

  @override
  void didUpdateWidget(covariant ExpressiveFabMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The shell hides the FAB while a sheet is open or the chrome is scrolled
    // away. Collapse in the same frame so the action stack cannot reappear
    // still expanded when the FAB comes back.
    if (!widget.visible && _open) {
      _open = false;
      _controller.value = 0;
    }
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
        WaltChrome.navHeight +
        WaltChrome.systemBottom(context) +
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
          // only intercepts pointers while the menu is open and visible. ─────
          Positioned.fill(
            child: FabScrim(
              opacity: scrimOpacity,
              active: _open && widget.visible,
              color: scheme.scrim,
              onTap: _collapse,
            ),
          ),

          // ── Actions, nearest-to-FAB first ────────────────────────────────
          // They follow the FAB's visibility, so a hidden menu can never leave
          // its actions floating over a sheet.
          if (widget.visible)
            for (var i = 0; i < widget.actions.length; i++)
              FabActionButton(
                action: widget.actions[i],
                controller: _controller,
                index: i,
                right: WaltChrome.horizontalMargin,
                bottom: bottom + _fabSize + 12 + i * 60.0,
                reduceMotion: reduceMotion,
                active: _open,
                onDismiss: _collapse,
              ),

          // ── The FAB ──────────────────────────────────────────────────────
          FabMenuButton(
            visible: widget.visible,
            open: _open,
            scheme: scheme,
            turns: reduceMotion ? null : _controller,
            semanticsLabel: widget.actions.length == 1
                ? widget.actions.single.label
                : 'Add',
            size: _fabSize,
            bottom: bottom,
            right: WaltChrome.horizontalMargin,
            reduceMotion: reduceMotion,
            onTap: _toggle,
          ),
        ],
      ),
    );
  }
}
