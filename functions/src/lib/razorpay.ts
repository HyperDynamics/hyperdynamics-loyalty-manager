import crypto from "crypto";
import Razorpay from "razorpay";

export interface RazorpayPaymentLink {
  id: string;
  short_url: string;
  reference_id: string;
}

export function razorpayClient(keyId: string, keySecret: string): Razorpay {
  return new Razorpay({ key_id: keyId, key_secret: keySecret });
}

export async function createPaymentLink(params: {
  client: Razorpay;
  amountPaise: number;
  referenceId: string;
  callbackUrl: string;
  description: string;
}): Promise<RazorpayPaymentLink> {
  const link = await params.client.paymentLink.create({
    amount: params.amountPaise,
    currency: "INR",
    description: params.description,
    reference_id: params.referenceId,
    callback_url: params.callbackUrl,
    callback_method: "get",
    notify: { sms: false, email: true },
  } as never);
  return link as unknown as RazorpayPaymentLink;
}

/** Verifies `X-Razorpay-Signature` per Razorpay's webhook signing scheme (HMAC-SHA256 of the raw body). */
export function verifyWebhookSignature(rawBody: Buffer, signatureHeader: string | undefined, secret: string): boolean {
  if (!signatureHeader) return false;
  const expected = crypto.createHmac("sha256", secret).update(rawBody).digest("hex");
  const a = Buffer.from(expected, "utf8");
  const b = Buffer.from(signatureHeader, "utf8");
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}
