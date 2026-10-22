import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt_ui/walt_ui.dart';

import 'support/nav_harness.dart';

void main() {
  group('selection indicator', () {
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
      WaltDestination(
        icon: Icons.pie_chart_outline_rounded,
        selectedIcon: Icons.pie_chart_rounded,
        label: 'Budget',
      ),
      WaltDestination(
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights_rounded,
        label: 'Reports',
      ),
    ];

    Future<void> pumpNav(WidgetTester tester, {required int selected}) async {
      await tester.pumpWidget(
        navHost(
          WaltNavBar(
            destinations: destinations,
            selectedIndex: selected,
            onDestinationSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('icon pill is 64x32 and centred in the row', (tester) async {
      await pumpNav(tester, selected: 0);

      final pill = findPills().first;
      final size = tester.getSize(pill);
      expect(size.width, 64);
      expect(size.height, 32);

      final item = tester.getRect(
        find.ancestor(of: pill, matching: find.byType(InkWell)).first,
      );
      final pillRect = tester.getRect(pill);
      expect((item.center.dx - pillRect.center.dx).abs(), lessThan(1));
    });

    testWidgets('selection pill uses the primary container', (tester) async {
      await pumpNav(tester, selected: 0);

      final selectedPill = findSelectionPill();
      final decoration =
          (tester.widget<Container>(selectedPill).decoration!
                  as ShapeDecoration)
              .color!;
      final scheme = Theme.of(tester.element(selectedPill)).colorScheme;

      expect(decoration.toARGB32(), scheme.primaryContainer.toARGB32());
    });
  });
}
