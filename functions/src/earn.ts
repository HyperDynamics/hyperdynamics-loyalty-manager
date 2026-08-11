import { onCall, HttpsError } from "firebase-functions/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, businessRef, customersCol, transactionsCol } from "./lib/admin";
import { requireBusinessId, getCallerIp } from "./lib/authContext";
import { requireActiveSession } from "./sessions";
import { digitsOnly, pointsForAmount } from "./lib/format";

/** E. Earn — credits points for a bill amount at the business's configured ratio. */
export const earnCredit = onCall(async (request) => {
  const businessId = requireBusinessId(request);
  await requireActiveSession(request);
  const phone = digitsOnly(String(request.data?.phone ?? ""));
  const amount = Number(request.data?.amount);
  const name = String(request.data?.name ?? "").trim().slice(0, 60);
  const billNumber = String(request.data?.billNumber ?? "").trim().slice(0, 40);
  const dobRaw = request.data?.dob !== undefined && request.data?.dob !== null ? String(request.data.dob).trim() : "";

  if (phone.length !== 10) throw new HttpsError("invalid-argument", "enter a valid 10-digit phone number.");
  if (!Number.isFinite(amount) || amount <= 0) throw new HttpsError("invalid-argument", "enter a valid bill amount.");
  if (!billNumber) throw new HttpsError("invalid-argument", "enter the bill number.");
  if (dobRaw && !/^\d{4}-\d{2}-\d{2}$/.test(dobRaw)) {
    throw new HttpsError("invalid-argument", "enter a valid date of birth.");
  }
  // "MM-DD" — lets the birthday screen match on month+day with a cheap,
  // auto-indexed single-field equality query, without needing to know the
  // year.
  const birthdayMonthDay = dobRaw ? dobRaw.slice(5) : "";

  const bizSnap = await businessRef(businessId).get();
  if (!bizSnap.exists) throw new HttpsError("not-found", "business not found.");
  const ratio = (bizSnap.get("pointsRatio") as number | undefined) ?? 10;
  const points = pointsForAmount(amount, ratio);

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
      createdAt: FieldValue.serverTimestamp(),
      createdBy: request.auth!.uid,
      ip: getCallerIp(request),
    });

    return nextBalance;
  });

  return { points, newBalance };
});
