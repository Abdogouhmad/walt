/// Everything that is *not* appearance.
///
/// The palette / mode / AMOLED decision lives in
/// `providers/theme_provider.dart` as its own `ThemeSettings` value: it is read
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
