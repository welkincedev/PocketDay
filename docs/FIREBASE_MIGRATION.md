# PocketDay — Phase 8 Firebase Authentication & Firestore Cloud Sync Plan

## 1. Executive Summary

PocketDay is migrating from local Hive-based persistence to a production-ready Firebase Authentication and Cloud Firestore cloud storage model while preserving local offline caching and sync.

The goal is to enable multi-device sync, secure user data isolation, and persistent offline operation without altering existing business rules, UI/UX aesthetics, or Riverpod state management patterns.

---

## 2. Target Architecture

```text
                           POCKETDAY APP
                                 │
                         Flutter & UI Layer
                                 │
                     Riverpod State Notifiers
                                 │
                     Repository Abstraction Layer
                 ┌───────────────┴───────────────┐
                 │                               │
        Firebase Auth (UID)           Cloud Firestore
                 │                               │
       Session & Credentials            User Collections
                                                 │
                                        Offline Persistence
```

---

## 3. Data Model & Firestore Schema

All user financial records are isolated under their authenticated Firebase UID (`users/{uid}/...`):

```text
users/{uid}
   ├── profile/data                (UserModel map)
   ├── transactions/{txnId}        (TransactionModel map)
   ├── goals/{goalId}              (GoalModel map)
   ├── budgets/{budgetId}          (BudgetModel map)
   └── subscriptions/{subId}       (SubscriptionModel map)
```

### Document Schemas:

* **User Profile** (`users/{uid}/profile/data`):
  - `uid`: String
  - `email`: String
  - `displayName`: String
  - `photoUrl`: String?
  - `createdAt`: String / Timestamp
  - `updatedAt`: String / Timestamp

* **Transactions** (`users/{uid}/transactions/{txnId}`):
  - `id`: String
  - `title`: String
  - `amount`: double
  - `type`: String ('income' | 'expense')
  - `categoryId`: String
  - `categoryName`: String
  - `date`: Timestamp / String
  - `notes`: String?
  - `goalId`: String?

* **Goals** (`users/{uid}/goals/{goalId}`):
  - `id`: String
  - `name`: String
  - `targetAmount`: double
  - `emoji`: String
  - `targetDate`: Timestamp / String?
  - `createdAt`: Timestamp / String
  - `updatedAt`: Timestamp / String

* **Budgets** (`users/{uid}/budgets/{budgetId}`):
  - `id`: String
  - `categoryId`: String?
  - `categoryName`: String?
  - `amount`: double
  - `month`: String ('YYYY-MM')
  - `createdAt`: Timestamp / String
  - `updatedAt`: Timestamp / String

* **Subscriptions** (`users/{uid}/subscriptions/{subId}`):
  - `id`: String
  - `name`: String
  - `amount`: double
  - `billingCycle`: String ('weekly' | 'monthly' | 'quarterly' | 'yearly')
  - `nextPaymentDate`: Timestamp / String
  - `startDate`: Timestamp / String
  - `category`: String
  - `paymentMethod`: String
  - `status`: String ('active' | 'paused' | 'cancelled')
  - `autoRecordExpense`: bool
  - `notes`: String?
  - `createdAt`: Timestamp / String
  - `updatedAt`: Timestamp / String

---

## 4. Migration Strategy (Hive → Firestore)

1. **Idempotent Data Migration**: When an existing user logs in or registers via Firebase Auth, the app checks `HiveService` for local data (`transactionsBox`, `goalsBox`, `budgetBox`, `subscriptionsBox`).
2. **Batch Document Upload**: Any existing Hive records are uploaded to `users/{uid}/{collection}/{id}` using document keys matching the existing IDs. Using deterministic keys guarantees duplicate uploads will not occur if migration is re-run.
3. **Migration Marker**: Once completed, a migration flag (`has_migrated_to_firestore`) is stored in local settings and user document.

---

## 5. Security & Isolation

Firestore Security Rules enforce strict ownership:
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

## 6. Migration Stages (Phase 8A to 8Z)

- **8A**: Full Project Audit & Mapping (Completed)
- **8B**: Migration Documentation (Completed)
- **8C**: Firebase Setup & App Initialization
- **8D**: Firebase Authentication Integration
- **8E**: Firestore Data Model & Schema Definitions
- **8F**: Firestore Repositories Construction
- **8G**: Riverpod Providers & Realtime Firestore Listeners Integration
- **8H - 8L**: Entity-by-entity Migration (Transactions, Goals, Budgets, Subscriptions, Profile)
- **8M - 8O**: Local Hive Migration, New/Existing User Setup, & Offline Persistence
- **8P - 8Z**: Security Rules, Error Handling, Multi-device Verification, & Final Cleanup
