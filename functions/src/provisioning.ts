import { FieldValue } from "firebase-admin/firestore";
import { auth, businessRef, statsDoc, db } from "./lib/admin";
import { randomSlugSuffix, slugify } from "./lib/format";
import { enqueueEmail, welcomeEmailHtml } from "./lib/mail";
import { LOGIN_EMAIL_DOMAIN } from "./config";

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
 * Runs once a Razorpay payment_link.paid webhook is verified: mints the
 * business's admin login, creates its Firestore profile, and emails the
 * credentials. Idempotent on `paymentOrders/{referenceId}.businessId`
 * being already set, so a duplicate webhook delivery is a no-op.
 */
export async function provisionBusiness(params: {
  referenceId: string;
  razorpayPaymentLinkId: string;
  customerName: string;
  customerEmail: string;
}): Promise<void> {
  const orderRef = db.collection("paymentOrders").doc(params.referenceId);

  const alreadyProvisioned = await db.runTransaction(async (tx) => {
    const snap = await tx.get(orderRef);
    if (snap.exists && snap.get("businessId")) return true;
    tx.set(
      orderRef,
      { status: "paid", razorpayPaymentLinkId: params.razorpayPaymentLinkId, paidAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
    return false;
  });
  if (alreadyProvisioned) return;

  const businessId = await reserveBusinessId(params.customerName);
  const tempPassword = randomPassword();
  const loginEmail = `${businessId}@${LOGIN_EMAIL_DOMAIN.value()}`;

  const userRecord = await auth.createUser({
    email: loginEmail,
    password: tempPassword,
    displayName: params.customerName || businessId,
  });
  await auth.setCustomUserClaims(userRecord.uid, { businessId });

  await businessRef(businessId).set({
    displayName: params.customerName || businessId,
    logoUrl: null,
    pointsRatio: 10,
    otpEnabled: false,
    gateway: "managed",
    ownerEmail: params.customerEmail,
    status: "active",
    createdAt: FieldValue.serverTimestamp(),
  });
  await statsDoc(businessId).set({ todayEarnCount: 0, todayRedeemCount: 0, pointsOutstanding: 0 });

  await orderRef.set({ businessId }, { merge: true });

  if (params.customerEmail) {
    await enqueueEmail(
      params.customerEmail,
      "your hyperdynamics loyalty manager account is ready",
      welcomeEmailHtml({ businessId, loginEmail, tempPassword })
    );
  }
}
