import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/local/hive_service.dart';

class SettingsState {
  final bool isDarkMode;
  final String currency;
  final bool isOnboardingCompleted;
  final bool isLoaded; // Added to track initialization

  SettingsState({
    this.isDarkMode = false,
    this.currency = 'MAD',
    this.isOnboardingCompleted = false,
    this.isLoaded = false, // Defaults to false
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? currency,
    bool? isOnboardingCompleted,
    bool? isLoaded,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currency: currency ?? this.currency,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  final _hive = HiveService.instance;

  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState(); // Initial state is NOT loaded
  }

  Future<void> _loadSettings() async {
    try {
      final isDark = await _hive.isDarkMode();
      final currency = await _hive.getCurrency();
      final onboardingCompleted = await _hive.isOnboardingCompleted();

      state = SettingsState(
        isDarkMode: isDark,
        currency: currency,
        isOnboardingCompleted: onboardingCompleted,
        isLoaded: true, // Now it is safe to check onboarding status
      );
    } catch (e) {
      state = state.copyWith(isLoaded: true); // Even on error, mark as loaded
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

  Future<void> completeOnboarding() async {
    await _hive.setOnboardingCompleted(true);
    state = state.copyWith(isOnboardingCompleted: true);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
