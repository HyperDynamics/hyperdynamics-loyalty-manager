# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

**HyperDynamics Loyalty Manager** — a multi-tenant SaaS admin tool for merchants to run a customer
loyalty-points program: pay a flat ₹5,000 onboarding fee, log in, then Earn points for customers on a bill,
Redeem points (with an optional paid OTP-verification add-on), and reverse/correct past transactions.

Stack: **Flutter** (iOS + Android + Web, one codebase) + **Firebase** (Auth, Firestore, Cloud Functions,
Storage, Hosting for the web build).

This was built from a Claude "Design Companion" click-through prototype and its functional spec, both kept in
the repo as design reference — **the spec is the source of truth for behavior**, the prototype for exact
interaction/copy details not otherwise specified:
- `uploads/loyalty-points-ui-spec.md` — the functional spec (screens A–I).
- `HyperDynamics Loyalty Manager.dc.html` / `support.js` / `_ds/` — the original interactive mockup (fake,
  in-memory data, no real auth/payment/SMS). Useful for exact copy, validation rules, and UI states; not
  itself part of the shipped app. See git history / the prior version of this file if you need the full
  breakdown of that format.

## Commands

**Flutter app** (repo root is the Flutter project root):
- `flutter pub get` — install/update Dart dependencies.
- `flutter analyze` — static analysis; keep this clean.
- `flutter test` — run all tests in `test/`. Run a single file with `flutter test test/formatters_test.dart`.
- `flutter run -d chrome` / `-d <device-id>` — run the app. `flutter devices` lists targets.
- `flutter build web` / `flutter build apk` / `flutter build ios --no-codesign` — production builds.

**Cloud Functions** (in `functions/`, TypeScript):
- `npm install` (first time), `npm run build` — compile to `lib/`.
- `npm run build:watch` — incremental compile while iterating.
- `firebase emulators:start` (from repo root) — run Auth/Firestore/Functions/Storage emulators locally; point
  the Flutter app at them with `FirebaseFirestore.instance.useFirestoreEmulator(...)` etc. during dev (not
  currently wired — add emulator connection calls in `main.dart` behind a debug/flag check if you need this).
- `firebase deploy --only functions` / `--only firestore:rules` / `--only storage` / `--only hosting` — deploy
  individual pieces. `firebase deploy` deploys everything in `firebase.json`.

## Architecture

### Flutter app (`lib/`)

- `theme/` — design tokens (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`) ported from the
  original prototype's design system, plus `app_theme.dart` building the `ThemeData`. Dark-first, mint accent,
  Gilroy font (bundled in `assets/fonts/`).
- `widgets/` — the shared component kit built on those tokens: `AppButton`, `AppCard`, `AppInput`, `AppToggle`,
  `AppSegmentedControl`, `StatTile`, `AppListRow` / `txn_list_row.dart` (transaction row formatting),
  `ToastHost` + `feedback_providers.dart`'s `toastProvider` (transient toasts), `LoadingOverlay` +
  `busyProvider` (full-screen busy spinner, use `busyProvider.notifier.run(message, action)`),
  `confirm_dialog.dart`'s `showAppConfirmDialog` (required before any balance-changing action, per spec).
- `models/` — plain Dart data classes (`Business`, `Customer`, `LoyaltyTransaction`, `PaymentOrder`) with
  manual `fromMap` — no codegen.
- `data/` — repositories wrapping Firestore reads and Cloud Functions callable calls
  (`AuthRepository`, `BusinessRepository`, `LedgerRepository`, `PaymentRepository`). **`LedgerRepository`
  never writes `customers`/`transactions` directly** — every balance-mutating action (`earnCredit`, `sendOtp`,
  `redeemPoints`, `reverseTransaction`) is a Cloud Functions callable; the repo only *streams* those
  collections for display.
- `providers/` — Riverpod (v3, no codegen) providers per concern: `authSessionProvider` (combines Firebase
  Auth's user with the `businessId` custom claim — this is what every screen and the router key off),
  `business_providers.dart`, `ledger_providers.dart` (family providers for customer/history/correction-feed
  streams), `feedback_providers.dart` (toast/busy), `payment_providers.dart`.
- `features/<name>/` — one folder per spec section: `landing`, `payment_confirm`, `auth` (login + forgot
  password), `shell` (responsive app shell + dashboard — sidebar on wide viewports, bottom tab bar on narrow,
  breakpoint `AppSpacing.wideBreakpoint`), `earn`, `redeem` (includes the OTP subflow), `correction`,
  `settings`.
- `app/router.dart` — go_router routes. Pre-auth: `/`, `/payment/confirm`, `/login`. Authed: `ShellRoute` under
  `/app/*` (dashboard/earn/redeem/correction/settings). The `redirect` callback reads `authSessionProvider`
  directly and is refreshed via `GoRouterRefreshNotifier` (see `app/app.dart`, which bridges Riverpod state
  changes into go_router's `refreshListenable`).
- `url_strategy/` — a conditional-import shim (`url_strategy.dart` exporting either `_stub.dart` or `_web.dart`
  based on `dart.library.js_interop`) around `flutter_web_plugins`' `usePathUrlStrategy()`. **Don't import
  `package:flutter_web_plugins` directly from non-web-only code** — even behind a runtime `kIsWeb` check, the
  unconditional import broke the iOS build (Dart's `dart:ui_web` isn't available to non-web compile targets).
  Always go through `configureUrlStrategy()` from this shim instead.

### Firebase backend

**Why Cloud Functions own all balance-mutating writes**: Earn/Redeem/Correction change a customer's point
balance and must be atomic, race-safe, and — for Redeem — gated on a server-verified OTP. `firestore.rules`
denies all client writes to `customers`, `transactions`, `otps`, and the `private/otpGateway` subdoc; only the
Admin SDK (Cloud Functions) can touch them. Business profile fields (name/logo/ratio/OTP toggle/gateway
choice) are simple enough to be direct, rule-guarded client writes (field allow-list in `firestore.rules`).

Cloud Functions (`functions/src/`, exported from `index.ts`):
- `auth.ts` — `resolveBusinessLoginEmail`: login is by "business id", not email, so this resolves it to the
  synthetic login email minted at provisioning (`{businessId}@<LOGIN_EMAIL_DOMAIN>`), rate-limited.
- `payments.ts` + `provisioning.ts` — `createOnboardingPaymentLink` (real Razorpay Payment Links API) and
  `razorpayWebhook` (HMAC-verifies the webhook, then provisions the business: mints business id + temp
  password, creates the Firebase Auth user + `businessId` custom claim, creates the `businesses/{id}` doc,
  emails credentials via the `mail` collection convention).
- `earn.ts`, `otp.ts`, `redeem.ts`, `correction.ts` — the ledger operations, each a Firestore transaction.
- `settings.ts` — `saveOtpGatewayCredentials` (BYO gateway secrets, functions-only storage).
- `stats.ts` — Firestore trigger maintaining `businesses/{id}/stats/summary` incrementally (dashboard tiles),
  plus a midnight-IST scheduled reset of the "today" counters.
- `lib/` — shared helpers: `admin.ts` (Firestore/Auth handles + collection-path helpers), `authContext.ts`
  (`requireBusinessId` — every authed callable derives its tenant from the caller's custom claim, **never**
  from a client-supplied parameter), `razorpay.ts`, `sms.ts` (MSG91), `mail.ts`, `format.ts`.
- `config.ts` — all third-party credentials are Cloud Functions secrets (`firebase functions:secrets:set
  <NAME>`): `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`, `MSG91_MANAGED_AUTH_KEY`.
  **These are not yet set** — Razorpay/MSG91 accounts don't exist yet, so payments and managed-gateway OTP SMS
  won't work end-to-end until they're created and the secrets are set. Everything else works today.

### Data model

See the Firestore layout and security-rule rationale in `firestore.rules`; summary:
`businesses/{id}` (+ `private/otpGateway`, `customers/{phone}`, `transactions/{txnId}`, `otps/{phone}`,
`stats/summary` subcollections) and top-level `paymentOrders/{referenceId}` (publicly readable by reference id
so the pre-login confirmation page can poll it; only Cloud Functions write it).

## Current status / known gaps

Verified: `flutter analyze` clean, `flutter test` passing, `flutter build web` and `flutter build ios
--no-codesign --simulator` both succeed. Android build is blocked locally only by unaccepted SDK licenses
(see below), not a code issue.

**Firebase project**: real project `hyperdynamics-loyalty` exists (Firebase CLI account
`hyperdynamics08@gmail.com`, aliased as `default` in `.firebaserc`). `lib/firebase_options.dart`,
`android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist` are all real, flutterfire-
generated config — not placeholders.

Deployed:
- Firestore database (region `asia-south1`), `firestore.rules`, `firestore.indexes.json`.
- **Firebase Hosting** (`flutter build web` + `firebase deploy --only hosting`) at
  **https://hyperdynamics-loyalty.web.app** — same domain family as the rest of the Firebase project; this
  is what `APP_BASE_URL` in `config.ts` assumes for the Razorpay callback once Functions are live. Re-deploy
  any time with `flutter build web --release && firebase deploy --only hosting`.
- **GitHub Pages** (source repo: `https://github.com/HyperDynamics/hyperdynamics-loyalty-manager`, public) at
  **https://hyperdynamics.github.io/hyperdynamics-loyalty-manager/** — auto-builds and redeploys on every
  push to `main` via `.github/workflows/deploy-pages.yml`. Kept alongside Firebase Hosting as a second,
  zero-config mirror (doesn't need Firebase billing state to stay up); Firebase Hosting is still the
  canonical URL once Functions go live, since that's the domain Razorpay's callback is wired to.
- Both currently only show the pre-auth marketing pages working end-to-end — login and every authed screen
  need Cloud Functions, which aren't deployed yet (see below).

Not yet deployed — each needs one manual, one-time action outside what a CLI/agent can do:
- **Storage** — needs a human to click "Get Started" once at
  `https://console.firebase.google.com/project/hyperdynamics-loyalty/storage` (no CLI equivalent for
  first-time bucket provisioning). Deploy `storage.rules` after that with `firebase deploy --only storage`.
- **Cloud Functions** — the project is on the free Spark plan; Functions requires upgrading to Blaze
  (pay-as-you-go, needs a billing account) at
  `https://console.firebase.google.com/project/hyperdynamics-loyalty/usage/details`. After upgrading:
  `firebase deploy --only functions`.
- Razorpay and MSG91 don't have real accounts/keys yet (see `config.ts`) — the integration code is real, just
  unwired. Once you have them, `firebase functions:secrets:set <NAME>` for each secret in `config.ts`.

Note for local development in this sandbox: the Firebase CLI's bundled npm fails on the `predeploy` build
hook here specifically (`Cannot read properties of undefined (reading 'stdin')` — a stdio quirk of this
sandboxed shell, not a real bug) — work around it by running `npm run build` inside `functions/` yourself
first. This does not happen in a normal terminal.

- Firebase emulator connection isn't wired into `main.dart` yet — add it (behind a debug check) before relying
  on `firebase emulators:start` for local testing.
- Android builds require accepting SDK licenses locally (`flutter doctor --android-licenses`) — not something
  to run non-interactively.
