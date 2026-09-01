# 🚀 PocketDay — Smart Personal Finance Manager

PocketDay is a modern, Firebase-first personal money manager built with **Flutter**, **Riverpod**, and **Cloud Firestore**. Designed with Google's **Material 3** design system, it delivers a minimal, clean, and intuitive experience for tracking income, managing expenses, monitoring category budget limits, tracking savings goals, and automating recurring subscription expenses in Indian Rupees (`₹`).

---

## 🌟 Core Features

- 🔑 **Google Authentication**: Instant, single-click sign-in powered by Firebase Authentication and Google Sign-In.
- 💼 **Total Balance & Summary**: Real-time balance calculations (`Total Balance = Income - Expense`) with hide/show privacy mode (`₹••••••`).
- 💳 **Transaction Management**: Complete support for income and expense transactions, category tagging, date filtering, and search.
- 📊 **Spending Analytics**: Breakdown pie charts powered by `fl_chart` illustrating category expenses.
- 🎯 **Savings Goals**: Goal tracking with progress indicators, contributions, and target completion dates.
- 🔄 **Subscriptions Engine**: Recurring subscription tracking with idempotent automatic expense generation.
- 📈 **Category Budget Limits**: Monthly budget limits with dynamic warning indicators (Safe, Warning, Critical, Exceeded).
- ⚙️ **Account Data Management**: Full user controls for **Reset App Data**, **Delete Account**, and **Sign Out**.
- ⚡ **Offline-First Persistence**: Native Cloud Firestore offline caching for instant launch and offline read/write capability.
- 🌐 **Web & Mobile Support**: Native support for Android (APK / AAB) and Web (`signInWithPopup`).

---

## 🛠️ Tech Stack & Architecture

- **Frontend Framework**: [Flutter](https://flutter.dev) (v3.22+)
- **Language**: [Dart](https://dart.dev) (v3.4+)
- **Architecture**: Clean Feature-First MVVM / Repository Architecture
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **Backend & Auth**: Firebase Authentication & Google Sign-In
- **Database Engine**: Cloud Firestore with Native Offline Cache (**Hive is completely removed**)
- **Data Visualization**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Design System**: Material 3 (M3)

---

## 🏗️ High-Level Architecture

```text
Google Account
      ↓
Firebase Authentication
      ↓
Firebase User UID
      ↓
Cloud Firestore (users/{uid})
      ↓
Firestore Native Offline Cache
      ↓
Riverpod State Notifiers
      ↓
PocketDay Flutter UI
```

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── constants/       # AppColors, AppConstants (₹), AppStrings
│   ├── theme/           # AppTheme (M3 Light & Dark), ThemeProvider
│   ├── routes/          # AppRouter named routes table
│   ├── utils/           # AppErrorHandler, CurrencyFormatter, DateFormatter
│   └── widgets/         # AppButton, AppTextField, AppCard, ErrorView, AppErrorScreen
├── data/
│   ├── models/          # UserModel, TransactionModel, BudgetModel, GoalModel, SubscriptionModel
│   └── repositories/    # AuthRepository, TransactionRepository, BudgetRepository, GoalRepository, SubscriptionRepository
├── features/
│   ├── auth/            # Splash, Onboarding, LoginScreens
│   ├── dashboard/       # DashboardScreen, AppMainNavigationScreen, DashboardCards, AnalyticsChart
│   ├── transactions/    # TransactionsScreen, Search & Filter BottomSheets
│   ├── budget/          # BudgetScreen (Budget & Subscriptions Tabs), Add & Detail Sheets
│   ├── goals/           # GoalsScreen, SavingsGoalsScreen
│   ├── subscriptions/   # SubscriptionsScreen, SubscriptionsContent, Add & Detail Sheets
│   └── profile/         # ProfileScreen (Theme, Reset, Delete Account, Sign Out)
└── main.dart            # Entry point & Firestore offline settings initializer
```

---

## 🚀 Developer Commands

### Setup & Run
```bash
# Fetch dependencies
flutter pub get

# Static analysis
flutter analyze

# Run unit & provider tests
flutter test

# Run application
flutter run -d android
flutter run -d chrome
```

### Release Builds
```bash
# Build Release Universal APK
flutter build apk --release

# Build Split per-ABI APKs
flutter build apk --release --split-per-abi

# Build Release Android App Bundle (AAB)
flutter build appbundle --release

# Build Web Bundle
flutter build web
```

---

## 🔒 Security

All Firestore security rules enforce user isolation via Firebase UID:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 📚 Documentation Suite

Comprehensive architecture and developer documentation is available in the [`docs/`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/docs/) directory:
- [`docs/project_overview.md`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/docs/project_overview.md) — Product identity, feature inventory, platforms, and release status.
- [`docs/architecture.md`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/docs/architecture.md) — Layered architecture, Riverpod system, Firestore structure, security, and error handling.
- [`docs/developer_guide.md`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/docs/developer_guide.md) — Prerequisites, build guide, development patterns, and release checklist.
- [`docs/release_checklist.md`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/docs/release_checklist.md) — Pre-release verification report and subsystem checklist.
- [`docs/test_plan.md`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/docs/test_plan.md) — Physical device and web manual test protocol.

---

## 📌 Release Status

- **Status**: READY FOR TEST RELEASE
- **Version**: 1.0.0+1
- **Analyze**: 0 Issues (Clean)
- **Tests**: 30/30 Passed
