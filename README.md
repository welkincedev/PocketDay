# 💰 PocketDay

### Personal Finance Manager for Everyday Spending

PocketDay is a simple, focused personal finance manager designed to help you understand **where your money goes, how much you can safely spend, and how long your balance can last.**

Built with Flutter and Firebase, PocketDay focuses on fast expense tracking, spending awareness, budgeting, and savings — without unnecessary complexity.

> **PocketDay — Know your money. Control your day.**

---

## ✨ Features

### 🏠 Home

* Current balance
* Today's spending
* Safe daily spending
* Survival days remaining
* Recent activity

### 💸 Transactions

* Add income
* Add expenses
* Categorize transactions
* View transaction history
* Edit and manage transactions

### 📊 Budget

* Set and monitor budgets
* Track spending against budgets
* Subscription management
* Budget overview

### 🎯 Savings

* Create savings goals
* Track progress
* Monitor saved amounts

### 👤 Profile

* Account information
* User settings
* Logout

### 🔐 Authentication

* Google Sign-In
* Firebase Authentication
* Persistent login sessions

### ☁️ Cloud Data

* Firebase Cloud Firestore
* User-specific data
* Cloud synchronization

---

## 🎨 Design Philosophy

PocketDay is intentionally designed around:

* **Light mode**
* Clean and minimal interfaces
* Clear financial information
* Fast interactions
* Consistent typography
* Subtle animations
* Simple navigation
* Trustworthy financial presentation

PocketDay avoids unnecessary visual clutter, excessive gradients, decorative elements, and complicated interfaces.

---

## 🧭 Navigation

PocketDay uses five primary destinations:

```text
Home
Transactions
Budget
Savings
Profile
```

The Budget section also contains:

```text
Budget | Subscriptions
```

---

## 🚀 Getting Started

### Requirements

Make sure you have:

* Flutter SDK
* Dart SDK
* Android Studio
* Android SDK
* Git

Check your Flutter installation:

```bash
flutter doctor
```

---

### Clone the Repository

```bash
git clone <repository-url>
cd pocketday
```

Install dependencies:

```bash
flutter pub get
```

---

### Run the Application

```bash
flutter run
```

For a release APK:

```bash
flutter build apk --release
```

The generated APK will be located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔥 Firebase

PocketDay uses Firebase for authentication and cloud storage.

### Services

* Firebase Authentication
* Google Sign-In
* Cloud Firestore

The application uses the authenticated Firebase user's UID to scope personal financial data.

### Important

Firebase configuration files are environment/project-specific and should **not be committed if they contain credentials or configuration that should remain private**.

For a new development environment, configure Firebase using the appropriate FlutterFire setup for the project.

---

## 🏗️ Architecture

PocketDay follows a feature-oriented architecture with separation between UI, state management, and data access.

```text
Feature
│
├── View
├── ViewModel
├── Repository
└── Models
```

### Main Technologies

| Technology      | Purpose               |
| --------------- | --------------------- |
| Flutter         | Application framework |
| Dart            | Programming language  |
| Riverpod        | State management      |
| Firebase Auth   | Authentication        |
| Cloud Firestore | Cloud database        |
| Material 3      | UI foundation         |

---

## 📁 Project Structure

The project follows a feature-first organization.

```text
lib/
│
├── core/
│   ├── constants/
│   ├── theme/
│   ├── routing/
│   └── services/
│
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── home/
│   ├── transactions/
│   ├── budget/
│   ├── savings/
│   └── profile/
│
└── main.dart
```

The exact structure may evolve as the application develops.

---

## 🔐 Authentication Flow

PocketDay uses a lightweight startup flow:

```text
App Launch
     ↓
PocketDay Splash
     ↓
Onboarding Check
     ↓
Authentication Check
     ↓
 ┌───────────────┐
 │               │
Onboarding     Authenticated
 │               │
Login           Home
 │
Google Login
 │
Home
```

The splash screen remains visible briefly while lightweight local startup checks are performed.

Heavy Firestore operations are not intended to block the initial application launch.

---

## 🧪 Testing

Before a test release, run:

```bash
flutter analyze
flutter test
flutter build apk --release
```

For web:

```bash
flutter build web
```

### Current Test Release

**Version:** `1.0.0-beta.1`

**Status:** 🟡 Beta / Test Release

This build is intended for testing and feedback rather than production financial use.

---

## 📱 Test APK

Test builds are distributed through **GitHub Releases**.

The latest release can be found under the repository's Releases section.

Download the APK from the release assets and install it on a compatible Android device.

---

## 📝 Beta Testing

When testing PocketDay, please pay particular attention to:

### Authentication

* Google Sign-In
* Login persistence
* Logout
* App restart after login

### Transactions

* Adding income
* Adding expenses
* Editing transactions
* Deleting transactions
* Transaction history

### Financial Calculations

* Balance
* Today's spending
* Safe daily spending
* Budget calculations
* Savings progress
* Survival days

### Cloud Data

* Data synchronization
* Data persistence after restarting
* Correct user data

### UI

* Screen layout
* Navigation
* Text overflow
* Buttons
* Loading states
* Dark/light system interactions
* Small-screen layouts

### Startup

* Splash screen
* Onboarding
* Login
* Home navigation

---

## 🐛 Reporting Issues

When reporting a bug, include:

1. What you were doing
2. What you expected
3. What actually happened
4. Device model
5. Android version
6. Screenshots or screen recordings if possible

Example:

```text
Bug: Expense disappears after app restart

Steps:
1. Login with Google
2. Add ₹500 expense
3. Close the application
4. Reopen PocketDay

Expected:
The ₹500 expense should still be visible.

Actual:
The expense is missing.
```

---

## 🛣️ Roadmap

PocketDay is being developed incrementally.

Potential future improvements include:

* Smarter spending insights
* Improved budget intelligence
* Advanced analytics
* Better savings planning
* Recurring transaction improvements
* Additional personalization
* Performance improvements
* Production hardening

Features will be added only when they improve the core PocketDay experience.

---

## ⚠️ Disclaimer

PocketDay is a personal finance management application intended to help users track and understand their own spending.

It does **not** provide financial, investment, tax, or legal advice.

During the beta period, users should not rely on PocketDay as the sole record of their financial information.

---

## 📄 License

License information will be added when the project license is finalized.

---

## 👨‍💻 Development

PocketDay is an independent software project built with Flutter.

**Project:** PocketDay
**Platform:** Android / Web
**Framework:** Flutter
**Backend:** Firebase
**Status:** Beta

---

<p align="center">
  Made with Flutter · Built for everyday money management
</p>
