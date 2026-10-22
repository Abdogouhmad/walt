import 'package:flutter/material.dart';

import '../layout/walt_chrome.dart';
import '../tokens/motion.dart';
import '../tokens/radius.dart';
import './blur_surface.dart';
import './floating_nav_item.dart';
import './walt_destination.dart';

/// Walt's signature bottom navigation: a detached, fully-rounded pill that
/// floats above the content (spec §2).
///
/// The selected destination grows a `secondaryContainer` pill that reveals its
/// label; unselected destinations stay as bare outlined icons. Motion is driven
/// by the spatial spring, and taps fire a selection haptic.
///
/// Accessibility:
///   * each destination is a `Semantics(button: true, selected: …)` node with
///     its label, so screen readers announce state;
///   * the slot is at least [WaltChrome.navHeight] tall and ≥48 dp wide;
///   * it animates away on scroll but is fully restored on reverse scroll.
class FloatingNavBar extends StatelessWidget {
  final List<WaltDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Whether the bar is currently revealed. Drives the scroll hide/show.
  final bool visible;

  const FloatingNavBar({
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
        offset: visible ? Offset.zero : const Offset(0, 1.8),
        duration: reduceMotion ? Duration.zero : AppMotion.medium,
        curve: AppMotion.emphasized,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: reduceMotion ? Duration.zero : AppMotion.short,
          child: Padding(
            // `navBottomOffset` keeps the pill clear of the gesture bar /
            // navigation buttons; the raw constant alone pinned it to y=0.
            padding: EdgeInsetsDirectional.only(
              start: WaltChrome.horizontalMargin,
              end: WaltChrome.horizontalMargin,
              bottom: WaltChrome.navBottomOffset(context),
            ),
            child: BlurSurface(
              radius: AppRadius.pill,
              // A heavier blur under a thinner tint. At the shared 0.82 light
              // fill only a fifth of the blurred backdrop survived, so the bar
              // read as a flat opaque slab — frosted only in theory. Dropping
              // the tint is what actually makes the blur visible; raising
              // sigma at the same time keeps the edges soft enough that the
              // remaining show-through never resolves into shapes.
              sigma: BlurSurface.maxSigma,
              opacity: 0.55,
              child: SizedBox(
                height: WaltChrome.navHeight,
                child: Row(
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      Expanded(
                        child: FloatingNavItem(
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
    );
  }
}
