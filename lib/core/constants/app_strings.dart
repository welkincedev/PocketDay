// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: app_strings.dart
//
// Purpose:
// Centralized string constants for UI text, labels, onboarding titles, navigation labels, and error messages.
//
// Responsibilities:
// - Provide consistent copy across onboarding, auth screens, dashboard, navigation, and feedback states.
// - Eliminate duplicate hardcoded string literals across feature widgets.
//
// Data Flow:
// AppStrings → UI Views & Dialogs
//
// Important Rules:
// - All core UI titles and buttons should consume AppStrings instead of raw strings.
//
// Main Constants:
// - Auth/Onboarding: onboardingTitle1-3, login, register, getStarted
// - Navigation: navHome, navTransactions, navBudget, navGoals, navProfile
// - Financial Labels: totalBalance, monthlyIncome, monthlyExpense, remainingBudget
// ============================================================

class AppStrings {
  static const String appTitle = 'PocketDay';
  static const String appTagline = 'Smart, simple personal finance management';

  // Auth & Onboarding
  static const String onboardingTitle1 = 'Master Your Money';
  static const String onboardingDesc1 =
      'Track income, expenses, and monthly spending effortlessly with clear insights.';

  static const String onboardingTitle2 = 'Smart Budget Planning';
  static const String onboardingDesc2 =
      'Set category budgets and receive real-time alerts before you overspend.';

  static const String onboardingTitle3 = 'Reach Financial Goals';
  static const String onboardingDesc3 =
      'Set savings targets and monitor progress to achieve your financial dreams.';

  static const String getStarted = 'Get Started';
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String next1 = 'Show me how';
  static const String next2 = 'Love it, What Else';
  static const String next3 = 'I need this';
  static const String login = 'Log In';
  static const String register = 'Register';
  static const String welcomeBack = 'Welcome Back!';
  static const String createAccount = 'Create Account';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String continueWithGoogle = 'Continue with Google';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String signUp = 'Sign Up';

  // Dashboard & Navigation
  static const String navHome = 'Home';
  static const String navTransactions = 'Transactions';
  static const String navBudget = 'Budget';
  static const String navGoals = 'Goals';
  static const String navProfile = 'Profile';

  static const String totalBalance = 'Total Balance';
  static const String monthlyIncome = 'Income';
  static const String monthlyExpense = 'Expense';
  static const String remainingBudget = 'Remaining Budget';
  static const String recentTransactions = 'Recent Transactions';
  static const String seeAll = 'See All';
  static const String quickActions = 'Quick Actions';
  static const String addIncome = 'Add Income';
  static const String addExpense = 'Add Expense';
  static const String monthlySummary = 'Monthly Summary';
  static const String categoryBreakdown = 'Category Breakdown';

  // Errors & Empty States
  static const String noTransactionsYet = 'No transactions recorded yet.';
  static const String addFirstTransaction =
      'Tap + to add your first expense or income!';
  static const String somethingWentWrong =
      'Something went wrong. Please try again.';
  static const String retry = 'Retry';
}
