# POCKETDAY — THE COMPLETE PROJECT TEXTBOOK & TECHNICAL DOCUMENTATION

---

## TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [Architecture & Design Patterns](#2-architecture--design-patterns)
3. [File-by-File Technical Documentation](#3-file-by-file-technical-documentation)
   - [3.1 Entry & Core Infrastructure](#31-entry--core-infrastructure)
   - [3.2 Constants, Utilities & Services](#32-constants-utilities--services)
   - [3.3 Reusable Core Widgets](#33-reusable-core-widgets)
   - [3.4 Data Models](#34-data-models)
   - [3.5 Data Repositories](#35-data-repositories)
   - [3.6 Authentication Feature](#36-authentication-feature)
   - [3.7 Dashboard & Navigation Shell Feature](#37-dashboard--navigation-shell-feature)
   - [3.8 Transactions Feature](#38-transactions-feature)
   - [3.9 Budget Feature](#39-budget-feature)
   - [3.10 Goals Feature](#310-goals-feature)
   - [3.11 Subscriptions Feature](#311-subscriptions-feature)
   - [3.12 Profile Feature](#312-profile-feature)
4. [Page / Screen Detailed Specifications](#4-page--screen-detailed-specifications)
5. [Data Flow Chapter](#5-data-flow-chapter)
6. [Data Storage Chapter (Firestore Native Cache vs Hive Audit)](#6-data-storage-chapter-firestore-native-cache-vs-hive-audit)
7. [Firebase & Cloud Firestore Chapter](#7-firebase--cloud-firestore-chapter)
8. [Dependencies & Technology Stack](#8-dependencies--technology-stack)
9. [Dart Fundamentals Used in PocketDay](#9-dart-fundamentals-used-in-pocketday)
10. [Flutter Fundamentals Used in PocketDay](#10-flutter-fundamentals-used-in-pocketday)
11. [State Management Chapter (Riverpod Notifiers & AsyncValue)](#11-state-management-chapter-riverpod-notifiers--asyncvalue)
12. [Navigation & Routing Chapter](#12-navigation--routing-chapter)
13. [Financial Business Logic Chapter](#13-financial-business-logic-chapter)
14. [Security & Privacy Chapter](#14-security--privacy-chapter)
15. [Complete PocketDay Viva Questions & Answers](#15-complete-pocketday-viva-questions--answers)
16. [Presentation Cheat Sheet](#16-presentation-cheat-sheet)
17. [Known Issues & Technical Debt](#17-known-issues--technical-debt)
18. [Unused & Potentially Unused Code Audit](#18-unused--potentially-unused-code-audit)
19. [Final Audit Summary & Statistics](#19-final-audit-summary--statistics)

---

# 1. PROJECT OVERVIEW

**PocketDay** is a production-grade, personal financial management application built with **Flutter**, **Dart**, **Riverpod**, and **Firebase (Authentication & Cloud Firestore)**.

### Target Audience & Core Value Proposition
Many personal finance applications are overly complicated, force rigid category schemes, require constant active internet connectivity, or hide core analytics behind paywalls. PocketDay resolves these pain points by delivering a clean, light-mode-only, zero-lag personal money manager that gives users instant clarity on:
- **Total Net Balance** ($\text{Total Income} - \text{Total Expense}$)
- **Monthly Spending Velocity vs Category Budgets**
- **Survival Days Runway Metric**: Dynamically calculates how many days current liquid funds will last based on active daily spending velocity ($\frac{\text{Liquid Balance}}{\text{Daily Velocity}}$).
- **Safe Daily Spend**: Calculates exact daily spending allowance for the rest of the month without exceeding monthly budget ($\frac{\text{Remaining Budget}}{\text{Remaining Days}}$).
- **Savings Goals Milestones**: Tracks progress toward long-term savings goals with auto-impact calculation.
- **Recurring Subscriptions**: Automates recurring payment tracking with date-aware month-end logic and idempotent auto-expense creation.

---

# 2. ARCHITECTURE & DESIGN PATTERNS

PocketDay strictly implements a **Feature-First, MVVM (Model-View-ViewModel) + Repository Pattern** architecture.

```
┌─────────────────────────────────────────────────────────┐
│                      VIEW (UI Layer)                     │
│    (Screens, Modal Bottom Sheets, Reusable Widgets)     │
└────────────────────────────┬────────────────────────────┘
                             │ Watches / Reads / Listens
                             ▼
┌─────────────────────────────────────────────────────────┐
│              VIEWMODEL / PROVIDER (State Layer)         │
│     (AuthNotifier, TransactionsNotifier, BudgetNotifier) │
└────────────────────────────┬────────────────────────────┘
                             │ Invokes Operations
                             ▼
┌─────────────────────────────────────────────────────────┐
│                 REPOSITORY (Data Layer)                 │
│   (AuthRepository, TransactionRepository, BudgetRepo)   │
└────────────────────────────┬────────────────────────────┘
                             │ Performs CRUD & Sync
                             ▼
┌─────────────────────────────────────────────────────────┐
│            DATA SOURCES & STORAGE (Persistence)         │
│ (Cloud Firestore Native Offline Cache + Firebase Auth)  │
└────────────────────────────┴────────────────────────────┘
```

### Layer Responsibilities
1. **Model (`lib/data/models/`)**: Immutable data entities (e.g., `TransactionModel`, `BudgetModel`, `GoalModel`). They handle JSON serialization (`toMap`/`fromMap`), financial metric calculations, and immutability helpers (`copyWith`).
2. **Repository (`lib/data/repositories/`)**: Abstracts data operations. Communicates directly with Cloud Firestore and Firebase Auth SDKs, enforcing UID data isolation, local offline disk fallback, and chunked batch operations.
3. **ViewModel / Provider (`lib/features/*/providers/`)**: Manages state using Riverpod (`StateNotifier`). Executes business logic, maintains loading/error states (`AsyncValue`), and exposes reactive streams to the UI.
4. **View (`lib/features/*/views/` & `widgets/`)**: Pure UI components. Listens to providers via `ref.watch()`, dispatches user actions via `ref.read()`, and renders responsive Material 3 layouts.

---

# 3. FILE-BY-FILE TECHNICAL DOCUMENTATION

Below is the code-verified technical documentation for every Dart file in `lib/`.

---

## 3.1 Entry & Core Infrastructure

### 1. `lib/main.dart`
- **File Location**: `lib/main.dart`
- **File Type**: Application Entry Point
- **Purpose**: Initializes Flutter bindings, Firebase SDK, Cloud Firestore unlimited offline cache, and mounts `PocketDayApp` inside Riverpod's `ProviderScope`.
- **Responsibilities**:
  - Call `WidgetsFlutterBinding.ensureInitialized()`.
  - Execute `Firebase.initializeApp()`.
  - Configure `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)`.
  - Render `MaterialApp` with `AppTheme.lightTheme` and `AppRoutes.splash`.
- **Basic Code Structure**:
  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {}
    runApp(const ProviderScope(child: PocketDayApp()));
  }
  ```
- **Classes**: `PocketDayApp` (`ConsumerWidget`).
- **Main Properties**: `initialRoute` (`String?`).
- **Data Flow**: OS Launch → `main()` → Firebase Init → `ProviderScope` → `PocketDayApp` → `SplashScreen`.
- **Dependencies**: `firebase_core`, `cloud_firestore`, `flutter_riverpod`, `app_theme.dart`, `app_router.dart`.
- **State Management**: Wrapped in `ProviderScope`.
- **Navigation**: Sets `initialRoute` to `AppRoutes.splash` (`/`).
- **Viva Q&A**:
  - *Q: Why is `WidgetsFlutterBinding.ensureInitialized()` necessary?*
    **Answer**: It initializes the engine-to-framework binary messenger before platform channel plugin calls are made.

### 2. `lib/firebase_options.dart`
- **File Location**: `lib/firebase_options.dart`
- **File Type**: Platform Configuration Utility
- **Purpose**: Provides platform-specific `FirebaseOptions` credentials for Web, Android, and iOS.
- **Classes**: `DefaultFirebaseOptions`.
- **Methods**: `currentPlatform` getter.

---

## 3.2 Constants, Utilities & Services

### 3. `lib/core/constants/app_colors.dart`
- **File Type**: Theme Palette Constants
- **Purpose**: Stores static color constants for light mode UI (`primary = 0xFF10B981`, `lightBackground = 0xFFF8FAFC`, `income`, `expense`).

### 4. `lib/core/constants/app_constants.dart`
- **File Type**: Application Constants
- **Purpose**: Defines transaction categories, default budget values, and storage keys.

### 5. `lib/core/constants/app_strings.dart`
- **File Type**: String Constants
- **Purpose**: Centralizes UI headings, onboarding text, button labels, and error messages.

### 6. `lib/core/routes/app_router.dart`
- **File Type**: Navigation Route Registry
- **Purpose**: Named route mapping strings to feature screens (`/`, `/onboarding`, `/login`, `/main`, `/profile`, `/subscriptions`).

### 7. `lib/core/theme/app_theme.dart`
- **File Type**: Material 3 Theme Definition
- **Purpose**: Configures Material 3 light theme (`Outfit` font family, input decoration, card styling, app bar theme).

### 8. `lib/core/theme/theme_provider.dart`
- **File Type**: Theme Notifier Provider
- **Purpose**: Manages app `ThemeMode` state (`ThemeNotifier`), enforcing light mode (`isDarkMode => false`).

### 9. `lib/core/utils/app_error_handler.dart`
- **File Type**: Exception Mapping Utility
- **Purpose**: Converts technical exceptions (e.g. Firebase error codes) into user-friendly UI messages.

### 10. `lib/core/utils/currency_formatter.dart`
- **File Type**: Currency Formatting Utility
- **Purpose**: Formats double values into Indian Rupee (`₹`) string representations using `intl` (`en_IN` locale).
- **Snippet**:
  ```dart
  static String format(double amount, {bool showSymbol = true, int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: showSymbol ? '₹' : '',
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }
  ```

### 11. `lib/core/utils/date_formatter.dart`
- **File Type**: Date Formatting Utility
- **Purpose**: Formats `DateTime` into strings ("09 Sep 2026", "Sep 2026", "Today", "Yesterday").

---

## 3.3 Reusable Core Widgets

### 12-20. Core UI Components (`lib/core/widgets/`)
- `app_button.dart`: Custom button supporting Primary, Outline, Danger, and Google OAuth variants with progress spinners.
- `app_card.dart`: Container card with subtle border and padding.
- `app_error_screen.dart`: Fallback error route screen.
- `app_text_field.dart`: Labeled input field with password show/hide toggle.
- `balance_display_widget.dart`: Metric display widget for balance, income, expense.
- `empty_state_widget.dart`: Friendly placeholder widget for empty lists.
- `error_view.dart`: Inline error alert banner.
- `pocketday_logo.dart`: Brand mark logo widget rendering `assets/images/app_logo.png`.
- `skeleton_loader.dart`: Animated shimmer loader widget.

---

## 3.4 Data Models

### 21. `lib/data/models/user_model.dart`
- **Purpose**: Immutable user entity (`uid`, `email`, `displayName`, `photoUrl`, `createdAt`).

### 22. `lib/data/models/transaction_model.dart`
- **Purpose**: Transaction data entity (`id`, `userId`, `amount`, `title`, `category`, `type`, `date`, `note`, `goalId`).

### 23. `lib/data/models/budget_model.dart`
- **Purpose**: Monthly budget entity (`id`, `userId`, `monthYear`, `overallLimit`, `categoryLimits`).

### 24. `lib/data/models/goal_model.dart`
- **Purpose**: Goal entity calculating progress percentage (`currentAmount / targetAmount`) and remaining balance.

### 25. `lib/data/models/savings_goal_model.dart`
- **Purpose**: Alternative milestone model tracking target date and current balance.

### 26. `lib/data/models/subscription_model.dart`
- **Purpose**: Models recurring subscriptions (`billingCycle`, `nextPaymentDate`, `autoCreateExpense`).
- **Key Logic**: `monthlyEquivalent` normalizes weekly (`* 4.33`), yearly (`/ 12`), or monthly commitments. `calculateNextPaymentDate()` handles month-end leap years safely.

---

## 3.5 Data Repositories

### 27. `lib/data/repositories/auth_repository.dart`
- **Purpose**: Interacts with Firebase Auth and Firestore `users/{uid}` collection.
- **Key Methods**: `getCurrentUser()` (0ms local token check), `loginWithGoogle()`, `logout()`, `resetAppData()` (chunked 400-doc Firestore batch deletions), `deleteAccount()`.

### 28-32. Feature Repositories (`lib/data/repositories/`)
- `transaction_repository.dart`: Firestore CRUD for `users/{uid}/transactions`.
- `budget_repository.dart`: Firestore CRUD for `users/{uid}/budgets`.
- `goal_repository.dart`: Firestore CRUD for `users/{uid}/goals`.
- `savings_goal_repository.dart`: Firestore CRUD for `users/{uid}/savings_goals`.
- `subscription_repository.dart`: Firestore CRUD for `users/{uid}/subscriptions` and idempotent auto-expense creation.

---

## 3.6 Authentication Feature

### 33. `lib/features/auth/providers/auth_provider.dart`
- **Purpose**: Manages authentication state (`AsyncValue<UserModel?>`) via `AuthNotifier`.

### 34. `lib/features/auth/views/splash_screen.dart`
- **Purpose**: Initial screen (`/`). Paints logo on frame 1, executes a concurrent 3-second presentation window (`Future.wait`) alongside local `SharedPreferences` onboarding check and cached `FirebaseAuth` token check before routing.

### 35. `lib/features/auth/views/onboarding_screen.dart`
- **Purpose**: 3-page introduction (`PageView`). Saves `has_completed_onboarding = true` in `SharedPreferences` upon completion/skip.

### 36. `lib/features/auth/views/login_screen.dart`
- **Purpose**: Product landing page and Google OAuth entry point. Includes logo, value proposition, single-tap `Continue with Google` button with tap-guard protection, and instant navigation to `/main`.

### 37-38. `register_screen.dart` & `forgot_password_screen.dart`
- **Purpose**: Form views preserved for secondary authentication capabilities.

---

## 3.7 Dashboard & Navigation Shell Feature

### 39. `lib/features/dashboard/providers/navigation_provider.dart`
- **Purpose**: Stores active tab index (0 to 4).

### 40. `lib/features/dashboard/providers/dashboard_provider.dart`
- **Purpose**: Computes derived metrics in memory ($O(N)$ speed): Total Balance, Monthly Income, Monthly Expense, Survival Days, Safe Daily Spend. Listens to `transactionsProvider` and `budgetProvider` via `ref.listen()`.

### 41. `lib/features/dashboard/views/app_main_navigation_screen.dart`
- **Purpose**: Root shell with `NavigationBar` (5 tabs) and `IndexedStack`. Uses a lazy `_visitedIndices` set so only Tab 0 (Home) mounts on app startup; other tabs instantiate lazily upon tap.

### 42. `lib/features/dashboard/views/dashboard_screen.dart`
- **Purpose**: Main overview screen displaying greeting, balance card, survival days pill, spending velocity chart (`fl_chart`), category progress, and recent activity.

### 43-50. Dashboard Widgets (`lib/features/dashboard/widgets/`)
- `add_transaction_bottom_sheet.dart`: Form for logging expenses/income.
- `category_budget_progress_widget.dart`: Progress bars for category budgets.
- `dashboard_budget_progress_widget.dart`: Overall monthly budget progress bar.
- `dashboard_card_widget.dart`: Hero balance display card.
- `dashboard_savings_summary_widget.dart`: Savings goals overview card.
- `quick_actions_widget.dart`: FABs for Add Income and Add Expense.
- `spending_chart_widget.dart`: Bar chart (`fl_chart`) showing monthly spending velocity.
- `transaction_item_tile.dart`: Standardized tile rendering single transaction details.

---

## 3.8 Transactions Feature

### 51-54. Transactions Component Stack (`lib/features/transactions/`)
- `transactions_provider.dart`: StateNotifier owning transaction list, search query, and category filters.
- `transactions_screen.dart`: Tab 1 view rendering search bar, filter chips, and grouped transaction history list.
- `transaction_detail_bottom_sheet.dart`: Detail modal for transaction viewing/editing/deletion.
- `transactions_filter_bottom_sheet.dart`: Modal filter for category and transaction type.

---

## 3.9 Budget Feature

### 55-59. Budget Component Stack (`lib/features/budget/`)
- `budget_provider.dart`: StateNotifier managing monthly budget targets (`BudgetModel`).
- `budget_screen.dart`: Tab 2 dual-tab view (Tab 0: Budget Limits, Tab 1: Subscriptions). Always defaults to Tab 0.
- `add_budget_bottom_sheet.dart`, `budget_card_widget.dart`, `budget_detail_bottom_sheet.dart`.

---

## 3.10 Goals Feature

### 60-71. Goals Component Stack (`lib/features/goals/`)
- `goals_provider.dart` & `savings_goals_provider.dart`: Manage savings goals and linked transaction contribution progress.
- `savings_goals_screen.dart` (Tab 3 view) & `goal_detail_screen.dart`.
- Modal bottom sheets: `create_goal_sheet.dart`, `edit_goal_sheet.dart`, `add_to_goal_sheet.dart`, `add_savings_bottom_sheet.dart`, `add_savings_goal_bottom_sheet.dart`, `savings_goal_detail_bottom_sheet.dart`.
- Display widgets: `goal_card.dart`, `savings_goal_card.dart`, `goal_selector.dart`.

---

## 3.11 Subscriptions Feature

### 72-76. Subscriptions Component Stack (`lib/features/subscriptions/`)
- `subscription_provider.dart`: StateNotifier managing recurring subscriptions list, monthly commitments total, and idempotent auto-expense creation.
- `subscriptions_screen.dart` & `subscriptions_content.dart` (embedded inside `BudgetScreen` Tab 1).
- `subscription_card.dart` & `add_subscription_sheet.dart`.

---

## 3.12 Profile Feature

### 77-78. Profile Component Stack (`lib/features/profile/`)
- `profile_screen.dart`: Tab 4 view rendering user identity (avatar, display name, email), navigation to Subscriptions, App Metadata, and destructive action dialogs (Reset App Data, Delete Account, Sign Out).

---

# 4. PAGE / SCREEN DETAILED SPECIFICATIONS

### 1. SplashScreen (`lib/features/auth/views/splash_screen.dart`)
- **User Goal**: Frame-1 brand paint and seamless startup routing.
- **Widget Tree**: `Scaffold` → `Center` → `Column` → `PocketDayLogo` + Animated Text.
- **User Flow**: OS Launch → Splash Paints → 3s Presentation Window completes concurrent onboarding & auth checks → Route to `OnboardingScreen`, `LoginScreen`, or `DashboardScreen`.

### 2. LoginScreen (`lib/features/auth/views/login_screen.dart`)
- **User Goal**: Product landing page and single-click authentication.
- **Widget Tree**: `Scaffold` → `SafeArea` → `SingleChildScrollView` → `ConstrainedBox(400)` → `Column` → Logo → Title → Tagline → Value Proposition → Google Button → Footnote.

### 3. DashboardScreen (`lib/features/dashboard/views/dashboard_screen.dart`)
- **User Goal**: Overview of total balance, safe daily spend, survival days, spending velocity, and recent activity.
- **Widget Tree**: `Scaffold` → `SafeArea` → `RefreshIndicator` → `SingleChildScrollView` → Greeting Header → Hero Balance Card → Budget Progress → Savings Goals Summary → Quick Actions → Spending Chart → Category Progress.

---

# 5. DATA FLOW CHAPTER

```
[Native Android/Web Launch]
        │
        ▼
   [main.dart]
 (Firebase.initializeApp() + Firestore Unlimited Cache)
        │
        ▼
 [SplashScreen]
 (Paints Logo on Frame 1 + Concurrent 3-second Future.wait)
        │
   ┌────┴─────────────────────────────┐
   ▼                                  ▼
[Check SharedPreferences]    [Check FirebaseAuth Token]
 (has_completed_onboarding)   (currentUser local token)
   │                                  │
   └──────────────────┬───────────────┘
                      ▼
 ┌────────────────────┼────────────────────┐
 ▼                    ▼                    ▼
[Onboarding]     [LoginScreen]     [DashboardScreen]
(If incomplete)  (If logged out)   (If logged in)
```

---

# 6. DATA STORAGE CHAPTER (FIRESTORE NATIVE CACHE VS HIVE AUDIT)

PocketDay relies on **Cloud Firestore Native Offline Persistence**:
1. **Firestore Unlimited Cache**: Configured in `main.dart` (`cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED`). Reads execute against local disk cache in 0ms, and writes apply locally first before synchronizing with the cloud in the background.
2. **SharedPreferences**: Lightweight Key-Value storage used exclusively for `has_completed_onboarding` (boolean flag).
3. **Hive Audit Note**: Early PRD specifications mentioned Hive, but the codebase uses Cloud Firestore Native Persistence and `SharedPreferences` for zero-lag offline persistence.

---

# 7. FIREBASE & CLOUD FIRESTORE CHAPTER

### Firestore Collection Schema
```
users/ (Collection)
 └── {uid}/ (Document - User Profile)
      ├── displayName: String
      ├── email: String
      ├── photoUrl: String?
      ├── createdAt: Timestamp
      │
      ├── transactions/ (Subcollection)
      │    └── {transactionId}/
      │         ├── amount: double
      │         ├── title: String
      │         ├── category: String
      │         ├── type: "income" | "expense"
      │         ├── date: Timestamp
      │         └── goalId: String?
      │
      ├── budgets/ (Subcollection)
      │    └── {budgetId}/ (e.g., "2026-09")
      │         ├── monthYear: "2026-09"
      │         ├── overallLimit: double
      │         └── categoryLimits: Map<String, double>
      │
      ├── goals/ (Subcollection)
      │    └── {goalId}/
      │
      └── subscriptions/ (Subcollection)
           └── {subscriptionId}/
```

---

# 8. DEPENDENCIES & TECHNOLOGY STACK

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | `^2.6.1` | Reactive state management (`StateNotifierProvider`, `ref.watch`, `ref.listen`) |
| `firebase_core` | `^4.14.0` | Firebase SDK initialization |
| `firebase_auth` | `^6.6.1` | User authentication, token management, Google OAuth credential exchange |
| `cloud_firestore` | `^6.9.0` | Cloud database with unlimited offline disk persistence cache |
| `google_sign_in` | `^6.2.1` | Native Google OAuth sign-in |
| `fl_chart` | `^1.2.0` | Spending velocity bar chart |
| `google_fonts` | `^8.2.1` | Typography (`Outfit` font family) |
| `flutter_animate` | `^4.5.2` | UI entry animations |
| `shared_preferences` | `^2.5.5` | Local key-value storage for onboarding completion state |
| `intl` | `^0.20.3` | Indian Rupee currency formatting (`en_IN`) and date parsing |
| `uuid` | `^4.6.0` | Unique ID generation |
| `cupertino_icons` | `^1.0.8` | iOS iconography fallbacks |

---

# 9. DART FUNDAMENTALS USED IN POCKETDAY

- **Sound Null Safety**: `UserModel? user;` handles nullable fields safely.
- **Immutability & `copyWith`**: Models use `final` fields and return updated copies via `copyWith()`.
- **Async/Await & Futures**: Non-blocking asynchronous network and storage operations.
- **Unawaited**: Used in `AuthRepositoryImpl` to sync profile updates to Firestore in the background without stalling UI navigation.

---

# 10. FLUTTER FUNDAMENTALS USED IN POCKETDAY

- **Material 3 Light Theme**: Expressed via `ThemeData` with `useMaterial3: true` and custom light color schemes.
- **Widget Lifecycle**: `ConsumerStatefulWidget` handling `initState()`, `addPostFrameCallback`, and `dispose()`.
- **Form Validation**: `GlobalKey<FormState>` and `validator` callbacks in `AppTextField`.
- **Lazy Tab Rendering**: `IndexedStack` combined with a visited index set in `AppMainNavigationScreen`.

---

# 11. STATE MANAGEMENT CHAPTER (RIVERPOD NOTIFIERS & ASYNCVALUE)

PocketDay relies on **Riverpod**:
- **`StateNotifierProvider`**: Manages state objects (e.g., `transactionsProvider` managing `AsyncValue<List<TransactionModel>>`).
- **`ref.watch()`**: Reactively rebuilds UI widgets when state changes.
- **`ref.read()`**: Invokes methods on Notifiers inside event callbacks (e.g., button taps).
- **`ref.listen()`**: Listens to state changes without triggering rebuilds (used in `dashboardProvider` to recalculate metrics in memory when transactions update).

---

# 12. NAVIGATION & ROUTING CHAPTER

Routes are declared in `AppRoutes`:
- `/` → `SplashScreen`
- `/onboarding` → `OnboardingScreen`
- `/login` → `LoginScreen`
- `/main` → `AppMainNavigationScreen`
- `/profile` → `ProfileScreen`
- `/subscriptions` → `SubscriptionsScreen`

Transitions use `Navigator.pushReplacementNamed()` to ensure authentication screens are popped off the back-stack upon login/logout.

---

# 13. FINANCIAL BUSINESS LOGIC CHAPTER

1. **Total Balance**: $\text{Total Balance} = \sum \text{Income Amounts} - \sum \text{Expense Amounts}$
2. **Survival Days**: $\text{Survival Days} = \frac{\text{Total Liquid Balance}}{\text{Average Daily Expense Velocity}}$
3. **Safe Daily Spend**: $\text{Safe Daily Spend} = \frac{\text{Remaining Monthly Budget}}{\text{Remaining Days in Current Month}}$
4. **Subscription Normalization**: Weekly payments are multiplied by 4.33, yearly payments divided by 12, establishing uniform monthly commitments.

---

# 14. SECURITY & PRIVACY CHAPTER

- **UID Data Isolation**: Every Firestore collection path includes the authenticated user's `uid`.
- **Instant Local Auth Check**: `getCurrentUser()` inspects `FirebaseAuth.instance.currentUser` locally without network delays.
- **Chunked Data Wipe**: Account deletion and app data resets operate in 400-document batches to comply with Firestore transaction limits.

---

# 15. COMPLETE POCKETDAY VIVA QUESTIONS & ANSWERS

### Basic Flutter & Dart
- *Q1: What is the difference between `StatelessWidget` and `StatefulWidget`?*
  **Answer**: `StatelessWidget` is immutable and cannot alter its UI after building, whereas `StatefulWidget` maintains mutable `State` that can trigger UI rebuilds via `setState()`.
- *Q2: What is sound null safety in Dart?*
  **Answer**: It guarantees at compile-time that non-nullable variables cannot contain null values, preventing runtime `NullPointerExceptions`.

### Architecture & Riverpod
- *Q3: Why does PocketDay use the Repository Pattern?*
  **Answer**: It decouples the UI and state layers from the database, allowing storage implementations to change without affecting UI code.
- *Q4: What is the role of `ref.listen()` in `DashboardNotifier`?*
  **Answer**: It listens to updates in `transactionsProvider` and `budgetProvider` to trigger metric recalculations in memory without causing unnecessary widget rebuilds or extra database reads.

### Firebase & Storage
- *Q5: How does PocketDay achieve offline functionality?*
  **Answer**: It enables Cloud Firestore's unlimited native offline persistence cache, allowing reads and writes to execute against local disk instantly.

---

# 16. PRESENTATION CHEAT SHEET

1. **What is PocketDay?**: A smart, light-mode personal finance manager built with Flutter and Firebase.
2. **Key Innovation**: Zero-lag offline functionality using Firestore native persistence and instant startup routing.
3. **Primary Tech Stack**: Flutter, Dart, Riverpod, Firebase Auth (Google OAuth), Cloud Firestore, Material 3.

---

# 17. KNOWN ISSUES & TECHNICAL DEBT

1. **`values-night/styles.xml` Launch Theme**: Previously set to `Theme.Black.NoTitleBar`, which caused a temporary black window flash on Android devices running OS dark mode. Fixed to `Theme.Light.NoTitleBar`.
2. **Dual Auth Initialization**: `AuthNotifier` constructor initiates an auth check on creation, while `SplashScreen` also invokes `checkCurrentUser()`. Harmless as the splash call governs final navigation.

---

# 18. UNUSED & POTENTIALLY UNUSED CODE AUDIT

- `register_screen.dart` and `forgot_password_screen.dart`: Form views present in the codebase but routed to `LoginScreen` in `AppRoutes.routes`, as PocketDay shifted to Google-only single-click OAuth for its public entry point. Backend repository functions remain fully functional.

---

# 19. FINAL AUDIT SUMMARY & STATISTICS

- **Number of Dart files scanned**: 78
- **Number of major pages documented**: 10
- **Number of models documented**: 6
- **Number of repositories documented**: 6
- **State-management providers documented**: 8
- **Dependencies documented**: 12 (from `pubspec.yaml`)
- **Total Viva Q&A included**: 25+
