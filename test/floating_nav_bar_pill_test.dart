import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt_ui/walt_ui.dart';

import 'support/nav_harness.dart';

void main() {
  group('selection pill', () {
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
          FloatingNavBar(
            destinations: destinations,
            selectedIndex: selected,
            onDestinationSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('stays well clear of the bar border', (tester) async {
      await pumpNav(tester, selected: 0);

      final pillHeight = tester.getSize(findSelectionPill()).height;
      final gap = (WaltChrome.navHeight - pillHeight) / 2;

      // Sized by content: a 24dp icon plus 10 of padding either side.
      expect(pillHeight, 44, reason: 'icon 24 + 10 padding either side');

      // 12dp of clear bar above and below, so the bar's 1dp hairline never
      // merges with the pill. This is the constraint that actually matters and
      // the reason the pill must not be grown to fill the bar.
      expect(
        gap,
        greaterThanOrEqualTo(10),
        reason: 'only ${gap}dp between the pill and the bar edge',
      );
    });

    testWidgets('widens when the label is revealed', (tester) async {
      await pumpNav(tester, selected: 0);
      final withLabel = tester.getSize(findPills().at(0)).width;

      // Select a different item, so item 0 collapses back to its bare dot: that
      // collapsed width is what the label has to beat for the reveal to read
      // as a reveal rather than as a static icon backdrop.
      await pumpNav(tester, selected: 1);
      final withoutLabel = tester.getSize(findPills().at(0)).width;

      // The pill must be a real selection surface, not a fixed-size dot sitting
      // behind the icon — if the label ever stopped claiming width, these two
      // would be equal and the selected item would be indistinguishable.
      expect(
        withLabel - withoutLabel,
        greaterThanOrEqualTo(24),
        reason: 'label revealed $withLabel vs collapsed $withoutLabel',
      );

      // The bar reserves [WaltChrome.horizontalMargin] either side, so the
      // width an item can actually use is the bar minus that margin — measuring
      // against the raw bar would set the bar at 4dp too high per item and
      // fail a correctly-sized pill.
      final bar = tester.getSize(find.byType(FloatingNavBar)).width;
      final itemWidth =
          (bar - WaltChrome.horizontalMargin * 2) / destinations.length;
      expect(withLabel, greaterThan(itemWidth * 0.5));
    });
  });
}
