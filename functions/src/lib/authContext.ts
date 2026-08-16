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

/** Who the caller is *within* a business. Absent claim ⇒ `owner`: every account that
 * existed before staff shipped is the business's own login, so this must not
 * default to the more restricted role or it would lock out every live business. */
export type BusinessRole = "owner" | "staff";

export function getRole(request: CallableRequest): BusinessRole {
  return request.auth?.token?.role === "staff" ? "staff" : "owner";
}

/**
 * Gates the owner-only callables (staff seat management, eventually anything else
 * that must not be delegable to staff). Distinct from the per-action
 * `staffPermissions` policy checked in `loadAuthorizedBusiness`/
 * `assertStaffPermission`: seat management was deliberately never made a
 * togglable permission — a staff account that could add staff could add itself
 * unlimited co-workers, which isn't a policy question, it's a hole.
 */
export function requireOwner(request: CallableRequest): string {
  const businessId = requireBusinessId(request);
  if (getRole(request) === "staff") {
    throw new HttpsError("permission-denied", "only the business owner can manage staff.");
  }
  return businessId;
}

/** The actions a staff account can be allowed to perform. `settings` is deliberately
 * absent and owner-only: staff editing settings could grant themselves every other
 * permission here, so it is not a toggle. */
export type StaffPermission = "earn" | "redeem" | "correction" | "customers" | "birthdays" | "export" | "sales";

/** Applied when a business has never had its policy edited — the defaults the
 * operator agreed on: staff run the till, everything else is off. */
export const DEFAULT_STAFF_PERMISSIONS: Record<StaffPermission, boolean> = {
  earn: true,
  redeem: true,
  correction: true,
  customers: false,
  birthdays: false,
  export: false,
  sales: false,
};

export function normalizeStaffPermissions(raw: unknown): Record<StaffPermission, boolean> {
  const out = { ...DEFAULT_STAFF_PERMISSIONS };
  if (raw && typeof raw === "object") {
    for (const key of Object.keys(out) as StaffPermission[]) {
      const v = (raw as Record<string, unknown>)[key];
      if (typeof v === "boolean") out[key] = v;
    }
  }
  return out;
}

/**
 * Server-side gate for the ledger callables. Owners always pass; staff pass only
 * if the business's single staff policy (`staffPermissions`, owner-edited in
 * Settings) grants that action. Enforced here rather than only in the UI because
 * hiding a nav item is presentation, not authorization.
 *
 * Always takes an already-fetched snapshot rather than fetching its own —
 * `sessions.ts`'s `loadAuthorizedBusiness` is what every mutating callable uses to
 * get that snapshot, in the same read it needs for the session check and its own
 * settings (ratio, otpEnabled, …). A version of this that fetched independently
 * used to mean earn/redeem/correction each read the business doc twice per call.
 */
export function assertStaffPermission(
  request: CallableRequest,
  permission: StaffPermission,
  staffPermissionsRaw: unknown
): void {
  if (getRole(request) !== "staff") return;
  const perms = normalizeStaffPermissions(staffPermissionsRaw);
  if (!perms[permission]) {
    throw new HttpsError("permission-denied", `your account is not allowed to ${permission}.`);
  }
}

/**
 * Human-readable "who did this", stamped onto every ledger write so the history
 * and correction screens can show the responsible person without an extra user
 * lookup per row. Falls back through display name → email → uid, so it is never
 * empty even for the synthetic `{businessId}@…` owner logins.
 */
export function getActorLabel(request: CallableRequest): string {
  const token = request.auth?.token as { name?: string; email?: string } | undefined;
  return String(token?.name || token?.email || request.auth?.uid || "").slice(0, 80);
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
