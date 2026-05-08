import { quantitativeFor, quantitativeForAe, formatEffect } from '../quantitativeAe';
import { costFor, listCostEntries, formatMyr, tierLabel } from '../costData';

describe('quantitativeAe', () => {
  test('returns effects for a drug with NMA data', () => {
    const effects = quantitativeFor('olanzapine');
    expect(effects.length).toBeGreaterThan(0);
  });

  test('returns empty array for unknown drug', () => {
    expect(quantitativeFor('imaginary-drug')).toEqual([]);
  });

  test('quantitativeForAe returns specific (drug,ae) pair', () => {
    const e = quantitativeForAe('olanzapine', 'weight_gain');
    expect(e?.metric).toBe('kg');
    expect(e?.value).toBeGreaterThan(0);
  });

  test('every entry cites a published source', () => {
    for (const e of quantitativeFor('olanzapine')) {
      expect(e.citation.length).toBeGreaterThan(0);
    }
  });

  test('formatEffect produces a sensible string for each metric', () => {
    expect(formatEffect({
      drugId: 'x', aeId: 'y', metric: 'OR', value: 1.5, ci: [1.2, 1.8], citation: 'c',
    })).toMatch(/OR/);
    expect(formatEffect({
      drugId: 'x', aeId: 'y', metric: 'kg', value: 2.5, citation: 'c',
    })).toMatch(/kg/);
  });

  test('aripiprazole akathisia OR is positive (drug worse than placebo)', () => {
    const e = quantitativeForAe('aripiprazole', 'eps_akathisia');
    expect(e?.value).toBeGreaterThan(1);
  });

  test('clozapine response SMD is the strongest', () => {
    const aps = ['clozapine', 'amisulpride', 'olanzapine', 'risperidone', 'haloperidol', 'aripiprazole']
      .map((id) => ({ id, e: quantitativeForAe(id, '_response') }))
      .filter((x) => x.e);
    aps.sort((a, b) => Math.abs(b.e!.value) - Math.abs(a.e!.value));
    expect(aps[0].id).toBe('clozapine');
  });
});

describe('costData', () => {
  test('returns entry for a known drug', () => {
    const c = costFor('fluoxetine');
    expect(c).not.toBeNull();
    expect(c?.tier).toBeDefined();
    expect(c?.monthlyCostMyr).toBeGreaterThanOrEqual(0);
  });

  test('returns null for unknown drug', () => {
    expect(costFor('imaginary')).toBeNull();
  });

  test('every entry has currency-formatted output', () => {
    for (const c of listCostEntries()) {
      expect(formatMyr(c.monthlyCostMyr)).toMatch(/^RM /);
    }
  });

  test('tier ordering: subsidised cheap, expensive expensive', () => {
    const subsidised = listCostEntries().filter((c) => c.tier === 'subsidised');
    const expensive = listCostEntries().filter((c) => c.tier === 'expensive');
    if (subsidised.length > 0 && expensive.length > 0) {
      const avgSub = subsidised.reduce((s, c) => s + c.monthlyCostMyr, 0) / subsidised.length;
      const avgExp = expensive.reduce((s, c) => s + c.monthlyCostMyr, 0) / expensive.length;
      expect(avgSub).toBeLessThan(avgExp);
    }
  });

  test('label helpers return user-facing strings', () => {
    expect(tierLabel('subsidised')).toBe('Subsidised');
    expect(tierLabel('expensive')).toBe('Expensive');
  });
});
