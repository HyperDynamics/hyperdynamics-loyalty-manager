import { randomUUID } from "crypto";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/https";
import { auth, businessRef } from "./lib/admin";
import { requireBusinessId } from "./lib/authContext";

export interface ActiveSession {
  sessionId: string;
  deviceLabel: string;
  createdAtMs: number;
}

const DEFAULT_MAX_SESSIONS = 1;

/** Oldest-first, keeping only the newest `cap` sessions — shared by `beginSession` (adding a new
 * session that may push the business over cap) and `adminUpdateBusinessFeatures` (an admin lowering
 * the cap itself, which must evict existing over-cap sessions immediately rather than waiting for
 * the next login to trim them). */
export function trimSessionsToCap(sessions: ActiveSession[], cap: number): ActiveSession[] {
  const sorted = sessions.slice().sort((a, b) => a.createdAtMs - b.createdAtMs);
  return sorted.slice(Math.max(0, sorted.length - cap));
}

/**
 * Called right after a device signs in (once its `businessId` claim is
 * confirmed present) — registers this device as an active session, evicting
 * the oldest session(s) if that pushes the business over its configured
 * `maxConcurrentSessions` (admin-set, default 1 — see `adminUpdateBusinessFeatures`).
 * `earnCredit`/`redeemPoints`/`reverseTransaction` then refuse to run for any
 * device whose session got evicted (see `requireActiveSession` below).
 */
export const beginSession = onCall(async (request) => {
  const businessId = requireBusinessId(request);
  const deviceLabel = String(request.data?.deviceLabel ?? "device").trim().slice(0, 60);
  const sessionId = randomUUID();

  const ref = businessRef(businessId);
  const snap = await ref.get();
  const maxSessions = (snap.get("maxConcurrentSessions") as number | undefined) ?? DEFAULT_MAX_SESSIONS;
  const existing = ((snap.get("activeSessions") as ActiveSession[] | undefined) ?? []).slice();

  existing.push({ sessionId, deviceLabel, createdAtMs: Date.now() });
  const kept = trimSessionsToCap(existing, maxSessions);

  await ref.set({ activeSessions: kept }, { merge: true });

  // Custom claims are a full replace, not a merge — read the user's current
  // claims first so this never clobbers `businessId`/`admin`.
  const user = await auth.getUser(request.auth!.uid);
  await auth.setCustomUserClaims(request.auth!.uid, { ...user.customClaims, sessionId });

  return { sessionId };
});

/**
 * Gate for the ledger-mutating callables. Grandfathered rollout: a business
 * whose `activeSessions` has never been initialized (nobody has logged in
 * since this feature shipped) is left unrestricted rather than locking out
 * every already-signed-in tab the moment this deploys — enforcement begins
 * the first time any device on that business does a fresh login.
 */
export async function requireActiveSession(request: CallableRequest): Promise<void> {
  const businessId = requireBusinessId(request);
  const snap = await businessRef(businessId).get();
  const activeSessions = snap.get("activeSessions") as ActiveSession[] | undefined;
  if (activeSessions === undefined) return;

  const sessionId = request.auth?.token?.sessionId as string | undefined;
  const stillActive = !!sessionId && activeSessions.some((s) => s.sessionId === sessionId);
  if (!stillActive) {
    throw new HttpsError("permission-denied", "signed out — this account is active on another device.");
  }
}
