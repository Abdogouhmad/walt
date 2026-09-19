# Changelog

> **This file is the single source of truth for release notes (spec §5).**
>
> The OTA release pipeline — `update_manifest.json`, GitHub release bodies and
> the in-app "What's new" pane — all derive their text from the matching
> section of this file. Every user-visible change MUST be recorded here,
> plain Keep a Changelog, one bullet per user-visible change.

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Material You redesign (spec §1)** — dynamic-color M3 port of the Walt UI:
  - Shared design tokens (`lib/core/design/`): `AppSpacing`, `AppRadius`, `AppMotion`.
  - Rewritten `app_theme.dart`: M3 expressive motion, `InkSparkle`, fade-forwards
    page transitions, 28dp surfaces / 16dp fields.
  - Shared components: `StatusBadge`, bottom-sheet driven modals (`showWaltModal`),
    consistent empty/loading/error state views, tactile `PressableScale`, shared
    `RoundedProgressBar` for all progress indicators.
- **OTA updates (spec §3)** — in-app update centre with an auto-check on launch,
  a "What's new" changelog pane, a non-dismissible mandatory-update screen, and
  a bottom-sheet update prompt, all driven by the versioned `update_manifest.json`.
- **Deterministic versioning (spec §2)** — `versionCode` is now derived from the
  pubspec SemVer (`major*10000 + minor*100 + patch`).
- **AI insights removed** — the Gemini AI "insight" feature (widget, provider,
  `ai_service`, `google_generative_ai` + `flutter_dotenv` dependencies and the
  `.env` asset) has been deleted entirely; the app is now fully offline.

### Changed

- **Consolidated duplicated UI into shared components** to minimise the codebase:
  - Sheets now open through `showWaltModal` everywhere (add-transaction and
    budgets); no screen hand-rolls a bottom-sheet shell, drag handle or radius box.
  - Budgets "empty", home "recent activity" and transactions-list empty states
    now use the shared `EmptyStateView`; the private budgets `EmptyState` widget
    was deleted.
  - Reports "average daily"/"saving rate" metric cards and the 6M/Yearly filter
    buttons share one builder instead of duplicated blocks.
  - "x% used", "Over budget"/"On track" pills now use `StatusBadge`.
  - Dead settings list widgets (`AppListHeader`, `AppListEmptyState`,
    `AppListActionTile`) were removed.
  - `AboutScreen` cards reuse the shared `M3Ecard`.
- **Design-token pass** — replaced remaining per-screen magic numbers with
  `AppSpacing`/`AppRadius`/`AppMotion` across home, budgets, reports,
  transactions and settings screens.
- **About & settings polish** — the About app card now fills the whole avatar
  circle with the wallet icon (`foregroundImage`), both About avatars share one
  radius, rows align to center and secondary labels are muted; the
  Settings → Update tile gained a matching 40dp circular "app update" icon.
- **Tighter cards** — `M3Ecard` skips the header row when a card has neither a
  title nor a leading widget, removing the empty band above title-less cards
  (summary, budget, About, report metrics).
- **Auto-check always on** — removed the "Check automatically" switch from the
  update screen; the app always checks for updates on launch. The manual
  "Check for updates" / "Try again" action is a compact outlined button at the
  bottom of the update screen.

### Fixed

- **Update notification vs budget-alert collision** — the OTA ping reused
  notification id `1`, the same id space budget alerts occupy (sequential from
  1); on Android, notifications sharing an id replace each other, so a budget
  alert could silently clobber the "new update" notification (or vice versa).
  Update notifications now use a dedicated id (`0x7A17`), locked in by a test.

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

[0.4.1]: https://github.com/Abdogouhmad/walt/compare/v0.4.0...v0.4.1
