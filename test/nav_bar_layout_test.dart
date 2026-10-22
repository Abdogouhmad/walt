import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt_ui/walt_ui.dart';

import 'support/nav_harness.dart';

void main() {
  group('narrow windows', () {
    // A desktop window can be resized far narrower than a phone, and the
    // selected label remains visible underneath the icon.
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
              WaltNavBar(
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
                      child: WaltNavBar(
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull, reason: 'moving to $index');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'settling on $index');
    }
  });
}
