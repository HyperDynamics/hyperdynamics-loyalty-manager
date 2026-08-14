import { onCall, HttpsError } from "firebase-functions/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, businessRef, customersCol, transactionsCol } from "./lib/admin";
import { requireBusinessId, getCallerIp, getActorLabel, getRole, assertStaffPermission } from "./lib/authContext";
import { requireActiveSession } from "./sessions";
import { digitsOnly } from "./lib/format";
import { verifyOtpOrThrow } from "./otp";
import { MSG91_MANAGED_AUTH_KEY } from "./config";

/**
 * F. Redeem — debits points after optional server-verified OTP. `override`
 * lets the admin force through a redemption when OTP delivery is failing;
 * the transaction record keeps `otpOverride: true` as the audit trail the
 * spec calls for ("logs as override").
 */
export const redeemPoints = onCall({ secrets: [MSG91_MANAGED_AUTH_KEY] }, async (request) => {
  const businessId = requireBusinessId(request);
  await requireActiveSession(request);
  const phone = digitsOnly(String(request.data?.phone ?? ""));
  const points = Number(request.data?.points);
  const otpCode = request.data?.otpCode ? String(request.data.otpCode) : undefined;
  const override = Boolean(request.data?.override);

  if (phone.length !== 10) throw new HttpsError("invalid-argument", "enter a valid phone number.");
  if (!Number.isFinite(points) || points <= 0) throw new HttpsError("invalid-argument", "enter a valid points amount.");

  const bizSnap = await businessRef(businessId).get();
  if (!bizSnap.exists) throw new HttpsError("not-found", "business not found.");
  assertStaffPermission(request, "redeem", bizSnap.get("staffPermissions"));
  const otpEnabled = (bizSnap.get("otpEnabled") as boolean | undefined) ?? false;

  let otpOverride = false;
  if (otpEnabled) {
    if (override) {
      otpOverride = true;
    } else {
      await verifyOtpOrThrow(businessId, phone, otpCode);
    }
  }

  const custRef = customersCol(businessId).doc(phone);
  const txnRef = transactionsCol(businessId).doc();

  const newBalance = await db.runTransaction(async (tx) => {
    const custSnap = await tx.get(custRef);
    if (!custSnap.exists) throw new HttpsError("failed-precondition", "no customer found with this number.");
    const currentBalance = (custSnap.get("balance") as number | undefined) ?? 0;
    if (points > currentBalance) {
      throw new HttpsError("failed-precondition", `exceeds available balance of ${currentBalance} pts`);
    }
    const nextBalance = currentBalance - points;

    tx.update(custRef, { balance: nextBalance, updatedAt: FieldValue.serverTimestamp() });
    tx.set(txnRef, {
      type: "redeem",
      phone,
      amount: null,
      points,
      status: "ok",
      otpOverride,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: request.auth!.uid,
      createdByName: getActorLabel(request),
      createdByRole: getRole(request),
      ip: getCallerIp(request),
    });

    return nextBalance;
  });

  return { newBalance };
});
