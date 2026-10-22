import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/settings/settings_screen.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Settings that are already loaded, so the screen never waits on Hive.
class StubScreenSettings extends SettingsNotifier {
  @override
  SettingsState build() =>
      SettingsState(isLoaded: true, isOnboardingCompleted: true);
}

/// Hosts the settings screen.
Widget settingsHost() => ProviderScope(
  overrides: [settingsProvider.overrideWith(StubScreenSettings.new)],
  child: MaterialApp(
    theme: AppTheme.lightTheme(),
    home: const SettingsScreen(),
  ),
);
