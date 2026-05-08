import {
  REVIEW_CADENCE_DAYS,
  computeReviewStatus,
  formatHumanDate,
  parseISODate,
} from '../reviewCadence';

describe('parseISODate', () => {
  test('returns Date for valid ISO strings', () => {
    expect(parseISODate('2026-05-04')).toBeInstanceOf(Date);
    expect(parseISODate('2026-05-04T10:00:00Z')).toBeInstanceOf(Date);
  });
  test('returns null for malformed input', () => {
    expect(parseISODate('not-a-date')).toBeNull();
    expect(parseISODate('')).toBeNull();
  });
});

describe('formatHumanDate', () => {
  test('returns "Mon YYYY" for ISO strings', () => {
    expect(formatHumanDate('2026-05-04')).toBe('May 2026');
    expect(formatHumanDate('2026-12-15')).toBe('Dec 2026');
  });
  test('returns the raw input when malformed', () => {
    expect(formatHumanDate('garbage')).toBe('garbage');
  });
});

describe('computeReviewStatus', () => {
  test('next review = lastReviewed + 90 days', () => {
    const now = new Date('2026-05-04');
    const status = computeReviewStatus('2026-04-01', now);
    expect(status.lastReviewed).toEqual(new Date('2026-04-01'));
    expect(status.nextReview).toEqual(new Date('2026-06-30'));
    expect(REVIEW_CADENCE_DAYS).toBe(90);
  });

  test('overdue when nextReview is in the past', () => {
    const now = new Date('2026-08-01');
    const status = computeReviewStatus('2026-04-01', now);
    expect(status.overdue).toBe(true);
    // Overdue → daysUntilReview should be negative
    expect(status.daysUntilReview).toBeLessThan(0);
  });

  test('not overdue when nextReview is in the future', () => {
    const now = new Date('2026-04-15');
    const status = computeReviewStatus('2026-04-01', now);
    expect(status.overdue).toBe(false);
    expect(status.daysUntilReview).toBeGreaterThan(0);
  });

  test('null fields when input is malformed', () => {
    const status = computeReviewStatus('not-a-date');
    expect(status.lastReviewed).toBeNull();
    expect(status.nextReview).toBeNull();
    expect(status.overdue).toBe(false);
    expect(status.daysUntilReview).toBeNull();
  });

  test('daysUntilReview is roughly correct', () => {
    const now = new Date('2026-04-15');
    // Reviewed exactly 30 days before "now" → next review in 60 days
    const status = computeReviewStatus('2026-03-16', now);
    expect(status.daysUntilReview).toBeGreaterThanOrEqual(58);
    expect(status.daysUntilReview).toBeLessThanOrEqual(62);
  });
});
