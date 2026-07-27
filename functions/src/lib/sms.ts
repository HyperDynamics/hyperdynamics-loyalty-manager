import axios from "axios";
import { logger } from "firebase-functions";

/**
 * MSG91 (₹-priced Indian transactional SMS API) — used for both the
 * "managed by us" gateway (HyperDynamics' own account) and "bring your
 * own" (the business's own MSG91 API key), see otp.ts.
 */
export async function sendSmsViaMsg91(params: { authKey: string; phone: string; message: string; senderId: string }): Promise<void> {
  try {
    await axios.post(
      "https://control.msg91.com/api/v5/flow/",
      {
        sender: params.senderId,
        route: "4",
        mobiles: `91${params.phone}`,
        message: params.message,
      },
      { headers: { authkey: params.authKey, "Content-Type": "application/json" }, timeout: 10_000 }
    );
  } catch (err) {
    logger.error("msg91 send failed", err);
    throw new Error("could not send otp. please try again.");
  }
}
