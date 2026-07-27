import { onCall, onRequest, HttpsError } from "firebase-functions/https";
import { logger } from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./lib/admin";
import { createPaymentLink, razorpayClient, verifyWebhookSignature } from "./lib/razorpay";
import { provisionBusiness } from "./provisioning";
import { APP_BASE_URL, ONBOARDING_FEE_PAISE, RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, RAZORPAY_WEBHOOK_SECRET } from "./config";

/**
 * Landing page "get started — ₹4,999" button. Creates a `paymentOrders` doc
 * plus a real Razorpay-hosted Payment Link (external redirect, not
 * embedded, per spec) whose `callback_url` brings the browser back to our
 * `/payment/confirm` page with this order's reference id.
 */
export const createOnboardingPaymentLink = onCall(
  { cors: true, secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async () => {
    const orderRef = db.collection("paymentOrders").doc();
    await orderRef.set({ status: "created", createdAt: FieldValue.serverTimestamp() });

    const client = razorpayClient(RAZORPAY_KEY_ID.value(), RAZORPAY_KEY_SECRET.value());
    const callbackUrl = `${APP_BASE_URL.value()}/payment/confirm?ref=${orderRef.id}`;

    try {
      const link = await createPaymentLink({
        client,
        amountPaise: ONBOARDING_FEE_PAISE,
        referenceId: orderRef.id,
        callbackUrl,
        description: "HyperDynamics Loyalty Manager — onboarding",
      });
      await orderRef.set({ razorpayPaymentLinkId: link.id }, { merge: true });
      return { referenceId: orderRef.id, checkoutUrl: link.short_url };
    } catch (err) {
      logger.error("razorpay payment link creation failed", err);
      await orderRef.set({ status: "failed" }, { merge: true });
      throw new HttpsError("internal", "could not start payment. please try again.");
    }
  }
);

/**
 * Razorpay webhook — register this function's URL in the Razorpay dashboard
 * with the same secret as RAZORPAY_WEBHOOK_SECRET. This, not the client
 * redirect, is the source of truth for whether a business gets provisioned.
 */
export const razorpayWebhook = onRequest(
  { secrets: [RAZORPAY_WEBHOOK_SECRET] },
  async (req, res) => {
    const signature = req.headers["x-razorpay-signature"] as string | undefined;
    const valid = verifyWebhookSignature(req.rawBody, signature, RAZORPAY_WEBHOOK_SECRET.value());
    if (!valid) {
      logger.warn("razorpay webhook: invalid signature");
      res.status(400).send("invalid signature");
      return;
    }

    const event = req.body?.event as string | undefined;
    const linkEntity = req.body?.payload?.payment_link?.entity;

    if (event === "payment_link.paid" && linkEntity) {
      const referenceId = linkEntity.reference_id as string | undefined;
      const customer = linkEntity.customer ?? {};
      if (referenceId) {
        try {
          await provisionBusiness({
            referenceId,
            razorpayPaymentLinkId: linkEntity.id,
            customerName: customer.name ?? "",
            customerEmail: customer.email ?? "",
          });
        } catch (err) {
          logger.error("provisioning failed for " + referenceId, err);
          res.status(500).send("provisioning failed");
          return;
        }
      }
    } else if (event === "payment_link.cancelled" || event === "payment_link.expired") {
      const referenceId = linkEntity?.reference_id as string | undefined;
      if (referenceId) {
        await db.collection("paymentOrders").doc(referenceId).set({ status: "failed" }, { merge: true });
      }
    }

    res.status(200).send("ok");
  }
);
