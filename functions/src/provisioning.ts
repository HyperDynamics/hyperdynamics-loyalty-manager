import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { auth, businessRef, statsDoc } from "./lib/admin";
import { oneYearFrom, randomSlugSuffix, slugify } from "./lib/format";
import { enqueueEmail, welcomeEmailHtml } from "./lib/mail";
import { LOGIN_EMAIL_DOMAIN } from "./config";
import { DEFAULT_STAFF_PERMISSIONS } from "./lib/authContext";

/** Defaults for the owner-configurable settings added alongside staff roles.
 * `billNumberRequired` starts true and `salesDashboardEnabled` starts true so a
 * newly provisioned business behaves exactly as every business did before those
 * switches existed — the toggles subtract capability, they don't add it. */
const BUSINESS_SETTINGS_DEFAULTS = {
  billNumberRequired: true,
  manualPointsEnabled: false,
  birthdayWindowDays: 1,
  salesDashboardEnabled: true,
  staffPermissions: DEFAULT_STAFF_PERMISSIONS,
  maxStaffSeats: 3,
};

const PASSWORD_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";

function randomPassword(length = 10): string {
  let out = "";
  for (let i = 0; i < length; i++) {
    out += PASSWORD_ALPHABET[Math.floor(Math.random() * PASSWORD_ALPHABET.length)];
  }
  return out;
}

async function reserveBusinessId(preferredName: string): Promise<string> {
  const base = slugify(preferredName || "business");
  for (let attempt = 0; attempt < 8; attempt++) {
    const candidate = attempt === 0 ? base : `${base}-${randomSlugSuffix(4)}`;
    const snap = await businessRef(candidate).get();
    if (!snap.exists) return candidate;
  }
  throw new Error("could not allocate a unique business id");
}

/**
 * Mints a business's admin login and creates its Firestore profile, and (if
 * an owner email is given) emails the credentials. Used by the operator
 * console's direct-create path — for businesses paid outside the normal
 * self-signup flow (friends & family, test accounts).
 */
export async function createBusinessAccount(params: {
  businessName: string;
  plan: "base" | "otp";
  ownerEmail?: string;
  ownerPhone?: string;
  source: "admin";
}): Promise<{ businessId: string; loginEmail: string; tempPassword: string }> {
  const businessId = await reserveBusinessId(params.businessName);
  const tempPassword = randomPassword();
  const loginEmail = `${businessId}@${LOGIN_EMAIL_DOMAIN.value()}`;

  const userRecord = await auth.createUser({
    email: loginEmail,
    password: tempPassword,
    displayName: params.businessName || businessId,
  });
  await auth.setCustomUserClaims(userRecord.uid, { businessId, role: "owner" });

  await businessRef(businessId).set({
    displayName: params.businessName || businessId,
    logoUrl: null,
    pointsRatio: 10,
    otpEnabled: params.plan === "otp",
    birthdayEnabled: false,
    whatsappEnabled: false,
    exportEnabled: false,
    gateway: "managed",
    ownerEmail: params.ownerEmail ?? "",
    ownerPhone: params.ownerPhone ?? "",
    source: params.source,
    status: "active",
    subscriptionRenewsAt: Timestamp.fromDate(oneYearFrom()),
    createdAt: FieldValue.serverTimestamp(),
    ...BUSINESS_SETTINGS_DEFAULTS,
  });
  await statsDoc(businessId).set({ todayEarnCount: 0, todayRedeemCount: 0, pointsOutstanding: 0 });

  if (params.ownerEmail) {
    await enqueueEmail(
      params.ownerEmail,
      "your hyperdynamics loyalty manager account is ready",
      welcomeEmailHtml({ businessId, loginEmail, tempPassword })
    );
  }

  return { businessId, loginEmail, tempPassword };
}

/**
 * Shared by both self-signup credential paths (email/password via
 * `createPendingBusinessAccount` below, and Google via `selfSignupGoogle` in
 * `selfSignup.ts`) — the only difference between them is how the Firebase
 * Auth user came to exist (minted here with a chosen password, vs. already
 * created by a client-side Google sign-in). Both land the business in
 * `status: 'pending'` until an admin approves it.
 */
export async function provisionPendingBusiness(params: {
  businessName: string;
  plan: "base" | "otp";
  ownerEmail: string;
  ownerPhone?: string;
  uid: string;
}): Promise<{ businessId: string }> {
  const businessId = await reserveBusinessId(params.businessName);
  await auth.setCustomUserClaims(params.uid, { businessId, role: "owner" });

  await businessRef(businessId).set({
    displayName: params.businessName || businessId,
    logoUrl: null,
    pointsRatio: 10,
    otpEnabled: params.plan === "otp",
    birthdayEnabled: false,
    whatsappEnabled: false,
    exportEnabled: false,
    gateway: "managed",
    ownerEmail: params.ownerEmail,
    ownerPhone: params.ownerPhone ?? "",
    source: "selfSignup",
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
    ...BUSINESS_SETTINGS_DEFAULTS,
  });
  await statsDoc(businessId).set({ todayEarnCount: 0, todayRedeemCount: 0, pointsOutstanding: 0 });

  return { businessId };
}

/**
 * Email/password self-signup — mints the Firebase Auth user with the
 * caller-chosen password, then hands off to `provisionPendingBusiness`.
 */
export async function createPendingBusinessAccount(params: {
  businessName: string;
  plan: "base" | "otp";
  email: string;
  password: string;
  ownerPhone?: string;
}): Promise<{ businessId: string }> {
  const userRecord = await auth.createUser({
    email: params.email,
    password: params.password,
    displayName: params.businessName || undefined,
  });
  return provisionPendingBusiness({
    businessName: params.businessName,
    plan: params.plan,
    ownerEmail: params.email,
    ownerPhone: params.ownerPhone,
    uid: userRecord.uid,
  });
}
