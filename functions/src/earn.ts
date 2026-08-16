import { onCall, HttpsError } from "firebase-functions/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, customersCol, transactionsCol } from "./lib/admin";
import { requireBusinessId, getCallerIp, getActorLabel, getRole } from "./lib/authContext";
import { loadAuthorizedBusiness } from "./sessions";
import { digitsOnly, pointsForAmount } from "./lib/format";

/** E. Earn — credits points for a bill amount at the business's configured ratio. */
export const earnCredit = onCall(async (request) => {
  const businessId = requireBusinessId(request);
  const phone = digitsOnly(String(request.data?.phone ?? ""));
  const amount = Number(request.data?.amount);
  const name = String(request.data?.name ?? "").trim().slice(0, 60);
  const billNumber = String(request.data?.billNumber ?? "").trim().slice(0, 40);
  const dobRaw = request.data?.dob !== undefined && request.data?.dob !== null ? String(request.data.dob).trim() : "";
  const manualPointsRaw = request.data?.manualPoints;

  if (phone.length !== 10) throw new HttpsError("invalid-argument", "enter a valid 10-digit phone number.");
  if (!Number.isFinite(amount) || amount <= 0) throw new HttpsError("invalid-argument", "enter a valid bill amount.");
  if (dobRaw && !/^\d{4}-\d{2}-\d{2}$/.test(dobRaw)) {
    throw new HttpsError("invalid-argument", "enter a valid date of birth.");
  }
  // "MM-DD" — lets the birthday screen match on month+day with a cheap,
  // auto-indexed single-field equality query, without needing to know the
  // year.
  const birthdayMonthDay = dobRaw ? dobRaw.slice(5) : "";

  const bizSnap = await loadAuthorizedBusiness(request, "earn");

  // Both of these are owner-configured in Settings, and both are re-checked here
  // rather than trusted from the client: the earn form hides the manual-points
  // field when it's off, but hiding an input is not a constraint.
  const billNumberRequired = (bizSnap.get("billNumberRequired") as boolean | undefined) ?? true;
  if (billNumberRequired && !billNumber) throw new HttpsError("invalid-argument", "enter the bill number.");

  const manualPointsEnabled = (bizSnap.get("manualPointsEnabled") as boolean | undefined) ?? false;
  const ratio = (bizSnap.get("pointsRatio") as number | undefined) ?? 10;

  let points = pointsForAmount(amount, ratio);
  let manualPointsApplied = false;
  if (manualPointsRaw !== undefined && manualPointsRaw !== null && String(manualPointsRaw).trim() !== "") {
    if (!manualPointsEnabled) {
      throw new HttpsError("failed-precondition", "manual points are not enabled for this business.");
    }
    const manual = Number(manualPointsRaw);
    if (!Number.isInteger(manual) || manual < 0) {
      throw new HttpsError("invalid-argument", "enter a whole number of points.");
    }
    points = manual;
    manualPointsApplied = true;
  }

  const custRef = customersCol(businessId).doc(phone);
  const txnRef = transactionsCol(businessId).doc();

  const newBalance = await db.runTransaction(async (tx) => {
    const custSnap = await tx.get(custRef);
    const currentBalance = custSnap.exists ? ((custSnap.get("balance") as number) ?? 0) : 0;
    const nextBalance = currentBalance + points;

    if (custSnap.exists) {
      const update: Record<string, unknown> = { balance: nextBalance, updatedAt: FieldValue.serverTimestamp() };
      if (name) update.name = name;
      if (dobRaw) {
        update.dob = dobRaw;
        update.birthdayMonthDay = birthdayMonthDay;
      }
      tx.update(custRef, update);
    } else {
      tx.set(custRef, {
        phone,
        name: name || "customer",
        balance: nextBalance,
        ...(dobRaw ? { dob: dobRaw, birthdayMonthDay } : {}),
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    tx.set(txnRef, {
      type: "earn",
      phone,
      amount,
      points,
      billNumber,
      status: "ok",
      otpOverride: false,
      manualPoints: manualPointsApplied,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: request.auth!.uid,
      createdByName: getActorLabel(request),
      createdByRole: getRole(request),
      ip: getCallerIp(request),
    });

    return nextBalance;
  });

  return { points, newBalance };
});
