import { db } from "./admin";

/**
 * Writes to a `mail` collection, the convention expected by the official
 * "Trigger Email from Firestore" Firebase Extension. Install that extension
 * (configured with your SMTP/SendGrid provider) against this project —
 * nothing else in this codebase needs to change.
 */
export async function enqueueEmail(to: string, subject: string, html: string): Promise<void> {
  await db.collection("mail").add({ to: [to], message: { subject, html } });
}

export function welcomeEmailHtml(params: { businessId: string; loginEmail: string; tempPassword: string }): string {
  return `
    <div style="font-family:sans-serif;max-width:480px;margin:0 auto;">
      <h2>welcome to hyperdynamics loyalty manager</h2>
      <p>your payment was received and your account is ready.</p>
      <table style="width:100%;border-collapse:collapse;margin:16px 0;">
        <tr><td style="padding:8px 0;color:#666;">business id</td><td style="padding:8px 0;font-weight:700;">${params.businessId}</td></tr>
        <tr><td style="padding:8px 0;color:#666;">temporary password</td><td style="padding:8px 0;font-weight:700;">${params.tempPassword}</td></tr>
      </table>
      <p>log in at the admin login screen with your business id and this password, then change it from settings.</p>
    </div>
  `;
}
