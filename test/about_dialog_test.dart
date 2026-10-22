import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/about_info_dialog.dart';
import 'package:walt_ui/walt_ui.dart';

/// The dialog frosts through the shared [BlurSurface], which consults the
/// reduce-transparency setting. Override it so the test never touches Hive.
Widget _host({required bool reduceTransparency}) => ProviderScope(
  overrides: [reduceTransparencyProvider.overrideWithValue(reduceTransparency)],
  child: MaterialApp(
    theme: AppTheme.lightTheme(),
    home: const Scaffold(body: AboutInfoDialog()),
  ),
);

void main() {
  // The dialog title renders the app name and version, so Appinfo has to be
  // primed before the first build. It reads through package_info_plus, which
  // has no test implementation, so the channel is answered directly.
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          (call) async => switch (call.method) {
            'getAll' => <String, Object?>{
              'appName': 'Walt',
              'packageName': 'dev.walt.app',
              'version': '1.0.5',
              'buildNumber': '10005',
            },
            _ => null,
          },
        );
    await Appinfo.init();
  });

  testWidgets('frosts its backdrop like the nav', (tester) async {
    await tester.pumpWidget(_host(reduceTransparency: false));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('reduce transparency drops the blur', (tester) async {
    await tester.pumpWidget(_host(reduceTransparency: true));
    await tester.pumpAndSettle();

    // Accessibility overrides win over the look: no live blur.
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
