import { HttpsError, CallableRequest } from "firebase-functions/https";

/**
 * Every authenticated callable derives its tenant from the caller's
 * `businessId` custom claim — never from a client-supplied parameter — so
 * one business can never operate on another's data even if the client is
 * compromised or buggy.
 */
export function requireBusinessId(request: CallableRequest): string {
  const businessId = request.auth?.token?.businessId;
  if (!request.auth || typeof businessId !== "string" || businessId.length === 0) {
    throw new HttpsError("unauthenticated", "sign in required.");
  }
  return businessId;
}

/**
 * Gates the internal operator console's callables (business creation
 * outside the payment flow). The `admin` custom claim is never
 * client-settable — it's only ever granted out-of-band via the
 * secret-guarded `bootstrapAdmin` HTTP function, so this is a real
 * server-side authorization boundary, not just a hidden route.
 */
export function requireAdmin(request: CallableRequest): void {
  if (!request.auth || request.auth.token?.admin !== true) {
    throw new HttpsError("permission-denied", "not authorized.");
  }
}

/**
 * Best-effort caller IP, recorded on point-of-sale transactions (earn/
 * redeem) purely as a diagnostic signal for `adminCheckMultiLocation` — one
 * business account used across several physical branches tends to show
 * transactions from multiple distinct networks on the same day. Not used
 * for any access-control decision, so a missing/spoofed value is harmless.
 */
export function getCallerIp(request: CallableRequest): string | null {
  const forwarded = request.rawRequest?.headers?.["x-forwarded-for"];
  const raw = Array.isArray(forwarded) ? forwarded[0] : forwarded;
  const ip = raw?.split(",")[0]?.trim();
  return ip || request.rawRequest?.ip || null;
}
