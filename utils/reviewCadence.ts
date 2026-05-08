// Review-cadence helpers — all rules carry a `lastReviewedISO`. The UX
// derives "next review due" from a fixed 90-day cadence so the
// clinician can see at a glance whether they're looking at a rule
// that's still fresh or due for re-review.
//
// Pure date math only — easy to test, no React state.

export const REVIEW_CADENCE_DAYS = 90;

export interface ReviewStatus {
  /** Parsed last-reviewed date, or null if input was malformed. */
  lastReviewed: Date | null;
  /** Computed next-review-due date, or null if last-reviewed is missing. */
  nextReview: Date | null;
  /** True when the next review is in the past. */
  overdue: boolean;
  /** Days until next review (negative when overdue). null if no input. */
  daysUntilReview: number | null;
}

export function computeReviewStatus(
  lastReviewedISO: string,
  now: Date = new Date(),
): ReviewStatus {
  const lastReviewed = parseISODate(lastReviewedISO);
  if (!lastReviewed) {
    return {
      lastReviewed: null,
      nextReview: null,
      overdue: false,
      daysUntilReview: null,
    };
  }
  const nextReview = new Date(
    lastReviewed.getTime() + REVIEW_CADENCE_DAYS * 24 * 60 * 60 * 1000,
  );
  const msPerDay = 24 * 60 * 60 * 1000;
  const daysUntilReview = Math.round((nextReview.getTime() - now.getTime()) / msPerDay);
  return {
    lastReviewed,
    nextReview,
    overdue: nextReview.getTime() < now.getTime(),
    daysUntilReview,
  };
}

export function parseISODate(iso: string): Date | null {
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? null : d;
}

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export function formatHumanDate(iso: string): string {
  const d = parseISODate(iso);
  if (!d) return iso;
  return `${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}
