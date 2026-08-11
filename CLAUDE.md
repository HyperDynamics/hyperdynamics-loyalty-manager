# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

**HyperDynamics Loyalty Manager** — a multi-tenant SaaS admin tool for merchants to run a customer
loyalty-points program: self-signup (anyone can create an account), pay a flat onboarding fee **outside the
app** (bank transfer/UPI/invoice — ₹7,999 standard, ₹12,999 with OTP-verified redemptions included), admin
approves once payment is confirmed, then Earn points for customers on a bill, Redeem points (with an optional
paid OTP-verification add-on), and reverse/correct past transactions. A ₹999/year subscription keeps the
account active after that; add-on features (birthday nudges, WhatsApp nudges, CSV/PDF export) are sold
separately and admin-toggled per business.

Stack: **Flutter** (iOS + Android + Web, one codebase) + **Firebase** (Auth, Firestore, Cloud Functions,
Storage, Hosting for the web build).

This was built from a Claude "Design Companion" click-through prototype and its functional spec, both kept in
the repo as design reference — **the spec is the source of truth for original behavior** (a lot has since
evolved past it per user direction, see "Current status" below), the prototype for exact interaction/copy
details not otherwise specified:
- `uploads/loyalty-points-ui-spec.md` — the original functional spec (screens A–I).
- `HyperDynamics Loyalty Manager.dc.html` / `support.js` / `_ds/` — the original interactive mockup (fake,
  in-memory data, no real auth/payment/SMS). Useful for exact copy, validation rules, and UI states; not
  itself part of the shipped app.

## Commands

**Flutter app** (repo root is the Flutter project root):
- `flutter pub get` — install/update Dart dependencies.
- `flutter analyze` — static analysis; keep this clean.
- `flutter test` — run all tests in `test/`. Run a single file with `flutter test test/formatters_test.dart`.
  Note: `relativeTimeLabel labels a moment 25 hours ago as "yesterday"` is a known day-boundary-flaky test
  (fails if the suite happens to run in the first hour after local midnight) — not a real regression if you
  see it fail in isolation.
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
  `AppSegmentedControl`, `AppBadge`, `StatTile`, `AppListRow` / `txn_list_row.dart` (transaction row
  formatting), `ToastHost` + `feedback_providers.dart`'s `toastProvider` (transient toasts), `LoadingOverlay` +
  `busyProvider` (full-screen busy spinner, use `busyProvider.notifier.run(message, action)`),
  `confirm_dialog.dart`'s `showAppConfirmDialog` (required before any balance-changing action, per spec),
  `nudge_sheet.dart`'s `showAppNudgeDialog` (shared WhatsApp click-to-chat popup — pending-points nudges and
  birthday wishes both use this; a centered `Dialog` with `maxWidth: 440`, matching `showAppConfirmDialog`'s
  pattern — it used to be a `showModalBottomSheet` but that rendered as an oddly-tall, unconstrained-width
  sheet on desktop web, so it was switched to the same centered-dialog convention every other popup in this
  app uses).
- `models/` — plain Dart data classes (`Business`, `Customer`, `LoyaltyTransaction`, `PendingBusiness`,
  `AdminBusinessSummary`) with manual `fromMap` — no codegen. `PaymentOrder` was deleted along with Razorpay.
- `data/` — repositories wrapping Firestore reads and Cloud Functions callable calls: `AuthRepository`
  (business-id/email/Google login, `beginSession`/`currentSessionId` for the device-session-cap feature),
  `BusinessRepository`, `LedgerRepository`, `SignupRepository` (self-signup email + Google),
  `AdminRepository` (operator console: create/approve/list businesses, feature flags, subscription renewal,
  `checkMultiLocation`). **`LedgerRepository` never writes `customers`/`transactions` directly** — every
  balance-mutating action (`earnCredit`, `sendOtp`, `redeemPoints`, `reverseTransaction`) is a Cloud Functions
  callable; the repo only *streams* those collections for display.
- `providers/` — Riverpod (v3, no codegen) providers per concern: `authSessionProvider` (combines Firebase
  Auth's user with the `businessId` custom claim, and now also this device's `sessionId` claim if
  `beginSession` has run — this is what every screen and the router key off), `adminSessionProvider`
  (separate operator-console session), `business_providers.dart`, `ledger_providers.dart` (family providers
  for customer/history/correction-feed/birthday streams), `admin_providers.dart`, `feedback_providers.dart`
  (toast/busy). `payment_providers.dart` was deleted along with Razorpay.
- `features/<name>/` — one folder per concern: `landing` (features + "contact sales" mailto, no visible
  pricing), `signup` (self-signup form + Google button + the `/pending` approval-wait screen), `auth` (login +
  forgot password + Google sign-in), `subscription` (the `/subscription-lapsed` blocking screen), `operator`
  (the hidden `/hd-ops` console), `shell` (responsive app shell + dashboard — sidebar on wide viewports,
  bottom tab bar on narrow, breakpoint `AppSpacing.wideBreakpoint`), `earn` (now requires a bill number),
  `redeem` (includes the OTP subflow), `correction`, `customers` (customer list w/ sort + CSV/PDF export +
  birthday screen), `settings`.
- `app/router.dart` — go_router routes. Pre-auth: `/`, `/login`, `/signup`. Post-signup-pre-approval:
  `/pending`. Lapsed-subscription block: `/subscription-lapsed`. Operator console (its own auth, unrelated to
  the business session):`/hd-ops/login`, `/hd-ops`. Authed business: `ShellRoute` under `/app/*`
  (dashboard/earn/redeem/customers/birthdays/correction/settings). The `redirect` callback reads
  `authSessionProvider`/`currentBusinessProvider`/`adminSessionProvider` directly and is refreshed via
  `GoRouterRefreshNotifier` (see `app/app.dart`, which bridges Riverpod state changes into go_router's
  `refreshListenable` — it also runs the live device-session-eviction check, see below). `/payment/confirm`
  was deleted along with Razorpay.
- `url_strategy/` — a conditional-import shim (`url_strategy.dart` exporting either `_stub.dart` or `_web.dart`
  based on `dart.library.js_interop`) around `flutter_web_plugins`' `usePathUrlStrategy()`. **Don't import
  `package:flutter_web_plugins` directly from non-web-only code** — even behind a runtime `kIsWeb` check, the
  unconditional import broke the iOS build (Dart's `dart:ui_web` isn't available to non-web compile targets).
  Always go through `configureUrlStrategy()` from this shim instead.

#### One-device-at-a-time sessions (`app/app.dart`, `data/auth_repository.dart`, `providers/auth_providers.dart`)

Each business can have at most `maxConcurrentSessions` devices logged in at once (default 1, admin-configurable
per business — see below). `AuthRepository.beginSession()` is called once per **fresh** sign-in (login or
signup screens, all four credential paths — never on a page reload of an already-authed session, which would
pointlessly evict this same device's own prior registration) and returns a `sessionId` straight from the
callable's response. `app.dart`'s `ref.listen(currentBusinessProvider, ...)` debounces 2 seconds then checks
whether this device's `sessionId` is still in the business's active list; if a newer login elsewhere evicted
it, this device signs itself out with a toast. **The debounce is load-bearing, not cosmetic**: `beginSession`'s
own Firestore write echoes back through that same `currentBusinessProvider` stream almost immediately, and
without the debounce a device could see that echo before its own local state finished updating, self-evicting
on login. If you touch this code, keep the debounce (or replace it with something that's provably not racy).

### Firebase backend

**Why Cloud Functions own all balance-mutating writes**: Earn/Redeem/Correction change a customer's point
balance and must be atomic, race-safe, and — for Redeem — gated on a server-verified OTP. `firestore.rules`
denies all client writes to `customers`, `transactions`, `otps`, and the `private/otpGateway` subdoc; only the
Admin SDK (Cloud Functions) can touch them. Business profile fields (name/logo/ratio/OTP toggle/gateway
choice) are simple enough to be direct, rule-guarded client writes (field allow-list in `firestore.rules`) —
everything else on the `businesses/{id}` doc (status, feature flags, subscription date, session list) is
Cloud-Functions-only.

Cloud Functions (`functions/src/`, 17 deployed, exported from `index.ts`):
- Login is by "business id", not email; Firebase Auth only speaks email/password. Provisioning mints each
  business a synthetic login email `{businessId}@<LOGIN_EMAIL_DOMAIN>`. There's deliberately **no Cloud
  Function to resolve it** — `lib/data/auth_repository.dart` computes the same email client-side (it's a
  deterministic, non-secret string), so login/forgot-password work independently of Cloud Functions/Blaze
  being live. Keep `loginEmailDomain` there in sync with `LOGIN_EMAIL_DOMAIN`'s default in `config.ts`.
  Self-signed-up businesses are the exception — they log in with their own real email, not the synthetic one.
- **Razorpay is gone entirely** (`payments.ts`, `lib/razorpay.ts`, and the `/payment/confirm` screen were all
  deleted) — per explicit user direction, in-app payment collection was removed; payment now happens outside
  the app and admin just approves once it's confirmed. Don't re-add a payment gateway without checking this is
  still wanted.
- `selfSignup.ts` — `selfSignup` (email/password) and `selfSignupGoogle` (Google credential, already
  authenticated client-side before calling this) both delegate to `provisionPendingBusiness` in
  `provisioning.ts`, which mints a `businessId` claim on the caller's own uid and writes a `status: 'pending'`
  business doc — no separate account-linking step needed, since self-signup mints its own Firebase Auth
  identity either way.
- `admin.ts` — the **operator console**'s callables, all gated by the `admin` custom claim
  (`requireAdmin`/`authContext.ts` — the hidden `/hd-ops` route is convenience, not the security boundary):
  `adminCreateBusiness` (direct-provision, skips self-signup, `source: 'admin'`, active immediately — for
  friends & family / anyone paid outside normal checkout), `adminListPendingBusinesses` /
  `adminApproveBusiness` (the self-signup approval queue — approving starts the ₹999/year subscription clock
  via `oneYearFrom()`), `adminListBusinesses` (any status, for the "manage businesses" feature-flag/session-cap
  panel), `adminUpdateBusinessFeatures` (partial-merge patch: `birthdayEnabled` / `whatsappEnabled` /
  `exportEnabled` booleans and/or `maxConcurrentSessions` 1–20), `adminRenewSubscription` (extends from the
  later of now or the current renewal date, so early renewal doesn't lose paid time), `bootstrapAdmin` (one-off,
  **not a callable** — an `onRequest` HTTP function guarded by the `ADMIN_BOOTSTRAP_SECRET` Cloud Functions
  secret, since there's no admin yet at that point to gate a claim check with; grants the `admin` claim and
  returns a Firebase-generated password-reset link. Safe to leave deployed indefinitely. Already run once for
  `hyperdynamics08@gmail.com`).
- `sessions.ts` — `beginSession` (registers a device, evicts the oldest over `maxConcurrentSessions`, sets a
  `sessionId` custom claim — merges with the user's *current* claims via `auth.getUser(uid).customClaims`
  first, since `setCustomUserClaims` is a full replace, not a merge, and clobbering `businessId`/`admin` would
  be a real problem) and `requireActiveSession` (the server-side gate called from `earn.ts`/`redeem.ts`/
  `correction.ts`). **Rollout safety**: if a business's `activeSessions` field has never been initialized
  (nobody's logged in since this feature shipped), `requireActiveSession` allows the call through rather than
  locking out every already-open tab the moment this deploys — enforcement only begins once that business's
  first fresh post-deploy login establishes the session record.
- `multiLocation.ts` — `adminCheckMultiLocation`, an admin-only **diagnostic, not a fraud gate**: looks at a
  business's last N days of transactions and reports which calendar days saw activity from more than one
  distinct IP (see `getCallerIp` below), so the operator can judge for themselves whether a business looks like
  it's running several physical branches off one ₹7,999 account, and start a pricing conversation — never an
  automated block. Only transactions posted since IP-capture shipped have anything to analyze.
- `earn.ts`, `otp.ts`, `redeem.ts`, `correction.ts` — the ledger operations, each a Firestore transaction.
  `earn.ts`/`redeem.ts` both call `requireActiveSession` and record `ip: getCallerIp(request)` (best-effort,
  `authContext.ts` — never blocks the transaction if absent) on the transaction doc. `earn.ts` also takes a
  **mandatory `billNumber`** (added as a lightweight fraud deterrent — ties every earn to a real receipt,
  surfaced in the Correction screen's detail panel) and an optional `dob` (→ derived `birthdayMonthDay` for the
  birthday module, "don't overwrite on omission" same as `name`).
- `settings.ts` — `saveOtpGatewayCredentials` (BYO gateway secrets, functions-only storage).
- `stats.ts` — Firestore trigger maintaining `businesses/{id}/stats/summary` incrementally (dashboard tiles),
  plus a midnight-IST scheduled reset of the "today" counters.
- `lib/` — shared helpers: `admin.ts` (Firestore/Auth handles + collection-path helpers), `authContext.ts`
  (`requireBusinessId` — every authed callable derives its tenant from the caller's custom claim, **never**
  from a client-supplied parameter; `requireAdmin`; `getCallerIp`), `format.ts` (incl. `oneYearFrom` for the
  subscription clock, `istDateKey`-style day-bucketing used by both `stats.ts` and `multiLocation.ts`),
  `sms.ts` (MSG91), `mail.ts`. `razorpay.ts` was deleted.
- `config.ts` — all third-party credentials are Cloud Functions secrets (`firebase functions:secrets:set
  <NAME>`): `MSG91_MANAGED_AUTH_KEY`. **Currently a placeholder value**, not a real MSG91 key — so managed-
  gateway OTP SMS won't send end-to-end until a real account exists and the secret is re-set. Everything else
  (self-signup, login, Earn, Redeem with OTP override, Correction, Settings, subscription lockout, session
  caps, the operator console) works today, deployed and verified live on both hosting targets (see below).
  `RAZORPAY_*` and `ONBOARDING_FEE_PAISE` were removed along with Razorpay — don't re-add without checking.
  `ADMIN_BOOTSTRAP_SECRET` (a real secret, already set) guards `bootstrapAdmin`.
- `defineString` params (`MSG91_SENDER_ID`, `LOGIN_EMAIL_DOMAIN`) are pinned in
  `functions/.env.hyperdynamics-loyalty` (committed — these aren't secrets, just non-interactive-deploy
  requirements) to their documented defaults from `config.ts`. `APP_BASE_URL` was removed along with Razorpay
  (it only fed the webhook callback URL).

### Data model

See the Firestore layout and security-rule rationale in `firestore.rules`; summary: `businesses/{id}` (+
`private/otpGateway`, `customers/{phone}`, `transactions/{txnId}`, `otps/{phone}`, `stats/summary`
subcollections). `paymentOrders/{referenceId}` (top-level, publicly-readable-by-id) was deleted along with
Razorpay.

`businesses/{id}` fields beyond the client-writable allow-list
(`displayName`/`logoUrl`/`pointsRatio`/`otpEnabled`/`gateway`) — all Cloud-Functions-only:
- `status`: `'pending'` | `'active'` — self-signed-up businesses start pending; admin-created ones start active.
- `source`: `'admin'` | `'selfSignup'`, `ownerEmail`, `ownerPhone` — audit-only, set once at provisioning.
- `subscriptionRenewsAt`: Timestamp, null until approval — the ₹999/year clock.
- `birthdayEnabled` / `whatsappEnabled` / `exportEnabled`: bool, default false — paid add-ons.
- `maxConcurrentSessions`: number, default 1 (when absent) — see the session-cap feature above.
- `activeSessions`: `Array<{sessionId, deviceLabel, createdAtMs}>` — current session occupants.

`transactions/{txnId}` also carries `billNumber` (earn, required), `ip` (earn/redeem, best-effort). `customers/
{phone}` also carries `dob`/`birthdayMonthDay` (optional, set at earn time).

## Current status (as of 2026-08-11)

Verified: `flutter analyze` clean, `flutter test` passing (bar the known day-boundary-flaky test noted above),
`flutter build web --release` succeeds. Deployed and smoke-tested **live** (not simulated) via a scripted
Playwright browser against the demo account: login → session registration → an actual `earnCredit` call →
correction/reversal, all confirmed working end-to-end after the session-cap feature shipped.

### Already live — don't redo this

- **Firebase project** `hyperdynamics-loyalty` (CLI account `hyperdynamics08@gmail.com`, aliased `default` in
  `.firebaserc`). `lib/firebase_options.dart`, `android/app/google-services.json`,
  `ios/Runner/GoogleService-Info.plist` are all real, flutterfire-generated config.
- **Firestore** (region `asia-south1`) — database, `firestore.rules`, `firestore.indexes.json` all deployed.
- **Authentication** — Email/Password enabled, Google sign-in wired client-side but **not yet enabled in the
  Firebase Console** (see Pending). **Demo login: business id `demo`, password `demo1234`** — has real,
  accumulated demo transaction history (not just one seeded row anymore).
- **Operator console** — `hyperdynamics08@gmail.com` already has the `admin` custom claim (granted via
  `bootstrapAdmin`). Log in at `/hd-ops/login` on either deployed site with that real email. To grant admin to
  another real email: `curl -G
  https://us-central1-hyperdynamics-loyalty.cloudfunctions.net/bootstrapAdmin --data-urlencode
  "secret=$(firebase functions:secrets:access ADMIN_BOOTSTRAP_SECRET)" --data-urlencode "email=<email>"`, then
  have them use the returned link to set their password.
- **All 17 Cloud Functions** deployed on the Blaze plan (`firebase functions:list` to confirm) — matches
  `index.ts` exactly.
- **Firebase Storage** — bucket live, `storage.rules` deployed, logo upload works. **CORS policy applied
  directly to the bucket** (via the Cloud Storage JSON API, not `gsutil` — wasn't installed locally; used a
  short-lived access token minted from the Firebase CLI's own stored refresh token instead) — without it,
  logo images uploaded fine but silently failed to *render* in the Flutter web app specifically (CanvasKit
  fetches images cross-origin; a plain browser tab or `curl` hitting the same download URL worked fine, which
  is what made this confusing — the OPTIONS preflight was already permissive, only the actual GET response was
  missing `Access-Control-Allow-Origin`). If logos ever stop rendering again, check this first before assuming
  a code regression: `curl -sI <download-url> -H "Origin: https://yourdomain"` should show
  `access-control-allow-origin`.
- **Two hosting targets, deliberately kept both**:
  - **Firebase Hosting** (staging/testing): **https://hyperdynamics-loyalty.web.app**. Redeploy:
    `flutter build web --release && firebase deploy --only hosting`. Effectively free to keep running (Hosting's
    free tier comfortably covers low-traffic staging use even though the project is on Blaze for Functions).
  - **Hostinger shared hosting** (production, the user's own domain): **https://hyperpoints.hyperdynamics.in**,
    document root `domains/hyperpoints.hyperdynamics.in/public_html`. **Deploy workflow is NOT a plain
    `rsync`/`scp` over SSH for the whole build** — Hostinger's SSH gateway has some kind of IO/duration limit
    that silently truncates or resets the connection on individual files roughly over ~1MB (confirmed via
    direct experiments: a 300KB–1MB test payload never landed on disk at all despite the client reporting
    "100% transferred"; `main.dart.js` and `canvaskit.wasm` — both several MB — got corrupted this way twice
    before the workaround was found). **The reliable path**: small files (`.htaccess`, `index.html`, fonts,
    icons, manifest, service worker) go fine via `rsync -avz` over SSH; `main.dart.js` and (if it changed)
    `canvaskit.wasm` must be zipped locally and uploaded through **hPanel's own File Manager web upload +
    Extract**, which isn't subject to the same SSH-jail limit. A `.htaccess` (SPA fallback rewrite +
    `Cache-Control: no-cache` on `.js`/`.css`, to avoid the exact "still see the old page" confusion that
    happened once from Firebase Hosting's default caching) needs to exist in the document root — it's not
    tracked in this repo (lives only on the server), so if the site ever needs re-provisioning from scratch,
    recreate it: `RewriteEngine On` + `RewriteCond %{REQUEST_FILENAME} !-f`/`!-d` → `RewriteRule . /index.html
    [L]`. SSH host/port/username/password are **not stored in this repo** (it's public on GitHub) — they're
    held by the user; ask them if you need to deploy and don't already have them in your current session
    context.
- Onboarding is **two tiers**, not the original spec's flat ₹5,000, and pricing has changed once already since
  launch: **₹7,999 standard** and **₹12,999 standard + OTP-verified redemptions** (was ₹4,999/₹7,999 at first
  launch). Shown on the signup form's plan toggle and the operator console; the landing page itself shows no
  numbers at all (just a feature list + "contact sales" mailto — pricing lives in the actual signup/admin
  flows, not publicly).
- **GitHub repo** (public): **https://github.com/HyperDynamics/hyperdynamics-loyalty-manager** — auto-deploys
  to **https://hyperdynamics.github.io/hyperdynamics-loyalty-manager/** on every push to `main` via
  `.github/workflows/deploy-pages.yml`. Kept as a zero-config mirror alongside the two real hosting targets
  above (that GitHub Pages URL is not one of the two that matters — don't confuse it with staging/production).

### Pending — ordered by what unblocks the most

0. **Production (Hostinger) is running a stale build missing the whole session-cap feature — deploy it.**
   User-reported symptom (2026-08-11): could log into the same account on Mac + phone simultaneously even with
   `maxConcurrentSessions` set to 1, and only found out via a "you've been signed out" error *while redeeming*
   — and bumping the cap to 2 didn't fix it either, both devices kept logging each other out. Root cause,
   confirmed by diffing the deployed bundles: `curl .../main.dart.js | grep beginSession` — **0 matches on
   `hyperpoints.hyperdynamics.in`, 1 match on `hyperdynamics-loyalty.web.app`**. The session-cap feature's
   *backend* (`beginSession`, `requireActiveSession` in `earnCredit`/`redeemPoints`/`reverseTransaction`) is
   already live — Cloud Functions are one shared backend for both hosting targets — but its *frontend* (the
   code that actually calls `beginSession` on login and registers a device) was only ever pushed to Firebase
   staging, never to Hostinger. Net effect: any device logging in through the production site never gets a
   `sessionId` claim at all, so it can **never** satisfy `requireActiveSession` on a mutating call — not "logs
   out the other device," but "can never win," regardless of the cap value. This is why it looked contradictory:
   the enforcement is real and working exactly as designed, just only reachable from a frontend that was never
   shipped to the domain being tested on. **Fix**: rebuild (`flutter build web --release`), and deploy to
   `hyperpoints.hyperdynamics.in` via the zip + hPanel File Manager process (see "Already live" above) — this
   was sitting ready to go before this was reported, just never confirmed/pushed. Also worth checking: the
   `demo` business's `activeSessions` field almost certainly already has stale entries from extensive
   Playwright-driven testing against staging earlier — if login issues persist on that account specifically
   after the production deploy, that's why; a fresh login from any device with the new build will naturally
   clear it (oldest gets evicted), no manual cleanup needed.
1. **Google Sign-In real Web Client ID.** `lib/data/auth_repository.dart`'s `googleWebClientId` constant is
   still a placeholder. Someone needs to enable Google as a sign-in provider in Firebase Console →
   Authentication → Sign-in method (manual, can't be scripted), which auto-generates the real Web Client ID —
   substitute it in. Until then, both Google sign-up and Google sign-in fail gracefully (a clean "not available
   yet, use business id and password" error, not a crash — this used to actually blank the entire app because
   `main.dart` initialized `GoogleSignIn` eagerly before `runApp`; that's fixed, initialization is now lazy and
   only happens on first tap of a Google button).
2. **Real MSG91 account.** `MSG91_MANAGED_AUTH_KEY` is a placeholder — needed for the "managed by us" OTP
   gateway option to send real SMS. (BYO gateway businesses supply their own key via Settings regardless.)
3. **Missing Firestore composite index for the sales-summary aggregation query — likely what's behind the
   "sales filter not working as expected" report (2026-08-11).** Noticed independently via browser console
   during unrelated testing: `RunAggregationQuery` on `transactions` (type/status/createdAt range, used by the
   dashboard's sales-summary card and its today/week/month/custom filter) throws `failed-precondition` with a
   400 on every call. Hadn't been confirmed as user-visible before, but a query that always 400s would produce
   exactly "the filter doesn't seem to do anything" — the card likely just shows stale/zero numbers regardless
   of which range is selected. Check `firestore.indexes.json` against what the actual query in
   `ledger_repository.dart`'s `fetchSalesSummary` needs and add the missing composite index; Firestore's own
   error message (visible in browser dev tools console) usually includes a direct console link to create it.
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
  `firebase.json`, deploying, then restoring it (`git diff --stat firebase.json` should show no diff once
  restored).
- A brand-new Firebase project's *very first* Cloud Functions deploy is expected to need 2–4 retries as GCP
  APIs (Secret Manager, Eventarc, Cloud Run, Pub/Sub, Cloud Scheduler) finish enabling and propagating IAM
  grants — retry the same `firebase deploy --only functions` command; it's not a code problem. Not an issue
  anymore now that functions are already deployed, but relevant again if this ever moves to a fresh project.
- **Smoke-testing the deployed web app**: this is a CanvasKit-rendered Flutter web app, so most of the UI is
  painted to a `<canvas>`, not real DOM — there are no `<input>`/`<button>` elements to select for automated
  testing. If you need to script a login/interaction flow (e.g. Playwright) against it: (1) text fields only
  become real focusable DOM elements *on focus*, so drive everything by clicking pixel coordinates from a
  screenshot, not selectors; (2) the very first click on a freshly-loaded page can get silently eaten (some
  kind of first-gesture/permission handshake) — do a throwaway warm-up interaction first, or just accept the
  first real click might need a retry; (3) reverse-tab order (`Shift+Tab` from a field that's reliably
  clickable, like the last one) was noticeably more reliable than forward-`Tab` for moving focus between
  fields in testing; (4) don't use `page.goto()` for in-app navigation once logged in — it does a full reload
  which is unnecessary and slower than just clicking the sidebar nav; (5) `waitUntil: 'networkidle'` never
  fires once Firestore's realtime listeners are open (they hold a connection forever by design) — use `'load'`
  plus an explicit wait instead for any post-login navigation.
- Cost estimate (Blaze free tier + usage-based pricing): Firebase/GCP infra cost stays low even at a fairly
  aggressive scale (~$30–35/month for 1,000 active businesses doing 100 ledger ops/day each) — the free tier
  covers ~200K ledger transactions/month before Firestore write charges even start. Firebase Hosting's own free
  tier separately covers low-traffic staging use at effectively $0. The costs that actually scale with revenue
  are **outside** Firebase's bill: MSG91 SMS at ~₹0.18–0.25/message for OTP-verified redemptions (billed
  through to the business per the Settings copy, not absorbed) — this is the one to watch once OTP-add-on
  adoption and redeem volume are both high. (Razorpay's per-transaction cut no longer applies — payment
  collection moved outside the app.)
