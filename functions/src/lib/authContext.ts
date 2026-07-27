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
