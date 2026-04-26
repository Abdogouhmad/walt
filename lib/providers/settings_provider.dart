import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/providers/auth_provider.dart';

class SettingsState {
  final bool isDarkMode;
  final String currency;
  final bool isOnboardingCompleted;
  final bool isLoaded;
  final bool isPasswordEnabled;
  final bool isFingerprintEnabled;

  SettingsState({
    this.isDarkMode = false,
    this.currency = 'MAD',
    this.isOnboardingCompleted = false,
    this.isLoaded = false,
    this.isPasswordEnabled = false,
    this.isFingerprintEnabled = false,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? currency,
    bool? isOnboardingCompleted,
    bool? isLoaded,
    bool? isPasswordEnabled,
    bool? isFingerprintEnabled,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currency: currency ?? this.currency,
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
      final isDark = _hive.isDarkMode();
      final currency = _hive.getCurrency();
      final onboardingCompleted = _hive.isOnboardingCompleted();

      final isPasswordEnabled =
          _hive.getSetting('isPasswordEnabled', defaultValue: false) as bool;
      final isFingerprintEnabled =
          _hive.getSetting('isFingerprintEnabled', defaultValue: false) as bool;

      return SettingsState(
        isDarkMode: isDark,
        currency: currency,
        isOnboardingCompleted: onboardingCompleted,
        isLoaded: true,
        isPasswordEnabled: isPasswordEnabled,
        isFingerprintEnabled: isFingerprintEnabled,
      );
    } catch (e) {
      // Even if loading fails, we must mark as loaded to proceed, but using defaults
      return SettingsState(isLoaded: true);
    }
  }

  Future<void> toggleDarkMode() async {
    final newValue = !state.isDarkMode;
    await _hive.setDarkMode(newValue);
    state = state.copyWith(isDarkMode: newValue);
  }

  Future<void> setCurrency(String currency) async {
    await _hive.setCurrency(currency);
    state = state.copyWith(currency: currency);
  }

  Future<void> togglePassword() async {
    final newValue = !state.isPasswordEnabled;
    await _hive.saveSetting('isPasswordEnabled', newValue);
    state = state.copyWith(isPasswordEnabled: newValue);
  }

  Future<bool> toggleFingerprint(WidgetRef ref) async {
    final newValue = !state.isFingerprintEnabled;

    if (newValue) {
      // When enabling, try to authenticate first to make sure it works
      final success = await ref.read(authProvider.notifier).authenticate(force: true);
      if (!success) return false;
    }

    await _hive.saveSetting('isFingerprintEnabled', newValue);
    state = state.copyWith(isFingerprintEnabled: newValue);
    return true;
  }

  Future<void> completeOnboarding() async {
    await _hive.setOnboardingCompleted(true);
    state = state.copyWith(isOnboardingCompleted: true);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
