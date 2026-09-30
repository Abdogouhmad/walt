import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:walt/core/theme/app_theme.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/reports/report_aggregation.dart';
import 'package:walt/features/reports/reports_screen.dart';
import 'package:walt/features/reports/widgets/report_chart_section.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';

class _StubSettings extends SettingsNotifier {
  @override
  SettingsState build() =>
      SettingsState(isLoaded: true, isOnboardingCompleted: true);
}

class FakePathProvider extends PathProviderPlatform {
  static final String _docs = Directory.systemTemp
      .createTempSync('walt_docs')
      .path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _docs;

  @override
  Future<String?> getTemporaryPath() async => _docs;
}

/// A fully populated report.
///
/// This is the whole point of this file. The first version of this test used the
/// real provider, which resolves to an *empty* aggregation, so the charts and
/// the loaded branch of the summary tiles were never built — and the test passed
/// happily while the screen threw every frame for anyone with real data.
class _StubReport extends ReportNotifier {
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

Widget _host(Widget child) => ProviderScope(
  overrides: [
    settingsProvider.overrideWith(_StubSettings.new),
    reportPeriodProvider.overrideWith((ref) => ReportPeriod.month),
    reportProvider.overrideWith(_StubReport.new),
  ],
  child: MaterialApp(theme: AppTheme.lightTheme(), home: child),
);

void main() {
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          (c) async => switch (c.method) {
            'getAll' => <String, Object?>{
              'appName': 'Walt',
              'packageName': 'dev.walt.app',
              'version': '0.7.0',
              'buildNumber': '70',
            },
            _ => null,
          },
        );
    PathProviderPlatform.instance = FakePathProvider();
    await HiveService.init();
    await Hive.deleteBoxFromDisk('settings_json_box');
  });

  group('Reports screen with data', () {
    testWidgets('lays out every frame without throwing', (tester) async {
      // Semantics must be on: the `!semantics.parentDataDirty` assertion only
      // runs inside `updateSemantics`, so a test without this cannot see it.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const ReportsScreen()));

      // Pumped frame by frame rather than with `pumpAndSettle`, and checking
      // after every one: a single throwing frame is enough to catch, and a
      // settled pump would let a repeat throw scroll past unnoticed.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 120));
        expect(tester.takeException(), isNull, reason: 'frame $i threw');
      }
      handle.dispose();
    });

    testWidgets('shows the loaded summary, not the empty state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const ReportsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Total spent'), findsOneWidget);
      expect(find.text('Average / day'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('every render object that forms a node has parent data', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const ReportsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // `RenderObject.parentDataDirty` is defined as `parentData == null`
      // (object.dart:5609), which is precisely what the failing assertion
      // checks. Reading it directly localises the failure if it ever returns.
      final offenders = <String>[];
      void walk(RenderObject node) {
        if (node.attached &&
            node.parent != null &&
            node.parentData == null &&
            node.toStringShallow().contains('Render')) {
          offenders.add('${node.toStringShallow()} in ${node.parent}');
        }
        node.visitChildren(walk);
      }

      walk(tester.renderObject(find.byType(ReportsScreen)));
      expect(offenders, isEmpty, reason: offenders.join('\n'));
      handle.dispose();
    });

    testWidgets('the chart section toggles between trend and categories', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        // In a scroll view, matching the real screen where this section is one
        // sliver among many. A bare Scaffold bounds it to the viewport, and the
        // chart — which is meant to size to its content — then overflows by
        // 56px. That is an artefact of the test host, not a layout bug: the
        // same tree inside a scroll view lays out clean.
        _host(
          const Scaffold(
            body: SingleChildScrollView(child: ReportChartSection()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Categories'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });
}
