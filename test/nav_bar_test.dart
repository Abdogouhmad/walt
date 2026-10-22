import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt_ui/walt_ui.dart';

import 'support/nav_harness.dart';

void main() {
  testWidgets('docked nav exposes selection semantics and reports taps', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var tapped = -1;

    await tester.pumpWidget(
      navHost(
        WaltNavBar(
          destinations: const [
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
          ],
          selectedIndex: 0,
          onDestinationSelected: (i) => tapped = i,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Every destination is announced, and only the selected one reveals its
    // pill.
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Activity'), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('Home')).label, 'Home');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Activity')).label,
      'Activity',
    );

    await tester.tap(find.bySemanticsLabel('Activity'));
    await tester.pump();
    expect(tapped, 1);

    handle.dispose();
  });

  testWidgets('single-action FAB fires immediately', (tester) async {
    var fired = false;

    await tester.pumpWidget(
      navHost(
        ExpressiveFabMenu(
          actions: [
            FabAction(
              icon: Icons.arrow_upward_rounded,
              label: 'Add expense',
              onPressed: () => fired = true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Add expense'));
    await tester.pump();
    expect(fired, isTrue);
  });

  testWidgets('multi-action FAB expands then fires the chosen action', (
    tester,
  ) async {
    final fired = <String>[];

    await tester.pumpWidget(
      navHost(
        ExpressiveFabMenu(
          actions: [
            FabAction(
              icon: Icons.arrow_upward_rounded,
              label: 'Add expense',
              onPressed: () => fired.add('expense'),
            ),
            FabAction(
              icon: Icons.arrow_downward_rounded,
              label: 'Add income',
              onPressed: () => fired.add('income'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Add expense'), findsOneWidget);
    expect(find.text('Add income'), findsOneWidget);

    await tester.tap(find.text('Add income'));
    await tester.pumpAndSettle();

    expect(fired, ['income']);
  });
}
