# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

**HyperDynamics Loyalty Manager** — a multi-tenant SaaS admin tool for merchants to run a customer
loyalty-points program: pay a flat ₹4,999 onboarding fee, log in, then Earn points for customers on a bill,
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
- Login is by "business id", not email; Firebase Auth only speaks email/password. Provisioning mints each
  business a synthetic login email `{businessId}@<LOGIN_EMAIL_DOMAIN>`. There's deliberately **no Cloud
  Function to resolve it** — `lib/data/auth_repository.dart` computes the same email client-side (it's a
  deterministic, non-secret string), so login/forgot-password work independently of Cloud Functions/Blaze
  being live. Keep `loginEmailDomain` there in sync with `LOGIN_EMAIL_DOMAIN`'s default in `config.ts`.
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
  **Currently set to placeholder values** (`placeholder-not-yet-real`), not real Razorpay/MSG91 keys — so
  payments and managed-gateway OTP SMS won't work end-to-end until real accounts exist and
  `firebase functions:secrets:set <NAME>` is re-run with the real values. Everything else (login, Earn,
  Redeem with OTP override, Correction, Settings) works today, deployed and verified live.
- `defineString` params (`MSG91_SENDER_ID`, `LOGIN_EMAIL_DOMAIN`, `APP_BASE_URL`) are pinned in
  `functions/.env.hyperdynamics-loyalty` (committed — these aren't secrets, just non-interactive-deploy
  requirements) to their documented defaults from `config.ts`.

### Data model

See the Firestore layout and security-rule rationale in `firestore.rules`; summary:
`businesses/{id}` (+ `private/otpGateway`, `customers/{phone}`, `transactions/{txnId}`, `otps/{phone}`,
`stats/summary` subcollections) and top-level `paymentOrders/{referenceId}` (publicly readable by reference id
so the pre-login confirmation page can poll it; only Cloud Functions write it).

## Current status (as of 2026-07-27)

Verified: `flutter analyze` clean, `flutter test` passing, `flutter build web` and `flutter build ios
--no-codesign --simulator` both succeed end-to-end. The Firebase backend is **live and verified working** —
signed in as the demo account and called `earnCredit` directly (not simulated): correct points math, customer
doc created, `stats/summary` incremented via the trigger.

### Already live — don't redo this

- **Firebase project** `hyperdynamics-loyalty` (CLI account `hyperdynamics08@gmail.com`, aliased `default` in
  `.firebaserc`). `lib/firebase_options.dart`, `android/app/google-services.json`,
  `ios/Runner/GoogleService-Info.plist` are all real, flutterfire-generated config.
- **Firestore** (region `asia-south1`) — database, `firestore.rules`, `firestore.indexes.json` all deployed.
- **Authentication** — Email/Password enabled. **Demo login: business id `demo`, password `demo1234`**
  (`businesses/demo` doc exists with one seeded Earn transaction — real pre-populated demo data).
- **All 9 Cloud Functions** deployed on the Blaze plan (`firebase functions:list` to confirm). The very first
  deploy needed several retries while freshly-enabled APIs (Secret Manager, Eventarc, Cloud Run, Pub/Sub)
  finished propagating IAM/service-agent permissions — a one-time thing for a project's first 2nd-gen
  Functions deploy, won't recur. Artifact Registry cleanup policy is set so container images don't accumulate.
- **Firebase Hosting** (canonical URL, matches `APP_BASE_URL`): **https://hyperdynamics-loyalty.web.app**.
  Redeploy: `flutter build web --release && firebase deploy --only hosting`.
- **GitHub repo** (public): **https://github.com/HyperDynamics/hyperdynamics-loyalty-manager** — auto-deploys
  to **https://hyperdynamics.github.io/hyperdynamics-loyalty-manager/** on every push to `main` via
  `.github/workflows/deploy-pages.yml`. Kept as a zero-config mirror alongside Firebase Hosting.
- Onboarding fee is **₹4,999** (not the original spec's ₹5,000) — updated in landing page copy, the real
  Razorpay charge amount (`ONBOARDING_FEE_PAISE` in `config.ts`), and `uploads/loyalty-points-ui-spec.md`.

### Pending — ordered by what unblocks the most

1. **Storage not initialized.** No CLI/API path for first-time bucket creation (same class of issue
   Authentication had before it was enabled) — visit
   `https://console.firebase.google.com/project/hyperdynamics-loyalty/storage`, click "Get Started," then
   `firebase deploy --only storage`. Only blocks Settings' logo upload; nothing else needs it.
2. **Real Razorpay account.** `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` / `RAZORPAY_WEBHOOK_SECRET` are
   currently placeholder values (`placeholder-not-yet-real`). Once real: `firebase functions:secrets:set
   <NAME>` for each, then register the webhook URL
   (`https://us-central1-hyperdynamics-loyalty.cloudfunctions.net/razorpayWebhook`) in the Razorpay dashboard
   with the same webhook secret. Until then, the actual "pay ₹4,999" flow doesn't complete.
3. **Real MSG91 account.** `MSG91_MANAGED_AUTH_KEY` is also a placeholder — needed for the "managed by us" OTP
   gateway option to send real SMS. (BYO gateway businesses supply their own key via Settings regardless.)
4. **Node.js 20 deprecation.** Every Functions deploy warns that Node 20 is decommissioned 2026-10-30. Bump
   `functions/package.json`'s `engines.node` to `"22"` and redeploy sometime before then.
5. **No local emulator wiring.** `main.dart` always talks to production Firebase; there's no debug-flag path
   to point the app at `firebase emulators:start` for local dev without touching real data.
6. **Android untested end-to-end.** Blocked locally only by unaccepted SDK licenses
   (`flutter doctor --android-licenses`, an interactive step) — not a code issue, but it means the Android
   build has only been analyzed/compiled, never actually run on a device/emulator (unlike web and iOS, both
   verified running).

### Notes for whoever picks this up

- Sandbox-specific quirk (won't happen in a normal terminal): the Firebase CLI's bundled npm fails on the
  `predeploy` build hook here (`Cannot read properties of undefined (reading 'stdin')`). Work around it by
  running `npm run build` inside `functions/` yourself first, temporarily dropping `predeploy` from
  `firebase.json`, deploying, then restoring it.
- A brand-new Firebase project's *very first* Cloud Functions deploy is expected to need 2–4 retries as GCP
  APIs (Secret Manager, Eventarc, Cloud Run, Pub/Sub, Cloud Scheduler) finish enabling and propagating IAM
  grants — retry the same `firebase deploy --only functions` command; it's not a code problem.
- Cost estimate (Blaze free tier + usage-based pricing): Firebase/GCP infra cost stays low even at a fairly
  aggressive scale (~$30–35/month for 1,000 active businesses doing 100 ledger ops/day each) — the free tier
  covers ~200K ledger transactions/month before Firestore write charges even start. The costs that actually
  scale with revenue are **outside** Firebase's bill: Razorpay's ~2%+GST per onboarding payment, and MSG91 SMS
  at ~₹0.18–0.25/message for OTP-verified redemptions (this is the one to watch if OTP-add-on adoption and
  redeem volume are both high — it's billed through to the business per the Settings copy, not absorbed).
