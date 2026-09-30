import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/core/theme/app_theme.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/features/budgets/widgets/budget_sheet.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/data/models/walt_category.dart';

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

/// Records what the sheet tried to save.
class _StubBudget extends BudgetNotifier {
  final List<WaltBudget> added = [];

  @override
  Future<void> addBudget(WaltBudget budget) async => added.add(budget);
}

class _StubCategories extends CategoryNotifier {
  @override
  AsyncValue<List<WaltCategory>> build() => AsyncData(const [
    WaltCategory(
      id: 1,
      name: 'Food',
      icon: 'food',
      color: '#FFB3261E',
      type: 'expense',
    ),
    WaltCategory(
      id: 2,
      name: 'Transport',
      icon: 'car',
      color: '#FF386A20',
      type: 'expense',
    ),
  ]);
}

Widget _host(_StubBudget budgets) => ProviderScope(
  overrides: [
    settingsProvider.overrideWith(_StubSettings.new),
    budgetProvider.overrideWith(() => budgets),
    categoryProvider.overrideWith(_StubCategories.new),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme(),
    home: Scaffold(body: Builder(builder: (c) => _open(c))),
  ),
);

Widget _open(BuildContext context) => TextButton(
  onPressed: () => showBudgetSheet(context),
  child: const Text('open'),
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

  testWidgets('the form key is attached to a real Form', (tester) async {
    final budgets = _StubBudget();
    await tester.pumpWidget(_host(budgets));
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
    final budgets = _StubBudget();
    await tester.pumpWidget(_host(budgets));
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

  testWidgets('Create with no category selected explains why', (tester) async {
    final budgets = _StubBudget();
    await tester.pumpWidget(_host(budgets));
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
    final budgets = _StubBudget();
    await tester.pumpWidget(_host(budgets));
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
