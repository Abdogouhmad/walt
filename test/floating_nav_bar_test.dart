import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt/core/widgets/blur_surface.dart';
import 'package:walt/core/widgets/fab_menu.dart';
import 'package:walt/core/widgets/floating_nav_bar.dart';
import 'package:walt/core/widgets/walt_chrome.dart';

/// The nav blurs through [BlurSurface], which consults the reduce-transparency
/// setting. Override it so the test never touches Hive.
Widget _host(Widget child) => ProviderScope(
  overrides: [reduceTransparencyProvider.overrideWithValue(false)],
  child: MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: Stack(children: [Positioned.fill(child: child)]),
    ),
  ),
);

void main() {
  testWidgets('floating nav exposes selection semantics and reports taps', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var tapped = -1;

    await tester.pumpWidget(
      _host(
        FloatingNavBar(
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
    // label inside the pill.
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Activity'), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('Home')).label, 'Home');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Activity')).label,
      'Activity',
    );
    expect(find.text('Home'), findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(
                  of: find.text('Activity'),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity,
      0,
    );

    await tester.tap(find.bySemanticsLabel('Activity'));
    await tester.pump();
    expect(tapped, 1);

    handle.dispose();
  });

  testWidgets('single-action FAB fires immediately', (tester) async {
    var fired = false;

    await tester.pumpWidget(
      _host(
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
      _host(
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

  group('narrow windows', () {
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
        icon: Icons.pie_chart_outline,
        selectedIcon: Icons.pie_chart,
        label: 'Budget',
      ),
      WaltDestination(
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        label: 'Reports',
      ),
    ];

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
            _host(
              FloatingNavBar(
                destinations: destinations,
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
        icon: Icons.pie_chart_outline,
        selectedIcon: Icons.pie_chart,
        label: 'Budget',
      ),
      WaltDestination(
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        label: 'Reports',
      ),
    ];

    /// The selected label is revealed by collapsing an unselected label's
    /// `widthFactor` from 1 to 0. That collapse is spring-driven elsewhere in
    /// the app, and a spring aimed at 0 overshoots through it into a negative
    /// factor, which `Align` refuses — an assertion thrown on every selection
    /// change. Rebuilding the bar across every selection pins the curve to a
    /// one that cannot leave the valid range.
    for (final selected in [0, 1, 2, 3]) {
      testWidgets('selecting index $selected throws nothing', (tester) async {
        await tester.pumpWidget(
          _host(
            FloatingNavBar(
              destinations: destinations,
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
                          destinations: destinations,
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
        await tester.tap(find.bySemanticsLabel(destinations[index].label));
        // Stop mid-spring, where the overshoot peaks.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: 'moving to $index');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'settling on $index');
      }
    });
  });

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
        _host(
          FloatingNavBar(
            destinations: destinations,
            selectedIndex: selected,
            onDestinationSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// The selection is the only [Container] drawing an opaque shape; the
    /// unselected items and the surrounding chrome all draw transparent.
    Finder findPill() => find
        .byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is ShapeDecoration &&
              ((w.decoration! as ShapeDecoration).color?.a ?? 0) > 0,
        )
        .first;

    /// Every item draws a pill [Container] with a [StadiumBorder], in
    /// destination order — including the transparent unselected ones, so a
    /// collapsed width is readable without comparing two separate pumps.
    Finder pills() => find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is ShapeDecoration &&
            (w.decoration! as ShapeDecoration).shape is StadiumBorder,
      ),
    );

    testWidgets('stays well clear of the bar border', (tester) async {
      await pumpNav(tester, selected: 0);

      final pillHeight = tester.getSize(findPill()).height;
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
      final withLabel = tester.getSize(pills().at(0)).width;

      // Select a different item, so item 0 collapses back to its bare dot: that
      // collapsed width is what the label has to beat for the reveal to read
      // as a reveal rather than as a static icon backdrop.
      await pumpNav(tester, selected: 1);
      final withoutLabel = tester.getSize(pills().at(0)).width;

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
        ProviderScope(
          overrides: [
            reduceTransparencyProvider.overrideWithValue(reduceTransparency),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: FloatingNavBar(
                      destinations: destinations,
                      selectedIndex: 0,
                      onDestinationSelected: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
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

      // The frosted look is a ratio of tint to show-through. At the shared
      // light-mode fill of 0.82 only a fifth of the blur survived and the bar
      // read as a flat slab, so this pins the thinner tint that fixes it.
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
