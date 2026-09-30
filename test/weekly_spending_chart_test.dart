import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt/core/theme/app_theme.dart';
import 'package:walt/features/home/widgets/weekly_spending_chart.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';

/// A day column reserves room for the selected day's amount label, the pill,
/// the gap, and the letter. Getting that arithmetic wrong does not crash or
/// fail an analyzer pass — it silently overflows the strip, so it is measured
/// here at text scales the user can actually reach.
class _StubSettings extends SettingsNotifier {
  @override
  SettingsState build() =>
      SettingsState(isLoaded: true, isOnboardingCompleted: true);
}

/// Pumps the recap inside a card wide enough to look like a phone, at [scale].
Future<void> _pumpRecap(WidgetTester tester, double scale) async {
  tester.view.physicalSize = const Size(400 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(_StubSettings.new),
        // A week where the last day is the big one, so the selected column
        // carries a three-figure amount and the others sit at the floor.
        weekSpendingProvider.overrideWithValue(
          List.generate(7, (i) => i == 6 ? 1730.0 : 12.0),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: const Scaffold(
            body: SingleChildScrollView(child: WeeklySpendingChart()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  /// Height of the selected day's pill. Mirrors `_selectedHeight`.
  const double selectedPillHeight = 76;

  /// Heights of the seven pills in the strip.
  List<double> pillHeights(WidgetTester tester) {
    final strip = find.byKey(const ValueKey('week-recap-strip'));
    final pills = find.descendant(
      of: strip,
      matching: find.byType(AnimatedContainer),
    );
    return pills
        .evaluate()
        .map((e) => tester.getSize(find.byWidget(e.widget)).height)
        .toList();
  }

  group('WeeklySpendingChart', () {
    for (final scale in <double>[1.0, 1.5, 2.0]) {
      testWidgets('lays out without overflow at ${scale}x text scale', (
        tester,
      ) async {
        await _pumpRecap(tester, scale);
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in <double>[1.0, 1.5, 2.0]) {
      testWidgets('the selected pill keeps its full height at ${scale}x', (
        tester,
      ) async {
        await _pumpRecap(tester, scale);
        expect(tester.takeException(), isNull);

        // A `Flexible` pill would happily shrink rather than overflow, so
        // "no overflow" alone hides a strip that has been squeezed flat. The
        // selected day has to actually reach its full height at every scale.
        expect(
          pillHeights(tester).reduce((a, b) => a > b ? a : b),
          selectedPillHeight,
        );
      });
    }

    testWidgets('the selected day shows its amount', (tester) async {
      await _pumpRecap(tester, 1.0);
      // Amounts are whole units, grouped, with no currency code in the strip.
      expect(find.text('1,730'), findsOneWidget);
      expect(find.text('12'), findsWidgets);
    });

    testWidgets('selecting another day does not resize the strip', (
      tester,
    ) async {
      await _pumpRecap(tester, 1.0);
      final strip = find.byKey(const ValueKey('week-recap-strip'));
      final before = tester.getSize(strip);

      // Walk the selection across the week so the pill animates between a
      // finite dot width and the full cell width several times.
      for (final letter in ['M', 'W', 'F', 'S', 'S']) {
        await tester.tap(find.text(letter).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'tapping $letter');
        expect(
          tester.getSize(strip),
          before,
          reason: 'strip resized on $letter',
        );
      }
    });

    testWidgets(
      'the card does not resize when the hint is replaced by a date',
      (tester) async {
        await _pumpRecap(tester, 1.0);
        final before = tester.getSize(find.byType(WeeklySpendingChart));

        await tester.tap(find.text('M').first);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(WeeklySpendingChart)), before);
      },
    );
  });
}
