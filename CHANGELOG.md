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

## [0.8.2] - 2026-10-01

### Fixed

- **Recent activity never appeared on Home** — the section filtered
  transactions down to a date window that ended *yesterday*, and a transaction
  is stamped with the moment it was added, so every entry carried a time of day
  and fell outside it. Home said "No recent activity" while the Activity tab
  listed those same transactions. The same window also emptied the section for
  anyone whose newest entry was more than three days old. "Recent" is now simply
  the newest entries, with no date window at all, and picking a day in the week
  recap still narrows the list to that day — now matched on the calendar day, so
  the time of day can no longer hide an entry.

## [0.8.1] - 2026-09-30

### Changed

- **Onboarding icon** — the welcome step now shows the app's real launcher icon
  (`walt_icon.png`) instead of the old generic wallet glyph.
- **Updates are picked up immediately** — the update check now asks for a fresh
  copy of the manifest, so a newly published release shows up on the very next
  check instead of waiting for the CDN cache to expire.

### Fixed

- **OTA releases resolve against the right repository** — the release workflow
  now derives the download URL from the repository it actually runs in, so a
  fork or a renamed repo can no longer publish a manifest that points at
  somebody else's APK.
- **Release notes are no longer mangled** — leading indentation is preserved,
  so nested bullets and code blocks survive into the GitHub release body and
  the in-app "What's new" pane.
- **Stale release notes can no longer be published** — the published APK and
  the APK recorded in the manifest are verified to be the same file, and a
  release whose CHANGELOG section does not match its version fails the build.
- **"Check for updates" no longer hangs forever** — the network fetch is
  bounded by a timeout, so a stalled connection resolves to a normal "couldn't
  check" state instead of spinning indefinitely.
- **A download that is cancelled or fails now resets cleanly** — the stale
  progress bar is cleared instead of being carried into the next attempt.

## [0.8.0] - 2026-09-30

### Added

- **Roboto Flex, bundled** — the variable font is now an asset
  (`assets/fonts/RobotoFlex.ttf`, OFL). One file carries weight, width,
  optical size, grade and slant, so the type scale interpolates instead of
  snapping. Nothing is fetched at runtime.
- **Type scale** — every M3 role is bound to the `wght` and `opsz` axes at the
  pinned size/weight, with tabular figures for money and a 12pt floor.
- **Reports** — Week / Month / Year switcher, a selectable bar chart, a
  category donut with a centred total, a percentage legend, and loading /
  empty / error / retry states. Every failure mode is reachable and
  recoverable; a category with no spending no longer renders `NaN`.
- **Budget alerts** — notify at 80% and at 100% of a limit, once per
  threshold per period, and again after the period rolls over. Permission is
  asked the first time a budget is created, not at launch.
- **Settings** — the profile avatar on every top-level screen opens Settings as
  a push (it is no longer a bottom-nav tab). New toggles for budget alerts,
  update notifications, and "Reduce transparency".
- **Android blur surface** — the floating nav, sheets and scrims use a calm
  tonal `BackdropFilter` instead of iOS-style liquid glass, with an opaque
  fallback that also engages automatically when the system reports that
  animations are off.
- **Soft updates** — a dismissible, non-modal card in Settings → About, a local
  notification once per released version, and release notes rendered as real
  Markdown.
- **Local avatar** — pick an image once; it is copied into the app's own
  storage so it survives reinstalls of the widget's temporary file.
- **Appearance** — Settings → Preferences → Appearance. Nine built-in palettes
  (Emerald, Ocean, Indigo, Violet, Rose, Amber, Terracotta, Teal, Graphite), a
  System / Light / Dark switch, and an AMOLED toggle for pure-black surfaces in
  dark mode. A live preview card at the top of the screen applies each choice as
  you tap it. A "Custom" swatch next to the palettes opens a colour picker for
  any seed you like. Your choice is remembered and restored on the next launch,
  including on the splash screen, with no flash of the wrong colours.

### Changed

- **Updates are optional.** The blocking "update required" screen is gone, along
  with every forced-update path. The version check now runs quietly in the
  background after start and fails silently when offline. An old build keeps
  working indefinitely and keeps being offered the new one.
- **Material You is gone.** Walt used to repaint itself from the wallpaper on
  Android 12+. It now always uses the palette you choose in Appearance, so the
  app looks identical on every device and the charts, income/expense colours and
  status bars all agree with it. An existing light/dark preference carries over;
  the dynamic-colour toggle is removed.
- **"Reduce transparency" moved** from Preferences into Appearance, where it
  belongs next to the other things that change how the app looks.
- **Money is grouped and legible** — thousands separators, and the currency
  code rendered as a lighter suffix rather than glued to the digits.
- **The period label is fixed** — navigating back one month now reads "Last
  month"; the direction was previously reversed.
- **Date maths is daylight-saving safe** — day counts and "N days remaining"
  no longer come out one short around a DST transition, and a closed period
  no longer reports an average below the true daily spend.
- **Reports update themselves** after adding, editing or deleting a
  transaction, instead of showing a cached snapshot until the screen is
  reopened.

### Fixed

- **Colours that ignored the theme** — income/expense greens and reds, the
  transaction list, the currency picker, category tints, progress-bar tracks and
  sheet shadows were hardcoded, so they stayed the same on every device and
  clashed with the app's own palette. They are all derived from the current
  theme now, and every palette is contrast-checked so a label on a filled
  button is always readable.
- **Reports could not open** — several failure paths threw instead of showing
  a recoverable error.
- **Budgets could not open** — the summary was passed around as an untyped map
  with string keys; it is now a real value type that cannot be read wrongly.
- **Amounts could animate from nothing** — the balance tween started and ended
  on the same value, so the number jumped instead of counting.
- **Tapping today's recap cleared the filter** instead of filtering to today.
- **Both budget thresholds could be skipped** — a budget that jumped straight
  past its limit reported only the severe one.
- **The week recap overflowed** — the strip reserved room for the gap and the
  day letter but not the selected day's amount, so any selection overflowed.
  The height is now measured from the text, which also holds at 200% text scale
  where the selected pill was being squeezed flat.
- **Selecting a nav tab threw** — the unselected label collapses via a
  `widthFactor` tween to 0, and the spring easing overshoots straight through
  zero into a negative value that `Align` rejects. The flood of "semantics
  parentDataDirty" errors that followed was the framework re-checking its own
  tree every frame while those builds kept failing.
- **The nav bar overflowed on narrow windows** — a selected label plus its
  padding is wider than a quarter of the bar below roughly 320pt, and the text
  laid out at its intrinsic width regardless of the cap. Labels now ellipsize
  and the item scales down rather than spilling.
- **The Home balance was too small** — the hero passed an explicit 56pt size
  alongside a themed `style`, but `TextStyle.merge` lets a style's own
  `fontSize` win, so the override was silently discarded and the number
  rendered at the role's 44pt. The size is now applied after the merge, and
  the currency code scales with the number instead of falling back to a 14pt
  label.
- **Settings rendered on a black background** — it is pushed on the root
  navigator, so a transparent Scaffold had nothing behind it and the platform
  window showed through. It now paints the app's own surface colour.
- **Settings rows had no visible separation** — the grouped-list gap was the
  spec's 2dp, which read as a hairline seam and made the cards look like one
  undifferentiated block. Now 8dp.
- **Update notifications could not be turned off** — the switcher is gone;
  update notifications are always on, as they are a service announcement
  rather than a preference.
- **About opened a dead-end screen** — it is informational, so it is now a
  dialog. The route is kept because update notifications deep-link to it.
- **One corrupt setting could discard all of them** — the saved toggles were
  read back with a hard type cast. Hive stores values untyped, so a single
  value of the wrong kind threw, and the failure path quietly returned empty
  settings: your display name, avatar and currency all reverted to defaults and
  you were given no hint why. A bad value now costs you that one toggle and is
  logged, instead of silently resetting your profile.
- **"Custom" did not clear a custom colour** — with a custom seed already
  chosen, tapping the Custom swatch again kept the old colour instead of
  opening the picker on it, so there was no way back to your palette from the
  picker itself.
- **Progress bars were silent to screen readers** — budget usage and the
  loading indicators are drawn with plain containers, which announce nothing.
  They now expose their percentage, and a bar can be labelled with what it is
  measuring.
- **Every screen reserved a large-title gap above its app bar** —
  `SliverAppBar.large` (152) then `.medium` (112) both pushed the title well
  below the top edge. All top-level screens now use a compact 56pt bar.
- **The nav bar did not look frosted** — the shared light-mode fill left only
  a fifth of the blurred backdrop showing, so the bar read as a flat opaque
  slab. It now uses a thinner tint under a stronger blur so the frost is
  actually visible, and still drops the blur entirely when "Reduce
  transparency" is on.
- **Category names were drawn over category colours in the Reports donut** —
  the pie's touch system is disabled, so nothing is painted over a slice; a
  category is read from its colour and named in the list below the chart.
- **Creating a budget always crashed** — the form held a `GlobalKey<FormState>`
  but no `Form` widget was ever given it, so `_formKey.currentState` was
  permanently null and every save threw "Null check operator used on a null
  value". The key is now attached to a real `Form`, which also means the
  amount field's own validator runs for the first time and reports inline
  instead of the sheet accepting an empty amount. Selecting a category is no
  longer required silently: it now explains itself.
- **Reports threw every frame, flooding the log with
  `!semantics.parentDataDirty`** — the summary tiles' row asked its children to
  stretch, but that row sits in a sliver, so it is handed unbounded height and
  the stretch resolved to infinity. The row then failed to lay out, and the
  unlaid-out subtree tripped the semantics consistency check on every frame.
  The same bug existed in both the loaded and loading branches.
- **The Reports regression test passed while the screen was broken** — it used
  the real provider, which resolves to an empty aggregation, so the charts and
  the loaded branch were never built. It now runs against a populated report
  and pumps frame by frame with semantics enabled, which is the only way the
  `!semantics.parentDataDirty` assertion is reachable at all.
- **The whole type scale was inert** — it was built from the colour half of
  Material's typography, whose `fontSize` is null, so every role fell back to
  the ambient default instead of the specified size.

## [0.7.0]

### Added

- **Material 3 Expressive UI overhaul** — every screen is rebuilt around the
  shared design system (`lib/core/theme/`, `lib/core/widgets/`):
  - **Floating chrome** — a detached pill navigation bar that slides away while
    you scroll, and a rounded-square FAB that unfolds a staggered, spring-driven
    action menu (route-aware: expense/income on Home & Activity, budget on
    Budgets). Both are fully labelled for screen readers.
  - **Hero surfaces** — a balance hero with income/expense pills on Home, a
    trend/category report switch with a donut + breakdown, and a budget
    progress summary card.
  - **Motion** — spring-driven press feedback (scale 0.97), staggered fade +
    slide for list items, wavy loading indicator; everything collapses to zero
    duration when "remove animations" is on.
  - **Adaptive colour** — light, dark and Android dynamic colour, with
    `WaltColors` income/expense roles replacing hardcoded red/green in screens.
- Widget tests covering the floating navigation bar and FAB menu (selection
  semantics, tap reporting, single- and multi-action flows).

### Changed

- Home, Activity, Reports, Budgets, Settings and the add-transaction flow now
  share `SectionHeader` / `GroupedList` grouped lists, `AmountText` and
  `CategoryAvatar` instead of per-screen card stacks; screens no longer draw
  their own app bar or FAB.
- Motion tokens live in `lib/core/theme/motion.dart`; `lib/core/design/motion.dart`
  re-exports them for existing imports.
- New launcher icon assets (`assets/icon/`) and a `flutter_launcher_icons`
  configuration for an adaptive, themed Android icon.

### Fixed

- The About screen and onboarding welcome step referenced a missing
  `assets/icons/wallet.png` and would have failed to load the image; both now
  point at the real `assets/icon/wallet.png`, which is declared in
  `pubspec.yaml` again.

## [0.6.0] - 2026-09-20

### Fixed

- **Installable release APK (fixes 0.5.0 not installing)** — the 0.5.0 release
  artifacts were published **unsigned** (the release keystore hadn't been
  provisioned on CI), so Android refused to install them at all
  (`INSTALL_FAILED_INVALID_APK` — an unsigned release APK is not installable).
  This release fixes that end-to-end:
  - The release pipeline now provisions the stable keystore from the `WALT_*`
    CI secrets and **fails the build when they are missing** — a release is
    never shipped unsigned or debug-signed again.
  - Every APK is signature-verified with `apksigner` before it is uploaded.
  - `android/app/build.gradle.kts` now always signs release builds (falling
    back to the debug key for local `flutter run --release`), so every APK
    Gradle emits is signed.
  - Split-per-ABI APKs now keep the **same `versionCode`** as the universal
    APK (`force-version-code-ignoring-abi`), so installing over a universal
    APK is an upgrade, never a signature/downgrade clash.
- The long-unreleased `0.5.0` changelog was promoted into its own released
  section; the release pipeline fails if `## [0.6.0]` (or whatever the current
  version is) is missing from CHANGELOG.md, keeping release notes and the
  in-app "What's new" pane truthful.

### Changed

- Release automation follows the brewline flow: a `build.sh` script carries the
  build/signing logic and `.github/workflows/release.yml` stays a thin wrapper
  (push to `main` → auto-tag `v<version>` → signed release + OTA manifest).

## [0.5.0] - 2026-09-19

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

[0.8.2]: https://github.com/Abdogouhmad/walt/compare/v0.8.1...v0.8.2
[0.8.1]: https://github.com/Abdogouhmad/walt/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/Abdogouhmad/walt/compare/v0.6.0...v0.8.0
[0.6.0]: https://github.com/Abdogouhmad/walt/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/Abdogouhmad/walt/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/Abdogouhmad/walt/compare/v0.4.0...v0.4.1
