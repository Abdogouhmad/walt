import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt_ui/walt_ui.dart';

import 'support/nav_harness.dart';

void main() {
  group('nav frost', () {
    const destinations = [
      WaltDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Home',
      ),
      WaltDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: 'Activity',
      ),
    ];

    Future<void> pumpNav(
      WidgetTester tester, {
      bool reduceTransparency = false,
    }) async {
      await tester.pumpWidget(
        navHost(
          WaltNavBar(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
          reduceTransparency: reduceTransparency,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('actually blurs its backdrop', (tester) async {
      await pumpNav(tester);

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('tint is light enough for the blur to read through', (
      tester,
    ) async {
      await pumpNav(tester);

      // The docked bar uses a translucent surfaceContainer tint so the blur
      // actually reads through busy content.
      final tint = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.color)
          .firstWhere((c) => c != null)!;

      expect(tint.a, lessThan(0.7));
      expect(tint.a, greaterThan(0.3));
    });

    testWidgets('reduce transparency still removes the blur', (tester) async {
      await pumpNav(tester, reduceTransparency: true);

      // Accessibility overrides win over the look: no live blur, opaque fill.
      expect(find.byType(BackdropFilter), findsNothing);

      final tint = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.color)
          .firstWhere((c) => c != null)!;

      expect(tint.a, 1.0);
    });
  });
}
