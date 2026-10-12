# Contributing to Walt

Thanks for taking the time to contribute! This document explains how to set up
the project, the conventions we follow, and how to get your change merged.

## What is Walt?

Walt is an **offline-first personal finance app** for Android, built with
Flutter and Material 3. It tracks income and expenses, manages per-category
budgets, produces charts and PDF reports, and updates itself over the air.

**Goals**

- Everything stays on-device: no accounts, no cloud sync, no analytics.
- A calm, coherent Material 3 interface backed by a real design system.
- Fast, small builds and a clean, tested codebase.

**Non-goals** (for now)

- Online banking integrations or server-side sync.
- Platforms other than Android (Linux exists for local development only).
- Speculative features that add bundles, permissions or background services
  without a concrete user benefit.

If you are unsure whether something fits, open an issue to discuss it first.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By
participating, you agree to uphold it. Please report unacceptable behaviour
through the contact in that document.

## Ways to contribute

- **Bug reports** — use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md).
- **Feature requests** — use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).
- **Documentation** — fixes to the README, CHANGELOG, or inline docs.
- **Code** — bug fixes, tests, and focused improvements.
- **Testing** — try a release on your device and report anything odd.
- **Translations** — the app currently ships English strings only; localization
  is not set up yet, so please open an issue before starting.

## Development setup

1. **Install Flutter** (stable channel). The project targets Dart `^3.11.4`;
   run `flutter doctor` and resolve any Android toolchain issues.
2. **Fork and clone** your fork:
   ```bash
   git clone git@github.com:<your-username>/walt.git
   cd walt
   ```
3. **Install dependencies**:
   ```bash
   flutter pub get
   ```
4. **Run the app**:
   ```bash
   flutter run              # attached Android device/emulator
   flutter run -d linux     # desktop (development/testing only)
   ```
5. **Regenerate code** only after changing a model annotated with `@freezed`,
   `@JsonSerializable` or `@HiveType`:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   Generated files are committed, so keep them in the same pull request.

No environment file or API key is needed.

## Architecture & conventions

The layer boundaries are described in the [README](README.md#architecture-overview).
In short: features depend on providers, providers depend on data, and data
never depends on the UI.

- **Screens** live in `lib/features/<feature>/` with feature-local widgets in a
  `widgets/` subfolder.
- **State** lives in `lib/providers/` as Riverpod `Notifier` / `AsyncNotifier`
  classes. Derive values with `select` rather than rebuilding whole screens.
- **Persistence** goes through `lib/data/local/` (sqflite DAOs and the Hive
  service). UI never touches the database directly.
- **Pure logic** (aggregation, date maths) belongs in `lib/data/reports/` so it
  can be unit-tested without Flutter bindings.
- **Design system**: use the tokens in `lib/core/design/` (`AppSpacing`,
  `AppRadius`, `AppMotion`) and the shared widgets in `lib/core/widgets/` and
  `lib/shared/`. Do not introduce magic numbers or hardcoded colours — take
  them from the `ColorScheme` / theme extensions.
- **Naming**: `lower_snake_case` files, `UpperCamelCase` types,
  `lowerCamelCase` members. Prefer `build_*` helpers only for trivial
  composition; split non-trivial parts into their own widgets.

## Branching & commit conventions

Branch from `main` using a descriptive prefix:

```text
feat/transaction-editing
fix/budget-overflow
docs/contributing
refactor/report-aggregation
chore/bump-deps
```

Write [Conventional Commits](https://www.conventionalcommits.org/), imperative
mood, one logical change per commit:

```text
feat(budgets): allow editing an existing budget
fix(home): keep recent activity on the home screen
test(notifications): cover payload parsing
docs(readme): document release builds
```

Keep commits focused; avoid mixing formatting, refactors and behaviour changes
in one commit.

## Coding standards

- **Formatting**: `dart format .` must leave the tree unchanged.
- **Analysis**: `flutter analyze` must report **no issues**. All warnings and
  infos are treated as failures in CI.
- Prefer `const` constructors and immutable widgets.
- **No `print`** — use `debugPrint` or `dart:developer` `log`.
- Handle async work deliberately: await it, or mark intentional fire-and-forget
  calls with `unawaited(...)`. Never use `BuildContext` after an `await` without
  a `mounted` check.
- Public APIs get documentation comments; comments explain *why*, not *what*.
- Do not add a dependency without a clear justification in the pull request.

## Testing requirements

- Add or update tests for the logic you change. Pure functions in
  `lib/data/reports/`, `lib/core/utils/` and providers are the highest-value
  targets; add widget tests for user-facing flows.
- Run and keep green:
  ```bash
  dart format --set-exit-if-changed .
  flutter analyze
  flutter test
  ```
- Coverage is reported with `flutter test --coverage`; aim for meaningful
  coverage of changed code rather than an absolute number.

## Pull request process

1. Rebase on the latest `main` and make sure the commands above pass locally.
2. Open the pull request and fill in the
   [PR template](.github/PULL_REQUEST_TEMPLATE.md).
3. **Checklist** before requesting review:
   - [ ] `dart format .` applied and `flutter analyze` is clean.
   - [ ] `flutter test` passes; new/updated tests added.
   - [ ] CHANGELOG updated under `[Unreleased]` for any user-visible change.
   - [ ] Screenshots or a short clip attached for UI changes.
   - [ ] No secrets, keystores or generated build output committed.
4. Keep the PR focused and small where possible. A maintainer will review and
   may request changes; there is no fixed response-time guarantee.

## Reporting bugs

Include as much of the following as you can:

- Walt version and build number (Settings → About), and your Android version.
- Device model and, for rendering issues, the display and text-scale settings.
- Clear steps to reproduce, expected vs. actual behaviour.
- Relevant logs (`flutter logs`) and screenshots or a screen recording.
- The output of `flutter doctor -v`.

## Requesting features

Open a feature request describing the problem, who it affects, and the outcome
you want. Explain how it fits the goals above and what the smallest useful
version would be. Discussion first avoids work that cannot be merged.

## Security

Please do **not** open a public issue for security problems. See
[SECURITY.md](SECURITY.md) for how to report them privately.

## License

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).
