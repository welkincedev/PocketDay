# PocketDay — Public Website & Google Play Compliance Implementation

> **Product**: PocketDay — Personal Finance Manager  
> **Brand & Publisher**: PocketDay  
> **Official Support Destination**: `welkince.dev@gmail.com`  
> **Active Firebase Project**: `pocketday-1679a` (Project #`104455039089`)  
> **Hosting Site**: `pocketday-1679a`  
> **Live Production URL**: `https://pocketday-1679a.web.app`  
> **Status**: Deployed Live on Firebase Hosting; Cloud Function Code Staged & Tested  

---

## 1. Firebase Project Discrepancy & Verification Resolution

We performed an audit across the developer's connected Firebase projects to resolve the discrepancy between `pocketday-6dfbe` and `pocketday-1679a`:

1. **`pocketday-6dfbe` (Project #199820187736)**:
   - Houses an older web prototype from March 2026 (*"PocketDay | Survival Budgeting"*).
   - Completely independent from this mobile codebase.
   - **Preserved 100% untouched** (verified `Last-Modified: Thu, 19 Mar 2026`).
2. **`pocketday-1679a` (Project #104455039089)**:
   - **Verified Active Backend** for the PocketDay Flutter mobile application (`android/app/google-services.json` and `lib/firebase_options.dart`).
   - Houses the actual user authentication records and Cloud Firestore collections (`users/{uid}/*`).
   - Hosting site `pocketday-1679a` was previously empty (404) and is now **deployed live** with the redesigned public website.

---

## 2. Contact Form & Server-Side Email Architecture

### Email Destination
* All contact inquiries are configured to deliver directly to **`welkince.dev@gmail.com`**.

### Frontend Behavior ([`public/assets/js/contact.js`](file:///D:/Coding/Luminar%20Flutter/Complete%20Apps/PocketDay/public/assets/js/contact.js))
* **Preserved Design**: Existing layout, CSS classes, and button:
  `<button type="submit" id="contactSubmitBtn" class="btn btn-primary btn-block"> Send Message </button>`.
* **Asynchronous Submission**: Submits via `fetch('/api/sendContactEmail')` without page reload or navigation.
* **Duplicate-Submission Prevention**: Disables the submit button and inputs immediately upon click, presenting an animated loading spinner (`Sending Message...`).
* **Input Validation**: Client-side name, email regex, message length, and honeypot spam protection.
* **Truthful Status Display**: Never shows success unless the backend confirms delivery (`response.ok && data.success === true`). If the backend endpoint is unreachable or credentials are unconfigured, presents a clear error banner and fallback direct mailto link to `welkince.dev@gmail.com`.

### Backend Function ([`functions/index.js`](file:///D:/Coding/Luminar%20Flutter/Complete%20Apps/PocketDay/functions/index.js))
* **Server-side Validation & Sanitization**: Strips HTML tags, escapes dangerous characters to prevent XSS and header injection, and validates RFC 5322 email patterns.
* **Spam Protection & Rate Limiting**: In-memory IP-based rate limiting (maximum 5 submissions per 10 minutes per IP).
* **Direct Delivery**:
  * `to`: `welkince.dev@gmail.com`
  * `replyTo`: Visitor's verified email address
  * `subject`: `[PocketDay Inquiry] {Category} — from {Name}`
  * Both plaintext and responsive HTML email templates.
* **Zero Credential Leaks**: Credentials are read strictly from server environment variables (`GMAIL_USER`, `GMAIL_APP_PASSWORD` or `SMTP_HOST`). No secrets in client bundles.

---

## 3. Automated Test Suite Results

### 1. Cloud Function Unit Tests ([`functions/test_contact_function.js`](file:///D:/Coding/Luminar%20Flutter/Complete%20Apps/PocketDay/functions/test_contact_function.js))
Ran 8 comprehensive automated unit test assertions:
```text
=== Running PocketDay Contact Function Test Suite ===
✓ Test 1 Passed: Rejects non-POST methods (405)
✓ Test 2 Passed: Honeypot catches bot submissions (400)
✓ Test 3 Passed: Rejects invalid email format (400)
✓ Test 4 Passed: Rejects undersized messages (400)
✓ Test 5 Passed: Rejects invalid name (400)
✓ Test 6 Passed: Valid submission delivered to welkince.dev@gmail.com with Reply-To set and XSS sanitized (200)
✓ Test 7 Passed: Rate limiting triggers at request threshold (429)
✓ Test 8 Passed: Unconfigured credentials gracefully return 503 without crashing

======================================================
Test Results: 8 passed, 0 failed.
All contact function verification assertions passed!
======================================================
```

### 2. Flutter Test Suite
Ran `flutter test` across all mobile application test suites:
```text
00:31 +53: All tests passed!
```

### 3. HTML Link Integrity Check
Ran `python verify_links.py` across all public HTML pages:
```text
Verification complete: 6 HTML files checked, 0 broken links found.
```

---

## 4. Live Deployed Production URLs

The website is live on Firebase Hosting under `pocketday-1679a`:

| Resource | Live Production URL | HTTP Status |
| :--- | :--- | :--- |
| **Home Page** | **https://pocketday-1679a.web.app/** | `HTTP/1.1 200 OK` |
| **Privacy Policy** | **https://pocketday-1679a.web.app/privacy-policy** | `HTTP/1.1 200 OK` |
| **Account Deletion** | **https://pocketday-1679a.web.app/delete-account** | `HTTP/1.1 200 OK` |
| **Contact & Support** | **https://pocketday-1679a.web.app/contact** | `HTTP/1.1 200 OK` |
| **Terms of Service** | **https://pocketday-1679a.web.app/terms** | `HTTP/1.1 200 OK` |
| **Legacy Prototype** | **https://pocketday-6dfbe.web.app/** | `HTTP/1.1 200 OK` (Preserved) |

---

## 5. Remaining Manual Setup Steps for Cloud Functions

Firebase Hosting is fully deployed and active. To enable server-side execution of `functions/index.js` for automated background SMTP delivery:

1. **Upgrade `pocketday-1679a` to the Firebase Blaze Plan**:
   - Google Cloud requires the Blaze plan (pay-as-you-go) to enable Cloud Build and Cloud Functions (`artifactregistry.googleapis.com`).
   - Visit: [https://console.firebase.google.com/project/pocketday-1679a/usage/details](https://console.firebase.google.com/project/pocketday-1679a/usage/details).
   - *(Note: Firebase includes a generous free tier of 2,000,000 function invocations per month).*
2. **Generate a Gmail App Password**:
   - Go to your Google Account (`welkince.dev@gmail.com`) &rarr; Security &rarr; 2-Step Verification &rarr; App Passwords.
   - Generate a 16-character password for "PocketDay Website".
3. **Configure Environment Secrets & Deploy Function**:
   - In terminal:
     ```bash
     firebase functions:secrets:set GMAIL_APP_PASSWORD
     # (Paste your 16-character app password when prompted)
     firebase deploy --only functions
     ```
   - Once deployed, `/api/sendContactEmail` will automatically process incoming submissions and dispatch them directly to `welkince.dev@gmail.com`.
