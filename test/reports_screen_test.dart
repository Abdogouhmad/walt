import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt/features/reports/reports_screen.dart';

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

  group('Reports screen with data', () {
    testWidgets('lays out every frame without throwing', (tester) async {
      // Semantics must be on: the `!semantics.parentDataDirty` assertion only
      // runs inside `updateSemantics`, so a test without this cannot see it.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(reportsHost(const ReportsScreen()));

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
      await tester.pumpWidget(reportsHost(const ReportsScreen()));
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
      await tester.pumpWidget(reportsHost(const ReportsScreen()));
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
  });
}
