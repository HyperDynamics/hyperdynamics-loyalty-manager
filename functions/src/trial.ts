import { onCall, HttpsError } from "firebase-functions/https";
import { onSchedule } from "firebase-functions/scheduler";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { requireAdmin } from "./lib/authContext";
import { businessRef, db } from "./lib/admin";

/**
 * Hard ceiling on a trial, per product decision: a trial may never run longer
 * than two weeks. Enforced server-side rather than only in the console, since
 * the callable is the real boundary.
 */
export const MAX_TRIAL_DAYS = 14;
export const DEFAULT_TRIAL_DAYS = 14;

/** The add-ons a "full-featured" trial switches on for the trial window. */
export const TRIAL_ADD_ONS = ["birthdayEnabled", "whatsappEnabled", "exportEnabled"] as const;
export type TrialAddOn = (typeof TRIAL_ADD_ONS)[number];

export function clampTrialDays(raw: unknown): number {
  const n = Math.floor(Number(raw));
  if (!Number.isFinite(n) || n < 1) {
    throw new HttpsError("invalid-argument", "trial length must be a whole number of days.");
  }
  if (n > MAX_TRIAL_DAYS) {
    throw new HttpsError("invalid-argument", `a trial may not exceed ${MAX_TRIAL_DAYS} days.`);
  }
  return n;
}

export function daysFromNow(days: number, from: Date = new Date()): Date {
  const out = new Date(from);
  out.setDate(out.getDate() + days);
  return out;
}

/**
 * Starts (or restarts) a trial on a business.
 *
 * A trial is deliberately not a new account state — it's the ordinary
 * `status: 'active'` plus a short `subscriptionRenewsAt`, so expiry reuses the
 * machinery that already exists: `Business.subscriptionLapsed` flips on its
 * own and the router confines the business to `/subscription-lapsed`. No timer
 * has to fire for the lockout to happen, which means a missed scheduled run
 * can never hand anyone free access.
 *
 * `isTrial` exists only so the UI can say "trial ended" rather than
 * "subscription lapsed", and so a later conversion knows to undo the add-ons.
 *
 * The end date is always computed from **now**, never added to an existing
 * one, so repeated calls can't stack a business past the two-week ceiling.
 */
export const adminStartTrial = onCall(async (request) => {
  requireAdmin(request);
  const businessId = String(request.data?.businessId ?? "").trim();
  if (!businessId) throw new HttpsError("invalid-argument", "missing businessId.");
  const days = clampTrialDays(request.data?.days ?? DEFAULT_TRIAL_DAYS);

  const ref = businessRef(businessId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "business not found.");

  // Only grant the add-ons this business doesn't already have, and record
  // exactly which ones we granted. Reverting blindly would strip an add-on the
  // business had actually paid for before the trial started.
  const granted = TRIAL_ADD_ONS.filter((flag) => (snap.get(flag) as boolean | undefined) !== true);
  const endsAt = daysFromNow(days);

  const patch: Record<string, unknown> = {
    status: "active",
    activatedVia: "trial",
    activatedAt: FieldValue.serverTimestamp(),
    subscriptionRenewsAt: Timestamp.fromDate(endsAt),
    isTrial: true,
    trialStartedAt: FieldValue.serverTimestamp(),
    trialDays: days,
    trialGrantedAddOns: granted,
  };
  for (const flag of granted) patch[flag] = true;

  await ref.set(patch, { merge: true });
  return { businessId, days, trialEndsAt: endsAt.toISOString(), grantedAddOns: granted };
});

/**
 * Clears trial state off a business, putting back any add-on the trial itself
 * switched on. Shared by the scheduled sweep and by conversion-to-paid, so
 * both undo a trial identically.
 */
export function clearTrialPatch(grantedAddOns: string[]): Record<string, unknown> {
  const patch: Record<string, unknown> = {
    isTrial: false,
    trialGrantedAddOns: FieldValue.delete(),
  };
  // Only flags this trial granted — never one the business already had.
  for (const flag of grantedAddOns) {
    if ((TRIAL_ADD_ONS as readonly string[]).includes(flag)) patch[flag] = false;
  }
  return patch;
}

/**
 * Daily sweep that tidies up expired trials nobody converted.
 *
 * This is bookkeeping, not enforcement — an expired trial is already locked
 * out by `subscriptionLapsed` the moment the clock passes, regardless of
 * whether this ever runs. All it does is stop a lapsed trial from sitting in
 * the operator console still showing add-ons it's no longer entitled to.
 */
export const expireTrials = onSchedule(
  { schedule: "30 0 * * *", timeZone: "Asia/Kolkata" },
  async () => {
    const now = Timestamp.now();
    const due = await db
      .collection("businesses")
      .where("isTrial", "==", true)
      .where("subscriptionRenewsAt", "<=", now)
      .get();

    for (const doc of due.docs) {
      const granted = ((doc.get("trialGrantedAddOns") as string[] | undefined) ?? []).slice();
      await doc.ref.set({ ...clearTrialPatch(granted), trialExpiredAt: FieldValue.serverTimestamp() }, { merge: true });
    }
  }
);
