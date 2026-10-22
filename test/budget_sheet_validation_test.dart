import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/data/local/hive_service.dart';

import 'support/budget_sheet_harness.dart';
import 'support/fake_path_provider.dart';

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

  testWidgets('Create with no category selected explains why', (tester) async {
    final budgets = StubBudget();
    await tester.pumpWidget(budgetSheetHost(budgets));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '250');
    await tester.ensureVisible(find.text('Create Budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Budget'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Used to return in silence, so the button looked broken.
    expect(find.text('Please select a category'), findsOneWidget);
    expect(budgets.added, isEmpty);
  });

  testWidgets('an empty amount is rejected', (tester) async {
    final budgets = StubBudget();
    await tester.pumpWidget(budgetSheetHost(budgets));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create Budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Budget'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(budgets.added, isEmpty);
    // Now that the `Form` is actually attached, the field's own validator runs
    // and reports inline rather than the sheet's snackbar. This is the
    // behaviour the missing `Form` was silently preventing.
    expect(find.text('Field required'), findsOneWidget);
  });
}
