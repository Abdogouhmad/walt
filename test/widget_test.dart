import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt/shared/splash_screen.dart';

void main() {
  testWidgets('Splash screen renders a loading indicator', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
