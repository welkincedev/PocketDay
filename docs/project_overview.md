# PocketDay — Project Overview

## 1. Project Identity

- **App Name**: PocketDay
- **Tagline**: Personal Finance & Money Manager
- **Core Purpose**: Everyday personal expense, income, budget, goal, and subscription tracking designed to be fast, simple, calm, personal, and financially empowering.

### Primary User Flow
```text
Open PocketDay App
      ↓
View Financial Situation & Balance
      ↓
Record Income / Expense Quickly
      ↓
Analyze Category Spend & Budgets
      ↓
Manage Goals & Subscriptions
```

---

## 2. Core Features (Implemented)

### Authentication & Profile
- **Google Authentication**: Clean, single-button sign in via Google Account and Firebase Authentication.
- **Profile Identity**: Automatic display of Google User Profile (Display Name, Email, Photo URL).
- **Data Management Controls**:
  - **Reset App Data**: Chunked batch deletion of all user cloud financial records while retaining user identity.
  - **Delete Account**: Complete erasure of subcollection documents, root Firestore user document, and Firebase Auth user account.
  - **Sign Out**: Clean logout ending the local session while preserving cloud data safely.

### Financial Tracking
- **Income & Expense Tracking**: Real-time balance calculations (`Total Balance = Income - Expense`) with hide/show privacy toggle mode (`₹••••••`).
- **Category Budgets**: Monthly overall and category-specific spending limits with dynamic warning indicators (Safe, Warning, Critical, Exceeded).
- **Savings Goals**: Target amount tracking with progress indicators, contributions, and target dates.
- **Subscriptions Engine**: Recurring subscription tracking (weekly, monthly, yearly) with idempotent automatic transaction creation.
- **Spending Analytics**: Breakdown pie charts powered by `fl_chart`.

### Architecture & Platform Features
- **Firebase-First Architecture**: Cloud Firestore as single source of truth.
- **Native Offline Persistence**: Cloud Firestore offline cache for instant launch and offline read/write capability.
- **Web & Android Multiplatform**: Fully supported and verified on Android (APK, AAB, split-per-ABI) and Web.

---

## 3. Supported Platforms

| Platform | Support Status | Notes |
| :--- | :--- | :--- |
| **Android** | ✅ Supported | Release APK (~54.7MB), Split APKs (~17.9MB–20.3MB), AAB (~45.8MB) |
| **Web** | ✅ Supported | Flutter Web compiled with `signInWithPopup(GoogleAuthProvider())` |

---

## 4. Authentication Architecture

```text
Google Account (Google Sign-In)
              ↓
    Firebase Authentication
              ↓
     Firebase User UID
```

User identity is bound to a unique Firebase User ID (`UID`). This UID strictly isolates all user data in Firestore under `users/{uid}` subcollections.

---

## 5. Data Storage

- **Cloud Firestore**: Primary persistent storage engine for profile, transactions, budgets, goals, and subscriptions.
- **Firestore Offline Cache**: Native SDK cache enabled in `main.dart` for offline access and instant app startup.
- **Hive Local Storage**: **Completely removed**. All local persistence is managed natively by Firestore SDK offline cache.

---

## 6. Cloud Firestore Structure

All application data is isolated per authenticated user:

```text
users/{uid} (Root User Document)
├── profile
│   └── data (Document: user profile details, currency, theme)
├── transactions
│   └── {transactionId} (Documents: income/expense transactions)
├── budgets
│   └── {budgetId} (Documents: monthly category budget limits)
├── goals
│   └── {goalId} (Documents: financial target goals)
├── subscriptions
│   └── {subscriptionId} (Documents: recurring subscriptions)
└── savings_goals
    └── {savingsGoalId} (Documents: dedicated savings targets)
```

---

## 7. Security Architecture

Firestore Security Rules enforce strict UID isolation:

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

No user can access, read, or modify another user's financial documents.

---

## 8. Current Release Status

- **Status**: Release Candidate (Phase 9 Complete)
- **Version**: 1.0.0+1
- **Analyzed**: `flutter analyze` — 0 issues
- **Tests**: `flutter test` — 27/27 passed
- **Artifacts**:
  - Universal Release APK: `build/app/outputs/flutter-apk/app-release.apk` (54.7 MB)
  - Split ABI Release APKs: `app-arm64-v8a-release.apk` (20.3 MB), `app-armeabi-v7a-release.apk` (17.9 MB)
  - Android App Bundle (AAB): `build/app/outputs/bundle/release/app-release.aab` (45.8 MB)
  - Web Output: `build/web`
