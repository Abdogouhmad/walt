import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:currency_converter/currency_converter.dart';
import 'package:currency_converter/currency.dart';
import 'package:walt/data/local/account_deo.dart';
import 'package:walt/data/local/budget_dao.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:walt/providers/account_provider.dart';
import 'package:walt/providers/auth_provider.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/transaction_provider.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String currency;
  final String userName;
  final String? profilePicPath;
  final bool isOnboardingCompleted;
  final bool isLoaded;
  final bool isPasswordEnabled;
  final bool isFingerprintEnabled;

  SettingsState({
    this.themeMode = ThemeMode.system,
    this.currency = 'MAD',
    this.userName = 'User',
    this.profilePicPath,
    this.isOnboardingCompleted = false,
    this.isLoaded = false,
    this.isPasswordEnabled = false,
    this.isFingerprintEnabled = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? currency,
    String? userName,
    String? profilePicPath,
    bool? isOnboardingCompleted,
    bool? isLoaded,
    bool? isPasswordEnabled,
    bool? isFingerprintEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
      userName: userName ?? this.userName,
      profilePicPath: profilePicPath ?? this.profilePicPath,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      isLoaded: isLoaded ?? this.isLoaded,
      isPasswordEnabled: isPasswordEnabled ?? this.isPasswordEnabled,
      isFingerprintEnabled: isFingerprintEnabled ?? this.isFingerprintEnabled,
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
      final themeModeStr = _hive.getThemeMode();
      final themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeModeStr,
        orElse: () => ThemeMode.system,
      );
      final currency = _hive.getCurrency();
      final userName = _hive.getUserName();
      final profilePicPath = _hive.getProfilePicPath();
      final onboardingCompleted = _hive.isOnboardingCompleted();

      final isPasswordEnabled =
          _hive.getSetting('isPasswordEnabled', defaultValue: false) as bool;
      final isFingerprintEnabled =
          _hive.getSetting('isFingerprintEnabled', defaultValue: false) as bool;

      return SettingsState(
        themeMode: themeMode,
        currency: currency,
        userName: userName,
        profilePicPath: profilePicPath,
        isOnboardingCompleted: onboardingCompleted,
        isLoaded: true,
        isPasswordEnabled: isPasswordEnabled,
        isFingerprintEnabled: isFingerprintEnabled,
      );
    } catch (e) {
      return SettingsState(isLoaded: true);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _hive.setThemeMode(mode.name);
    state = state.copyWith(themeMode: mode);
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
      print('Error converting currency: $e');
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
  }

  Future<void> setUserProfile({required String name, String? profilePic}) async {
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

  // Future<void> togglePassword() async {
  //   final newValue = !state.isPasswordEnabled;
  //   await _hive.saveSetting('isPasswordEnabled', newValue);
  //   state = state.copyWith(isPasswordEnabled: newValue);
  // }

  Future<bool> toggleFingerprint(WidgetRef ref) async {
    final newValue = !state.isFingerprintEnabled;

    if (newValue) {
      final success = await ref.read(authProvider.notifier).authenticate(force: true);
      if (!success) return false;
    }

    await _hive.saveSetting('isFingerprintEnabled', newValue);
    if (this.ref.mounted) {
      state = state.copyWith(isFingerprintEnabled: newValue);
    }
    return true;
  }

  Future<void> completeOnboarding() async {
    await _hive.setOnboardingCompleted(true);
    if (ref.mounted) {
      state = state.copyWith(isOnboardingCompleted: true);
    }
  }

  Currency? _getCurrencyEnum(String code) {
    try {
      return Currency.values.firstWhere(
        (c) => c.name.toUpperCase() == code.toUpperCase(),
      );
    } catch (_) {
      // Manual fallback for common ones if enum names don't match exactly
      if (code.toUpperCase() == 'MAD') return Currency.mad;
      if (code.toUpperCase() == 'USD') return Currency.usd;
      if (code.toUpperCase() == 'EUR') return Currency.eur;
      if (code.toUpperCase() == 'GBP') return Currency.gbp;
      return null;
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
