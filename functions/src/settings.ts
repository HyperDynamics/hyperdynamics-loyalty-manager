import { onCall, HttpsError } from "firebase-functions/https";
import { FieldValue } from "firebase-admin/firestore";
import { privateGatewayDoc } from "./lib/admin";
import { requireBusinessId } from "./lib/authContext";

/**
 * H. Settings — "bring your own" OTP gateway credentials. Written to the
 * Cloud-Functions-only `private/otpGateway` subdocument (see
 * firestore.rules) via a callable rather than a direct client write, so
 * the secret never sits behind a client-writable security rule.
 */
export const saveOtpGatewayCredentials = onCall(async (request) => {
  const businessId = requireBusinessId(request);
  const apiKey = String(request.data?.apiKey ?? "").trim();
  const apiSecret = String(request.data?.apiSecret ?? "").trim();
  if (!apiKey || !apiSecret) throw new HttpsError("invalid-argument", "api key and secret are required.");

  await privateGatewayDoc(businessId).set({ apiKey, apiSecret, updatedAt: FieldValue.serverTimestamp() });
  return { ok: true };
});
