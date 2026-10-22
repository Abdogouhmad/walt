import 'package:flutter/material.dart';

/// Layout metrics for Walt's chrome — the docked navigation bar and the FAB
/// that floats above it.
///
/// The bar is a `Scaffold.bottomNavigationBar`, so the shell reserves its space
/// and keeps `extendBody` on: content scrolls *behind* its frosted surface.
/// Every scrollable must therefore end with [scrollBottomPadding] so its last
/// item is never hidden behind the bar.
abstract final class WaltChrome {
  const WaltChrome._();

  /// Horizontal margin between the FAB and the screen edge. The navigation bar
  /// itself is edge to edge.
  static const double horizontalMargin = 16;

  /// Height of the bar's destination row, excluding the bottom system inset.
  static const double navHeight = 80;

  /// Gap between the FAB and the top edge of the navigation bar.
  static const double fabGap = 12;

  /// Max content width before the layout starts constraining and centring.
  static const double maxContentWidth = 600;

  /// Tablet/foldable breakpoint above which a navigation rail is preferable.
  static const double railBreakpoint = 840;

  /// Bottom system inset (gesture bar / nav buttons).
  static double systemBottom(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom;

  /// Distance from the screen's bottom edge to the top of the navigation bar.
  static double navTopOffset(BuildContext context) =>
      navHeight + systemBottom(context);

  /// Bottom padding a scrollable must add to clear the chrome that scrolls
  /// behind it.
  static double scrollBottomPadding(
    BuildContext context, {
    double extra = 24,
  }) => navTopOffset(context) + extra;

  /// Centres and width-caps [child] on large screens so phone-first layouts do
  /// not stretch across a foldable or tablet.
  static Widget constrain(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxContentWidth),
      child: child,
    ),
  );
}
