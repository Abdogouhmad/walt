import 'package:flutter/material.dart';

import 'package:walt/core/theme/text_theme.dart';
import 'package:walt/core/theme/walt_colors.dart';
import 'package:walt/core/utils/money.dart';

/// A money value rendered consistently across the app (spec §3).
///
/// Always uses tabular figures so changing balances do not reflow the layout,
/// always tints by income/expense semantics from [WaltColors], and optionally
/// tweens between values when [animate] is on.
///
/// The currency code is rendered as a lighter-weight suffix rather than being
/// concatenated into the string, so the digits stay the thing the eye lands on
/// (spec §6).
///
/// The number is wrapped in a [FittedBox] so it never overflows at 200 % text
/// scale (spec §6).
class AmountText extends StatefulWidget {
  final double amount;
  final String currency;

  /// Whether this is money coming in (`+`, income tint) or going out.
  final bool isIncome;

  /// Whether to prefix the sign (`+` / `-`). Off for balances.
  final bool showSign;

  /// Use the larger display tier intended for the hero balance.
  final bool hero;

  final TextStyle? style;
  final TextAlign? textAlign;
  final double? fontSize;

  /// Overrides the semantic income/expense tint (e.g. `onSurface` for a
  /// balance hero, which is neither income nor expense).
  final Color? color;

  /// Tween the number when it changes. Off by default for list rows.
  final bool animate;

  final int fractionDigits;

  const AmountText({
    super.key,
    required this.amount,
    required this.currency,
    this.isIncome = false,
    this.showSign = true,
    this.hero = false,
    this.style,
    this.textAlign,
    this.fontSize,
    this.color,
    this.animate = false,
    this.fractionDigits = 2,
  });

  @override
  State<AmountText> createState() => _AmountTextState();
}

class _AmountTextState extends State<AmountText> {
  /// The last value passed in, so a re-tween has somewhere to start from.
  double? _last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walt = WaltColors.of(context);

    final tint = widget.color ?? (widget.isIncome ? walt.income : walt.expense);

    final base = widget.hero
        ? theme.textTheme.displaySmall
        : theme.textTheme.titleMedium;
    final effective = (base ?? const TextStyle())
        .copyWith(
          color: tint,
          fontWeight: FontWeight.w700,
          fontFeatures: AppTextTheme.tabular,
        )
        .merge(widget.style)
        // Applied *after* the merge on purpose. `TextStyle.merge` lets a
        // non-null field in the incoming style win, so a `style` carrying a
        // role's own fontSize (every role does) would silently discard an
        // explicit [fontSize] and the override would do nothing.
        .copyWith(fontSize: widget.fontSize);

    // A tween whose begin and end are both `amount` never moves, which is why
    // the previous value has to be carried across rebuilds explicitly.
    final start = _last ?? widget.amount;
    _last = widget.amount;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment:
          widget.textAlign == TextAlign.right ||
              widget.textAlign == TextAlign.end
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: widget.animate
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: start, end: widget.amount),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => _label(effective, value),
            )
          : _label(effective, widget.amount),
    );
  }

  Widget _label(TextStyle style, double value) {
    final sign = !widget.showSign ? '' : (widget.isIncome ? '+' : '-');
    final digits = MoneyFormat.digits(
      value.abs(),
      fractionDigits: widget.fractionDigits,
    );
    final code = widget.currency.trim();

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
      textAlign: widget.textAlign,
    );
  }
}
