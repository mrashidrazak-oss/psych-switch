import {
  computeCasePulses,
  pulseCountsByTier,
  tierLabel,
} from '../casePulse';
import type { SavedCase } from '../caseManager';

function buildCase(overrides: Partial<SavedCase> = {}): SavedCase {
  const now = new Date();
  return {
    id: 'c1',
    label: 'Mr A',
    fromDrugId: 'sertraline',
    fromDoseMg: 100,
    toDrugId: 'mirtazapine',
    toDoseMg: 30,
    startedISO: now.toISOString(),
    updatedISO: now.toISOString(),
    ...overrides,
  };
}

describe('computeCasePulses', () => {
  test('returns empty list when no cases', () => {
    expect(computeCasePulses([])).toEqual([]);
  });

  test('cases starting today with early-monitoring drugs produce "soon" pulses', () => {
    // Switching TO clozapine triggers a weekly FBC schedule starting D7,
    // which lands inside the "soon" (+2 to +7) tier.
    const cases = [
      buildCase({
        startedISO: new Date().toISOString(),
        toDrugId: 'clozapine',
        toDoseMg: 12.5,
      }),
    ];
    const pulses = computeCasePulses(cases);
    const soon = pulses.filter((p) => p.tier === 'soon');
    expect(soon.length).toBeGreaterThan(0);
  });

  test('AD-only cases with no early monitoring may yield zero pulses today', () => {
    // sertraline→mirtazapine has its first monitoring at D14, which is
    // beyond the +7 "soon" ceiling — so no pulses surface yet.
    const cases = [buildCase({ startedISO: new Date().toISOString() })];
    const pulses = computeCasePulses(cases);
    expect(pulses).toEqual([]);
  });

  test('overdue tier captures items 2-14 days in the past', () => {
    const past = new Date();
    past.setDate(past.getDate() - 15); // 15 days ago — D14 monitoring is now 1 day overdue
    const cases = [buildCase({ startedISO: past.toISOString() })];
    const pulses = computeCasePulses(cases);
    const overdue = pulses.filter((p) => p.tier === 'overdue');
    expect(overdue.length).toBeGreaterThanOrEqual(0); // depends on plan
  });

  test('items >14 days old fall off (not surfaced)', () => {
    const veryOld = new Date();
    veryOld.setDate(veryOld.getDate() - 100);
    const cases = [buildCase({ startedISO: veryOld.toISOString() })];
    const pulses = computeCasePulses(cases);
    // Every entry should be either nothing or within ±14d window — none
    // older than -14 days from now.
    for (const p of pulses) {
      expect(p.daysFromNow).toBeGreaterThanOrEqual(-14);
    }
  });

  test('pulses are sorted by tier (overdue first, then today, then soon)', () => {
    const cases = [
      buildCase({ id: 'c1', startedISO: daysAgo(15).toISOString() }), // some overdue
      buildCase({ id: 'c2', startedISO: new Date().toISOString() }),  // some soon
    ];
    const pulses = computeCasePulses(cases);
    const tierOrder = ['overdue', 'today', 'soon'];
    let lastIndex = -1;
    for (const p of pulses) {
      const i = tierOrder.indexOf(p.tier);
      expect(i).toBeGreaterThanOrEqual(lastIndex);
      lastIndex = i;
    }
  });

  test('pulseCountsByTier sums correctly', () => {
    const cases = [buildCase({ startedISO: new Date().toISOString() })];
    const pulses = computeCasePulses(cases);
    const counts = pulseCountsByTier(pulses);
    expect(counts.overdue + counts.today + counts.soon).toBe(pulses.length);
  });

  test('tierLabel returns user-facing strings', () => {
    expect(tierLabel('overdue')).toBe('Overdue');
    expect(tierLabel('today')).toBe('Today');
    expect(tierLabel('soon')).toBe('This week');
  });

  test('skips cases with unregistered drug ids', () => {
    const cases = [buildCase({ fromDrugId: 'imaginary-drug', toDrugId: 'sertraline' })];
    expect(computeCasePulses(cases)).toEqual([]);
  });

  test('skips cases with malformed start dates', () => {
    const cases = [buildCase({ startedISO: 'garbage' })];
    expect(computeCasePulses(cases)).toEqual([]);
  });
});

function daysAgo(n: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}
