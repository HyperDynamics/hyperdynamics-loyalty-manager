import { onCall, HttpsError } from "firebase-functions/https";
import { transactionsCol } from "./lib/admin";
import { requireAdmin } from "./lib/authContext";

const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

function istDateKey(date: Date): string {
  const ist = new Date(date.getTime() + IST_OFFSET_MS);
  return `${ist.getUTCFullYear()}-${ist.getUTCMonth()}-${ist.getUTCDate()}`;
}

/**
 * Admin-only diagnostic, not a fraud gate: one business account run across
 * several physical branches tends to show earn/redeem transactions from
 * more than one network on the same day, while a single location's staff
 * share one network. This surfaces that raw evidence (which days, how many
 * distinct networks) so the operator can judge context and start a pricing
 * conversation — never an automated block. Only transactions recorded since
 * `ip` capture was added (see earn.ts/redeem.ts) have a value to analyze.
 */
export const adminCheckMultiLocation = onCall(async (request) => {
  requireAdmin(request);
  const businessId = String(request.data?.businessId ?? "").trim();
  const days = Math.min(90, Math.max(1, Number(request.data?.days) || 30));
  if (!businessId) throw new HttpsError("invalid-argument", "missing businessId.");

  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
  const snap = await transactionsCol(businessId).where("createdAt", ">=", since).orderBy("createdAt", "desc").get();

  const ipsByDay = new Map<string, Set<string>>();
  const allIps = new Set<string>();
  for (const doc of snap.docs) {
    const ip = doc.get("ip") as string | undefined;
    const createdAt = doc.get("createdAt")?.toDate?.() as Date | undefined;
    if (!ip || !createdAt) continue;
    allIps.add(ip);
    const key = istDateKey(createdAt);
    if (!ipsByDay.has(key)) ipsByDay.set(key, new Set());
    ipsByDay.get(key)!.add(ip);
  }

  const multiIpDays = [...ipsByDay.entries()]
    .filter(([, ips]) => ips.size > 1)
    .map(([day, ips]) => ({ day, distinctIps: ips.size }))
    .sort((a, b) => (a.day < b.day ? 1 : -1));

  return {
    daysAnalyzed: days,
    totalDistinctIps: allIps.size,
    multiIpDayCount: multiIpDays.length,
    multiIpDays: multiIpDays.slice(0, 30),
  };
});
