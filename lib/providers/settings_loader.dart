import 'package:flutter/foundation.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt/providers/settings_state.dart';

/// Reads every stored setting into a [SettingsState].
///
/// A store that cannot be read is a store that has never been written, as far
/// as the settings are concerned: refusing to start would be worse than
/// starting with the defaults. `isLoaded` is `true` either way, because a
/// failed read must not strand the app on a splash screen.
SettingsState loadSettingsState(HiveService hive) {
  try {
    final currency = hive.getCurrency();
    final userName = hive.getUserName();
    final profilePicPath = hive.getProfilePicPath();
    final onboardingCompleted = hive.isOnboardingCompleted();

    final isPasswordEnabled = hive.getFlag(
      'isPasswordEnabled',
      defaultValue: false,
    );
    final isFingerprintEnabled = hive.getFlag(
      'isFingerprintEnabled',
      defaultValue: false,
    );
    final budgetAlertsEnabled = hive.getFlag(
      'budgetAlertsEnabled',
      defaultValue: true,
    );
    final updateNotificationsEnabled = hive.getFlag(
      'updateNotificationsEnabled',
      defaultValue: true,
    );
    final reduceTransparency = hive.getFlag(
      'reduceTransparency',
      defaultValue: false,
    );

    return SettingsState(
      currency: currency,
      userName: userName,
      profilePicPath: profilePicPath,
      isOnboardingCompleted: onboardingCompleted,
      isLoaded: true,
      isPasswordEnabled: isPasswordEnabled,
      isFingerprintEnabled: isFingerprintEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled,
      updateNotificationsEnabled: updateNotificationsEnabled,
      reduceTransparency: reduceTransparency,
    );
  } catch (e) {
    debugPrint('Could not read settings, using defaults: $e');
    return SettingsState(isLoaded: true);
  }
}
