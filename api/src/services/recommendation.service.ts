import { RowDataPacket } from 'mysql2';
import { pool } from '../config/db';
import { BusinessModel } from '../models/business.model';

/** Jaccard similarity: |A ∩ B| / |A ∪ B| */
export function jaccard(a: Set<number>, b: Set<number>): number {
  if (!a.size || !b.size) return 0;
  let inter = 0;
  const [small, big] = a.size < b.size ? [a, b] : [b, a];
  for (const x of small) if (big.has(x)) inter++;
  return inter / (a.size + b.size - inter);
}

/**
 * User-based collaborative filtering.
 * - Each user = set of businesses they ordered from.
 * - Similarity between two users = Jaccard of those sets.
 * - Business score for user U = sum of sim(U, V) over neighbours V who ordered it
 *   (normalised), + small boost for repeat orders + small popularity prior + smoothed star rating
 *   (popularity also handles cold-start / guest users).
 */
export const RecommendationService = {
  async recommend(
    userId: number | undefined,
    filters: { type?: any; city?: string; search?: string; limit?: number },
  ) {
    const businesses: any[] = await BusinessModel.list({
      ...filters,
      status: 'approved',
      limit: filters.limit ?? 100,
    } as any);
    if (!businesses.length) return businesses;

    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT DISTINCT user_id, business_id FROM orders WHERE status <> 'cancelled'`,
    );
    const byUser = new Map<number, Set<number>>();
    const buyers = new Map<number, Set<number>>();
    for (const r of rows) {
      if (!byUser.has(r.user_id)) byUser.set(r.user_id, new Set());
      byUser.get(r.user_id)!.add(r.business_id);
      if (!buyers.has(r.business_id)) buyers.set(r.business_id, new Set());
      buyers.get(r.business_id)!.add(r.user_id);
    }

    const mine = userId ? byUser.get(userId) ?? new Set<number>() : new Set<number>();
    const cf = new Map<number, number>();
    let simTotal = 0;
    if (mine.size) {
      for (const [v, theirs] of byUser) {
        if (v === userId) continue;
        const sim = jaccard(mine, theirs);
        if (sim <= 0) continue;
        simTotal += sim;
        for (const b of theirs) if (!mine.has(b)) cf.set(b, (cf.get(b) ?? 0) + sim);
      }
    }
    const maxPop = Math.max(1, ...[...buyers.values()].map((s) => s.size));

    const scored = businesses.map((b) => {
      const cfScore = simTotal ? (cf.get(b.id) ?? 0) / simTotal : 0;
      const pop = (buyers.get(b.id)?.size ?? 0) / maxPop;
      const repeat = mine.has(b.id) ? 0.3 : 0;
      // Bayesian-smoothed rating (prior 4.0 with weight 5) so a single 5★ can't dominate
      const n = Number(b.rating_count ?? 0);
      const avg = Number(b.avg_rating ?? 0);
      const smoothed = (avg * n + 4.0 * 5) / (n + 5);
      const ratingBoost = 0.15 * (smoothed / 5);
      const open = b.is_open ? 0.05 : 0;
      return { ...b, rec_score: +(cfScore + repeat + 0.1 * pop + ratingBoost + open).toFixed(4) };
    });
    scored.sort((a, b) => b.rec_score - a.rec_score);
    return scored;
  },
};
