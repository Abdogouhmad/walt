import 'package:flutter/material.dart';

import '../tokens/motion.dart';
import '../utils/haptics.dart';
import './walt_destination.dart';
import './walt_nav_icon.dart';

/// A single destination inside [WaltNavBar]: an icon in a pill with the label
/// underneath, always visible.
///
/// The selected pill fills with `primaryContainer`; unselected ones stay
/// transparent, so only the active destination reads as a surface. Taps fire a
/// selection haptic.
class WaltNavItem extends StatelessWidget {
  /// Size of the pill behind the icon (spec: `w-16 h-8`).
  static const Size pillSize = Size(64, 32);

  final WaltDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const WaltNavItem({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduceMotion = AppSpring.isDisabled(context);

    final foreground = isSelected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        customBorder: const StadiumBorder(),
        child: Center(
          // Scale down rather than clip: four items share the bar, and on a
          // very narrow window a quarter of it is less than the pill's 64 dp.
          // Shrinking the whole column keeps the design intact instead of
          // dropping the label, and at any normal width the factor is 1.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : AppMotion.short,
                  curve: AppMotion.standard,
                  width: pillSize.width,
                  height: pillSize.height,
                  decoration: ShapeDecoration(
                    color: isSelected
                        ? scheme.primaryContainer
                        : Colors.transparent,
                    shape: const StadiumBorder(),
                  ),
                  child: Center(
                    child: WaltNavIcon(
                      icon: destination.icon,
                      selectedIcon: destination.selectedIcon,
                      isSelected: isSelected,
                      color: foreground,
                      springDuration: reduceMotion
                          ? Duration.zero
                          : AppMotion.long,
                      spring: AppSpring.spatialCurve,
                      badgeCount: destination.badgeCount ?? 0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
