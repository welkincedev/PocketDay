# PocketDay — Manual Physical Device & Web Test Plan

## Overview
This document outlines the comprehensive manual testing protocol for verifying PocketDay functionality on physical Android devices and Web browsers prior to public release.

---

## 14-Point Pre-Release Manual QA Checklist

### 1. Fresh Install Authentication
1. Install fresh APK on a physical Android device or open a new browser session.
2. Launch PocketDay. Verify app goes `SplashScreen` → `LoginScreen` immediately without hanging or artificial delays.

### 2. Google Sign-In & Single Loading Transition
1. Tap **Continue with Google**.
2. Select Google Account. Verify user navigates directly to Home (`/main`) without a second redundant loading screen.

### 3. Cold Reopen Session Persistence
1. With user logged in, close app completely from recent apps.
2. Reopen PocketDay. Verify app goes `SplashScreen` → `Home` (`/main`) immediately.

### 4. Force-Stop & OS Process Death Reopen
1. Force-stop PocketDay via Android App Settings.
2. Reopen PocketDay. Verify user session persists and app lands directly on `Home`.

### 5. Explicit Sign Out Flow
1. Navigate to **Profile**.
2. Tap **Sign Out** and confirm dialog. Verify app navigates to `LoginScreen`.

### 6. Post-Sign-Out Reopen Security
1. Close app after signing out.
2. Reopen PocketDay. Verify app goes `SplashScreen` → `LoginScreen` (session is not resumed after explicit logout).

### 7. Default Budget Tab Selection
1. Tap **Budget** on bottom navigation bar.
2. Verify Tab 0 (`Budget`) is selected by default every time Budget section is freshly entered.

### 8. Subscriptions CRUD & Relocation
1. Switch to Tab 1 (`Subscriptions`) inside Budget.
2. Add a new subscription (e.g., Netflix ₹499/mo). Edit amount to ₹649/mo. Delete subscription.
3. Verify all CRUD operations, search, status filter chips, and upcoming payments operate cleanly.

### 9. Single FloatingActionButton (FAB) Behavior
1. In Budget tab 0 (`Budget`), verify FAB displays `+` (Add Budget).
2. Switch to Subscriptions tab 1 (`Subscriptions`), verify FAB smoothly transitions to `+ Subscription` (Add Subscription).
3. Verify exactly ONE parent Scaffold FAB exists (no duplicate or nested FABs).

### 10. Profile Cleanliness & No Duplication
1. Navigate to **Profile**.
2. Verify Subscriptions entry tile is completely removed from Profile.

### 11. Offline Read Resilience
1. Enable Airplane Mode while logged in.
2. Navigate between Home, Transactions, Budget, Savings, and Profile.
3. Verify app reads cached data seamlessly without crashing or showing raw errors.

### 12. Reset App Data Action
1. Navigate to **Profile** → **Reset App Data**. Confirm dialog.
2. Verify all user subcollections are wiped from Cloud Firestore while Google User session remains active.

### 13. Delete Account Action
1. Navigate to **Profile** → **Delete Account**. Confirm dialog.
2. Verify subcollections, root user document, and Firebase Auth user account are permanently deleted, returning to `LoginScreen`.

### 14. Web Platform Parity
1. Launch Web build (`flutter run -d chrome` or release bundle).
2. Test Google popup sign-in, navigation tabs, Budget internal tabs, Subscriptions management, and Profile actions on desktop browser.
