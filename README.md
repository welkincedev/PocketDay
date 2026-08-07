# 🚀 PocketDay — Smart Personal Finance Manager

PocketDay is a modern, portfolio-quality personal finance application built with **Flutter** and **Dart**. Designed with Google's **Material 3** design system, it delivers a minimal, clean, and intuitive experience for tracking income, managing expenses, monitoring category budget limits, and visualizing monthly spending analytics in Indian Rupees (`₹`).

---

## 🌟 Key Features

- 💼 **Total Balance & Summary Cards**: Real-time balance calculations (`Total Balance = Income - Expense`) with hide/show balance privacy mode (`₹••••••`).
- ➕ **Lightweight Modal Bottom Sheets**: Quick `+ Add Income` and `- Add Expense` forms with Category `DropdownMenu`, native DatePicker, and keyboard safety.
- 📊 **Spending Analytics**: Interactive PieChart preview powered by `fl_chart` illustrating category breakdown and income vs. expense distribution.
- 📈 **Category Budget Progress**: Visual progress indicators tracking spending thresholds for Food, Shopping, Transport, and Bills.
- 🌓 **Dynamic Light & Dark Themes**: Full Material 3 theme customization using Google Fonts (`Outfit` for titles, `Inter` for body text).
- ⚡ **Offline-First Storage**: Powered by **Hive**, storing user credentials, settings, and transactions locally with instant launch speeds.

---

## 🛠️ Tech Stack & Architecture

- **Frontend Framework**: [Flutter](https://flutter.dev) (Latest Stable)
- **Language**: [Dart](https://dart.dev)
- **Architecture**: MVVM (Model-View-ViewModel) + Repository Pattern
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) with `StatefulShellRoute` for tab state persistence
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
│   └── widgets/         # AppButton, AppTextField, AppCard, BalanceDisplayWidget, SkeletonLoader
├── data/
│   ├── models/          # UserModel, TransactionModel
│   └── repositories/    # AuthRepository, TransactionRepository
├── features/
│   ├── auth/            # Splash, Onboarding, Login, Register, Forgot Password
│   ├── profile/         # ProfileScreen (Theme toggle, Privacy settings, Logout)
│   ├── dashboard/       # DashboardScreen, MainShellScreen, DashboardCard, SpendingChart, CategoryBudgetProgress, AddTransactionBottomSheet
│   ├── transactions/    # TransactionsScreen
│   ├── budget/          # BudgetScreen
│   └── goals/           # GoalsScreen
└── main.dart            # Application entry point & ProviderScope
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.22.0 or higher)
- [Dart SDK](https://dart.dev/get-started) (v3.4.0 or higher)
- Android Studio / VS Code with Flutter extension

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/PocketDay.git
   cd PocketDay
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run static analysis**:
   ```bash
   flutter analyze
   ```

4. **Run the application**:
   ```bash
   # Run on connected Android device
   flutter run -d android

   # Run on Web (Chrome)
   flutter run -d chrome

   # Run on Windows Desktop
   flutter run -d windows
   ```

---

## 🧪 Quality & Testing

This project enforces strict code quality and clean architecture guidelines:
- **0 Analysis Errors & Warnings**: Verified with `flutter analyze`.
- **Zero Overflow Guarantee**: All dynamic values and containers are responsive with `FittedBox` text auto-scaling.
