import 'package:flutter/material.dart';

import '../layout/walt_chrome.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';
import './blur_surface.dart';
import './walt_destination.dart';
import './walt_nav_item.dart';

/// Walt's bottom navigation: a docked, edge-to-edge bar that sits flush with
/// the bottom of the screen (spec §2).
///
/// It lives in the shell's `Scaffold.bottomNavigationBar` slot while the shell
/// keeps `extendBody` on, so content scrolls behind its frosted surface. Each
/// destination is a 64×32 pill behind the icon with the label underneath; the
/// selected one is tinted `primaryContainer`.
///
/// Accessibility:
///   * each destination is a `Semantics(button: true, selected: …)` node with
///     its label, so screen readers announce state;
///   * the row is [WaltChrome.navHeight] tall and every item is ≥48 dp wide.
class WaltNavBar extends StatelessWidget {
  final List<WaltDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Whether the bar is shown. The shell hides it while a modal sheet covers
  /// the screen; its slot keeps its height, so the layout never reflows.
  final bool visible;

  const WaltNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppSpring.isDisabled(context);

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1),
        duration: reduceMotion ? Duration.zero : AppMotion.medium,
        curve: AppMotion.emphasized,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: reduceMotion ? Duration.zero : AppMotion.short,
          child: BlurSurface(
            // A docked bar has no corners: it spans the full width and butts up
            // against the bottom edge. `BlurSurface` still owns the frost and
            // the reduce-transparency fallback, so only its rounding and its
            // all-round hairline are switched off — the single top hairline
            // below is painted in the foreground so the tint cannot cover it.
            radius: 0,
            border: false,
            shadows: false,
            sigma: BlurSurface.maxSigma,
            opacity: 0.55,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: SafeArea(
                // The Scaffold consumes the system inset for the body, not for
                // this slot: the bar owns the gesture-bar clearance itself.
                top: false,
                child: SizedBox(
                  height: WaltChrome.navHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Row(
                      // Stretch, so each item's tap target is the full bar
                      // height rather than just the icon-and-label column.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          Expanded(
                            child: WaltNavItem(
                              destination: destinations[i],
                              isSelected: i == selectedIndex,
                              onTap: () => onDestinationSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
