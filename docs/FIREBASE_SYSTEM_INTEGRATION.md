# PocketDay — System Operation & Firebase / Firestore Integration Architecture

> **Document Type**: Technical Integration Note  
> **Target Audience**: Developers, System Architects, Evaluators  
> **Scope**: End-to-End System Operation, Firebase Authentication, Cloud Firestore Integration

---

## 1. System Overview: How PocketDay Operates End-to-End

PocketDay is built on a **Clean, Feature-First Architecture** powered by **Flutter**, **Riverpod**, and **Firebase**. The core operational flow of the system works as follows:

```text
┌──────────────────────────────────────────────────────────────────┐
│ 1. Application Launch (lib/main.dart)                             │
│    - Initializes Flutter bindings                                │
│    - Initializes Firebase SDK                                    │
│    - Configures Cloud Firestore Native Offline Persistence       │
│    - Mounts global Riverpod ProviderScope                        │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│ 2. Session & Auth Routing (lib/features/auth/views/splash_screen)│
│    - Checks FirebaseAuth.instance.currentUser                     │
│    - Unauthenticated → Navigates to LoginScreen                  │
│    - Authenticated   → Navigates to AppMainNavigationScreen       │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│ 3. Navigation Shell & Lazy Mounting                             │
│    - AppMainNavigationScreen initializes M3 NavigationBar        │
│    - IndexedStack mounts Tab 0 (DashboardScreen) lazily          │
│    - Other tabs (Transactions, Budget, Goals, Profile) mount     │
│      only on initial tap and stay alive in memory               │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│ 4. Reactive State & Offline Persistence Engine                  │
│    - Repositories attach real-time Firestore listeners (.snapshots())│
│    - Riverpod Notifiers update in-memory state on stream emits   │
│    - Offline reads execute against local disk cache immediately   │
│    - Offline writes queue locally and auto-sync when connected   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Where Firebase & Firestore Are Integrated (File-by-File)

Firebase and Cloud Firestore are integrated across specific layers of the application. Here is the exact breakdown:

### A. Core System Initialization
- **[`lib/main.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/main.dart)**
  - **Where**: Lines 24–32 inside `main()`.
  - **How**: 
    - `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` initializes the platform connection.
    - `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)` enables native offline storage on Android, iOS, and Web.
- **[`lib/firebase_options.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/firebase_options.dart)**
  - **Where**: Whole file.
  - **How**: Auto-generated configuration containing API keys, App IDs, and Messaging Sender IDs for Android, iOS, Web, and macOS.

### B. Authentication & User Profile Management
- **[`lib/data/repositories/auth_repository.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/data/repositories/auth_repository.dart)**
  - **Where**: `AuthRepositoryImpl` class.
  - **How**:
    - **Authentication**: Wraps `FirebaseAuth.instance` for email/password register, login, password reset (`sendPasswordResetEmail`), and sign-out.
    - **Google OAuth**: Integrates `GoogleSignIn` to retrieve Google Auth tokens (`idToken`, `accessToken`) and exchange them with Firebase (`GoogleAuthProvider.credential`).
    - **Profile Document Creation**: Writes root profile documents to `users/{uid}` and `users/{uid}/profile/data`.
    - **Background Sync**: Executes non-blocking background profile syncs (`unawaited`) so login flows never hang on weak networks.
    - **App Data Reset**: Queries subcollections and performs chunked 400-document batch deletions (`FirebaseFirestore.instance.batch()`).
    - **Account Deletion**: Deletes all user subcollections, root user document, and calls `user.delete()` on Firebase Auth.

### C. Financial Data Subcollections (CRUD & Realtime Streams)
All financial entities are stored under subcollections of the authenticated user's UID (`users/{uid}/*`):

1. **Transactions Repository**: [`lib/data/repositories/transaction_repository.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/data/repositories/transaction_repository.dart)
   - **Path**: `users/{uid}/transactions`
   - **How**: Listens to `.snapshots()` stream sorted by `date` descending. Writes new transactions using `.doc(id).set(model.toMap())`.
2. **Budget Repository**: [`lib/data/repositories/budget_repository.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/data/repositories/budget_repository.dart)
   - **Path**: `users/{uid}/budgets`
   - **How**: Queries budgets for the active month (`month == YYYY-MM`). Allows setting overall monthly and category-specific budget limits.
3. **Goal Repository**: [`lib/data/repositories/goal_repository.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/data/repositories/goal_repository.dart)
   - **Path**: `users/{uid}/goals`
   - **How**: Stores target savings goals. Goal balances are derived dynamically by matching `txn.goalId == goal.id`.
4. **Subscription Repository**: [`lib/data/repositories/subscription_repository.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/data/repositories/subscription_repository.dart)
   - **Path**: `users/{uid}/subscriptions`
   - **How**: Stores recurring subscriptions (Weekly, Monthly, Yearly). Supports client-side automatic expense generation when payments are due.

---

## 3. How Firestore Offline Persistence Engine Works

```text
  [Flutter UI / App]
         │
  Reads & Writes
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  Cloud Firestore Local Cache Engine (On-Device Storage)     │
│  - Instant Latency (< 5ms)                                  │
│  - Unlimited Storage (Settings.CACHE_SIZE_UNLIMITED)       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                Online Sync (Automatic Queueing)
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  Cloud Firestore Distributed Backend (Google Cloud)         │
└─────────────────────────────────────────────────────────────┘
```

1. **Instant UI Response**: When a user creates a transaction, the document is written directly to local device cache. The UI updates in `< 5ms` without waiting for network confirmation.
2. **Automatic Synchronization**: If the user is offline, Firestore queues mutation operations locally. As soon as connectivity returns, Firestore silently pushes queued writes to Google Cloud servers.
3. **Multi-Tab Security & Data Isolation**: All Firestore subcollection queries require `request.auth.uid == userId`, guaranteeing complete data privacy between user accounts.

---

## 4. Key Summary Table

| Layer / Feature | File Location | Firebase API / Concept Used |
| :--- | :--- | :--- |
| **SDK Initialization** | [`lib/main.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/main.dart) | `Firebase.initializeApp()`, `Settings(persistenceEnabled: true)` |
| **Authentication** | [`auth_repository.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/data/repositories/auth_repository.dart) | `FirebaseAuth`, `GoogleSignIn`, `GoogleAuthProvider` |
| **Transactions DB** | [`transaction_repository.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/data/repositories/transaction_repository.dart) | `FirebaseFirestore`, `.snapshots()`, `.doc().set()` |
| **Budgets DB** | [`budget_repository.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/data/repositories/budget_repository.dart) | Firestore Subcollection (`users/{uid}/budgets`) |
| **Goals DB** | [`goal_repository.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/data/repositories/goal_repository.dart) | Firestore Subcollection (`users/{uid}/goals`) |
| **Subscriptions DB** | [`subscription_repository.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/data/repositories/subscription_repository.dart) | Firestore Subcollection (`users/{uid}/subscriptions`) |
| **Data Reset / Wipe** | [`auth_repository.dart`](file:///d:/Luminar%20Flutter/Complete%20Apps/PocketDay/lib/data/repositories/auth_repository.dart) | `FirebaseFirestore.instance.batch()` (400-doc chunks) |
