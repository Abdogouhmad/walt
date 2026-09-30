import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/theme/motion.dart';
import 'package:walt/core/widgets/blur_surface.dart';
import 'package:walt/core/widgets/walt_chrome.dart';

/// One destination in [FloatingNavBar].
@immutable
class WaltDestination {
  /// Outlined icon, shown when the destination is not selected.
  final IconData icon;

  /// Filled icon, shown inside the active pill.
  final IconData selectedIcon;

  /// Accessibility label; also the text revealed inside the active pill.
  final String label;

  /// Optional badge count (0 / null hides the badge).
  final int? badgeCount;

  const WaltDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
  });
}

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
                        child: _NavItem(
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

class _NavItem extends StatelessWidget {
  final WaltDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = AppSpring.isDisabled(context);

    final springDuration = reduceMotion ? Duration.zero : AppMotion.long;
    final spatial = AppSpring.curve(AppSpring.spatial);

    final foreground = isSelected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        customBorder: const StadiumBorder(),
        child: Center(
          // Scale-down rather than clip. The item's floor is its own padding
          // plus the icon, and on a very narrow window even that exceeds a
          // quarter of the bar, so no amount of flexing inside the row can
          // make it fit. Shrinking the whole item keeps the design intact
          // instead of dropping the label on the floor, and at any normal
          // width the scale factor is exactly 1 and nothing moves.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedContainer(
              duration: springDuration,
              curve: spatial,
              // Sized by its own content: a 24dp icon plus this padding either
              // side, so the vertical value is the whole height budget. 10 makes
              // a 44dp pill, which leaves 12dp of bar above and below — already
              // clear of the bar's 1dp hairline. Going tighter than this thins
              // the pill out without buying any extra clearance.
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 8 : 12,
                vertical: 10,
              ),
              decoration: ShapeDecoration(
                color: isSelected
                    ? scheme.secondaryContainer
                    : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavIcon(
                    destination: destination,
                    isSelected: isSelected,
                    color: foreground,
                    springDuration: springDuration,
                    spring: spatial,
                  ),
                  // The label is always in the tree (so it can animate) but its
                  // width collapses to zero when unselected.
                  //
                  // `Flexible` hands the label whatever the icon leaves over
                  // rather than letting it claim its full intrinsic width: four
                  // items share this bar, and on a narrow window the selected
                  // label plus its padding is wider than a quarter of it.
                  Flexible(
                    child: ClipRect(
                      child: AnimatedAlign(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: isSelected ? 1 : 0,
                        duration: springDuration,
                        // Deliberately not the spring. `spatial` overshoots by
                        // ~35%, and a factor whose target is 0 overshoots
                        // straight through it into negative, which `Align`
                        // rejects. Springs need both endpoints inside the valid
                        // range; a dimension anchored at zero has no room for
                        // that, so the collapse uses a monotone curve.
                        curve: AppMotion.standard,
                        child: AnimatedOpacity(
                          opacity: isSelected ? 1 : 0,
                          duration: reduceMotion
                              ? Duration.zero
                              : AppMotion.short,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: Text(
                              destination.label,
                              maxLines: 1,
                              // Truncates rather than overflowing.
                              // `softWrap: false` would let the text lay out
                              // at its intrinsic width and spill past the cell.
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: foreground,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ),
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

class _NavIcon extends StatelessWidget {
  final WaltDestination destination;
  final bool isSelected;
  final Color color;
  final Duration springDuration;
  final Curve spring;

  const _NavIcon({
    required this.destination,
    required this.isSelected,
    required this.color,
    required this.springDuration,
    required this.spring,
  });

  @override
  Widget build(BuildContext context) {
    final badge = destination.badgeCount ?? 0;

    final icon = AnimatedSwitcher(
      duration: springDuration,
      switchInCurve: spring,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Icon(
        isSelected ? destination.selectedIcon : destination.icon,
        key: ValueKey<bool>(isSelected),
        size: 24,
        color: color,
      ),
    );

    if (badge <= 0) return icon;

    return Badge(
      isLabelVisible: true,
      label: Text(badge > 99 ? '99+' : '$badge'),
      child: icon,
    );
  }
}
