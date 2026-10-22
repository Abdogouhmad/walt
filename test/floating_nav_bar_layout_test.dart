import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt_ui/walt_ui.dart';

import 'support/nav_harness.dart';

void main() {
  group('narrow windows', () {
    // A desktop window can be resized far narrower than a phone, and the
    // selected label is the one item that lays out at full width.
    for (final width in [320.0, 280.0, 240.0, 200.0]) {
      for (final selected in [0, 3]) {
        testWidgets('no overflow at ${width.round()}px wide, index $selected', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width * 3, 800 * 3);
          tester.view.devicePixelRatio = 3.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            navHost(
              FloatingNavBar(
                destinations: shellDestinations,
                selectedIndex: selected,
                onDestinationSelected: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('label collapse', () {
    /// The selected label is revealed by collapsing an unselected label's
    /// `widthFactor` from 1 to 0. That collapse is spring-driven elsewhere in
    /// the app, and a spring aimed at 0 overshoots through it into a negative
    /// factor, which `Align` refuses — an assertion thrown on every selection
    /// change. Rebuilding the bar across every selection pins the curve to a
    /// one that cannot leave the valid range.
    for (final selected in [0, 1, 2, 3]) {
      testWidgets('selecting index $selected throws nothing', (tester) async {
        await tester.pumpWidget(
          navHost(
            FloatingNavBar(
              destinations: shellDestinations,
              selectedIndex: selected,
              onDestinationSelected: (_) {},
            ),
          ),
        );
        // Mid-flight is where the overshoot is largest, so sample the animation
        // rather than only its settled state.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        await tester.pump(const Duration(milliseconds: 180));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('walking the selection forward and back throws nothing', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter setState;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [reduceTransparencyProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, set) {
                setState = set;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: FloatingNavBar(
                        destinations: shellDestinations,
                        selectedIndex: selected,
                        onDestinationSelected: (i) =>
                            setState(() => selected = i),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final index in [1, 2, 3, 2, 1, 0, 3, 0]) {
      await tester.tap(find.bySemanticsLabel(shellDestinations[index].label));
      // Stop mid-spring, where the overshoot peaks.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: 'moving to $index');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'settling on $index');
    }
  });
}
