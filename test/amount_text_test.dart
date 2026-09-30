import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt/core/theme/app_theme.dart';
import 'package:walt/core/widgets/amount_text.dart';

/// Pumps [AmountText] and returns the `TextStyle` its digits actually render
/// with.
///
/// `Text.rich` wraps the supplied span in a root of its own that carries the
/// ambient `DefaultTextStyle` (14pt in a bare test app). The span built by
/// [AmountText] — which sets the real style and holds the digits as a child
/// with no style of its own — is that root's only child.
Future<TextStyle> _effectiveStyle(
  WidgetTester tester, {
  required double? fontSize,
  TextStyle? style,
}) async {
  late TextStyle captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme(),
      home: Scaffold(
        body: AmountText(
          amount: 1234.5,
          currency: 'MAD',
          hero: true,
          fontSize: fontSize,
          style: style,
        ),
      ),
    ),
  );
  final root = tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
  captured = (root.children!.single as TextSpan).style!;
  return captured;
}

void main() {
  group('AmountText font size', () {
    testWidgets('an explicit fontSize survives a style that also sets one', (
      tester,
    ) async {
      final theme = AppTheme.lightTheme();

      // This is the case that broke the home balance. The caller passed
      // `fontSize: 56` alongside a themed `style`, and `TextStyle.merge` lets
      // the style's own fontSize win — so the 56 was silently discarded and the
      // number rendered at the role's 44.
      final effective = await _effectiveStyle(
        tester,
        fontSize: 56,
        style: theme.textTheme.displayMedium,
      );

      expect(
        effective.fontSize,
        56,
        reason:
            'An explicit fontSize must win over a style that also specifies one',
      );
    });

    testWidgets('with no overrides the hero role size is used', (tester) async {
      final theme = AppTheme.lightTheme();
      final effective = await _effectiveStyle(tester, fontSize: null);

      expect(effective.fontSize, theme.textTheme.displaySmall?.fontSize);
    });

    testWidgets('the currency suffix stays proportional at any size', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const Scaffold(
            body: AmountText(
              amount: 1234.5,
              currency: 'MAD',
              hero: true,
              fontSize: 56,
            ),
          ),
        ),
      );

      final root =
          tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
      final suffix =
          (root.children!.single as TextSpan).children!.last as TextSpan;

      // 72% of the number, so the code never outshouts the amount and never
      // collapses to a 14pt role label under a 56pt number.
      expect(suffix.style!.fontSize, closeTo(56 * 0.72, 0.01));
    });
  });
}
