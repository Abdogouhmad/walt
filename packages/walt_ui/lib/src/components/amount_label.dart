import 'package:flutter/material.dart';

import '../format/money_format.dart';

/// Builds the money label for [value] in [currency].
///
/// The currency code is rendered as a lighter-weight suffix rather than being
/// concatenated into the string, so the digits stay the thing the eye lands on
/// (spec §6).
Widget amountLabel({
  required double value,
  required String currency,
  required TextStyle style,
  required bool isIncome,
  required bool showSign,
  required int fractionDigits,
  TextAlign? textAlign,
}) {
  final sign = !showSign ? '' : (isIncome ? '+' : '-');
  final digits = MoneyFormat.digits(
    value.abs(),
    fractionDigits: fractionDigits,
  );
  final code = currency.trim();

  // The suffix steps down a size and sheds weight so it reads as a unit, not
  // as part of the number. Always derived from the *effective* size so the
  // two stay in proportion at every tier — hardcoding a role here made a
  // 14pt code sit under a 56pt hero number.
  final suffix = style.copyWith(
    fontSize: (style.fontSize ?? 16) * 0.72,
    fontWeight: FontWeight.w500,
    color: style.color?.withValues(alpha: 0.72),
    fontFeatures: const <FontFeature>[],
  );

  if (code.isEmpty) {
    return Text('$sign$digits', maxLines: 1, style: style);
  }

  return Text.rich(
    TextSpan(
      // Set on the root span rather than relying on `Text.rich` to propagate
      // it down. The digits span below has no style of its own, so this is
      // the style it actually renders with.
      style: style,
      children: [
        TextSpan(text: '$sign$digits'),
        TextSpan(text: ' $code', style: suffix),
      ],
    ),
    maxLines: 1,
    textAlign: textAlign,
  );
}
