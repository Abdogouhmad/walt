import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:walt/core/theme/app_theme.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/features/budgets/budgets_screen.dart';
import 'package:walt/features/home/home_screen.dart';
import 'package:walt/features/reports/reports_screen.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/settings_screen.dart';
import 'package:walt/features/transactions/transaction_list_screen.dart';
import 'package:walt/providers/settings_provider.dart';

class _StubSettings extends SettingsNotifier {
  @override
  SettingsState build() =>
      SettingsState(isLoaded: true, isOnboardingCompleted: true);
}

class FakePathProvider extends PathProviderPlatform {
  static final String _docs = Directory.systemTemp
      .createTempSync('walt_test_docs')
      .path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _docs;

  @override
  Future<String?> getTemporaryPath() async => _docs;
}

Widget _host(Widget child) => ProviderScope(
  overrides: [settingsProvider.overrideWith(_StubSettings.new)],
  child: MaterialApp(theme: AppTheme.lightTheme(), home: child),
);

/// Every top-level screen's app bar, paired with a finder for its title so the
/// measurement can be attributed to the right bar.
const _screens = <String, (String, Widget)>{
  'Home': ('WALT', HomeScreen()),
  'Activity': ('Activity', TransactionListScreen()),
  'Budgets': ('Budgets', BudgetsScreen()),
  'Reports': ('Reports', ReportsScreen()),
  'Settings': ('Settings', SettingsScreen()),
};

void main() {
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          (call) async => switch (call.method) {
            'getAll' => <String, Object?>{
              'appName': 'Walt',
              'packageName': 'dev.walt.app',
              'version': '0.7.0',
              'buildNumber': '70',
            },
            _ => null,
          },
        );
    await Appinfo.init();
    PathProviderPlatform.instance = FakePathProvider();
    await HiveService.init();
    await Hive.deleteBoxFromDisk('settings_json_box');
  });

  group('top padding', () {
    for (final entry in _screens.entries) {
      testWidgets('${entry.key} keeps the app bar compact', (tester) async {
        // A status bar is unavoidable and not what "padding top" means here, so
        // it is zeroed to measure only the space the app chooses to add.
        tester.view.padding = FakeViewPadding.zero;
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_host(entry.value.$2));
        // Not `pumpAndSettle`: these screens run looping progress animations
        // that never settle. The app bar is laid out on the first frame, so a
        // couple of bounded pumps is enough and terminates.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final bar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
        final expanded = bar.expandedHeight ?? kToolbarHeight;

        // `SliverAppBar.large` is 152 and `.medium` is 112. Both leave the title
        // floating well below the top edge. A plain SliverAppBar is just the
        // 56 toolbar, which is as tight as this can go without hiding the title.
        expect(
          expanded,
          lessThanOrEqualTo(kToolbarHeight + 0.01),
          reason:
              '${entry.key} reserves ${expanded.toStringAsFixed(0)}px above the title; a compact '
              'bar is ${kToolbarHeight}px',
        );

        // The title itself must sit at the top, not below a large-title gap.
        final title = tester.getRect(find.text(entry.value.$1).first);
        expect(
          title.top,
          lessThanOrEqualTo(kToolbarHeight + 0.01),
          reason: '${entry.key} pushes its title down to ${title.top}px',
        );
      });
    }
  });
}
