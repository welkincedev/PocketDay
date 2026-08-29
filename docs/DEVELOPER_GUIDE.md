# PocketDay — Developer Guide

A practical guide for developers working on or learning the PocketDay codebase.

---

## What is PocketDay?

PocketDay is a personal money manager Flutter app. It is **offline-first** — all data is stored locally on the device using **Hive**. There is no server or cloud backend (Firebase sync is a future phase).

---

## Project Structure

```
lib/
├── core/                    # Shared infrastructure
│   ├── constants/           # AppColors, AppStrings, AppConstants
│   ├── routes/              # Named route definitions (AppRoutes)
│   ├── services/            # HiveService (persistence init + getters)
│   ├── theme/               # AppTheme, ThemeProvider (Riverpod)
│   ├── utils/               # CurrencyFormatter, DateFormatter
│   └── widgets/             # Reusable UI: AppButton, AppCard, AppTextField, etc.
│
├── data/
│   ├── models/              # Plain Dart data classes: TransactionModel, GoalModel, BudgetModel
│   └── repositories/        # Hive read/write: TransactionRepository, GoalRepository, BudgetRepository
│
└── features/
    ├── auth/                # Onboarding, Login, Register, ForgotPassword
    ├── budget/              # Budget screen, Budget provider
    ├── dashboard/           # Home screen, DashboardProvider, balance card widgets
    ├── goals/               # Goals screen, GoalDetail, GoalsProvider
    ├── profile/             # Profile settings screen
    └── transactions/        # Transactions list, filters, TransactionsProvider
```

---

## Architecture

PocketDay uses **Feature-First MVVM + Repository Pattern**:

```
UI (Widget / View)
     │
     │ ref.watch / ref.read
     ▼
Provider / Notifier   (lib/features/*/providers/)
     │
     │ calls
     ▼
Repository            (lib/data/repositories/)
     │
     │ reads / writes
     ▼
Hive Box              (local SQLite-like storage)
```

- **Widgets** render state and dispatch user actions.
- **Providers / Notifiers** hold application state (Riverpod `StateNotifier`).
- **Repositories** encapsulate all Hive I/O — notifiers never call Hive directly.
- **Models** are plain Dart classes — no Flutter, no Riverpod, no Hive.

---

## State Management: Riverpod

All state is managed by **Riverpod providers** (`flutter_riverpod`).

Key providers:

| Provider | File | Purpose |
|---|---|---|
| `authProvider` | `features/auth/providers/auth_provider.dart` | Auth state (logged-in user) |
| `dashboardProvider` | `features/dashboard/providers/dashboard_provider.dart` | Monthly income/expense totals |
| `transactionsProvider` | `features/transactions/providers/transactions_provider.dart` | Full transaction list + filters |
| `budgetProvider` | `features/budget/providers/budget_provider.dart` | Budget CRUD + monthly progress |
| `goalsProvider` | `features/goals/providers/goals_provider.dart` | Goals CRUD + transaction-derived balance |
| `themeProvider` | `core/theme/theme_provider.dart` | Dark / Light mode |

---

## Persistence: Hive

Hive is used as the local key-value / list store. All boxes are opened once at app start in `HiveService.init()`.

| Box name | Key in AppConstants | Contents |
|---|---|---|
| `settingsBox` | `AppConstants.settingsBox` | isDarkMode, hasOnboarded |
| `userBox` | `AppConstants.userBox` | Logged-in user data |
| `transactionsBox` | `AppConstants.transactionsBox` | List of `TransactionModel` |
| `budgetBox` | `AppConstants.budgetBox` | `BudgetModel` (single document) |
| `goalsBox` | `AppConstants.goalsBox` | List of `GoalModel` |

**Data format**: Models are serialised to `Map<String, dynamic>` and stored as Hive map values under UUID keys.

---

## Data Flow: Adding a Transaction

```
User fills AddTransactionBottomSheet
         │
         │  calls repo.addTransaction(txn)
         ▼
TransactionRepository.addTransaction()
         │
         │  writes Map<String,dynamic> to Hive transactionsBox
         ▼
Hive (local storage)
         │
         │  onAdd callback triggers provider refresh
         ▼
transactionsProvider.loadTransactions()
         │
         │  reads updated list from Hive
         ▼
UI rebuilds:  TransactionsScreen, DashboardScreen, GoalsScreen (if goalId linked)
```

---

## Data Flow: Goal Balance Calculation

Goals never store a current balance. It is always derived from transactions:

```
GoalsProvider watches transactionsProvider
         │
         │  When transactions change, GoalsProvider rebuilds
         ▼
GoalModelExtensions.calculateCurrentAmount(transactions)
         │
         │  contributions (income + goalId match) - expenses (expense + goalId match)
         ▼
GoalCard, GoalDetailScreen render correct balance without extra API calls
```

**Rule**: An expense linked to a goal (`transaction.goalId == goal.id`) counts normally toward Dashboard totals AND reduces the goal balance. This is intentional — goal spending is real spending.

---

## Data Flow: Budget Progress

```
BudgetModel  (from budgetProvider)
         +
TransactionModel list (expenses this month, from transactionsProvider)
         │
         │  monthly spend per category
         ▼
BudgetProgressWidget / CategoryBudgetProgressWidget
```

---

## Navigation / Routing

Named routes are defined in `AppRoutes` (`core/routes/app_router.dart`).

The main shell uses `IndexedStack` so each tab preserves its scroll position:

| Index | Tab |
|---|---|
| 0 | Dashboard (Home) |
| 1 | Transactions |
| 2 | Budget |
| 3 | Goals |
| 4 | Profile |

Navigation within the shell is controlled by `navigationProvider` (a simple `StateProvider<int>`).

---

## Theme System

- Dark/Light mode is persisted to Hive via `ThemeProvider`.
- All colours come from `AppColors` (dark and light variants).
- Typography comes from `AppTheme` (`core/theme/app_theme.dart`) which configures `ThemeData`.
- Do not hardcode colours or sizes in widget files — use `Theme.of(context)` or `AppColors`.

---

## Common Commands

```bash
# Install/sync packages
flutter pub get

# Analyse for errors and warnings (should return "No issues found")
flutter analyze

# Run all unit tests
flutter test

# Run the app in debug mode (hot reload enabled)
flutter run

# Build Android APK (release)
flutter build apk --release

# Build for web
flutter build web
```

---

## Development Workflow

1. `git pull` — get latest changes
2. `flutter pub get` — sync packages
3. `flutter analyze` — confirm clean baseline
4. Make your changes
5. `flutter test` — verify tests pass
6. `flutter run` — test on device/emulator
7. Check both **dark mode** and **light mode**
8. Test on a **360×800** screen (smallest common Android)
9. Commit with a descriptive message

---

## Adding a New Feature

Follow the pattern of Goals or Budget:

1. Create a model in `lib/data/models/`.
2. Create a repository in `lib/data/repositories/`.
3. Create a provider in `lib/features/<feature>/providers/`.
4. Create views in `lib/features/<feature>/views/`.
5. Create widgets in `lib/features/<feature>/widgets/`.
6. Register any new Hive box in `HiveService.init()` and `AppConstants`.
7. Add navigation entry to `app_router.dart` or `main_shell_screen.dart`.
8. Write unit tests in `test/`.

---

## Known Gotchas

- **Goal-linked expenses**: A transaction with `goalId != null` is still a normal expense globally. Do not filter it out of Dashboard or Budget calculations.
- **Hive box names**: Must match exactly between `HiveService.init()`, `AppConstants`, and repository code. A mismatch causes a runtime exception.
- **Riverpod ConsumerWidget vs ConsumerStatefulWidget**: Use `ConsumerWidget` for stateless/read-only views. Use `ConsumerStatefulWidget` when you need local state (forms, animations).
- **`mounted` checks**: After any `async` call that may pop the widget, always check `if (mounted)` before calling `context` or `Navigator`.
