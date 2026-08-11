import { onCall, onRequest, HttpsError } from "firebase-functions/https";
import { defineSecret } from "firebase-functions/params";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { requireAdmin } from "./lib/authContext";
import { auth, businessRef, db } from "./lib/admin";
import { oneYearFrom } from "./lib/format";
import { createBusinessAccount } from "./provisioning";
import { ActiveSession, trimSessionsToCap } from "./sessions";

/**
 * Operator console's "create business" action — provisions an account
 * directly, bypassing self-signup entirely. For friends & family, test
 * accounts, or any business admin wants to onboard without them going
 * through the signup form. Gated by the `admin` custom claim, never by the
 * route being unlinked — see requireAdmin.
 */
export const adminCreateBusiness = onCall(async (request) => {
  requireAdmin(request);

  const businessName = String(request.data?.businessName ?? "").trim();
  const plan = request.data?.plan === "otp" ? "otp" : "base";
  const ownerEmail = String(request.data?.ownerEmail ?? "").trim();
  const ownerPhone = String(request.data?.ownerPhone ?? "").trim();

  if (!businessName) throw new HttpsError("invalid-argument", "enter a business name.");

  return createBusinessAccount({
    businessName,
    plan,
    ownerEmail: ownerEmail || undefined,
    ownerPhone: ownerPhone || undefined,
    source: "admin",
  });
});

/**
 * Operator console's "pending approvals" list — businesses that self-signed
 * up (see `selfSignup.ts`, email/password or Google) and are waiting on
 * admin to confirm payment (collected outside the app) and approve. Rules
 * only grant per-owner read on `businesses`, so listing across all of them
 * has to go through the Admin SDK via a callable, not a direct client query.
 */
export const adminListPendingBusinesses = onCall(async (request) => {
  requireAdmin(request);
  const snap = await db.collection("businesses").where("status", "==", "pending").orderBy("createdAt", "desc").get();
  return snap.docs.map((d) => ({
    businessId: d.id,
    displayName: (d.get("displayName") as string) ?? d.id,
    otpEnabled: (d.get("otpEnabled") as boolean) ?? false,
    ownerEmail: (d.get("ownerEmail") as string) ?? "",
    ownerPhone: (d.get("ownerPhone") as string) ?? "",
    createdAt: (d.get("createdAt")?.toDate?.() as Date | undefined)?.toISOString() ?? null,
  }));
});

/**
 * Approves a self-signed-up business once admin has confirmed payment
 * (collected outside the app — bank transfer, UPI, invoice, etc.). The
 * ₹999/year subscription clock starts now — one year from approval, not
 * from signup — see `oneYearFrom`.
 */
export const adminApproveBusiness = onCall(async (request) => {
  requireAdmin(request);
  const businessId = String(request.data?.businessId ?? "").trim();
  if (!businessId) throw new HttpsError("invalid-argument", "missing businessId.");

  const ref = businessRef(businessId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "business not found.");
  if (snap.get("status") !== "pending") throw new HttpsError("failed-precondition", "business is not pending.");

  await ref.set(
    {
      status: "active",
      activatedVia: "admin",
      activatedAt: FieldValue.serverTimestamp(),
      subscriptionRenewsAt: Timestamp.fromDate(oneYearFrom()),
    },
    { merge: true }
  );
});

/**
 * Renews a business's ₹999/year subscription — the manual counterpart to
 * `adminApproveBusiness`'s initial grant, called whenever admin confirms a
 * renewal payment (collected outside the app, same as onboarding). Extends
 * from the later of "now" or the current renewal date, so renewing early
 * doesn't lose the remaining paid time, and renewing late doesn't grant
 * more than a year from today.
 */
export const adminRenewSubscription = onCall(async (request) => {
  requireAdmin(request);
  const businessId = String(request.data?.businessId ?? "").trim();
  if (!businessId) throw new HttpsError("invalid-argument", "missing businessId.");

  const ref = businessRef(businessId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "business not found.");

  const current = snap.get("subscriptionRenewsAt") as Timestamp | undefined;
  const base = current && current.toMillis() > Date.now() ? current.toDate() : new Date();
  const next = oneYearFrom(base);

  await ref.set({ subscriptionRenewsAt: Timestamp.fromDate(next) }, { merge: true });
  return { subscriptionRenewsAt: next.toISOString() };
});

/**
 * Operator console's "manage businesses" browser — lists businesses of any
 * status so admin can toggle add-on feature flags on already-active ones,
 * not just pending ones. Same reasoning as `adminListPendingBusinesses`:
 * rules only grant per-owner read, so this has to go through the Admin SDK.
 */
export const adminListBusinesses = onCall(async (request) => {
  requireAdmin(request);
  const search = String(request.data?.search ?? "").trim().toLowerCase();
  const snap = await db.collection("businesses").orderBy("createdAt", "desc").limit(200).get();
  const rows = snap.docs.map((d) => ({
    businessId: d.id,
    displayName: (d.get("displayName") as string) ?? d.id,
    ownerEmail: (d.get("ownerEmail") as string) ?? "",
    otpEnabled: (d.get("otpEnabled") as boolean) ?? false,
    birthdayEnabled: (d.get("birthdayEnabled") as boolean) ?? false,
    whatsappEnabled: (d.get("whatsappEnabled") as boolean) ?? false,
    exportEnabled: (d.get("exportEnabled") as boolean) ?? false,
    subscriptionRenewsAt: (d.get("subscriptionRenewsAt")?.toDate?.() as Date | undefined)?.toISOString() ?? null,
    maxConcurrentSessions: (d.get("maxConcurrentSessions") as number) ?? 1,
    activeSessionCount: ((d.get("activeSessions") as unknown[]) ?? []).length,
  }));
  if (!search) return rows;
  return rows.filter(
    (r) =>
      r.businessId.toLowerCase().includes(search) ||
      r.displayName.toLowerCase().includes(search) ||
      r.ownerEmail.toLowerCase().includes(search)
  );
});

/**
 * Toggles a business's add-on feature flags — birthday nudges, whatsapp
 * nudges, csv/pdf export — sold separately from the base tier — and/or its
 * `maxConcurrentSessions` cap (see `sessions.ts`: how many devices can be
 * logged in to this one shared account at once, admin-configurable per
 * business rather than a fixed "just Netflix it" default). Deliberately not
 * client-writable (see firestore.rules' businesses update allow-list): only
 * admin can grant these.
 */
export const adminUpdateBusinessFeatures = onCall(async (request) => {
  requireAdmin(request);
  const businessId = String(request.data?.businessId ?? "").trim();
  if (!businessId) throw new HttpsError("invalid-argument", "missing businessId.");

  const patch: Record<string, boolean | number | ActiveSession[]> = {};
  for (const key of ["birthdayEnabled", "whatsappEnabled", "exportEnabled"] as const) {
    if (typeof request.data?.[key] === "boolean") patch[key] = request.data[key];
  }
  if (typeof request.data?.maxConcurrentSessions === "number") {
    patch.maxConcurrentSessions = Math.min(20, Math.max(1, Math.round(request.data.maxConcurrentSessions)));
  }
  if (Object.keys(patch).length === 0) throw new HttpsError("invalid-argument", "no fields provided.");

  const ref = businessRef(businessId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "business not found.");

  // Lowering the cap must evict already-active over-cap sessions right away —
  // otherwise they'd stay valid until the next fresh login happens to trim
  // them, which could be days, and "the limit doesn't actually apply" is
  // exactly the bug this is meant to prevent.
  if (typeof patch.maxConcurrentSessions === "number") {
    const existing = (snap.get("activeSessions") as ActiveSession[] | undefined) ?? [];
    patch.activeSessions = trimSessionsToCap(existing, patch.maxConcurrentSessions);
  }

  await ref.set(patch, { merge: true });
});

const ADMIN_BOOTSTRAP_SECRET = defineSecret("ADMIN_BOOTSTRAP_SECRET");

/**
 * One-off bootstrap for granting the `admin` custom claim to an operator's
 * real email — there's no admin yet at that point to gate this behind a
 * claim check, so it's guarded by a Cloud Functions secret instead
 * (`?secret=...` query param). Not a callable on purpose: keeps it out of
 * the app's Functions surface entirely; only reachable by whoever holds
 * the secret. Safe to leave deployed — grants nobody anything without it.
 */
export const bootstrapAdmin = onRequest({ secrets: [ADMIN_BOOTSTRAP_SECRET] }, async (req, res) => {
  if (req.query.secret !== ADMIN_BOOTSTRAP_SECRET.value()) {
    res.status(403).send("forbidden");
    return;
  }
  const email = String(req.query.email ?? "").trim();
  if (!email) {
    res.status(400).send("missing email query param");
    return;
  }

  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(email);
  } catch {
    userRecord = await auth.createUser({ email });
  }
  await auth.setCustomUserClaims(userRecord.uid, { admin: true });

  const resetLink = await auth.generatePasswordResetLink(email);
  res.status(200).send(`admin claim granted to ${email}\n\nset your password: ${resetLink}`);
});
