# 🚀 PocketDay — Smart Personal Finance Manager

PocketDay is a modern, offline-first personal finance application built with **Flutter** and **Dart**. Designed with Google's **Material 3** design system, it delivers a minimal, clean, and intuitive experience for tracking income, managing expenses, monitoring category budget limits, tracking savings goals, and automating recurring subscription expenses in Indian Rupees (`₹`).

---

## 🌟 Key Features

- 💼 **Total Balance & Financial Summary**: Real-time balance calculations (`Total Balance = Income - Expense`) with hide/show privacy toggle mode (`₹••••••`).
- 💳 **Transactions Management**: Complete support for income and expense transactions, category tagging, goal allocations, custom date ranges, search, and filtering.
- 📊 **Spending Analytics**: Interactive PieChart and bar previews powered by `fl_chart` illustrating category breakdowns and income vs. expense ratios.
- 🎯 **Savings Goals**: Target tracking with visual progress indicators, goal-linked expense allocations, and contribution history.
- 🔄 **Subscriptions Engine**: Recurring subscription tracking across weekly, monthly, and yearly cycles with idempotent automatic expense generation.
- 📈 **Category Budget System**: Monthly overall and category-specific budget limits with dynamic warning states (Safe, Warning, Critical, Exceeded).
- 🌓 **Dynamic Light & Dark Themes**: Material 3 theme customization using Google Fonts (`Outfit` for titles, `Inter` for body text).
- ⚡ **Offline-First Local Storage**: Powered by **Hive**, storing user profile, settings, transactions, budgets, goals, and subscriptions locally with instant launch speeds.

---

## 🛠️ Tech Stack & Architecture

- **Frontend Framework**: [Flutter](https://flutter.dev) (Latest Stable)
- **Language**: [Dart](https://dart.dev)
- **Architecture**: Clean Layered Architecture (UI → Riverpod Notifiers → Repositories → Hive Storage)
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) with `StatefulShellRoute` for tab state preservation
- **Local Storage Engine**: [Hive](https://pub.dev/packages/hive_flutter)
- **Charts & Data Visualization**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Design System**: Material 3 (M3)

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── constants/       # AppColors, AppConstants (₹), AppStrings
│   ├── theme/           # AppTheme (M3 Light & Dark), ThemeProvider
│   ├── routes/          # AppRouter (GoRouter setup with StatefulShellRoute)
│   ├── services/        # HiveService (Hive boxes initializer)
│   ├── utils/           # CurrencyFormatter (en_IN), DateFormatter
│   └── widgets/         # AppButton, AppTextField, AppCard, BalanceDisplayWidget, SkeletonLoader, EmptyStateWidget, ErrorView
├── data/
│   ├── models/          # UserModel, TransactionModel, BudgetModel, GoalModel, SavingsGoalModel, SubscriptionModel
│   └── repositories/    # AuthRepository, TransactionRepository, BudgetRepository, GoalRepository, SavingsGoalRepository, SubscriptionRepository
├── features/
│   ├── auth/            # Splash, Onboarding, Login, Register, Forgot Password
│   ├── dashboard/       # DashboardScreen, MainShellScreen, DashboardCard, SpendingChart, CategoryBudgetProgress, AddTransactionBottomSheet
│   ├── transactions/    # TransactionsScreen, Filter & Detail Bottom Sheets
│   ├── budget/          # BudgetScreen, Add & Detail Bottom Sheets
│   ├── goals/           # GoalsScreen, SavingsGoalsScreen, Create & Edit Sheets
│   ├── subscriptions/   # SubscriptionsScreen, Add & Detail Sheets
│   └── profile/         # ProfileScreen (Theme toggle, Privacy settings, User info)
└── main.dart            # Application entry point & ProviderScope
```

---

## 🚀 Developer Commands & Execution

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.22.0 or higher)
- [Dart SDK](https://dart.dev/get-started) (v3.4.0 or higher)

### Setup & Run
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static code analysis (0 warnings/errors expected)
flutter analyze

# 3. Format code
dart format lib test

# 4. Run full unit and integration test suite
flutter test

# 5. Run local app (Chrome / Android / Windows)
flutter run -d chrome
flutter run -d android
flutter run -d windows
```

### Production Release Builds
```bash
# Build Release Android APK
flutter build apk --release

# Build Release Android App Bundle (AAB)
flutter build appbundle --release

# Build Web Bundle
flutter build web --release
```

---

## 📚 Technical Documentation

Detailed architecture and audit documentation is available in the [`docs/`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/docs/) directory:
- [`docs/FINAL_PROJECT_AUDIT.md`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/docs/FINAL_PROJECT_AUDIT.md) — Comprehensive health, risk, and stability audit.
- [`docs/ARCHITECTURE.md`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/docs/ARCHITECTURE.md) — System layer contracts and data flow.
- [`docs/FIREBASE_MIGRATION_ASSESSMENT.md`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/docs/FIREBASE_MIGRATION_ASSESSMENT.md) — Hive vs. Firebase comparison & future sync blueprint.
- [`docs/RELEASE_CHECKLIST.md`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/docs/RELEASE_CHECKLIST.md) — Release gate checklist and deployment verification.
