# Loyalty Points Tool — UI/Component Requirements

Scope: functional requirements per screen and component only. Visual styling follows your existing design system — this covers what each component must do, not how it looks.

---

## A. Public Landing Page (pre-signup)

**Components:**
- **Header** — logo, product name
- **Hero block** — headline, one-line value prop, "Get Started — ₹4,999" CTA button
- **Pricing card** — states the flat ₹5k fee, what's included (Earn, Redeem, Correction Tool), note that OTP is a paid add-on
- **CTA Button** → triggers Razorpay Payment Link (external redirect, not embedded)
- **Footer** — contact/support link

**States:** default only (static marketing page, no auth).

---

## B. Post-Payment Confirmation Page

**Components:**
- **Success message** — "Payment received, check your email for login details"
- **Failure/pending message** — shown if redirected back without confirmed webhook success; includes support contact
- No form inputs on this page — it's purely a redirect landing target from Razorpay

---

## C. Admin Login Screen

**Components:**
- **Business ID / username field**
- **Password field** (masked, show/hide toggle)
- **Login button**
- **Forgot password link** → triggers reset flow (email-based, out of scope detail beyond trigger)
- **Error state** — invalid credentials message inline, not a toast (needs to persist until corrected)

---

## D. Admin Dashboard (Home)

**Components:**
- **Business header** — logo + business name pulled from tenant config
- **Quick stats cards** (optional but useful): today's Earn count, today's Redeem count, total points outstanding
- **Primary navigation** — Earn / Redeem / History (Correction) / Settings, always visible (tab bar or side nav depending on design system)
- **Logout control**

---

## E. Earn Screen

**Components:**
- **Phone number input** — numeric keypad, format validation (length check)
- **Bill amount input** — numeric keypad, currency formatting
- **Live points preview** — recalculates in real time as bill amount changes, using the business's configured ratio (e.g., "₹450 → 45 pts")
- **Submit/Credit button** — disabled until both fields are valid
- **Success confirmation** — toast or inline banner: "45 points credited to 98765XXXXX"
- **Recent earn list** (optional but recommended) — last 5 entries this session, each showing phone (partially masked), amount, points, timestamp — gives the admin a quick undo entry point into the Correction Tool

**States:** empty (no input yet), validating, success, error (e.g., network failure — show retry).

---

## F. Redeem Screen

**Components:**
- **Phone number input** + **Lookup button**
- **Customer balance card** (appears after lookup) — current points balance, prominently displayed
- **Recent visit history list** — last few Earn/Redeem entries for this phone number (date, amount, points) — this is the admin's manual verification context, not decorative
- **Points-to-redeem input** — numeric, with inline validation: blocks and shows error if `requested > available balance`
- **OTP input field — CONDITIONAL** — only rendered if this business has the OTP add-on enabled; hidden entirely otherwise. When shown: appears after "Send OTP" is triggered, has its own submit/verify action
- **Confirm Redeem button** — label/behavior differs slightly depending on whether OTP is active ("Redeem" vs "Verify & Redeem")
- **Success confirmation** — "20 points redeemed. New balance: 25"
- **Empty state** — "No customer found with this number" (distinct from a genuine zero-balance customer)
- **OTP failure/fallback state** — if OTP delivery fails, show an admin override option ("Force approve — logs as override") so redemption is never permanently blocked

---

## G. Correction Tool Screen

**Components:**
- **Transaction list** — recent Earn/Redeem entries, filterable by phone number
- **Transaction detail view** — full record: type, phone, amount/points, timestamp, status
- **Reverse/Correct action** — opens an edit form (phone number and/or amount) or a straight reversal button
- **Confirmation dialog** — required before any reversal/correction commits, since this directly changes a customer's balance

---

## H. Settings Screen

**Components:**
- **Business profile section** — business name, logo upload, points ratio config (e.g., "₹ per point")
- **OTP module section** — toggle (only interactive if add-on purchased); when enabled, fields for gateway choice: "Bring your own" (API key/secret inputs) vs "Managed" (read-only, shows it's billed by us)
- **Admin password change form**
- **Logout control**

---

## I. Shared/System-Level Components

- **Toast/snackbar** — used for all success and transient error messages (Earn success, Redeem success, network errors)
- **Inline error banner** — used where an error must persist until the user fixes input (login failure, redeem-exceeds-balance)
- **Loading indicator** — used during lookup, submit, and OTP verification actions
- **Confirmation dialog** — reused for Correction Tool reversals and any other destructive/balance-changing action
- **Masked phone number display** — used anywhere a phone number is shown in a list, for basic privacy (e.g., 98765XXXXX)

---

## Notes on what's intentionally NOT here
- No customer-facing screens of any kind (confirmed out of scope in the PRD)
- No multi-staff role management UI (single admin login only, v1)
- No points-expiry configuration UI (not in v1)
