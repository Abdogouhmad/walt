import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt/core/theme/app_theme.dart';
import 'package:walt/data/reports/report_aggregation.dart';
import 'package:walt/features/reports/widgets/category_donut.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';

class _StubSettings extends SettingsNotifier {
  @override
  SettingsState build() =>
      SettingsState(isLoaded: true, isOnboardingCompleted: true);
}

class _StubReport extends ReportNotifier {
  @override
  Future<ReportAggregation> build() async => ReportAggregation(
    range: ReportRange(
      period: ReportPeriod.month,
      anchor: DateTime(2026, 9, 30),
      start: DateTime(2026, 9, 1),
      endExclusive: DateTime(2026, 10, 1),
    ),
    buckets: const [],
    categories: const [
      CategorySlice(
        categoryId: 1,
        name: 'Food',
        color: '0xFFB3261E',
        icon: '🍔',
        amount: 820.5,
        percent: 46.2,
      ),
      CategorySlice(
        categoryId: 2,
        name: 'Transport',
        color: '0xFF386A20',
        icon: '🚕',
        amount: 512.25,
        percent: 28.8,
      ),
      CategorySlice(
        categoryId: 3,
        name: 'Shopping',
        color: '0xFF1D4ED8',
        icon: '🛍️',
        amount: 441,
        percent: 24.8,
      ),
    ],
    totalExpense: 1773.75,
    totalIncome: 2000,
    averageDailyExpense: 57.86,
    biggestCategory: null,
  );
}

Widget _host(Widget child) => ProviderScope(
  overrides: [
    settingsProvider.overrideWith(_StubSettings.new),
    reportProvider.overrideWith(_StubReport.new),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme(),
    home: Scaffold(body: child),
  ),
);

void main() {
  Future<void> pumpDonut(WidgetTester tester) async {
    await tester.pumpWidget(_host(const CategoryDonut()));
    await tester.pumpAndSettle();
  }

  group('CategoryDonut', () {
    testWidgets('draws no text over the category colours', (tester) async {
      await pumpDonut(tester);

      final data = tester.widget<PieChart>(find.byType(PieChart)).data;

      // `fl_chart` would paint a title across a slice for any non-empty title.
      for (final section in data.sections) {
        expect(
          section.title,
          isEmpty,
          reason: 'a slice must not carry text over its colour',
        );
      }
    });

    testWidgets('disables touch so a tap can never paint over a slice', (
      tester,
    ) async {
      await pumpDonut(tester);

      final data = tester.widget<PieChart>(find.byType(PieChart)).data;

      // Left at its default, fl_chart enables its touch system, which
      // highlights the touched section by drawing over the colour that
      // identifies it. Verified against the default: it reports true.
      expect(data.pieTouchData.enabled, isFalse);
    });

    testWidgets('still names the period total in the hole', (tester) async {
      // The hole is unfilled, so this is not text-on-colour and it carries
      // information the colours cannot.
      await pumpDonut(tester);

      expect(find.text('Total'), findsOneWidget);
      expect(find.textContaining('1774'), findsOneWidget);
    });
  });
}
