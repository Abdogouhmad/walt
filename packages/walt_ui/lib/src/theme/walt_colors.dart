import 'package:flutter/material.dart';

import './semantic_accents.dart';

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

  /// Builds the semantic palette for [scheme].
  ///
  /// [surface] is the background the accents are read against; pass
  /// `surfaceContainer` for text and icons, `surface` for full-bleed fills.
  factory WaltColors.fromScheme(ColorScheme scheme, {Color? surface}) =>
      buildSemanticColors(scheme, surface: surface);

  /// The semantic extension for [context], or a scheme-derived fallback.
  ///
  /// The fallback keeps widgets usable in isolation (tests, `MaterialApp`
  /// snippets) where the app theme was never installed.
  static WaltColors of(BuildContext context) =>
      Theme.of(context).extension<WaltColors>() ??
      WaltColors.fromScheme(Theme.of(context).colorScheme);

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
