import 'package:intl/intl.dart';

/// Number formatting for money, kept in one place so every screen agrees on
/// grouping and decimals.
///
/// `NumberFormat` rather than `toStringAsFixed`, because the plain Dart
/// formatter drops the thousands separator entirely: `1234567.5` rendered as
/// `1234567.50` is unreadable, and unreadable numbers are how people
/// mis-budget.
abstract final class MoneyFormat {
  const MoneyFormat._();

  /// Formatter cache keyed by fraction-digit count.
  ///
  /// `NumberFormat.decimalPatternDigits` does a locale lookup and builds a new
  /// formatter on every call, and [digits] runs for every amount on every
  /// rebuild. The key space is tiny (headers use 0, everything else 2), so
  /// building each formatter once removes that work from the hot path.
  static final Map<int, NumberFormat> _formats = {};

  static NumberFormat _formatFor(int fractionDigits) => _formats.putIfAbsent(
    fractionDigits,
    () => NumberFormat.decimalPatternDigits(
      locale: 'en_US',
      decimalDigits: fractionDigits,
    ),
  );

  /// Formats [value] with grouping separators and a fixed decimal count.
  ///
  /// [fractionDigits] of 0 is used for round figures in headers; 2 elsewhere.
  /// The currency symbol is *not* appended here — it is rendered separately at
  /// a lighter weight, so this returns the digits only.
  ///
  /// Non-finite input collapses to 0. `NumberFormat` would otherwise render
  /// `∞` and `NaN` verbatim, and a balance reading `NaN` is worse than a
  /// balance reading zero: it looks like the app is broken and gives the user
  /// nothing to act on. Since this is the one formatter every amount goes
  /// through, guarding here also keeps a division-by-zero upstream from
  /// reaching the screen at all.
  static String digits(double value, {int fractionDigits = 2}) {
    final safe = value.isFinite ? value : 0.0;
    return _formatFor(fractionDigits).format(safe);
  }

  /// The full amount including a trailing currency code, for places that show
  /// the value inline (notifications, list subtitles).
  static String withCode(
    double value, {
    required String currency,
    int fractionDigits = 2,
    bool signed = false,
  }) {
    final sign = !signed ? '' : (value < 0 ? '-' : '+');
    final code = currency.trim();
    final body = digits(value.abs(), fractionDigits: fractionDigits);
    return code.isEmpty ? '$sign$body' : '$sign$body $code';
  }
}
