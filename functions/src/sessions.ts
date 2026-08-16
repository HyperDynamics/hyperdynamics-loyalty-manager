import { randomUUID } from "crypto";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/https";
import { auth, businessRef } from "./lib/admin";
import { requireBusinessId, StaffPermission, assertStaffPermission } from "./lib/authContext";

export interface ActiveSession {
  sessionId: string;
  deviceLabel: string;
  createdAtMs: number;
  /** Absent on entries written before staff roles existed — see `trimSessionsToCap`. */
  uid?: string;
}

const DEFAULT_MAX_SESSIONS = 1;
const LEGACY_SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000;

/**
 * Caps concurrent devices **per user account**, not per business. Each account —
 * the owner's and every staff member's — gets its own allowance of `cap` devices,
 * so a business with several staff no longer has them signing each other out; the
 * original point of the cap (one account can't be shared across branches) still
 * holds, since it's still enforced within each account.
 *
 * Entries with no `uid` predate staff roles and can't be attributed to an account.
 * They're deliberately left in place rather than evicted — dropping them would sign
 * out every already-logged-in owner the moment this deploys — and simply age out
 * after `LEGACY_SESSION_TTL_MS` so the array can't grow forever.
 *
 * Shared by `beginSession` (adding a device that may push its own account over cap)
 * and `adminUpdateBusinessFeatures` (an operator lowering the cap, which must evict
 * over-cap devices immediately rather than waiting for each account's next login).
 */
export function trimSessionsToCap(sessions: ActiveSession[], cap: number, now = Date.now()): ActiveSession[] {
  const legacy = sessions.filter((s) => !s.uid && now - s.createdAtMs < LEGACY_SESSION_TTL_MS);

  const byUid = new Map<string, ActiveSession[]>();
  for (const s of sessions) {
    if (!s.uid) continue;
    const list = byUid.get(s.uid) ?? [];
    list.push(s);
    byUid.set(s.uid, list);
  }

  const kept: ActiveSession[] = [...legacy];
  for (const list of byUid.values()) {
    list.sort((a, b) => a.createdAtMs - b.createdAtMs);
    kept.push(...list.slice(Math.max(0, list.length - cap)));
  }
  return kept.sort((a, b) => a.createdAtMs - b.createdAtMs);
}

/**
 * Called right after a device signs in (once its `businessId` claim is
 * confirmed present) — registers this device as an active session, evicting
 * this *same account's* oldest session(s) if that pushes it over the business's
 * configured `maxConcurrentSessions` (admin-set, default 1 — see
 * `adminUpdateBusinessFeatures`). Other accounts on the business are untouched.
 * `earnCredit`/`redeemPoints`/`reverseTransaction` then refuse to run for any
 * device whose session got evicted (see `assertSessionActive`/`loadAuthorizedBusiness` below).
 */
export const beginSession = onCall(async (request) => {
  const businessId = requireBusinessId(request);
  const deviceLabel = String(request.data?.deviceLabel ?? "device").trim().slice(0, 60);
  const sessionId = randomUUID();

  const ref = businessRef(businessId);
  const snap = await ref.get();
  const maxSessions = (snap.get("maxConcurrentSessions") as number | undefined) ?? DEFAULT_MAX_SESSIONS;
  const existing = ((snap.get("activeSessions") as ActiveSession[] | undefined) ?? []).slice();

  existing.push({ sessionId, deviceLabel, createdAtMs: Date.now(), uid: request.auth!.uid });
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
export function assertSessionActive(request: CallableRequest, bizSnap: FirebaseFirestore.DocumentSnapshot): void {
  const activeSessions = bizSnap.get("activeSessions") as ActiveSession[] | undefined;
  if (activeSessions === undefined) return;

  const sessionId = request.auth?.token?.sessionId as string | undefined;
  const stillActive = !!sessionId && activeSessions.some((s) => s.sessionId === sessionId);
  if (!stillActive) {
    throw new HttpsError("permission-denied", "signed out — this account is active on another device.");
  }
}

/**
 * One Firestore read covering three checks earn/redeem/correction all need
 * regardless — the business exists, this device's session is still live, and
 * this account (owner or staff) is allowed to perform `permission` — instead of
 * each doing its own separate `businessRef().get()`. Two sequential reads of
 * the same document on every single Earn/Redeem tap was real, measurable
 * latency added directly to the click-to-response path; this merges them into
 * one round trip. Returns the snapshot so the caller can also pull whatever
 * settings it needs (ratio, staffPermissions, otpEnabled, …) from the same
 * read rather than fetching again.
 */
export async function loadAuthorizedBusiness(
  request: CallableRequest,
  permission: StaffPermission
): Promise<FirebaseFirestore.DocumentSnapshot> {
  const businessId = requireBusinessId(request);
  const snap = await businessRef(businessId).get();
  if (!snap.exists) throw new HttpsError("not-found", "business not found.");
  assertSessionActive(request, snap);
  assertStaffPermission(request, permission, snap.get("staffPermissions"));
  return snap;
}
