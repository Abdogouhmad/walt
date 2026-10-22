import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/motion.dart';
import './floating_nav_icon.dart';
import './walt_destination.dart';

/// A single destination inside [FloatingNavBar].
///
/// The selected destination grows a `secondaryContainer` pill that reveals its
/// label; unselected ones stay as bare outlined icons.
class FloatingNavItem extends StatelessWidget {
  final WaltDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const FloatingNavItem({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = AppSpring.isDisabled(context);

    final springDuration = reduceMotion ? Duration.zero : AppMotion.long;
    final spatial = AppSpring.spatialCurve;

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
                vertical: 15,
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
                  FloatingNavIcon(
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    isSelected: isSelected,
                    color: foreground,
                    springDuration: springDuration,
                    spring: spatial,
                    badgeCount: destination.badgeCount ?? 0,
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
