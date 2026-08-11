import { onCall, HttpsError } from "firebase-functions/https";
import { createPendingBusinessAccount, provisionPendingBusiness } from "./provisioning";

/**
 * Signup form's email/password path. Creates the business in
 * `status: 'pending'` — see `createPendingBusinessAccount` — the client
 * signs itself in with the same email/password right after this resolves,
 * then lands on `/pending` until an admin approves it (payment is confirmed
 * outside the app; see `adminApproveBusiness`).
 */
export const selfSignup = onCall(async (request) => {
  const businessName = String(request.data?.businessName ?? "").trim();
  const plan = request.data?.plan === "otp" ? "otp" : "base";
  const email = String(request.data?.email ?? "").trim();
  const password = String(request.data?.password ?? "");
  const ownerPhone = String(request.data?.ownerPhone ?? "").trim();

  if (!businessName) throw new HttpsError("invalid-argument", "enter a business name.");
  if (!email.includes("@")) throw new HttpsError("invalid-argument", "enter a valid email address.");
  if (password.length < 6) throw new HttpsError("invalid-argument", "password must be at least 6 characters.");

  try {
    return await createPendingBusinessAccount({
      businessName,
      plan,
      email,
      password,
      ownerPhone: ownerPhone || undefined,
    });
  } catch (err: unknown) {
    if ((err as { code?: string })?.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "an account with this email already exists.");
    }
    throw err;
  }
});

/**
 * Signup form's "sign up with google" path. The client has already
 * completed a Google sign-in before calling this — unlike `selfSignup`,
 * there's no Firebase Auth user to mint here, just a business to attach to
 * the uid Google sign-in already produced. Idempotent: a second call from
 * an already-claimed uid just returns the existing businessId.
 */
export const selfSignupGoogle = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "sign in required.");

  const existingBusinessId = request.auth.token?.businessId;
  if (typeof existingBusinessId === "string" && existingBusinessId) {
    return { businessId: existingBusinessId };
  }

  const email = request.auth.token?.email as string | undefined;
  if (!email || request.auth.token?.email_verified !== true) {
    throw new HttpsError("failed-precondition", "your google account's email must be verified.");
  }

  const businessName = String(request.data?.businessName ?? "").trim();
  const plan = request.data?.plan === "otp" ? "otp" : "base";
  const ownerPhone = String(request.data?.ownerPhone ?? "").trim();
  if (!businessName) throw new HttpsError("invalid-argument", "enter a business name.");

  return provisionPendingBusiness({
    businessName,
    plan,
    ownerEmail: email.toLowerCase(),
    ownerPhone: ownerPhone || undefined,
    uid: request.auth.uid,
  });
});
