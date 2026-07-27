import crypto from "crypto";
import { onCall, HttpsError } from "firebase-functions/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, businessRef, otpsCol, privateGatewayDoc } from "./lib/admin";
import { requireBusinessId } from "./lib/authContext";
import { digitsOnly, randomDigits } from "./lib/format";
import { sendSmsViaMsg91 } from "./lib/sms";
import { MSG91_MANAGED_AUTH_KEY, MSG91_SENDER_ID } from "./config";

const OTP_TTL_MS = 5 * 60 * 1000;
const MAX_ATTEMPTS = 5;

function hashCode(businessId: string, phone: string, code: string): string {
  return crypto.createHash("sha256").update(`${businessId}:${phone}:${code}`).digest("hex");
}

/** F. Redeem's OTP step — generates and sends a 4-digit code via the business's configured gateway. */
export const sendOtp = onCall({ secrets: [MSG91_MANAGED_AUTH_KEY] }, async (request) => {
  const businessId = requireBusinessId(request);
  const phone = digitsOnly(String(request.data?.phone ?? ""));
  if (phone.length !== 10) throw new HttpsError("invalid-argument", "enter a valid phone number.");

  const bizSnap = await businessRef(businessId).get();
  if (!bizSnap.exists) throw new HttpsError("not-found", "business not found.");

  const code = randomDigits(4);
  await otpsCol(businessId)
    .doc(phone)
    .set({
      phone,
      codeHash: hashCode(businessId, phone, code),
      expiresAt: Date.now() + OTP_TTL_MS,
      attempts: 0,
      verified: false,
      createdAt: FieldValue.serverTimestamp(),
    });

  const message = `${code} is your OTP to verify this redemption. Valid 5 min. - HyperDynamics`;
  const gateway = (bizSnap.get("gateway") as string | undefined) ?? "managed";

  if (gateway === "byo") {
    const gwSnap = await privateGatewayDoc(businessId).get();
    if (!gwSnap.exists) throw new HttpsError("failed-precondition", "sms gateway is not configured yet — set it up in settings.");
    await sendSmsViaMsg91({
      authKey: gwSnap.get("apiKey") as string,
      phone,
      message,
      senderId: MSG91_SENDER_ID.value(),
    });
  } else {
    await sendSmsViaMsg91({
      authKey: MSG91_MANAGED_AUTH_KEY.value(),
      phone,
      message,
      senderId: MSG91_SENDER_ID.value(),
    });
  }

  return { sent: true };
});

const OTP_FAILURE_MESSAGE = "otp didn't verify. try again or override.";

/** Used by redeem.ts — throws HttpsError('failed-precondition', ...) on any failure to verify. */
export async function verifyOtpOrThrow(businessId: string, phone: string, code: string | undefined): Promise<void> {
  if (!code) throw new HttpsError("invalid-argument", "enter the otp code.");
  const ref = otpsCol(businessId).doc(phone);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("failed-precondition", OTP_FAILURE_MESSAGE);
    const data = snap.data()!;

    if (data.verified) throw new HttpsError("failed-precondition", "this otp was already used — send a new one.");
    if (Date.now() > (data.expiresAt as number)) throw new HttpsError("failed-precondition", OTP_FAILURE_MESSAGE);
    if ((data.attempts as number) >= MAX_ATTEMPTS) throw new HttpsError("failed-precondition", OTP_FAILURE_MESSAGE);

    if (data.codeHash !== hashCode(businessId, phone, code)) {
      tx.update(ref, { attempts: FieldValue.increment(1) });
      throw new HttpsError("failed-precondition", OTP_FAILURE_MESSAGE);
    }

    tx.update(ref, { verified: true });
  });
}
