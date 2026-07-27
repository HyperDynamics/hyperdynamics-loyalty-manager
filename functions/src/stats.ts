import { onDocumentWritten } from "firebase-functions/firestore";
import { onSchedule } from "firebase-functions/scheduler";
import { FieldValue } from "firebase-admin/firestore";
import { db, statsDoc } from "./lib/admin";

const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

function istDateKey(date: Date): string {
  const ist = new Date(date.getTime() + IST_OFFSET_MS);
  return `${ist.getUTCFullYear()}-${ist.getUTCMonth()}-${ist.getUTCDate()}`;
}

/**
 * D. Dashboard quick stats — kept current incrementally so the dashboard is
 * a single cheap doc read instead of a query-time aggregation. This trades
 * perfect exactness (at-least-once trigger delivery could in rare retries
 * double-count) for simplicity; it only feeds the "optional but useful"
 * summary tiles, never the actual point ledger (which is strictly
 * transactional in earn.ts/redeem.ts/correction.ts).
 */
export const onTransactionWritten = onDocumentWritten(
  "businesses/{businessId}/transactions/{txnId}",
  async (event) => {
    const businessId = event.params.businessId as string;
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    const ref = statsDoc(businessId);
    const today = istDateKey(new Date());

    if (!before && after) {
      // newly created transaction
      if (after.status !== "ok") return;
      const isEarn = after.type === "earn";
      await ref.set(
        {
          [isEarn ? "todayEarnCount" : "todayRedeemCount"]: FieldValue.increment(1),
          pointsOutstanding: FieldValue.increment(isEarn ? after.points : -after.points),
          lastResetDateKey: today,
        },
        { merge: true }
      );
      return;
    }

    if (before && after && before.status === "ok" && after.status === "reversed") {
      // reversal — undo the original effect, and undo today's count only if it was posted today
      const isEarn = before.type === "earn";
      const createdAt = before.createdAt?.toDate?.() as Date | undefined;
      const postedToday = createdAt ? istDateKey(createdAt) === today : false;

      await ref.set(
        {
          ...(postedToday
            ? { [isEarn ? "todayEarnCount" : "todayRedeemCount"]: FieldValue.increment(-1) }
            : {}),
          pointsOutstanding: FieldValue.increment(isEarn ? -before.points : before.points),
        },
        { merge: true }
      );
    }
  }
);

/** Resets the "today" counters at midnight IST (this business is India-focused, per the spec's ₹ pricing). */
export const resetDailyStatsIst = onSchedule(
  { schedule: "0 0 * * *", timeZone: "Asia/Kolkata" },
  async () => {
    const businesses = await db.collection("businesses").select().get();
    const batchSize = 400;
    for (let i = 0; i < businesses.docs.length; i += batchSize) {
      const batch = db.batch();
      for (const doc of businesses.docs.slice(i, i + batchSize)) {
        batch.set(statsDoc(doc.id), { todayEarnCount: 0, todayRedeemCount: 0 }, { merge: true });
      }
      await batch.commit();
    }
  }
);
