# Walt — Optimization pass notes

Scope: the optimization and documentation pass on branch
`chore/optimize-and-docs`. This file records the baseline, what changed and
why, what was deliberately skipped, and open questions for the maintainer.

> **Verification note.** Per the task instruction, no full build or run was
> performed. `dart format .` and `flutter analyze` were run (both clean) as
> static checks; `flutter test` and `flutter build` were **not** executed, so
> the test suite and binary sizes below are the last known state, not a
> re-measurement after these changes.

---

## 1. Baseline vs. after

| Check | Baseline | After this pass |
| --- | --- | --- |
| `flutter analyze` | 0 issues (ruleset: `flutter_lints` only) | 0 issues (stricter ruleset) |
| Diagnostics surfaced by the stricter rules | — | 117, all fixed |
| `dart format --set-exit-if-changed .` | (not verified) | clean |
| `flutter test` | not run (instructed not to run) | tests added, not run |
| Universal APK | `dist/walt-v1.0.1-universal.apk` ≈ 43.8 MiB | unchanged (not rebuilt) |
| arm64-v8a APK | `dist/walt-v1.0.1-arm64-v8a.apk` ≈ 24.3 MiB | unchanged (not rebuilt) |
| armeabi-v7a APK | `dist/walt-v1.0.1-armeabi-v7a.apk` ≈ 22.2 MiB | unchanged (not rebuilt) |

The strict ruleset added: `prefer_const_constructors`,
`prefer_const_constructors_in_immutables`, `prefer_const_declarations`,
`prefer_final_locals`, `prefer_single_quotes`, `directives_ordering`,
`unnecessary_brace_in_string_interps`, `avoid_print`, `unawaited_futures`,
`use_build_context_synchronously`. The 117 diagnostics broke down as:
`prefer_const_constructors` ×42, `directives_ordering` ×34,
`prefer_single_quotes` ×32, `unawaited_futures` ×6,
`prefer_const_declarations` ×3. 102 were auto-fixed with `dart fix --apply`;
the 6 unawaited futures were fixed by hand.

---

## 2. What changed and why

### 2.1 Static analysis & code quality

- Enabled the additional lints above on top of `flutter_lints`
  (`analysis_options.yaml`). Kept `flutter_lints` rather than switching to
  `very_good_analysis`, which the project had not adopted.
- Fixed every resulting diagnostic. The only non-mechanical fixes were the six
  `unawaited_futures`:
  - `budget_sheet.dart` now **awaits** `addBudget`/`updateBudget`. This also
    fixes a latent ordering issue: the first-budget path awaited
    `evaluateBudgetAlertsNow` immediately after firing (not awaiting) the insert,
    so a budget created already over its limit could be evaluated before it was
    persisted.
  - `pages.dart` (onboarding avatar pick) and `settings_provider.dart`
    (currency conversion refreshes) wrap intentional fire-and-forget calls in
    `unawaited(...)`, preserving their behaviour explicitly.
- Removed two commented-out `print(...)` debug lines in
  `onboarding_screen.dart`.
- No raw `print` remains in `lib/`; the existing `debugPrint` calls (which are
  the Flutter logger and are stripped in release) were kept as-is rather than
  introducing a new logging dependency.

### 2.2 Runtime performance

- The `dart fix` pass added `const` to widget constructors flagged by
  `prefer_const_constructors`, reducing needless rebuilds/allocations. No
  behaviour change.
- Reviewed list/chart/controller usage while adding the rules; no additional
  changes were justified without profiling (see §3).

### 2.3 Architecture & structure

- No architectural change. The existing layering (features → providers →
  data/services → sqflite/Hive, with pure logic in `data/reports/`) is sound
  and is now documented in the README and CONTRIBUTING.

### 2.4 Dependencies

- No dependency added, removed or upgraded. `flutter pub outdated` was not run
  (it is a pub command, not executed); however `flutter analyze`'s implicit
  resolve printed the available upgrades, which are listed in §3 for the
  maintainer. The existing `dependency_overrides: image: 4.9.2` (required so
  `pdf` and `image` can coexist) is left in place and is already documented in
  `pubspec.yaml`.

### 2.5 Build size & release config

- Removed two declared-but-unreferenced assets:
  `assets/profile/meme.jpg` and `assets/icon/wallet.png` (and their files).
  They were declared in `pubspec.yaml` and therefore bundled, but used nowhere
  in the Dart/generated sources.
- Confirmed release config is already correct:
  `android/app/build.gradle.kts` enables `isMinifyEnabled = true` and
  `isShrinkResources = true` for the `release` type with the default
  `proguard-android-optimize.txt` plus `proguard-rules.pro`; release signing
  is provisioned from `key.properties` / `WALT_*` secrets by `build.sh`.
- Release commands are now documented in the README.

### 2.6 Testing

- Added `test/notification_routing_test.dart` covering
  `parseNotificationPayload` and `destinationToLocation` — pure functions that
  decide where a tapped notification navigates and that had no coverage
  (`notification_service` / `notification_router` were both untested).
- Did not run the suite (instructed not to). Existing tests were left intact.

### 2.7 CI/CD

- Added `.github/workflows/ci.yml`, triggered on pull requests and pushes to
  `main` plus manual dispatch:
  - `dart format --set-exit-if-changed .`
  - `flutter analyze`
  - `flutter test --coverage` (coverage uploaded as an artifact)
  - a debug-APK smoke build (no signing secrets required), gated on the
    analyze/test job.
  - Concurrency group cancels superseded runs.
- The existing tag-driven signed release pipeline (`.github/workflows/release.yml`)
  is unchanged; it still runs on push to `main`.

### 2.8 Repo hygiene

- No secrets, keystores or API keys are tracked. Verified with `git ls-files`:
  no `*.jks`, `key.properties`, `.env`, or service-account files are committed.
  `android/key.properties` and `android/local.properties` exist locally but are
  untracked and covered by `.gitignore`.
- `.gitignore` already covers build output, `.dart_tool`, IDE files, keystores,
  `key.properties`, `.env`, symbols and `coverage/`. No change required.
- `LICENSE` exists (MIT) and matches the README. **Caveat:** its copyright line
  is still the Flutter template placeholder `Copyright (c) 2026 <T>` — see §4.

### 2.9 Documentation

- Rewrote `README.md` to match the current code: Material 3 (not Material You
  / dynamic colour), SQLite + Hive, the nine palettes, biometric lock, and the
  OTA flow. Removed the previously advertised **Google Pay capture** feature,
  which is not implemented anywhere in `lib/` (see §4).
- Added `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`,
  `.github/ISSUE_TEMPLATE/bug_report.md`,
  `.github/ISSUE_TEMPLATE/feature_request.md`, and
  `.github/PULL_REQUEST_TEMPLATE.md`.
- Extended `CHANGELOG.md` with an `[Unreleased]` section for this pass and
  added the missing `[Unreleased]`, `[1.0.1]` and `[1.0.0]` comparison links
  (the file previously skipped straight to `[0.8.2]`).

---

## 3. Skipped or deferred (risky / breaking)

- **Major dependency upgrades.** The resolve reported these newer majors
  available under the current constraints:
  `go_router` 17.x → 18.x, `flutter_local_notifications` 21.x → 22.x,
  `freezed` 3.x → 4.x, `xml` 6.x → 7.x, `cross_file`, `dbus`, `package_config`.
  These have migration guides/breaking changes and were **not** attempted
  without the ability to build and run the tests. Recommend upgrading one at a
  time on a dedicated branch with the suite green after each.
- **Patch/minor upgrades** are available for many packages (`flutter_riverpod`
  3.4.2 → 3.4.3, `share_plus` 13.3.0 → 13.3.1, `image_picker`, `sqflite`,
  `url_launcher`, …) and should be safe, but were left for a normal dependency
  bump because the lockfile could not be validated by a build here.
- **Obfuscation / split-debug-info** for the AAB was not added to the pipeline.
  The README documents it as an option, but enabling it in
  `.github/workflows/release.yml` is a release-process decision.
- **Localization** is entirely absent (hardcoded English, `intl` used only for
  formatting). Adding it is a large, behaviour-adjacent change and was out of
  scope.
- **Dead "accounts" stack** (`walt_account` model, `account_dao`,
  `account_provider`, the empty `accounts` table) is only touched by the
  currency-conversion refresh; it has no UI. Left in place — removing it is a
  data-model decision for the maintainer.
- **`SettingsState.isPasswordEnabled`** is persisted but never surfaced or
  enforced. Left as-is.
- **`update_manifest.json`** currently describes `1.0.0` while `pubspec.yaml`
  is `1.0.1`. This is expected pre-release: the release workflow rewrites the
  manifest on merge. Not touched.
- **Compatibility shims** (`lib/core/design/motion.dart`,
  `lib/core/theme/shapes.dart` re-export only) were kept to avoid breaking
  imports.

---

## 4. Open TODOs / questions for the maintainer

1. **Google Pay capture is not implemented.** `AndroidManifest.xml` declares a
   notification-listener service for
   `im.zoe.labs.flutter_notification_listener.NotificationsHandlerService`,
   but that package is not a dependency and no Dart code references it. The old
   README advertised the feature. It was removed from the README; decide
   whether to implement the feature (add the dependency + settings UI) or delete
   the stale manifest service and its `BIND_NOTIFICATION_LISTENER_SERVICE`
   declaration and comments. Left in place rather than silently removing a
   manifest entry.
2. **LICENSE copyright holder** is the placeholder `Copyright (c) 2026 <T>`.
   Replace with the real name/organisation.
3. **Security contact** — `SECURITY.md` and `CODE_OF_CONDUCT.md` contain
   `<!-- TODO -->` placeholders for the reporting contact. Add a real address
   (or enable GitHub private vulnerability reporting and drop the email).
4. **Screenshots** — none exist in the repo. Add them under
   `docs/screenshots/` and link them from the README (there is a `TODO`
   placeholder).
5. **Unused source asset** — `assets/icon/walt_icon.svg` exists but is neither
   declared in `pubspec.yaml` nor referenced; confirm whether it is a design
   source to keep or remove.
6. **Stale planning docs** at the repo root — `feat.md`, `polish.md`,
   `WALT_M3_EXPRESSIVE.md`, and the task's `instruction.md` — are untracked or
   describe removed features (Material You / dynamic colour). Consider deleting
   or archiving them.
7. **`updateNotificationsEnabled`** is read by the update provider but its UI
   toggle was removed (updates notification is always on per the 0.8.0 notes).
   Harmless, but vestigial.
8. **Unused helpers** spotted during review (kept, not deleted): a duplicate
   `weekdayIndex` in the weekly chart vs. `report_aggregation.dart`,
   `transaction_dao.getTransactionsBetween`, `walt_colors
   .containerForTransactionType`, `HiveService.clearAll/close`, and
   `BudgetAlertService.reset`.
9. **Test coverage gaps** — no tests for the sqflite DAO / account layer, PDF
   export, `image_store`, `transaction_provider`, or
   `settings_provider.setCurrency`'s conversion path. Good next targets.
