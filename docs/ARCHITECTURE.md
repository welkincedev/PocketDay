# PocketDay System Architecture

**Document Version**: 1.0.0  
**Last Updated**: August 31, 2026  

---

## 1. Overview

PocketDay follows a clean, layered architecture designed for local-first reliability, high UI responsiveness, testability, and clear separation of concerns.

```text
┌──────────────────────────────────────────────────────────┐
│                         UI Layer                         │
│   (Views, Screens, Custom Widgets, Sheets, Dialogs)      │
└────────────────────────────┬─────────────────────────────┘
                             │ Watches / Dispatches
                             ▼
┌──────────────────────────────────────────────────────────┐
│                   State Management Layer                 │
│         (Riverpod Notifiers & Immutable States)          │
└────────────────────────────┬─────────────────────────────┘
                             │ Calls Data Methods
                             ▼
┌──────────────────────────────────────────────────────────┐
│                     Repository Layer                     │
│      (Abstract Contracts & Local Hive Implementations)   │
└────────────────────────────┬─────────────────────────────┘
                             │ Persists / Retrieves
                             ▼
┌──────────────────────────────────────────────────────────┐
│                      Storage Layer                       │
│           (Hive Key-Value Boxes / Local Storage)         │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Core Architectural Layers

### 2.1 UI Layer (`lib/features/*/views`, `lib/core/widgets`)
- Implements Flutter `ConsumerWidget` or `ConsumerStatefulWidget` to consume Riverpod providers.
- Displays responsive layouts using standard Flutter flex widgets (`Flex`, `Expanded`, `LayoutBuilder`, `MediaQuery`).
- Leverages central theme definitions (`AppTheme`, `AppColors`, `CurrencyFormatter`, `DateFormatter`).

### 2.2 State Management Layer (`lib/features/*/providers`)
- Powered by `flutter_riverpod`.
- Each feature exposes a dedicated `StateNotifier` and immutable state class:
  - `TransactionsNotifier` → `TransactionsState`
  - `BudgetNotifier` → `BudgetState`
  - `GoalsNotifier` → `GoalsState`
  - `SubscriptionNotifier` → `SubscriptionState`
  - `AuthNotifier` → `AuthState`
  - `DashboardNotifier` → `DashboardState`
- Providers handle business logic, calculation of aggregates, filtering, and coordination between models.

### 2.3 Repository Layer (`lib/data/repositories`)
- Serves as the abstraction boundary between state managers and storage engines.
- Implements repository patterns:
  - `TransactionRepository`
  - `BudgetRepository`
  - `GoalRepository`
  - `SubscriptionRepository`
  - `AuthRepository`
- Decouples Riverpod notifiers from storage-specific code (allowing seamless unit testing with in-memory or mock implementations).

### 2.4 Storage Layer (`lib/core/services/hive_service.dart`)
- Fast, local key-value store using **Hive**.
- Hive Boxes:
  - `transactionsBox`: Stores all income and expense transactions (`TransactionModel.toMap()`).
  - `budgetBox`: Stores monthly overall and category budgets (`BudgetModel.toMap()`).
  - `goalsBox`: Stores target savings goals (`GoalModel.toMap()`).
  - `subscriptionsBox`: Stores active recurring subscriptions (`SubscriptionModel.toMap()`).
  - `userBox`: Stores authenticated user profile (`UserModel.toMap()`).
  - `settingsBox`: Stores app preferences (e.g. theme mode, onboarding completion).

---

## 3. Data Flow Example: Adding a Goal Contribution Expense

1. **User Action**: User enters contribution amount in `AddToGoalSheet` and taps **Save**.
2. **UI Call**: `ref.read(goalsProvider.notifier).addContribution(goalId, amount)`.
3. **Notifier Processing**:
   - Creates a new `TransactionModel` with `type: TransactionType.expense`, category `Goal Contribution`, and `goalId: goalId`.
   - Invokes `TransactionRepository.addTransaction(txn)`.
   - Invokes `GoalRepository.updateGoal(updatedGoal)`.
4. **Persistence**:
   - Transaction saved to `transactionsBox`.
   - Goal updated in `goalsBox`.
5. **State Update**:
   - Notifier refreshes local state and notifies listening UI widgets.
   - Transactions tab shows the ₹5,000 expense.
   - Goals tab updates target progress percentage dynamically.
