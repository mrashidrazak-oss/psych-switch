import {
  EQUIVALENCY_FAMILIES,
  convertWithinFamily,
  doseInReferenceUnits,
  roundToClinicalDose,
} from '../doseEquivalents';

describe('dose equivalents', () => {
  test('CPZ family: 100 mg chlorpromazine = 1 CPZ-eq', () => {
    const r = doseInReferenceUnits('cpz', 'chlorpromazine', 100);
    expect(r).not.toBeNull();
    expect(r!.refUnits).toBeCloseTo(1, 5);
    expect(r!.referenceDoseMg).toBeCloseTo(100, 5);
  });

  test('CPZ family: 5 mg olanzapine ≈ 100 mg CPZ', () => {
    const r = doseInReferenceUnits('cpz', 'olanzapine', 5);
    expect(r!.referenceDoseMg).toBeCloseTo(100, 5);
  });

  test('FLX family: 20 mg fluoxetine = 0.5 FLX-eq', () => {
    const r = doseInReferenceUnits('fluoxetine', 'fluoxetine', 20);
    expect(r!.refUnits).toBeCloseTo(0.5, 5);
  });

  test('DZP family: 10 mg diazepam = 1 DZP-eq', () => {
    const r = doseInReferenceUnits('diazepam', 'diazepam', 10);
    expect(r!.refUnits).toBeCloseTo(1, 5);
  });

  test('convertWithinFamily: 200 mg sertraline → fluoxetine', () => {
    // sertraline 100 = 40 fluoxetine; 200 → 80
    const r = convertWithinFamily('fluoxetine', 'sertraline', 200, 'fluoxetine');
    expect(r!.toDoseMg).toBeCloseTo(80, 5);
    expect(r!.refUnits).toBeCloseTo(2, 5);
  });

  test('convertWithinFamily returns null for unknown drugs', () => {
    expect(convertWithinFamily('cpz', 'imaginary', 10, 'olanzapine')).toBeNull();
    expect(convertWithinFamily('cpz', 'olanzapine', 10, 'imaginary')).toBeNull();
  });

  test('roundToClinicalDose: 0–5 mg → 0.5', () => {
    expect(roundToClinicalDose(0)).toBe(0);
    expect(roundToClinicalDose(2.3)).toBe(2.5);
    expect(roundToClinicalDose(4.6)).toBe(4.5);
    // 5–50 mg → 1 mg
    expect(roundToClinicalDose(7.4)).toBe(7);
    expect(roundToClinicalDose(48.7)).toBe(49);
    // 50–200 mg → 5 mg
    expect(roundToClinicalDose(73)).toBe(75);
    expect(roundToClinicalDose(127)).toBe(125);
    // ≥200 mg → 25 mg
    expect(roundToClinicalDose(213)).toBe(225);
    expect(roundToClinicalDose(490)).toBe(500);
  });

  test('all families have a reference entry that maps to itself', () => {
    for (const meta of Object.values(EQUIVALENCY_FAMILIES)) {
      const ref = meta.entries.find((e) => e.equivalentMg === meta.reference.mg);
      expect(ref).toBeDefined();
    }
  });
});
