import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt/providers/auth_provider.dart';
import 'package:walt/providers/currency_migration.dart';
import 'package:walt/providers/settings_loader.dart';
import 'package:walt/providers/settings_state.dart';

export 'settings_state.dart';

class SettingsNotifier extends Notifier<SettingsState> {
  final _hive = HiveService.instance;

  @override
  SettingsState build() {
    return loadSettingsState(_hive);
  }

  Future<void> setCurrency(String newCurrency) async {
    final oldCurrency = state.currency;
    if (oldCurrency == newCurrency) return;

    final rate = await conversionRate(oldCurrency, newCurrency);

    await _hive.setCurrency(newCurrency);
    if (ref.mounted) {
      state = state.copyWith(currency: newCurrency);
    }

    await migrateAmountsToCurrency(ref: ref, rate: rate, currency: newCurrency);
  }

  Future<void> setUserProfile({
    required String name,
    String? profilePic,
  }) async {
    await _hive.setUserName(name);
    if (profilePic != null) {
      await _hive.setProfilePicPath(profilePic);
    }
    if (ref.mounted) {
      state = state.copyWith(userName: name, profilePicPath: profilePic);
    }
  }

  Future<void> updateProfilePic(String path) async {
    await _hive.setProfilePicPath(path);
    if (ref.mounted) {
      state = state.copyWith(profilePicPath: path);
    }
  }

  Future<bool> toggleFingerprint() async {
    final newValue = !state.isFingerprintEnabled;

    if (newValue) {
      final success = await ref
          .read(authProvider.notifier)
          .authenticate(force: true);
      if (!success) return false;
    }

    await _hive.saveSetting('isFingerprintEnabled', newValue);
    if (ref.mounted) {
      state = state.copyWith(isFingerprintEnabled: newValue);
    }
    return true;
  }

  Future<void> setBudgetAlertsEnabled(bool value) async {
    await _hive.saveSetting('budgetAlertsEnabled', value);
    if (ref.mounted) state = state.copyWith(budgetAlertsEnabled: value);
  }

  Future<void> setReduceTransparency(bool value) async {
    await _hive.saveSetting('reduceTransparency', value);
    if (ref.mounted) state = state.copyWith(reduceTransparency: value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    await _hive.saveSetting('hapticsEnabled', value);
    if (ref.mounted) state = state.copyWith(hapticsEnabled: value);
  }

  Future<void> setAnimationsEnabled(bool value) async {
    await _hive.saveSetting('animationsEnabled', value);
    if (ref.mounted) state = state.copyWith(animationsEnabled: value);
  }

  Future<void> completeOnboarding() async {
    await _hive.setOnboardingCompleted(true);
    if (ref.mounted) {
      state = state.copyWith(isOnboardingCompleted: true);
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
