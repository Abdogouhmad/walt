import 'package:flutter/material.dart';
import 'package:walt/core/theme/color_math.dart';

/// Semantic colours that Material 3's [ColorScheme] does not name explicitly:
/// money direction (income / expense) and the "heads up" state used by budgets.
///
/// These are registered on [ThemeData.extensions] so screens read them with
/// `WaltColors.of(context)` instead of hardcoding `Colors.green` /
/// `Colors.red` (spec §1.2).
///
/// **Hue is meaning, tone is solved.** A finance app that recolours "money in"
/// to whatever the user's seed happens to be has stopped communicating. So the
/// *hue* of each semantic role is fixed — green, red, amber — while the *tone*
/// is solved against whichever surface it will be drawn on:
///
///   * the hue is pulled a short distance toward `primary` (12–25%) so the
///     accent still belongs to the active palette;
///   * the hue is then re-asserted, because harmonisation is what would
///     otherwise turn income into a second shade of the primary;
///   * the tone is stepped until the accent clears its contrast target against
///     `surfaceContainer` — which is what keeps income legible on white in
///     light mode *and* on pure black under AMOLED in dark mode.
///
/// The result is that all nine palettes get cohesive, and identical, money
/// colours.
@immutable
class WaltColors extends ThemeExtension<WaltColors> {
  /// Tonal accent for money coming in. Foreground/icon tone.
  final Color income;

  /// Tonal accent for money going out. Foreground/icon tone.
  final Color expense;

  /// Tonal accent for "approaching a limit" states.
  final Color warning;

  /// Low-emphasis fill behind income figures (pills, list avatars).
  final Color incomeContainer;

  /// Low-emphasis fill behind expense figures.
  final Color expenseContainer;

  /// Low-emphasis fill behind warning figures.
  final Color warningContainer;

  const WaltColors({
    required this.income,
    required this.expense,
    required this.warning,
    required this.incomeContainer,
    required this.expenseContainer,
    required this.warningContainer,
  });

  /// The fixed semantic hues. Chroma is left to [ColorMath.ensureContrast],
  /// which only ever moves lightness, so these stay recognisable in every
  /// palette.
  static const double _incomeHue = 145;
  static const double _expenseHue = 15;
  static const double _warningHue = 45;

  /// How far each accent is allowed to drift toward the palette. Income and
  /// expense are small because their hue carries meaning; the warning is larger
  /// because "amber" is a mood, not a fact about the user's money.
  static const double _incomeHarmonize = 0.12;
  static const double _expenseHarmonize = 0.12;
  static const double _warningHarmonize = 0.25;

  /// Builds the semantic palette for [scheme].
  ///
  /// [surface] is the background the accents are read against; pass
  /// `surfaceContainer` for text and icons, `surface` for full-bleed fills.
  factory WaltColors.fromScheme(ColorScheme scheme, {Color? surface}) {
    final background = surface ?? scheme.surfaceContainer;

    return WaltColors(
      income: _accent(scheme, _incomeHue, background, _incomeHarmonize),
      expense: _accent(scheme, _expenseHue, background, _expenseHarmonize),
      warning: _accent(scheme, _warningHue, background, _warningHarmonize),
      incomeContainer: _container(scheme, _incomeHue, background),
      expenseContainer: _container(scheme, _expenseHue, background),
      warningContainer: _container(scheme, _warningHue, background),
    );
  }

  /// The semantic extension for [context], or a scheme-derived fallback.
  ///
  /// The fallback keeps widgets usable in isolation (tests, `MaterialApp`
  /// snippets) where the app theme was never installed.
  static WaltColors of(BuildContext context) =>
      Theme.of(context).extension<WaltColors>() ??
      WaltColors.fromScheme(Theme.of(context).colorScheme);

  /// A semantic accent: harmonised toward the palette, hue re-asserted, tone
  /// solved for legibility on [background].
  static Color _accent(
    ColorScheme scheme,
    double hue,
    Color background,
    double harmonize,
  ) {
    final base = ColorMath.harmonize(
      HSLColor.fromAHSL(1, hue, 0.62, 0.32).toColor(),
      scheme.primary,
      harmonize,
    );
    final rehued = HSLColor.fromColor(base).withHue(hue).toColor();
    return ColorMath.ensureContrast(rehued, background);
  }

  /// A quiet fill in the same hue, stepped away from [background] so it reads as
  /// a recessive tint rather than as another accent.
  static Color _container(ColorScheme scheme, double hue, Color background) {
    final hsl = HSLColor.fromColor(
      ColorMath.harmonize(
        HSLColor.fromAHSL(1, hue, 0.62, 0.5).toColor(),
        scheme.primary,
        0.12,
      ),
    ).withHue(hue);
    final onLightBackground = ColorMath.luminance(background) > 0.5;
    return hsl
        .withLightness(onLightBackground ? 0.9 : 0.28)
        .withSaturation(hsl.saturation * 0.55)
        .toColor();
  }

  /// Foreground tone for a transaction [type] (`'income'` / `'expense'`).
  Color forTransactionType(String type) =>
      type.toLowerCase() == 'income' ? income : expense;

  /// Low-emphasis fill matching [forTransactionType].
  Color containerForTransactionType(String type) =>
      type.toLowerCase() == 'income' ? incomeContainer : expenseContainer;

  @override
  WaltColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? incomeContainer,
    Color? expenseContainer,
    Color? warningContainer,
  }) {
    return WaltColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      warningContainer: warningContainer ?? this.warningContainer,
    );
  }

  @override
  WaltColors lerp(ThemeExtension<WaltColors>? other, double t) {
    if (other is! WaltColors) return this;
    return WaltColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      expenseContainer: Color.lerp(
        expenseContainer,
        other.expenseContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WaltColors &&
      other.income == income &&
      other.expense == expense &&
      other.warning == warning &&
      other.incomeContainer == incomeContainer &&
      other.expenseContainer == expenseContainer &&
      other.warningContainer == warningContainer;

  @override
  int get hashCode => Object.hash(
    income,
    expense,
    warning,
    incomeContainer,
    expenseContainer,
    warningContainer,
  );
}
