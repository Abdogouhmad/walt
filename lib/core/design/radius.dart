/// Canonical corner-radius tokens for the entire app.
///
/// The scale is 8 / 12 / 20 / 28 with two semantic aliases layered on top:
///
/// | token    | value | use                                        |
/// |----------|-------|--------------------------------------------|
/// | `xs`     | 8     | chips, tags, tiny badges                   |
/// | `sm`     | 12    | inner items of a grouped list              |
/// | `md`     | 16    | text fields, buttons                       |
/// | `lg`     | 20    | grouped-list ends, secondary buttons       |
/// | `xl`     | 28    | cards, sheets, dialogs — the Walt radius   |
/// | `pill`   | 999   | fully-rounded pills and stadiums           |
///
/// Together with `AppSpacing` and `AppMotion` these are the only geometry
/// tokens UI code should use instead of arbitrary literals.
library;

import 'package:flutter/material.dart';

/// Aliases kept for the pre-existing call sites so no screen has to churn.
// ignore: constant_identifier_names
const double AppShapeExtraSmall = AppRadius.xs;
// ignore: constant_identifier_names
const double AppShapeSmall = AppRadius.sm;
// ignore: constant_identifier_names
const double AppShapeMedium = AppRadius.md;
// ignore: constant_identifier_names
const double AppShapeLarge = AppRadius.lg;
// ignore: constant_identifier_names
const double AppShapeExtraLarge = AppRadius.xl;
// ignore: constant_identifier_names
const double AppShapeFull = AppRadius.pill;

abstract final class AppRadius {
  const AppRadius._();

  /// 8 — chips, tags, tiny badges.
  static const double xs = 8;

  /// 12 — inner items of a grouped list, small controls.
  static const double sm = 12;

  /// 16 — text fields and buttons.
  static const double md = 16;

  /// 20 — grouped-list ends, secondary buttons.
  static const double lg = 20;

  /// 28 — cards, sheets, dialogs, FABs. The signature Walt radius.
  static const double xl = 28;

  /// Fully rounded (pills, stadiums). Matches `BorderRadius.circular` clamping
  /// so pill surfaces never overflow their box.
  static const double pill = 999.0;

  // ---- semantic aliases -------------------------------------------------

  /// Chips, tags, tiny badges.
  static const double extraSmall = xs;

  /// Small controls.
  static const double small = sm;

  /// Text fields and buttons.
  static const double medium = md;

  /// Grouped-list ends.
  static const double large = lg;

  /// Cards and sheets.
  static const double extraLarge = xl;

  /// Fields, buttons and smaller containers.
  static const double field = md;

  /// Cards, sheets, dialogs.
  static const double surface = xl;

  /// A single card's radius.
  static const double card = xl;

  /// Pills and stadiums.
  static const double full = pill;

  // ---- ready-made radii -------------------------------------------------

  static const BorderRadius rXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rPill = BorderRadius.all(Radius.circular(pill));

  /// Vertical-only shape for bottom sheets and top-anchored panels.
  static RoundedRectangleBorder sheet({double radius = xl}) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      );

  /// Shape used by the floating navigation bar and every pill surface.
  static const StadiumBorder stadium = StadiumBorder();
}

/// Radius scale for a grouped list: the first and last items keep the large
/// silhouette, the items in between tuck into [AppRadius.sm] so the group reads
/// as one container.
abstract final class GroupedRadii {
  const GroupedRadii._();

  static BorderRadius forIndex(int index, int count) {
    final isFirst = index == 0;
    final isLast = index == count - 1;
    return BorderRadius.only(
      topLeft: Radius.circular(isFirst ? AppRadius.lg : AppRadius.sm),
      topRight: Radius.circular(isFirst ? AppRadius.lg : AppRadius.sm),
      bottomLeft: Radius.circular(isLast ? AppRadius.lg : AppRadius.sm),
      bottomRight: Radius.circular(isLast ? AppRadius.lg : AppRadius.sm),
    );
  }
}
