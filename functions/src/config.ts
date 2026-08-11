import { defineSecret, defineString } from "firebase-functions/params";

/**
 * All third-party credentials are Cloud Functions secrets (set via
 * `firebase functions:secrets:set <NAME>`), never committed. Fill this in
 * once a real MSG91 account exists.
 */
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
