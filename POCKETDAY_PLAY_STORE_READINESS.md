# PocketDay — Google Play Store Pre-Upload Readiness Audit

**Application:** PocketDay – Personal Finance Manager  
**Publisher / Brand:** PocketDay  
**Official Support Contact:** `welkince.dev@gmail.com`  
**Package Name (Application ID):** `com.wclabs.pocketday`  
**Target Firebase Project:** `pocketday-1679a` (Project Number: `104455039089`)  
**Public Website & Policy Portal:** `https://pocketday-1679a.web.app`  
**Audit Date:** November 16, 2026  
**Auditor:** Antigravity Senior Release & Compliance Auditor  

---

## 1. Executive Summary & Readiness Verdict

| Audit Domain | Status | Key Finding / Requirement |
| :--- | :---: | :--- |
| **Application Identity & Versioning** | `PASS` | Unique Application ID (`com.wclabs.pocketday`), Clean App Name (`PocketDay`), version `1.0.0+1`. |
| **Target SDK & Architecture** | `PASS` | Target SDK 36 (Android 16), Min SDK 24 (Android 7.0), full 64-bit native binary support (`arm64-v8a`, `x86_64`, `armeabi-v7a`). |
| **Permissions & Background Policies** | `PASS` (Resolved) | Policy-violating `USE_EXACT_ALARM` removed. Necessary permissions (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `INTERNET`) aligned. |
| **App Bundle (AAB) Generation** | `PASS` | Successfully compiled release bundle `app-release.aab` (62.1 MB) without obfuscation crashes. |
| **Release Signing Configuration** | `WARNING` | Configured release signing pipeline via `android/key.properties`. Production `.jks` keystore must be generated and signed prior to Play Console upload. |
| **Firebase & Google Sign-In** | `WARNING` | Release SHA-1 and Google Play App Signing SHA-1 must be registered in Firebase Console to prevent Google Sign-In failure. |
| **Firestore Security Rules** | `PASS` | Strict user-isolation rules (`match /users/{userId}/{document=**}`) prevent unauthorized cross-tenant data access. |
| **Account Deletion & Data Safety** | `PASS` | Dual account deletion implemented (in-app under Profile + live web portal at `/delete-account`). Compliant with Google Play Data Safety policy. |
| **Privacy Policy & Support Presence** | `PASS` | Live HTTPS Privacy Policy and Contact Portal verified at `https://pocketday-1679a.web.app/privacy-policy` with 0 broken links. |

---

## 2. Application Identity & Versioning

- **Application ID:** `com.wclabs.pocketday` (`android/app/build.gradle.kts` line 23)
- **App Name:** `PocketDay` (`android/app/src/main/res/values/strings.xml` line 2: `<string name="app_name">PocketDay</string>`)
- **Version Name:** `1.0.0` (`pubspec.yaml` line 19)
- **Version Code:** `1` (`pubspec.yaml` line 19)
- **Verification Status:** `PASS`
  - The package name is globally unique and formatted correctly.
  - Initial version code `1` is optimal for the initial Play Store production track release.

---

## 3. Android SDK, Toolchain & Architecture Audit

- **Compile SDK:** 36 (Android 16)
- **Target SDK:** 36 (Android 16) — Exceeds Google Play minimum requirement (Target API 34+ required; Target API 35 recommended).
- **Min SDK:** 24 (Android 7.0 Nougat) — Covers >95% of active global Android devices.
- **Java Toolchain Compatibility:** Java 17 (`sourceCompatibility` & `targetCompatibility` = `JavaVersion.VERSION_17`, `jvmTarget` = `JVM_17`).
- **Core Library Desugaring:** Enabled (`com.android.tools:desugar_jdk_libs:2.1.4`) ensuring backward compatibility for modern Java APIs.
- **64-bit Architecture Compliance:** `PASS`
  - Inspected inside `build/app/outputs/bundle/release/app-release.aab`:
    - `arm64-v8a`: 4 native libraries
    - `armeabi-v7a`: 4 native libraries
    - `x86_64`: 4 native libraries
  - Fully conforms to Google Play's 64-bit native code mandate.

---

## 4. Permissions Audit & Policy Risk Assessment

### Merged Permissions in Release Build:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.VIBRATE" />
```

### Risk Remediation Summary:
- **`USE_EXACT_ALARM` Removal (`RESOLVED`):**
  - **Issue:** `android/app/src/main/AndroidManifest.xml` previously declared `<uses-permission android:name="android.permission.USE_EXACT_ALARM" />`.
  - **Google Play Policy:** Google Play strictly restricts `USE_EXACT_ALARM` to alarm clock, timer, and calendar apps. Finance reminder apps submitting with this permission face immediate automated rejection.
  - **Action Taken:** `USE_EXACT_ALARM` was removed from `AndroidManifest.xml`. PocketDay retains `SCHEDULE_EXACT_ALARM` alongside standard notification channels.
- **`INTERNET` Permission (`RESOLVED`):**
  - Explicitly added to `android/app/src/main/AndroidManifest.xml` to avoid dependence on transitive plugin manifest merging.

---

## 5. Release Signing & Build Artifacts

- **AAB Build Output:** `build/app/outputs/bundle/release/app-release.aab` (62.1 MB)
- **Signing Pipeline Configuration:**
  - `android/app/build.gradle.kts` has been updated with a production-ready signing configuration that reads from `android/key.properties`:
  ```kotlin
  val keystorePropertiesFile = rootProject.file("key.properties")
  val keystoreProperties = Properties()
  if (keystorePropertiesFile.exists()) {
      keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
  }
  // Falls back gracefully to debug if key.properties does not exist yet
  ```
- **Security Safeguard:** Added `android/key.properties`, `*.jks`, and `*.keystore` to `.gitignore`.
- **Status:** `WARNING`
  - While the build pipeline is fully wired and tested, an actual production release keystore must be generated by the release engineer before uploading to the Google Play Console (see Section 10 for key generation command).

---

## 6. Firebase & Authentication Production Readiness

- **Target Project:** `pocketday-1679a`
- **Android Client App ID:** `1:104455039089:android:ff170940169db8258713d0`
- **OAuth Web Client ID:** `104455039089-ij4t0jqku157r56cpgnep7a5tg75pkj2.apps.googleusercontent.com`
- **Status:** `WARNING`
  - **CRITICAL REQUIREMENT:** Google Sign-In requires SHA-1 and SHA-256 certificate fingerprints in Firebase Console. Currently, only the debug keystore fingerprint (`5E:E2:F3:9A:BF:D3:82:90:54:49:C1:F6:DC:11:C7:E2:D6:10:B2:91`) is registered.
  - When the production keystore is generated, its SHA-1 fingerprint must be added to Firebase Console under Project Settings -> Your apps -> `com.wclabs.pocketday`.
  - Furthermore, if Google Play App Signing is opted in (required for all new apps), the SHA-1 from **Google Play Console -> Release -> Setup -> App integrity -> App signing key certificate** must also be added to Firebase Console. Failure to do this will cause Google Sign-In to throw error `10` / `12500` in production.

---

## 7. Cloud Firestore Security Rules Audit

**Inspected File:** `firestore.rules`
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data isolation rule:
    // Every user has exclusive read/write permissions for documents nested under their own auth UID.
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
- **Evaluation:**
  - Multi-tenant data isolation: `PASS`
  - No global read/write access: `PASS`
  - All operations require an authenticated session (`request.auth != null`) matching the exact user document root (`request.auth.uid == userId`).
  - Web contact submissions do not write unauthenticated data directly to Firestore.

---

## 8. Account Deletion & Data Safety Compliance

Google Play requires that apps with account creation provide both an **In-App** and an **External Web** account deletion mechanism, along with explicit Data Safety declarations.

### In-App Account Deletion (`PASS`):
- Location: Settings / Profile Screen -> Account Management -> `Delete Account`.
- Implementation: `AuthRepository.deleteAccount()` recursively purges:
  1. Subcollections: `transactions`, `budgets`, `goals`, `subscriptions`, `savings_goals`, `profile`.
  2. Root document: `users/{uid}`.
  3. Firebase Authentication user profile: `user.delete()`.
  4. Local cache: SharedPreferences, active alarms, and Riverpod state.

### Web Account Deletion Portal (`PASS`):
- Live URL: `https://pocketday-1679a.web.app/delete-account`
- Features: Direct Firebase Auth login + verified recursive deletion, plus an assisted ticket submission fallback.

### Google Play Data Safety Questionnaire Responses:
When completing the Data Safety form in Google Play Console, declare:
1. **Data Collection & Sharing:**
   - **Financial Info:** User-entered financial info (income, expense transactions, budgets, savings goals). Collected: `YES`. Shared: `NO`. Ephemeral processing: `NO`. Optional: `NO` (Core app feature).
   - **Personal Info:** Name, Email address, User IDs. Collected: `YES`. Shared: `NO`.
   - **App Info & Performance:** Crash logs, Diagnostics (Firebase Analytics/Crashlytics if enabled).
2. **Security Practices:**
   - Data is encrypted in transit (`YES` — HTTPS/TLS via Firebase).
   - Data deletion request mechanism provided (`YES` — Provide link: `https://pocketday-1679a.web.app/delete-account`).

---

## 9. Store Presence & Public Portal Verification

- **Privacy Policy URL:** `https://pocketday-1679a.web.app/privacy-policy` (`PASS` — HTTP 200, zero broken links)
- **Account Deletion URL:** `https://pocketday-1679a.web.app/delete-account` (`PASS` — HTTP 200)
- **Terms of Service URL:** `https://pocketday-1679a.web.app/terms` (`PASS` — HTTP 200)
- **Support Contact URL:** `https://pocketday-1679a.web.app/contact` (`PASS` — HTTP 200)
- **App Icons:** Verified in `android/app/src/main/res/mipmap-*` (`ic_launcher.png`, `ic_launcher_round.png`).
- **Unit Test Health:** 53 / 53 passed (`flutter test`).

---

## 10. Pre-Launch Action Checklist for Developer

Before uploading `app-release.aab` to Google Play Console, perform the following final operational steps:

### Step 1: Generate Release Keystore
Run in PowerShell (replace `YOUR_KEYSTORE_PASSWORD`):
```powershell
keytool -genkey -v -keystore "D:\Coding\Luminar Flutter\Complete Apps\PocketDay\android\pocketday-release.jks" `
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 `
  -alias pocketday_upload_key
```

### Step 2: Configure `key.properties`
Create `D:\Coding\Luminar Flutter\Complete Apps\PocketDay\android\key.properties` (this file is ignored by git):
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=pocketday_upload_key
storeFile=../pocketday-release.jks
```

### Step 3: Extract Keystore SHA-1 & Add to Firebase
Extract fingerprint:
```powershell
keytool -list -v -keystore "D:\Coding\Luminar Flutter\Complete Apps\PocketDay\android\pocketday-release.jks" -alias pocketday_upload_key
```
Copy the **SHA-1** and **SHA-256** into Firebase Console:
`Project Settings -> General -> Your apps -> com.wclabs.pocketday -> Add fingerprint`.

### Step 4: Build Signed Production Bundle
Run:
```powershell
flutter build appbundle --release
```
Verify signer:
```powershell
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```
Ensure signer says `CN=...` of your keystore (not `CN=Android Debug`).

### Step 5: Upload to Google Play Console
1. Create App: **PocketDay – Personal Finance Manager** (Default language: English, App, Free).
2. Complete Store presence:
   - App category: **Finance**.
   - Tags: **Budgeting**, **Personal Finance**, **Expense Tracker**.
   - Contact email: `welkince.dev@gmail.com`.
   - Privacy Policy URL: `https://pocketday-1679a.web.app/privacy-policy`.
3. Complete Content Rating, Target Audience (18+ / General), and Data Safety forms.
4. Upload `app-release.aab` to **Production** or **Closed Testing** track.
5. In Play Console -> Release -> Setup -> App integrity, copy the **Google Play App Signing key SHA-1** into Firebase Console.
