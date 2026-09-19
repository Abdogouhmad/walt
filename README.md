# Walt

A modern, privacy-first expense & income tracker built with **Flutter** and
**Material You (M3)** for Android.

Track expenses & income, set budgets with live progress alerts, visualise
spending with charts, export PDF reports, auto-capture Google Pay transactions,
and self-update straight from the app via OTA.

**Current Version:** v0.5.0

---

## Features

- **Offline-first** — everything stays on-device (SQLite + Hive). No account,
  no cloud, no tracking.
- **Material You (M3)** — dynamic color theming, expressive motion, 28dp
  surfaces, light & dark themes.
- **Charts** — monthly trends, category breakdowns and report views with
  `fl_chart`.
- **Budgets** — per-category limits with progress bars and "near-limit / over
  budget" notifications.
- **Reports** — monthly / 6-month / yearly metrics, exportable as styled PDFs
  via the Android share sheet.
- **Google Pay capture** — automatic detection of GPay transactions matched
  against your spending.
- **App lock** — optional biometric authentication.
- **Custom categories** and multi-currency conversion.
- **OTA updates** — in-app update centre: auto-checks for new versions on
  launch, shows a "What's new" changelog pane, prompts to download & install,
  and blocks with a non-dismissible screen when a mandatory update is required.

---

## Tech Stack & Packages

### Core

- **Flutter** + **Dart**
- **flutter_riverpod** (+ `hooks_riverpod`) – State management
- **go_router** – Declarative routing
- **sqflite** (+ `sqflite_common_ffi`) – Local SQLite database
- **hive_ce** – Fast key-value caching (settings, pending GPay)
- **dynamic_color** – Material You dynamic color scheme

### UI & Charts

- **fl_chart** – All charts (bar, pie, line)
- **flutter_slidable** – Swipe actions on list items

### Export

- **pdf** – Generate styled PDF reports
- **share_plus** – Share files via the Android share sheet
- **path_provider** – Temporary file storage

### Utilities

- **freezed + json_serializable** – Immutable models
- **intl** – Date & currency formatting
- **local_auth** – Biometric authentication
- **flutter_local_notifications** – Budget alerts & update notifications
- **ota_update** – Downloading and installing updates in-app
- **currency_converter** – Multi-currency support
- **http / url_launcher / image_picker / package_info_plus** – Networking and platform helpers

---

## Project Folder Structure

```bash
walt/
├── android/                  # Android config (OTA install intent, GPay listener)
├── .github/workflows/        # CI: release.yml (build, publish, manifest)
├── assets/
│   ├── profile/
│   └── icons/
├── lib/
│   ├── core/
│   │   ├── design/           # Design tokens: spacing, radius, motion
│   │   ├── theme/            # app_theme.dart (M3, dynamic color)
│   │   ├── constants/
│   │   └── utils/
│   │
│   ├── data/
│   │   ├── models/           # @freezed models (transaction, category, budget, account, update_manifest)
│   │   ├── local/            # database_helper, DAOs, hive_service
│   │   └── services/         # notification_service, pdf_export_service, update_service
│   │
│   ├── providers/            # Riverpod providers
│   ├── features/             # auth, budgets, home, onboarding, reports, settings, transactions
│   ├── shared/               # Reusable widgets & modals (StatusBadge, M3Ecard, showWaltModal, ...)
│   ├── app_router.dart
│   └── main.dart
│
├── test/                     # Unit tests
├── update_manifest.json      # OTA release feed
├── CHANGELOG.md              # Single source of truth for release notes
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Release Pipeline

Versions follow SemVer; the Android `versionCode` is derived deterministically
from the pubspec version (`major*10000 + minor*100 + patch`). The
`.github/workflows/release.yml` CI build packages the APK, drafts the GitHub
release from `CHANGELOG.md`, and rewrites `update_manifest.json` — which the
app fetches on launch to power the in-app update centre.