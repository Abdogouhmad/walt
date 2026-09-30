/// Backwards-compatible view of the radius scale.
///
/// The tokens now live in `core/design/radius.dart` alongside spacing and
/// motion, so there is exactly one geometry source of truth. This file keeps
/// the historical `AppShape.*` names working.
library;

import 'package:flutter/material.dart';

import 'package:walt/core/design/radius.dart';

export 'package:walt/core/design/radius.dart'
    show
        AppRadius,
        GroupedRadii,
        AppShapeExtraSmall,
        AppShapeSmall,
        AppShapeMedium,
        AppShapeLarge,
        AppShapeExtraLarge,
        AppShapeFull;

abstract final class AppShape {
  const AppShape._();

  static const double extraSmall = AppRadius.xs;
  static const double small = AppRadius.sm;
  static const double medium = AppRadius.md;
  static const double large = AppRadius.lg;
  static const double extraLarge = AppRadius.xl;
  static const double full = AppRadius.pill;

  static const BorderRadius radiusExtraSmall = AppRadius.rXs;
  static const BorderRadius radiusSmall = AppRadius.rSm;
  static const BorderRadius radiusMedium = AppRadius.rMd;
  static const BorderRadius radiusLarge = AppRadius.rLg;
  static const BorderRadius radiusExtraLarge = AppRadius.rXl;
  static const BorderRadius radiusFull = AppRadius.rPill;

  static RoundedRectangleBorder sheet({double radius = AppRadius.xl}) =>
      AppRadius.sheet(radius: radius);

  static const StadiumBorder stadium = StadiumBorder();
}
