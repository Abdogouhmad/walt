# Finance Tracker - Project TODO

A step-by-step checklist to build the app version by version.

**Current Version:** v0.1 - Foundation

---

## Progress Summary

- **Total Tasks:** **58**
- **Done:** 0
- **Overall Progress:** 0%

---

## v0.1 — Foundation (Project Skeleton + Data Layer)

**Estimated time:** ~1 week  
**Goal:** Set up clean architecture, database, and routing. No UI yet.

### Tasks

- [x] Create Flutter project (`flutter create finance_tracker`)
- [x] Update `pubspec.yaml` with all required packages:
  - sqflite, hive_flutter, shared_preferences
  - flutter_riverpod, hooks_riverpod, go_router
  - freezed, json_serializable, build_runner
  - fl_chart, pdf, csv, share_plus, path_provider
  - intl, local_auth, flutter_local_notifications, permission_handler
- [x] Configure `AndroidManifest.xml`:
  - Permissions (BIOMETRIC, BOOT_COMPLETED, VIBRATE, FOREGROUND_SERVICE, WAKE_LOCK, POST_NOTIFICATIONS)
  - FileProvider declaration
  - Adaptive icon stubs
- [x] Create complete folder structure (exactly as specified in spec)
- [x] Set up SQLite schema in `lib/data/local/database_helper.dart`
  - Create tables: `transactions`, `categories`, `budgets`, `accounts`
  - Add version migration scaffold
- [x] Create Freezed models:
  - `lib/data/models/transaction.dart`
  - `lib/data/models/category.dart`
  - `lib/data/models/budget.dart`
  - `lib/data/models/account.dart`
- [x] Run build_runner (`flutter pub run build_runner build --delete-conflicting-outputs`)
- [x] Create DAO layer:
  - `TransactionDao`
  - `CategoryDao`
  - `BudgetDao`
  - `AccountDao`
- [x] Set up Hive boxes in `HiveService` (categories cache, settings)
- [x] Create Riverpod providers scaffold:\*\*\*\*
  - `TransactionProvider`
  - `CategoryProvider`
  - `BudgetProvider`
  - `SettingsProvider`
- [x] Create `AppTheme` (`lib/core/theme/app_theme.dart`) with accent color `#534AB7` and dark mode support
- [x] Configure `go_router` in `lib/app_router.dart` (shell route with bottom nav)

**When finished with v0.1:** Update current version to **v0.2** in README and this file.

---

## v0.2 — Core UI

**Estimated time:** ~1.5 weeks  
**Goal:** Build main navigation and basic transaction flow.

- [ ] onboarding for account manual input no sing up for google or something (privacy matter)
- [x] Main scaffold + BottomNavigationBar (4 tabs: Home, Transactions, Reports, Budgets)
- [x] Home screen:
  - Balance card
  - Income/Expense summary cards
  - Recent transactions list
  - Floating Action Button
- [ ] Transaction list screen (grouped by date)
- [ ] Add transaction screen (expense/income toggle, amount, category, account, date, note)
- [ ] Form validation + error snackbars
- [ ] Swipe to delete transaction with undo snackbar
- [ ] Empty states for transaction list and first-launch home
- [ ] Seed default categories on first launch

---

## v0.3 — Categories & Filters

**Estimated time:** ~1 week

- [ ] Categories management screen (list, add, edit, delete)
- [ ] Icon + color picker for categories
- [ ] Filter bar (All / Income / Expense / date range / category)
- [ ] Date range picker (month picker + custom range)
- [ ] Transaction detail screen (view + edit in-place)
- [ ] Search bar on transaction list (SQL LIKE query)

---

## v0.4 — Reports & Charts

**Estimated time:** ~1 week

- [ ] Reports screen with tab bar (Overview / By Category / Trend)
- [ ] Summary statistic cards (income, expense, net saved)
- [ ] Monthly bar chart using fl_chart
- [ ] Category pie chart using fl_chart
- [ ] Trend line chart using fl_chart
- [ ] Add SQL aggregation queries to TransactionDao (GROUP BY, SUM, running totals)

---

## v0.5 — Budgets & Notifications

**Estimated time:** ~1 week

- [ ] Budgets screen with progress bars (green/amber/red)
- [ ] Add/Edit budget screen (category, limit, period, alert threshold)
- [ ] Budget progress calculation logic in provider
- [ ] Set up `flutter_local_notifications` + notification channels
- [ ] Budget alert notifications (when crossing threshold)
- [ ] Recurring transaction reminders

---

## v0.6 — CSV + PDF Export

**Estimated time:** ~1 week

- [ ] Export screen (date range, type, category filters + preview count)
- [ ] Implement CSV export in `ExportService`
- [ ] Implement styled PDF export in `ExportService`
- [ ] Configure FileProvider in Android resources
- [ ] Test sharing to Gmail, WhatsApp, Google Drive, Downloads

---

## v0.7 — Google Pay Capture

**Estimated time:** ~1.5 weeks

- [ ] Add NotificationListenerService to AndroidManifest
- [ ] Integrate `flutter_notification_listener` + Isolate setup
- [ ] Create notification permission onboarding screen
- [ ] Build GPay notification parser (regex for amount + merchant)
- [ ] Set up pending transactions Hive box
- [ ] Create capture bottom sheet (smart category suggestion)
- [ ] Implement merchant → category mapping
- [ ] Add duplicate detection (hashing)
- [ ] Add pending banner on Home screen
- [ ] Prepare Play Store disclosure for Notification Listener

---

## v1.0 — Polish & Release

**Estimated time:** ~1 week

- [ ] Biometric lock using `local_auth` (with PIN fallback)
- [ ] Onboarding flow (3 screens: welcome, currency picker, permissions)
- [ ] Full dark mode implementation + persistence
- [ ] App icon + splash screen (flutter_native_splash)
- [ ] Complete Settings screen
- [ ] Robust error handling across the app
- [ ] Unit tests (at least TransactionDao, ExportService, GPay parser)
- [ ] Prepare Play Store assets (screenshots, feature graphic, descriptions, privacy policy)

---

## How to Use This TODO

1. Work on one version at a time.
2. Check off tasks as you complete them (`- [x]`).
3. When you finish all tasks in a version:
   - Mark the whole section as done.
   - Update **Current Version** at the top.
   - Move to the next version.
4. You can track your progress by counting checked boxes.

---

**Tip:** After finishing v0.1, run the app to verify the skeleton works before moving to UI.

Good luck! 🚀

You can now start working on **v0.1 — Foundation**.

Would you like me to create a more detailed step-by-step guide specifically for **v0.1** (with code structure hints) to help you complete it faster?
