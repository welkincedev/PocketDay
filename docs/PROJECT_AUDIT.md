# Project Audit - PocketDay

PocketDay is a personal money manager app built with Flutter. Below is the comprehensive audit of the current state of the application.

## 1. Current Architecture
The app follows a **Feature-first MVVM + Repository Pattern** structure:
- **`lib/core/`**: Central utilities, constants, routes, theme, reusable widgets, and database service.
- **`lib/data/`**: Core data models (`UserModel`, `TransactionModel`) and repository implementations (`AuthRepositoryImpl`, `TransactionRepositoryImpl`).
- **`lib/features/`**: Feature-specific views and providers (Riverpod). The modules structured here include `auth`, `dashboard`, `transactions`, `budget`, `goals`, and `profile`.

## 2. Current Screens
- **Splash Screen (`splash_screen.dart`)**: Shows the wallet icon, title, and tagline with entrance animations. Directs users based on onboarding and login status.
- **Onboarding Screen (`onboarding_screen.dart`)**: Introduces key app concepts in a carousel.
- **Login Screen (`login_screen.dart`) / Register Screen (`register_screen.dart`) / Forgot Password Screen (`forgot_password_screen.dart`)**: Simulated authentication forms.
- **Dashboard Screen (`dashboard_screen.dart`)**: Displays the main metrics (Total Balance, Income, Expense, Remaining budget), quick action buttons to add transactions, a spending chart, and a category budget progress card.
- **Transactions Screen (`transactions_screen.dart`)**: Displays a short list of transactions.
- **Budget Screen (`budget_screen.dart`)**: Placeholder screen showing an empty state indicating budget management is coming soon.
- **Goals Screen (`goals_screen.dart`)**: Placeholder screen showing an empty state indicating goals tracker is coming soon.
- **Profile Screen (`profile_screen.dart`)**: Displays user credentials and handles settings like Dark Theme, Hide Financial Balances, and Log Out.
- **Main Shell Screen (`main_shell_screen.dart`)**: Wraps the core screens with an `IndexedStack` and a bottom navigation bar.

## 3. Current Features
- **Simulated Offline Authentication**: Log in, register, and password reset flows with dummy latency.
- **Balance Privacy**: Toggleable setting to hide/unhide financial balances across the app.
- **Theme Switching**: Seamless light and dark mode toggles saved locally.
- **Add Transactions**: Direct transaction creation (Income/Expense) via bottom sheet.
- **Local Persistence**: Offline-first design utilizing Hive for transactions and settings.

## 4. Existing Dependencies
Major packages defined in `pubspec.yaml`:
- **`flutter_riverpod: ^2.6.1`**: State management.
- **`hive_flutter: ^1.1.0`**: Local database engine.
- **`fl_chart: ^1.2.0`**: Spending visualizations.
- **`google_fonts: ^8.2.1`**: Google Outfit (headings) and Inter (body text) fonts.
- **`flutter_animate: ^4.5.2`**: Splash and dashboard animations.
- **`firebase_core: ^4.13.0`**, `firebase_auth`, `cloud_firestore`: Firebase dependencies (installed but not yet integrated into repositories).
- **`flutter_local_notifications: ^22.2.0`**: Notification framework.

## 5. Existing Database Structure
Hive service is initialized in `lib/core/services/hive_service.dart`.
- **`settingsBox`**: Stores boolean flags for `isDarkMode`, `hideBalance`, and `hasOnboarded`.
- **`userBox`**: Cached user credentials (`uid`, `name`, `email`).
- **`transactionsBox`**: Stores transactions serialized as maps/JSON objects using standard `toMap()` / `fromMap()`.
- **`budgetBox`, `goalsBox`, `subscriptionsBox`**: Opened, but unused in the current codebase.

## 6. Existing Navigation
- Standard Flutter `Navigator` with defined named routes in `lib/core/routes/app_router.dart`.
- Tabs on the main screen switch using `IndexedStack` inside `MainShellScreen`.

## 7. Existing Theme
- **Material 3** compliance.
- **Brand Colors**: Emerald green (`#10B981`) primary, Indigo (`#6366F1`) accent.
- **Dark Mode Palette**: Slate grey dark themes (`#0F172A` background, `#1E293B` surface).
- **Typography**: Outfit for headings, Inter for body/captions.

## 8. Existing Reusable Widgets
Located in `lib/core/widgets/`:
- `AppButton`: Custom standard elevated button.
- `AppCard`: Standard themed card.
- `AppTextField`: Standard text input field.
- `BalanceDisplayWidget`: Maskable financial text.
- `EmptyStateWidget`: Styled blank state illustrations.
- `ErrorView`: Displays custom failure messages.
- `SkeletonLoader`: Visual placeholder shimmer during loads.

## 9. Problems & Gaps Found
1. **Limited Transactions Screen**: Currently displays `dashboardState.recentTransactions` which is capped at 5! It does not load the complete transaction history, nor does it support search, filter, or transaction actions (edit/delete).
2. **Mock Budget Progress Widget**: The `CategoryBudgetProgressWidget` on the dashboard has static mock data. It should load budgets and calculate values dynamically.
3. **Budget and Goals Screens are Empty**: Both screens display static placeholder empty states and lack domain logic, providers, or repository connections.
4. **Unused Dependencies**: Firebase core/auth/firestore are imported in `pubspec.yaml` but are completely inactive.
5. **No Subscriptions and Notifications modules**: Incomplete folders with no files under these features.

## 10. Recommended Next Step
Proceed to **Phase 4 (Advanced Transactions)**:
- Create a dedicated transactions repository stream or provider to load all transactions.
- Implement transaction search, filters (category, income/expense, date range), and sorting.
- Add edit/delete functionality with confirmation dialogs.
