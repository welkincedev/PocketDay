# PocketDay — Comprehensive Developer Guide

> **Version**: 1.0.0+1  
> **Target Framework**: Flutter 3.11+ / Dart 3.0+  
> **Architecture**: Feature-First Clean Architecture + Riverpod 2.6+  
> **Database Engine**: Cloud Firestore with Native Offline Persistence  
> **Authentication**: Firebase Auth + Google OAuth  
> **Last Updated**: September 2026

---

## 1. Project Overview & Architecture

PocketDay is an offline-first personal finance tracking application designed for high performance, responsive UI layout, and transparent financial tracking.

```text
┌─────────────────────────────────────────────────────────────┐
│                      UI / View Layer                        │
│   (ConsumerWidget, ConsumerStatefulWidget, BottomSheets)    │
└──────────────────────────────┬──────────────────────────────┘
                               │ ref.watch() / ref.read()
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   State Management Layer                    │
│     (Riverpod StateNotifiers: Transactions, Budget, etc.)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ Calls CRUD / Stream Methods
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      Repository Layer                       │
│    (TransactionRepository, BudgetRepository, AuthRepo)      │
└──────────────────────────────┬──────────────────────────────┘
                               │ Syncs & Persists
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   Cloud Firestore Database                  │
│    (Native Offline Cache enabled, Unlimited Storage)        │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Principles
1. **Offline-First Storage**: Firestore native caching (`persistenceEnabled: true`, `CACHE_SIZE_UNLIMITED`) allows users to read and write financial records without an active internet connection. Writes queue locally and sync automatically when online.
2. **State Management**: Powered by `flutter_riverpod`. State Notifiers hold immutable state classes (`TransactionsState`, `BudgetState`, `GoalsState`, `SubscriptionState`).
3. **Lazy Navigation Shell**: [`app_main_navigation_screen.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/features/dashboard/views/app_main_navigation_screen.dart) uses an `IndexedStack` with lazy mounting (`_visitedIndices`) to prevent loading all 5 main screens simultaneously on startup.
4. **UID-Isolated Database**: All user data is partitioned under `users/{uid}/...` subcollections, secured via Firestore Security Rules matching `request.auth.uid == userId`.

---

## 2. Prerequisites & Environment Setup

### Prerequisites
- **Flutter SDK**: 3.11.0 or higher
- **Dart SDK**: 3.0.0 or higher
- **Firebase CLI**: Configured with your Firebase project
- **IDE**: VS Code or Android Studio with Flutter & Dart plugins

### Setup Steps
1. Clone the repository and navigate to the project directory:
   ```bash
   cd PocketDay
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run static analysis to verify project health:
   ```bash
   flutter analyze
   ```
4. Run unit and widget tests:
   ```bash
   flutter test
   ```
5. Launch the application:
   ```bash
   flutter run
   ```

---

## 3. Project Directory Map

The codebase follows a **Feature-First** layout under `lib/`:

```text
lib/
├── main.dart                      # App entry point, Firebase init & ProviderScope
├── firebase_options.dart          # Auto-generated Firebase CLI configuration
│
├── core/                          # Cross-cutting application assets & services
│   ├── constants/                 # AppColors, AppConstants, AppStrings
│   ├── routes/                    # AppRoutes definition & route generator
│   ├── services/                  # Global service placeholder directory
│   ├── theme/                     # AppTheme (Material 3 light/dark) & ThemeProvider
│   ├── utils/                     # AppErrorHandler, CurrencyFormatter, DateFormatter
│   └── widgets/                   # AppButton, AppCard, AppTextField, SkeletonLoader, etc.
│
├── data/                          # Data Layer contracts & Firestore implementations
│   ├── models/                    # UserModel, TransactionModel, BudgetModel, GoalModel, SubscriptionModel
│   └── repositories/              # AuthRepository, TransactionRepository, BudgetRepository, GoalRepository, SubscriptionRepository
│
└── features/                      # Feature modules (Views, Providers, Widgets)
    ├── auth/                      # Login, Register, Splash, Onboarding, Forgot Password
    ├── dashboard/                 # Overview Dashboard, Hero Balance Card, Spending Chart, Quick Actions
    ├── transactions/              # History View, Category Filters, Transaction Details
    ├── budget/                    # Monthly Budget Limits & Category Breakdown
    ├── goals/                     # Savings Target Goals & Direct Contribution Sheets
    ├── subscriptions/             # Recurring Payments Tracker & Auto-Expense Recording
    └── profile/                   # User Profile, Theme Toggle, Data Reset & Account Deletion
```

---

## 4. Feature Execution Workflows & Data Flows

### 4.1 Transaction Creation Data Flow

```text
User enters transaction details in AddTransactionBottomSheet
                         │
                         ▼
Validation passes → ref.read(transactionsProvider.notifier).addTransaction()
                         │
                         ▼
Instantiates TransactionModel (UUID assigned)
                         │
                         ▼
TransactionRepository.addTransaction(model)
                         │
                         ▼
Firestore Write: doc("users/{uid}/transactions/{id}").set(model.toMap())
                         │
                         ▼
Local disk cache updates instantly & emits stream update
                         │
                         ▼
transactionsProvider updates state → dashboardProvider recalculates balance metrics
                         │
                         ▼
UI Components (DashboardCard, SpendingChart, TransactionList) rebuild
```

### 4.2 Goal Balance Derivation Flow

Goals do not hardcode a static balance. Instead, goal progress is **dynamically derived** at runtime from linked transactions:

```text
goalsProvider watches transactionsProvider
                         │
                         ▼
When transactions emit new data, goalsProvider recalculates
                         │
                         ▼
GoalModelExtensions.calculateCurrentAmount(transactions)
                         │
                         ▼
Sums all transactions where txn.goalId == goal.id
                         │
                         ▼
GoalCard & GoalDetailScreen render updated progress & balance
```

### 4.3 Recurring Subscription Auto-Expense Flow

When subscriptions are loaded in `SubscriptionNotifier`:

```text
SubscriptionNotifier.checkAndAutoRecordExpenses()
                         │
                         ▼
Iterates through active subscriptions where autoRecordExpense == true
                         │
                         ▼
Checks if nextPaymentDate <= DateTime.now()
                         │
                         ▼
If due: Creates a new TransactionModel (type: expense, category: subscription.category)
                         │
                         ▼
Calls transactionRepository.addTransaction()
                         │
                         ▼
Updates subscription's nextPaymentDate to the next cycle (Weekly, Monthly, Yearly)
                         │
                         ▼
Saves updated SubscriptionModel to Firestore
```

---

## 5. Firebase Authentication & Firestore Database Schema

### Firestore Hierarchy (`users/{uid}/...`)

```text
users (Collection)
  └── {uid} (Document)
        ├── displayName: String
        ├── email: String
        ├── photoUrl: String?
        ├── createdAt: String (ISO-8601)
        │
        ├── transactions (Subcollection)
        │     └── {transactionId}
        │           ├── id: String
        │           ├── title: String
        │           ├── amount: double
        │           ├── type: String ("income" | "expense")
        │           ├── categoryId: String
        │           ├── categoryName: String
        │           ├── date: String (ISO-8601)
        │           └── goalId: String?
        │
        ├── budgets (Subcollection)
        │     └── {budgetId}
        │           ├── id: String
        │           ├── amount: double
        │           ├── month: String ("YYYY-MM")
        │           └── categoryId: String?
        │
        ├── goals (Subcollection)
        │     └── {goalId}
        │           ├── id: String
        │           ├── name: String
        │           ├── targetAmount: double
        │           ├── emoji: String
        │           └── targetDate: String?
        │
        └── subscriptions (Subcollection)
              └── {subscriptionId}
                    ├── id: String
                    ├── name: String
                    ├── amount: double
                    ├── billingCycle: String ("weekly" | "monthly" | "quarterly" | "yearly")
                    ├── nextPaymentDate: String (ISO-8601)
                    └── autoRecordExpense: bool
```

---

## 6. Financial Calculation Formulas

### 1. Total Balance
$$\text{Total Balance} = \sum \text{Income Amounts} - \sum \text{Expense Amounts}$$

### 2. Remaining Monthly Budget
$$\text{Remaining Budget} = \text{Monthly Budget Limit} - \sum_{\text{Month}} \text{Expense Amounts}$$

### 3. Safe Daily Spending
$$\text{Days Left} = \text{Total Days in Month} - \text{Current Day of Month} + 1$$
$$\text{Safe Daily Spend} = \max\left(0, \frac{\text{Remaining Monthly Budget}}{\text{Days Left}}\right)$$

### 4. Subscription Monthly Equivalent
$$\text{Monthly Cost} = \begin{cases} 
\text{Amount} \times \frac{52}{12} & \text{Weekly} \\
\text{Amount} & \text{Monthly} \\
\frac{\text{Amount}}{3} & \text{Quarterly} \\
\frac{\text{Amount}}{12} & \text{Yearly}
\end{cases}$$

---

## 7. State Management Guidelines (Riverpod 2.6+)

### Standard Notifier Structure Example
When adding a new feature with state management:

```dart
class FeatureState {
  final List<ItemModel> items;
  final bool isLoading;
  final String? error;

  FeatureState({
    required this.items,
    this.isLoading = false,
    this.error,
  });

  FeatureState copyWith({
    List<ItemModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return FeatureState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FeatureNotifier extends StateNotifier<FeatureState> {
  final FeatureRepository _repository;

  FeatureNotifier(this._repository) : super(FeatureState(items: [])) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repository.fetchItems();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final featureProvider = StateNotifierProvider<FeatureNotifier, FeatureState>((ref) {
  final repository = ref.watch(featureRepositoryProvider);
  return FeatureNotifier(repository);
});
```

---

## 8. Common Developer Pitfalls & Best Practices

1. **Do Not Hardcode Static Balances on Goals**:  
   Always calculate goal progress dynamically via `GoalCalculations` extension methods using the transaction list.
2. **Firestore Batch Operation Limit (500 Docs)**:  
   When deleting app data (`resetAppData()`), operations must be chunked in max **400-document batches** to prevent exceeding Firestore limits.
3. **Modal Bottom Sheets & Keyboard Overlaps**:  
   Always wrap form content inside `SingleChildScrollView` and add padding using `MediaQuery.of(context).viewInsets.bottom` to prevent overflow when the soft keyboard opens.
4. **Unawaited Async Profile Sync**:  
   When updating non-critical user profile data upon login, use unawaited background futures so authentication flow never hangs on poor network conditions.

---

## 9. Testing & Quality Assurance

Unit and integration tests are stored under `test/`:
- `auth_session_test.dart`: Validates authentication state transitions and sessions.
- `budget_test.dart`: Validates monthly budget calculations and limit utilization.
- `transactions_test.dart`: Validates income vs expense balance calculations.
- `goal_test.dart`: Validates goal progress percentages and remaining target calculations.
- `subscription_test.dart`: Validates subscription renewal date calculations and monthly equivalents.

Run tests via terminal:
```bash
flutter test
```
