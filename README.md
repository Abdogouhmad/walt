# Finance Tracker

A clean, offline-first personal finance tracker built with **Flutter** for Android.  
Track expenses & income, manage budgets, view beautiful charts, export reports, and automatically capture Google Pay transactions.

**Current Version:** v0.1 (Foundation)

---

## Features (Planned)

- **Offline-first** with SQLite + Hive
- Beautiful charts (monthly, category pie, trends) using fl_chart
- Budget planning with progress tracking & alerts
- CSV & PDF export with share sheet
- Biometric app lock
- Dark mode support
- Fully customizable categories

---

## Tech Stack & Packages

### Core Packages

- **Flutter** + **Dart**
- **sqflite** – Local SQLite database
- **hive_flutter** – Fast caching (categories, settings, pending GPay)
- **shared_preferences** – User preferences
- **flutter_riverpod + hooks_riverpod** – State management
- **go_router** – Declarative navigation

### UI & Charts

- **fl_chart** – All charts (bar, pie, line)

### Export

- **pdf** – Generate styled PDF reports
- **csv** – Generate CSV files
- **share_plus** – Share files via Android share sheet
- **path_provider** – Temporary file storage

### Utilities

- **freezed + json_serializable** – Immutable models
- **intl** – Date & currency formatting
- **local_auth** – Biometric authentication
- **flutter_local_notifications** – Budget alerts & reminders
- **permission_handler** – Permissions management

---

## Project Folder Structure

```bash
finance_tracker/
├── android/                  # Android-specific configuration
├── assets/
│   ├── fonts/
│   └── icons/
├── lib/
│   ├── core/
│   │   ├── constants/        # app_colors, app_strings, currency_symbols
│   │   ├── theme/            # app_theme.dart
│   │   ├── utils/            # formatters, validators, extensions
│   │   └── extensions/
│   │
│   ├── data/
│   │   ├── models/           # @freezed models (transaction, category, budget, account)
│   │   ├── local/            # database_helper, DAOs, hive_service
│   │   ├── repositories/     # transaction_repo, category_repo, etc.
│   │   └── services/         # export_service, notification_service
│   │
│   ├── providers/            # Riverpod providers
│   │   ├── transaction_provider.dart
│   │   ├── category_provider.dart
│   │   ├── budget_provider.dart
│   │   └── settings_provider.dart
│   │
│   ├── features/
│   │   ├── home/
│   │   ├── transactions/
│   │   ├── reports/
│   │   ├── budgets/
│   │   ├── categories/
│   │   ├── export/
│   │   ├── settings/
│   │   └── onboarding/
│   │
│   ├── shared/               # Reusable widgets
│   ├── app_router.dart
│   └── main.dart
│
├── test/                     # Unit tests
├── pubspec.yaml
└── analysis_options.yaml
```
