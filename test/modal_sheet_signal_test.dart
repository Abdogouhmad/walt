import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt_ui/walt_ui.dart';

void main() {
  testWidgets('showWaltModal raises the sheet signal while it is open', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => unawaited(
                  showWaltModal<void>(
                    context,
                    content: const Text('sheet content'),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(container.read(modalSheetOpenProvider), isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('sheet content'), findsOneWidget);
    expect(
      container.read(modalSheetOpenProvider),
      isTrue,
      reason: 'the shell has to know a sheet is open to step its chrome aside',
    );

    Navigator.of(tester.element(find.text('sheet content'))).pop();
    await tester.pumpAndSettle();

    expect(
      container.read(modalSheetOpenProvider),
      isFalse,
      reason: 'the chrome must come back once the sheet is gone',
    );
  });

  testWidgets(
    'nested sheets keep the signal raised until the last one closes',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => unawaited(
                    showWaltModal<void>(
                      context,
                      content: Builder(
                        builder: (inner) => ElevatedButton(
                          onPressed: () => unawaited(
                            showWaltModal<void>(
                              inner,
                              content: const Text('inner sheet'),
                            ),
                          ),
                          child: const Text('open inner'),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(container.read(modalSheetOpenProvider), isTrue);

      await tester.tap(find.text('open inner'));
      await tester.pumpAndSettle();
      expect(container.read(modalSheetOpenProvider), isTrue);

      Navigator.of(tester.element(find.text('inner sheet'))).pop();
      await tester.pumpAndSettle();

      expect(
        container.read(modalSheetOpenProvider),
        isTrue,
        reason: 'the outer sheet is still open',
      );

      Navigator.of(tester.element(find.text('open inner'))).pop();
      await tester.pumpAndSettle();

      expect(container.read(modalSheetOpenProvider), isFalse);
    },
  );
}
