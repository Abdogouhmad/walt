import 'package:flutter/material.dart';

/// Layout metrics for Walt's floating chrome — the detached pill navigation bar
/// and the FAB that sits above it.
///
/// The nav is *not* a `bottomNavigationBar`, so Flutter will not reserve space
/// for it. Every scrollable in the app must therefore end with
/// [scrollBottomPadding] so its last item is never hidden behind the pill, and
/// the shell positions chrome with [navBottomOffset].
abstract final class WaltChrome {
  const WaltChrome._();

  /// Horizontal margin between the pill and the screen edge.
  static const double horizontalMargin = 16;

  /// Height of the pill itself.
  static const double navHeight = 68;

  /// Gap between the pill and the bottom system inset.
  static const double navBottomMargin = 16;

  /// Vertical extent the chrome occupies, ignoring system insets.
  static const double navExtent = navHeight + navBottomMargin;

  /// Gap between the FAB and the top of the nav pill.
  static const double fabGap = 12;

  /// Max content width before the layout starts constraining and centring.
  static const double maxContentWidth = 600;

  /// Tablet/foldable breakpoint above which a navigation rail is preferable.
  static const double railBreakpoint = 840;

  /// Bottom system inset (gesture bar / nav buttons).
  static double systemBottom(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom;

  /// Distance from the screen's bottom edge to the pill's bottom edge.
  static double navBottomOffset(BuildContext context) =>
      navBottomMargin + systemBottom(context);

  /// Bottom padding a scrollable must add to clear the floating chrome.
  static double scrollBottomPadding(
    BuildContext context, {
    double extra = 24,
  }) => navExtent + systemBottom(context) + extra;

  /// Padding for a screen's scrollable body: [AppSpacing]-based sides, chrome
  /// clearance at the bottom.
  static EdgeInsets screenPadding(
    BuildContext context, {
    double horizontal = 16,
    double top = 0,
    double extraBottom = 0,
  }) => EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    scrollBottomPadding(context, extra: extraBottom),
  );

  /// Centres and width-caps [child] on large screens so phone-first layouts do
  /// not stretch across a foldable or tablet.
  static Widget constrain(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxContentWidth),
      child: child,
    ),
  );
}
