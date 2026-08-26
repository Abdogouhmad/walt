# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.1] - 2026-08-26

Full codebase polish pass: dead code removal, dependency cleanup, startup
resilience, and UI/theme refinements (449 additions, 861 deletions).

### Changed

- **Startup (`main.dart`)**
  - Made `.env` optional — app no longer crashes without it (AI insights simply disabled).
  - Notifications initialization no longer blocks or breaks app startup on failure.
  - Guarded desktop sqflite FFI setup with a `kIsWeb` check.
  - Removed noisy debug prints and the rethrow of init errors.
- **Theme (`app_theme.dart`)**
  - Unified light/dark theme construction into a single `_buildTheme` helper.
  - Switched from `BottomNavigationBarTheme` to Material 3 `NavigationBarTheme`.
  - Removed unused `getTheme` helper.
- **Bottom navigation**
  - Converted to a Riverpod `ConsumerWidget` with budget progress / notification service integration.
- **Data layer**
  - Simplified `TransactionDao`, `BudgetDao`, `AccountDao`: inline insert/update maps, direct `map(_mapToTransaction)` conversions, removed redundant queries.
  - Tightened `HiveService`.
- **Providers**
  - Cleaned up `update_provider` OTA flow (formatting, clearer error states).
  - Refactored `settings_provider`, `auth_provider`, `budget_progress_provider` logic.
- **Dependency cleanup (`pubspec.yaml`)**
  - Removed unused packages: `cupertino_icons`, `hooks_riverpod` (kept `flutter_riverpod`), `shared_preferences`, `permission_handler`, `google_generative_ai`, `font_awesome_flutter`, legacy `hive`/`hive_flutter` (kept `hive_ce`).
  - Bumped version to `0.4.1`.

### Removed

- Dead code and files:
  - `lib/data/local/category_dao.dart`
  - `lib/providers/summary_provider.dart`
  - `lib/core/utils/rotation.dart`
  - `lib/features/home/widgets/notificationpopup.dart`
  - `lib/features/onboarding/widgets/dots.dart`
- Unused widgets and UI leftovers across home, budgets, transactions, settings, and onboarding screens (~860 lines deleted).
- Stray `folders` directory and `packages` symlink.

### Fixed

- Onboarding screen bugs carried over from earlier builds.
- Crash risk at startup when optional services (dotenv, notifications) are unavailable.

### Internal

- Added platform directories (`android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`) to analyzer excludes in `analysis_options.yaml`.
- Reformatted and lint-cleaned most files under `lib/`.
- Trimmed `test/widget_test.dart` to match current app structure.

[0.4.1]: https://github.com/abdo/walt/compare/v0.4.0...v0.4.1
