import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/reports/report_aggregation.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Settings that are already loaded, so the screen never waits on Hive.
class StubReportSettings extends SettingsNotifier {
  @override
  SettingsState build() =>
      SettingsState(isLoaded: true, isOnboardingCompleted: true);
}

/// A fully populated report.
///
/// This is the whole point of this harness. The first version of the reports
/// test used the real provider, which resolves to an *empty* aggregation, so the
/// charts and the loaded branch of the summary tiles were never built — and the
/// test passed happily while the screen threw every frame for anyone with real
/// data.
class StubReport extends ReportNotifier {
  @override
  Future<ReportAggregation> build() async => ReportAggregation(
    range: ReportRange(
      period: ReportPeriod.month,
      anchor: DateTime(2026, 9, 30),
      start: DateTime(2026, 9, 1),
      endExclusive: DateTime(2026, 10, 1),
    ),
    buckets: List.generate(30, (i) {
      return PeriodBucket(
        start: DateTime(2026, 9, i + 1),
        label: '${i + 1}',
        expense: i % 4 == 0 ? 0 : 120 + i * 7.5,
        income: i == 3 ? 2000 : 0,
      );
    }),
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

/// Hosts [child] with a populated report and a settled settings provider.
Widget reportsHost(Widget child) => ProviderScope(
  overrides: [
    settingsProvider.overrideWith(StubReportSettings.new),
    reportPeriodProvider.overrideWith((ref) => ReportPeriod.month),
    reportProvider.overrideWith(StubReport.new),
  ],
  child: MaterialApp(theme: AppTheme.lightTheme(), home: child),
);
