import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/local/hive_service.dart';

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
    _loadSettings();
    return SettingsState();
  }

  Future<void> _loadSettings() async {
    try {
      final isDark = await _hive.isDarkMode();
      final currency = await _hive.getCurrency();
      final onboardingCompleted = await _hive.isOnboardingCompleted();
      final isPasswordEnabled =
          await _hive.getSetting('isPasswordEnabled', defaultValue: false);
      final isFingerprintEnabled =
          await _hive.getSetting('isFingerprintEnabled', defaultValue: false);

      state = SettingsState(
        isDarkMode: isDark,
        currency: currency,
        isOnboardingCompleted: onboardingCompleted,
        isLoaded: true,
        isPasswordEnabled: isPasswordEnabled as bool,
        isFingerprintEnabled: isFingerprintEnabled as bool,
      );
    } catch (e) {
      state = state.copyWith(isLoaded: true);
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

  Future<void> toggleFingerprint() async {
    final newValue = !state.isFingerprintEnabled;
    await _hive.saveSetting('isFingerprintEnabled', newValue);
    state = state.copyWith(isFingerprintEnabled: newValue);
  }

  Future<void> completeOnboarding() async {
    await _hive.setOnboardingCompleted(true);
    state = state.copyWith(isOnboardingCompleted: true);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
