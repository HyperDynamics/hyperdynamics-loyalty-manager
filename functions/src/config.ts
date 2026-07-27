import { defineSecret, defineString } from "firebase-functions/params";

/**
 * All third-party credentials are Cloud Functions secrets (set via
 * `firebase functions:secrets:set <NAME>`), never committed. Fill these in
 * once real Razorpay / MSG91 accounts exist — see the plan's note that
 * these integrations are wired for real but need live keys.
 */
export const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
export const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");
export const RAZORPAY_WEBHOOK_SECRET = defineSecret("RAZORPAY_WEBHOOK_SECRET");

// Managed-gateway MSG91 account HyperDynamics bills SMS through when a
// business picks "managed by us" instead of bringing their own gateway.
export const MSG91_MANAGED_AUTH_KEY = defineSecret("MSG91_MANAGED_AUTH_KEY");
export const MSG91_SENDER_ID = defineString("MSG91_SENDER_ID", { default: "HYPRDY" });

// Domain used to mint synthetic login emails for "business id" auth, e.g.
// mintmax@login.hyperdynamics.app — never actually sent mail, just an
// Auth-compatible identifier.
export const LOGIN_EMAIL_DOMAIN = defineString("LOGIN_EMAIL_DOMAIN", {
  default: "login.hyperdynamics.app",
});

// Base URL of the deployed Flutter web app, used to build the Razorpay
// Payment Link's callback_url. Update once Firebase Hosting is live.
export const APP_BASE_URL = defineString("APP_BASE_URL", {
  default: "https://hyperdynamics-loyalty-placeholder.web.app",
});

export const ONBOARDING_FEE_PAISE = 500000; // ₹5,000, in the smallest currency unit Razorpay expects
