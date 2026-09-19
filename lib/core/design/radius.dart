/// Canonical corner-radius tokens for the entire app.
///
/// Walt targets a single Android form factor, so exactly two radii are
/// used (spec §1.1):
///   - 28dp on large surfaces: cards, sheets, dialogs
///   - 16dp on fields, buttons, and smaller containers
///
/// Together with [AppSpacing] and [AppMotion] these are the only geometry
/// tokens UI code should use instead of arbitrary literals.
library;

class AppRadius {
  AppRadius._();

  /// 16dp — fields, buttons, smaller containers.
  static const double field = 16;

  /// 28dp — cards, sheets, dialogs.
  static const double surface = 28;

  /// Pill shape / fully-rounded.
  static const double full = 9999;
}