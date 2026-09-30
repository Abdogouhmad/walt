import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:currency_converter/currency_converter.dart';
import 'package:currency_converter/currency.dart';
import 'package:walt/data/local/account_dao.dart';
import 'package:walt/data/local/budget_dao.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:walt/providers/account_provider.dart';
import 'package:walt/providers/auth_provider.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/transaction_provider.dart';

/// Everything that is *not* appearance.
///
/// The palette / mode / AMOLED decision lives in
/// `providers/theme_provider.dart` as its own [ThemeSettings] value: it is read
/// on every frame to build the `ThemeData` and it is written as a unit, so
/// keeping it apart stops a currency change from re-reading the theme and
/// stops the theme from being persisted on an unrelated save.
class SettingsState {
  final String currency;
  final String userName;
  final String? profilePicPath;
  final bool isOnboardingCompleted;
  final bool isLoaded;
  final bool isPasswordEnabled;
  final bool isFingerprintEnabled;

  /// Budget threshold notifications (80% / 100%). Default on.
  final bool budgetAlertsEnabled;

  /// "New version available" notification. Default on.
  final bool updateNotificationsEnabled;

  /// Renders the floating nav opaque instead of frosted. Default off.
  final bool reduceTransparency;

  SettingsState({
    this.currency = 'MAD',
    this.userName = 'User',
    this.profilePicPath,
    this.isOnboardingCompleted = false,
    this.isLoaded = false,
    this.isPasswordEnabled = false,
    this.isFingerprintEnabled = false,
    this.budgetAlertsEnabled = true,
    this.updateNotificationsEnabled = true,
    this.reduceTransparency = false,
  });

  SettingsState copyWith({
    String? currency,
    String? userName,
    String? profilePicPath,
    bool? isOnboardingCompleted,
    bool? isLoaded,
    bool? isPasswordEnabled,
    bool? isFingerprintEnabled,
    bool? budgetAlertsEnabled,
    bool? updateNotificationsEnabled,
    bool? reduceTransparency,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      userName: userName ?? this.userName,
      profilePicPath: profilePicPath ?? this.profilePicPath,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      isLoaded: isLoaded ?? this.isLoaded,
      isPasswordEnabled: isPasswordEnabled ?? this.isPasswordEnabled,
      isFingerprintEnabled: isFingerprintEnabled ?? this.isFingerprintEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      updateNotificationsEnabled:
          updateNotificationsEnabled ?? this.updateNotificationsEnabled,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  final _hive = HiveService.instance;

  @override
  SettingsState build() {
    return _loadSettings();
  }

  SettingsState _loadSettings() {
    try {
      final currency = _hive.getCurrency();
      final userName = _hive.getUserName();
      final profilePicPath = _hive.getProfilePicPath();
      final onboardingCompleted = _hive.isOnboardingCompleted();

      final isPasswordEnabled = _hive.getFlag(
        'isPasswordEnabled',
        defaultValue: false,
      );
      final isFingerprintEnabled = _hive.getFlag(
        'isFingerprintEnabled',
        defaultValue: false,
      );
      final budgetAlertsEnabled = _hive.getFlag(
        'budgetAlertsEnabled',
        defaultValue: true,
      );
      final updateNotificationsEnabled = _hive.getFlag(
        'updateNotificationsEnabled',
        defaultValue: true,
      );
      final reduceTransparency = _hive.getFlag(
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
      // Last-resort fallback. Reaching here means the store itself is
      // unreadable, not that one value is odd — every individual read is
      // already type-checked, so a failure now means the whole box is broken and
      // defaulting is the only useful thing to do. `isLoaded: true` either way,
      // because a failed read must not strand the app on a splash screen.
      debugPrint('Could not read settings, using defaults: $e');
      return SettingsState(isLoaded: true);
    }
  }

  Future<void> setCurrency(String newCurrency) async {
    final oldCurrency = state.currency;
    if (oldCurrency == newCurrency) return;

    double rate = 1.0;
    try {
      final from = _getCurrencyEnum(oldCurrency);
      final to = _getCurrencyEnum(newCurrency);

      if (from != null && to != null) {
        final convertedRate = await CurrencyConverter.convert(
          from: from,
          to: to,
          amount: 1,
        );
        if (convertedRate != null) {
          rate = convertedRate;
        }
      }
    } catch (e) {
      debugPrint('Error converting currency: $e');
    }

    await _hive.setCurrency(newCurrency);
    if (ref.mounted) {
      state = state.copyWith(currency: newCurrency);
    }

    final accountDao = AccountDao();
    await accountDao.updateAllBalances(rate, newCurrency);

    await TransactionDao().updateAllAmounts(rate);
    await BudgetDao().updateAllAmounts(rate);

    ref.read(accountProvider.notifier).refresh();
    ref.read(transactionProvider.notifier).refresh();
    ref.read(budgetProvider.notifier).refresh();
    // Reports hold converted amounts, so they must be rebuilt too.
    ref.invalidate(reportProvider);
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

  Future<void> setUpdateNotificationsEnabled(bool value) async {
    await _hive.saveSetting('updateNotificationsEnabled', value);
    if (ref.mounted) {
      state = state.copyWith(updateNotificationsEnabled: value);
    }
  }

  Future<void> setReduceTransparency(bool value) async {
    await _hive.saveSetting('reduceTransparency', value);
    if (ref.mounted) state = state.copyWith(reduceTransparency: value);
  }

  Future<void> completeOnboarding() async {
    await _hive.setOnboardingCompleted(true);
    if (ref.mounted) {
      state = state.copyWith(isOnboardingCompleted: true);
    }
  }

  Currency? _getCurrencyEnum(String code) {
    final upper = code.toUpperCase();
    for (final c in Currency.values) {
      if (c.name.toUpperCase() == upper) return c;
    }
    return null;
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
