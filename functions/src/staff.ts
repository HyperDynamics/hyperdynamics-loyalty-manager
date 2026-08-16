import { onCall, HttpsError } from "firebase-functions/https";
import { FieldValue } from "firebase-admin/firestore";
import { UserRecord } from "firebase-admin/auth";
import { requireAdmin, requireOwner } from "./lib/authContext";
import { auth, businessRef, staffCol } from "./lib/admin";

/**
 * Staff accounts are self-serve, created and removed by the *business owner* in
 * their own Settings screen — capped at `maxStaffSeats` per business (default 3,
 * operator-adjustable per business from `/hd-ops`, same pattern as
 * `maxConcurrentSessions`). `/hd-ops` itself only gets a read-only staff list
 * (`adminListStaff`) plus the seat-cap stepper — one authoritative place to
 * actually add/remove staff avoids the two consoles drifting out of sync on who's
 * really on an account.
 *
 * Staff sign in with Google only — no password is ever minted for them. The Auth
 * user is pre-created here from their Gmail address so the `businessId`/`role`
 * claims exist before their first sign-in; Firebase then links the Google
 * credential to this same uid on that first sign-in, because the project uses the
 * default "one account per email address" setting. If that setting were ever
 * flipped to allow multiple accounts per email, Google sign-in would mint a
 * *second* uid without these claims and staff login would silently break.
 */

const DEFAULT_MAX_STAFF_SEATS = 3;

/** Shared shape returned to the client for both create and list. */
function staffRow(uid: string, data: FirebaseFirestore.DocumentData) {
  return {
    uid,
    email: (data.email as string | undefined) ?? "",
    displayName: (data.displayName as string | undefined) ?? "",
    createdAtMs: (data.createdAt as FirebaseFirestore.Timestamp | undefined)?.toMillis() ?? null,
  };
}

export const ownerCreateStaff = onCall(async (request) => {
  const businessId = requireOwner(request);
  const email = String(request.data?.email ?? "").trim().toLowerCase();
  const displayName = String(request.data?.displayName ?? "").trim();

  if (!email) throw new HttpsError("invalid-argument", "enter the staff member's email.");
  // Google-only sign-in: a non-Google address would create an account that can
  // never actually be signed into, so reject it here rather than at first login.
  if (!/^[^@\s]+@(gmail\.com|googlemail\.com)$/.test(email)) {
    throw new HttpsError("invalid-argument", "staff sign in with Google — enter a gmail address.");
  }

  const bizSnap = await businessRef(businessId).get();
  if (!bizSnap.exists) throw new HttpsError("not-found", "business not found.");

  const maxStaffSeats = (bizSnap.get("maxStaffSeats") as number | undefined) ?? DEFAULT_MAX_STAFF_SEATS;
  const seatCount = (await staffCol(businessId).count().get()).data().count;
  if (seatCount >= maxStaffSeats) {
    throw new HttpsError(
      "resource-exhausted",
      `you can have at most ${maxStaffSeats} staff account${maxStaffSeats === 1 ? "" : "s"} — remove one first, or contact us to raise the limit.`
    );
  }

  let userRecord: UserRecord;
  try {
    userRecord = await auth.getUserByEmail(email);
  } catch {
    userRecord = await auth.createUser({ email, displayName: displayName || undefined });
  }

  // Never silently move an account that already belongs somewhere else — that
  // would detach it from its current business (or demote an owner) without any
  // trace. Re-adding to the same business is allowed and idempotent.
  const existingClaims = userRecord.customClaims ?? {};
  const existingBusinessId = existingClaims.businessId as string | undefined;
  if (existingBusinessId && existingBusinessId !== businessId) {
    throw new HttpsError("already-exists", "that account already belongs to another business.");
  }
  if (existingClaims.admin === true) {
    throw new HttpsError("failed-precondition", "that account is an operator account.");
  }

  await auth.setCustomUserClaims(userRecord.uid, { ...existingClaims, businessId, role: "staff" });
  await staffCol(businessId).doc(userRecord.uid).set(
    {
      email,
      displayName: displayName || userRecord.displayName || "",
      createdAt: FieldValue.serverTimestamp(),
      createdBy: request.auth!.uid,
    },
    { merge: true }
  );

  const saved = await staffCol(businessId).doc(userRecord.uid).get();
  return staffRow(userRecord.uid, saved.data() ?? {});
});

export const ownerRemoveStaff = onCall(async (request) => {
  const businessId = requireOwner(request);
  const uid = String(request.data?.uid ?? "").trim();
  if (!uid) throw new HttpsError("invalid-argument", "missing uid.");

  const staffDoc = await staffCol(businessId).doc(uid).get();
  if (!staffDoc.exists) throw new HttpsError("not-found", "staff member not found.");

  // Strip the tenant claims so the account can no longer resolve a business at
  // all, and drop its device sessions so any signed-in tab is evicted on its
  // next check rather than lingering with a valid sessionId.
  const user = await auth.getUser(uid);
  const claims = { ...(user.customClaims ?? {}) };
  delete claims.businessId;
  delete claims.role;
  await auth.setCustomUserClaims(uid, claims);
  await auth.revokeRefreshTokens(uid);

  const bizSnap = await businessRef(businessId).get();
  const sessions = (bizSnap.get("activeSessions") as Array<{ uid?: string }> | undefined) ?? [];
  await businessRef(businessId).set(
    { activeSessions: sessions.filter((s) => s.uid !== uid) },
    { merge: true }
  );

  await staffCol(businessId).doc(uid).delete();
  return { removed: uid };
});

/** Operator's read-only view in /hd-ops — no create/remove counterpart here on purpose. */
export const adminListStaff = onCall(async (request) => {
  requireAdmin(request);
  const businessId = String(request.data?.businessId ?? "").trim();
  if (!businessId) throw new HttpsError("invalid-argument", "missing businessId.");

  const snap = await staffCol(businessId).orderBy("createdAt", "asc").get();
  return snap.docs.map((d) => staffRow(d.id, d.data()));
});
