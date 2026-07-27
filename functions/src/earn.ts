import { onCall, HttpsError } from "firebase-functions/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, businessRef, customersCol, transactionsCol } from "./lib/admin";
import { requireBusinessId } from "./lib/authContext";
import { digitsOnly, pointsForAmount } from "./lib/format";

/** E. Earn — credits points for a bill amount at the business's configured ratio. */
export const earnCredit = onCall(async (request) => {
  const businessId = requireBusinessId(request);
  const phone = digitsOnly(String(request.data?.phone ?? ""));
  const amount = Number(request.data?.amount);

  if (phone.length !== 10) throw new HttpsError("invalid-argument", "enter a valid 10-digit phone number.");
  if (!Number.isFinite(amount) || amount <= 0) throw new HttpsError("invalid-argument", "enter a valid bill amount.");

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
      tx.update(custRef, { balance: nextBalance, updatedAt: FieldValue.serverTimestamp() });
    } else {
      tx.set(custRef, {
        phone,
        name: "customer",
        balance: nextBalance,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    tx.set(txnRef, {
      type: "earn",
      phone,
      amount,
      points,
      status: "ok",
      otpOverride: false,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: request.auth!.uid,
    });

    return nextBalance;
  });

  return { points, newBalance };
});
