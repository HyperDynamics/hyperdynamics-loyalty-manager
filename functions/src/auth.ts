import { onCall, HttpsError } from "firebase-functions/https";
import { db, businessRef } from "./lib/admin";
import { LOGIN_EMAIL_DOMAIN } from "./config";

const RATE_LIMIT_MAX_ATTEMPTS = 10;
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000;

/**
 * Login is by "business id", but Firebase Auth only speaks email/password.
 * This resolves business id -> the synthetic login email minted for that
 * business at provisioning time, so the client can then call
 * signInWithEmailAndPassword. Deliberately doesn't reveal whether a
 * business id exists — an unknown id just resolves to `null`, which the
 * client folds into the same generic "invalid business id or password".
 *
 * Rate-limited per business id to slow down enumeration; for production,
 * also enable Firebase App Check on this callable.
 */
export const resolveBusinessLoginEmail = onCall(
  { cors: true },
  async (request) => {
    const businessId = String(request.data?.businessId ?? "").trim().toLowerCase();
    if (!businessId) {
      throw new HttpsError("invalid-argument", "business id is required.");
    }

    await enforceRateLimit(businessId);

    const snap = await businessRef(businessId).get();
    if (!snap.exists || snap.get("status") !== "active") {
      return { email: null };
    }
    return { email: `${businessId}@${LOGIN_EMAIL_DOMAIN.value()}` };
  }
);

async function enforceRateLimit(key: string): Promise<void> {
  const ref = db.collection("loginRateLimits").doc(key);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    const data = snap.data() as { count: number; windowStart: number } | undefined;

    if (!data || now - data.windowStart > RATE_LIMIT_WINDOW_MS) {
      tx.set(ref, { count: 1, windowStart: now });
      return;
    }
    if (data.count >= RATE_LIMIT_MAX_ATTEMPTS) {
      throw new HttpsError("resource-exhausted", "too many attempts. try again later.");
    }
    tx.update(ref, { count: data.count + 1 });
  });
}
