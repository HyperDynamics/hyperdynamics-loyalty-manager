import { onCall, HttpsError } from "firebase-functions/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, customersCol, transactionsCol } from "./lib/admin";
import { requireBusinessId } from "./lib/authContext";
import { requireActiveSession } from "./sessions";

/**
 * G. Correction Tool — reverses a posted transaction, adjusting the
 * customer's balance by the inverse of the original effect. Aborts
 * mid-transaction if it's already reversed, closing the double-click /
 * concurrent-admin race the prototype didn't need to worry about.
 */
export const reverseTransaction = onCall(async (request) => {
  const businessId = requireBusinessId(request);
  await requireActiveSession(request);
  const txnId = String(request.data?.txnId ?? "");
  if (!txnId) throw new HttpsError("invalid-argument", "txnId is required.");

  const txnRef = transactionsCol(businessId).doc(txnId);

  await db.runTransaction(async (tx) => {
    const txnSnap = await tx.get(txnRef);
    if (!txnSnap.exists) throw new HttpsError("not-found", "transaction not found.");
    const txn = txnSnap.data()!;
    if (txn.status === "reversed") {
      throw new HttpsError("failed-precondition", "already reversed — no further action available.");
    }

    const custRef = customersCol(businessId).doc(txn.phone as string);
    const custSnap = await tx.get(custRef);
    const currentBalance = custSnap.exists ? ((custSnap.get("balance") as number) ?? 0) : 0;
    const delta = txn.type === "earn" ? -(txn.points as number) : (txn.points as number);
    const nextBalance = Math.max(0, currentBalance + delta);

    if (custSnap.exists) {
      tx.update(custRef, { balance: nextBalance, updatedAt: FieldValue.serverTimestamp() });
    } else {
      tx.set(custRef, {
        phone: txn.phone,
        name: "customer",
        balance: nextBalance,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    tx.update(txnRef, {
      status: "reversed",
      reversedAt: FieldValue.serverTimestamp(),
      reversedBy: request.auth!.uid,
    });
  });

  return { ok: true };
});
