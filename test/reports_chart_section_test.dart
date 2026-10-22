import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt/features/reports/widgets/report_chart_section.dart';

import 'support/fake_path_provider.dart';
import 'support/reports_harness.dart';

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

  group('Report chart section', () {
    testWidgets('toggles between trend and categories', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        // In a scroll view, matching the real screen where this section is one
        // sliver among many. A bare Scaffold bounds it to the viewport, and the
        // chart — which is meant to size to its content — then overflows by
        // 56px. That is an artefact of the test host, not a layout bug: the
        // same tree inside a scroll view lays out clean.
        reportsHost(
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
