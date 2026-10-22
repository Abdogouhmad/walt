import 'package:walt_ui/walt_ui.dart';

/// Trims trailing ".00" noise: `120.50` -> `120.5`, `200.00` -> `200`.
/// Whole amounts read better without cents; fractional ones keep them, but
/// both go through the shared formatter so a notification and the screen it
/// opens never disagree about how a number is written.
String trimNotificationAmount(double value) {
  final fractionDigits = value == value.roundToDouble() ? 0 : 2;
  return MoneyFormat.digits(value, fractionDigits: fractionDigits);
}

/// The body of a budget-alert notification.
///
/// Two shapes, because they say different things: "spent of" for a limit that
/// has been passed, plain "of" for one that is about to be.
String budgetAlertBody({
  required String categoryName,
  required double limit,
  required double spent,
  required String currency,
  required bool exceeded,
}) {
  final cur = currency.trim().isEmpty ? '' : ' $currency';
  final spentLabel = '${trimNotificationAmount(spent)}$cur';
  final limitLabel = '${trimNotificationAmount(limit)}$cur';

  return exceeded
      ? '$categoryName: $spentLabel spent of $limitLabel.'
      : '$categoryName: $spentLabel of $limitLabel spent.';
}
