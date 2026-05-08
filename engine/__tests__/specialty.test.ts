import {
  activeSpecialties,
  assessSpecialty,
  specialtyLabel,
  tierLabel,
} from '../specialty';
import { pregnancyTierFor, pregnancyEntryFor } from '../specialty/pregnancy';
import { geriatricEntryFor } from '../specialty/geriatric';
import { pediatricEntryFor, pediatricTierFor } from '../specialty/pediatric';

describe('activeSpecialties', () => {
  test('empty context → no specialties', () => {
    expect(activeSpecialties({})).toEqual([]);
  });

  test('pregnant → pregnancy', () => {
    expect(activeSpecialties({ pregnant: true })).toContain('pregnancy');
  });

  test('breastfeeding → breastfeeding', () => {
    expect(activeSpecialties({ breastfeeding: true })).toContain('breastfeeding');
  });

  test('age >=65 → geriatric', () => {
    expect(activeSpecialties({ ageYears: 75 })).toContain('geriatric');
  });

  test('age <18 → pediatric', () => {
    expect(activeSpecialties({ ageYears: 12 })).toContain('pediatric');
  });

  test('multiple flags → multiple specialties', () => {
    const out = activeSpecialties({ ageYears: 30, pregnant: true, breastfeeding: true });
    expect(out).toContain('pregnancy');
    expect(out).toContain('breastfeeding');
  });
});

describe('pregnancy matrix', () => {
  test('valproate is avoid', () => {
    expect(pregnancyTierFor('valproate')).toBe('avoid');
  });

  test('lamotrigine is preferred for bipolar maintenance', () => {
    expect(pregnancyTierFor('lamotrigine')).toBe('preferred');
  });

  test('paroxetine is avoid in 1st trimester, caution in 2nd/3rd', () => {
    expect(pregnancyTierFor('paroxetine', 1)).toBe('avoid');
    expect(pregnancyTierFor('paroxetine', 2)).toBe('caution');
    expect(pregnancyTierFor('paroxetine', 3)).toBe('caution');
  });

  test('lithium is avoid 1st trimester only', () => {
    expect(pregnancyTierFor('lithium', 1)).toBe('avoid');
    expect(pregnancyTierFor('lithium', 2)).toBe('caution');
  });

  test('sertraline is preferred for breastfeeding', () => {
    const e = pregnancyEntryFor('sertraline');
    expect(e?.breastfeedingTier).toBe('preferred');
  });

  test('clozapine breastfeeding = avoid', () => {
    const e = pregnancyEntryFor('clozapine');
    expect(e?.breastfeedingTier).toBe('avoid');
  });
});

describe('geriatric matrix', () => {
  test('paroxetine is avoid (Beers list)', () => {
    expect(geriatricEntryFor('paroxetine')?.tier).toBe('avoid');
  });

  test('aripiprazole is preferred (low metabolic + sedation)', () => {
    expect(geriatricEntryFor('aripiprazole')?.tier).toBe('preferred');
  });

  test('chlorpromazine is avoid (anticholinergic)', () => {
    expect(geriatricEntryFor('chlorpromazine')?.tier).toBe('avoid');
  });

  test('every drug has a doseFactor < 1 (start low)', () => {
    const all = ['sertraline', 'olanzapine', 'aripiprazole', 'lithium', 'lamotrigine'];
    for (const id of all) {
      const e = geriatricEntryFor(id);
      expect(e?.doseFactor).toBeDefined();
      expect(e!.doseFactor).toBeLessThan(1);
    }
  });
});

describe('pediatric matrix', () => {
  test('fluoxetine is preferred (NICE first-line for paeds depression)', () => {
    expect(pediatricEntryFor('fluoxetine')?.tier).toBe('preferred');
  });

  test('paroxetine is avoid (suicidality signal in trials)', () => {
    expect(pediatricEntryFor('paroxetine')?.tier).toBe('avoid');
  });

  test('valproate is avoid (PPP)', () => {
    expect(pediatricEntryFor('valproate')?.tier).toBe('avoid');
  });

  test('age boost: paroxetine in 17yo → bumps avoid to caution? no — licensedFrom is null', () => {
    expect(pediatricTierFor('paroxetine', 17)).toBe('avoid');
  });

  test('age boost: risperidone licensed from 5 → on-label for 12yo bumps tier', () => {
    // risperidone base tier is 'preferred' → no further boost needed
    expect(pediatricTierFor('risperidone', 12)).toBe('preferred');
  });
});

describe('assessSpecialty', () => {
  test('non-applicable context → empty applicable list', () => {
    const a = assessSpecialty({
      fromDrugId: 'sertraline',
      toDrugId: 'mirtazapine',
      context: { ageYears: 30, sex: 'male' },
    });
    expect(a.applicable).toEqual([]);
    expect(a.recommendations).toEqual([]);
  });

  test('pregnant context → pregnancy + breastfeeding-tier-only-when-flagged', () => {
    const a = assessSpecialty({
      fromDrugId: 'sertraline',
      toDrugId: 'mirtazapine',
      context: { pregnant: true, trimester: 1 },
    });
    expect(a.applicable).toContain('pregnancy');
    expect(a.recommendations.some((r) => r.specialty === 'pregnancy' && r.drugId === 'sertraline')).toBe(true);
  });

  test('paroxetine + 1st trimester → avoid tier', () => {
    const a = assessSpecialty({
      fromDrugId: 'sertraline',
      toDrugId: 'paroxetine',
      context: { pregnant: true, trimester: 1 },
    });
    const paroxRec = a.recommendations.find((r) => r.drugId === 'paroxetine' && r.specialty === 'pregnancy');
    expect(paroxRec?.tier).toBe('avoid');
  });

  test('older adult → geriatric recommendations include doseFactor', () => {
    const a = assessSpecialty({
      fromDrugId: 'sertraline',
      toDrugId: 'mirtazapine',
      context: { ageYears: 80 },
    });
    expect(a.applicable).toContain('geriatric');
    const geriatricRec = a.recommendations.find((r) => r.specialty === 'geriatric');
    expect(geriatricRec?.doseFactor).toBeDefined();
    expect(geriatricRec!.doseFactor).toBeLessThan(1);
  });

  test('headline reflects worst tier per specialty', () => {
    const a = assessSpecialty({
      fromDrugId: 'sertraline',
      toDrugId: 'paroxetine',
      context: { pregnant: true, trimester: 1 },
    });
    expect(a.headline.toLowerCase()).toMatch(/avoid/);
  });

  test('label helpers return user-facing strings', () => {
    expect(specialtyLabel('pregnancy')).toBe('Pregnancy');
    expect(tierLabel('avoid')).toBe('Avoid');
  });
});
