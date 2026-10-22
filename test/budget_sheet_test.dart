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

  testWidgets('the form key is attached to a real Form', (tester) async {
    final budgets = StubBudget();
    await tester.pumpWidget(budgetSheetHost(budgets));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The root cause of the crash: `_formKey` was never given to a `Form`, so
    // `_formKey.currentState` was permanently null and every save threw
    // "Null check operator used on a null value".
    expect(find.byType(Form), findsOneWidget);

    final key = tester.widget<Form>(find.byType(Form)).key;
    expect(key, isA<GlobalKey<FormState>>());
    expect((key! as GlobalKey<FormState>).currentState, isNotNull);
  });

  testWidgets('tapping Create with a category does not throw', (tester) async {
    final budgets = StubBudget();
    await tester.pumpWidget(budgetSheetHost(budgets));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '250');
    await tester.pump();
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Budget'));
    await tester.pumpAndSettle();

    // The regression: this used to throw before reaching any of this.
    expect(tester.takeException(), isNull);
    expect(budgets.added, hasLength(1));
    expect(budgets.added.single.amount, 250);
    expect(budgets.added.single.categoryId, 1);
  });
}
