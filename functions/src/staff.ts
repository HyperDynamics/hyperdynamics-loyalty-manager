import { onCall, HttpsError } from "firebase-functions/https";
import { FieldValue } from "firebase-admin/firestore";
import { UserRecord } from "firebase-admin/auth";
import { requireAdmin } from "./lib/authContext";
import { auth, businessRef, staffCol } from "./lib/admin";

/**
 * Staff accounts are created by the *HyperDynamics operator* in `/hd-ops`, not by
 * the business owner — seats are the commercial lever, so handing businesses
 * self-serve creation would give away the thing being sold. What the owner does
 * control is the single `staffPermissions` policy in Settings (what any staff
 * member may do); this file only controls who exists.
 *
 * Staff sign in with Google only — no password is ever minted for them. The Auth
 * user is pre-created here from their Gmail address so the `businessId`/`role`
 * claims exist before their first sign-in; Firebase then links the Google
 * credential to this same uid on that first sign-in, because the project uses the
 * default "one account per email address" setting. If that setting were ever
 * flipped to allow multiple accounts per email, Google sign-in would mint a
 * *second* uid without these claims and staff login would silently break.
 */

/** Shared shape returned to the console for both create and list. */
function staffRow(uid: string, data: FirebaseFirestore.DocumentData) {
  return {
    uid,
    email: (data.email as string | undefined) ?? "",
    displayName: (data.displayName as string | undefined) ?? "",
    createdAtMs: (data.createdAt as FirebaseFirestore.Timestamp | undefined)?.toMillis() ?? null,
  };
}

export const adminCreateStaff = onCall(async (request) => {
  requireAdmin(request);
  const businessId = String(request.data?.businessId ?? "").trim();
  const email = String(request.data?.email ?? "").trim().toLowerCase();
  const displayName = String(request.data?.displayName ?? "").trim();

  if (!businessId) throw new HttpsError("invalid-argument", "missing businessId.");
  if (!email) throw new HttpsError("invalid-argument", "enter the staff member's email.");
  // Google-only sign-in: a non-Google address would create an account that can
  // never actually be signed into, so reject it here rather than at first login.
  if (!/^[^@\s]+@(gmail\.com|googlemail\.com)$/.test(email)) {
    throw new HttpsError("invalid-argument", "staff sign in with Google — enter a gmail address.");
  }

  const bizSnap = await businessRef(businessId).get();
  if (!bizSnap.exists) throw new HttpsError("not-found", "business not found.");

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

export const adminListStaff = onCall(async (request) => {
  requireAdmin(request);
  const businessId = String(request.data?.businessId ?? "").trim();
  if (!businessId) throw new HttpsError("invalid-argument", "missing businessId.");

  const snap = await staffCol(businessId).orderBy("createdAt", "asc").get();
  return snap.docs.map((d) => staffRow(d.id, d.data()));
});

export const adminRemoveStaff = onCall(async (request) => {
  requireAdmin(request);
  const businessId = String(request.data?.businessId ?? "").trim();
  const uid = String(request.data?.uid ?? "").trim();
  if (!businessId || !uid) throw new HttpsError("invalid-argument", "missing businessId or uid.");

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
