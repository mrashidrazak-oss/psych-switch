import {
  ageBand,
  bmi,
  isComplete,
  renalBandFromEgfr,
  warningsForDrug,
} from '../patientContext';

describe('patient context helpers', () => {
  test('ageBand bins correctly', () => {
    expect(ageBand({ ageYears: 12 })).toBe('pediatric');
    expect(ageBand({ ageYears: 30 })).toBe('adult');
    expect(ageBand({ ageYears: 65 })).toBe('older_adult');
    expect(ageBand({ ageYears: 80 })).toBe('older_adult');
    expect(ageBand({})).toBeNull();
  });

  test('renalBandFromEgfr maps K/DOQI bands', () => {
    expect(renalBandFromEgfr(95)).toBe('normal');
    expect(renalBandFromEgfr(75)).toBe('mild');
    expect(renalBandFromEgfr(45)).toBe('moderate');
    expect(renalBandFromEgfr(20)).toBe('severe');
  });

  test('bmi calculation', () => {
    const b = bmi({ weightKg: 70, heightCm: 170 });
    expect(b).toBeCloseTo(24.22, 1);
  });

  test('isComplete requires age and sex', () => {
    expect(isComplete({})).toBe(false);
    expect(isComplete({ ageYears: 30 })).toBe(false);
    expect(isComplete({ ageYears: 30, sex: 'male' })).toBe(true);
  });
});

describe('context warnings', () => {
  test('lithium + severe CKD = danger', () => {
    const w = warningsForDrug({ renal: 'severe' }, 'lithium');
    expect(w.some((x) => x.severity === 'danger')).toBe(true);
  });

  test('valproate + pregnancy = danger', () => {
    const w = warningsForDrug({ pregnant: true }, 'valproate');
    expect(w.some((x) => x.severity === 'danger')).toBe(true);
  });

  test('older adult + olanzapine = warning', () => {
    const w = warningsForDrug({ ageYears: 75, sex: 'female' }, 'olanzapine');
    expect(w.some((x) => x.severity === 'warning')).toBe(true);
  });

  test('smoker + clozapine = info', () => {
    const w = warningsForDrug({ smoker: true }, 'clozapine');
    expect(w.some((x) => x.severity === 'info')).toBe(true);
  });

  test('benign pair = no warnings', () => {
    expect(warningsForDrug({ ageYears: 30, sex: 'male' }, 'sertraline')).toEqual([]);
  });
});
