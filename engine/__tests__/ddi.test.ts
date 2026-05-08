import { checkAll, checkPair } from '../ddi';

describe('DDI checker', () => {
  test('SSRI + SSRI flags serotonergic stacking', () => {
    const hits = checkPair('fluoxetine', 'sertraline');
    expect(hits.some((h) => h.mechanism === 'serotonergic')).toBe(true);
  });

  test('SSRI + MAOI is "avoid"', () => {
    const hits = checkPair('fluoxetine', 'phenelzine');
    expect(hits.find((h) => h.mechanism === 'serotonergic')?.severity).toBe('avoid');
  });

  test('paroxetine + risperidone flags CYP2D6 inhibition', () => {
    const hits = checkPair('paroxetine', 'risperidone');
    expect(hits.some((h) => h.mechanism === 'cyp_inhibition')).toBe(true);
  });

  test('fluvoxamine + clozapine flags CYP1A2 inhibition', () => {
    const hits = checkPair('fluvoxamine', 'clozapine');
    expect(hits.some((h) => h.mechanism === 'cyp_inhibition')).toBe(true);
  });

  test('aripiprazole + risperidone flags pharmacodynamic conflict', () => {
    const hits = checkPair('aripiprazole', 'risperidone');
    expect(hits.some((h) => h.mechanism === 'pharmacodynamic')).toBe(true);
  });

  test('haloperidol + amisulpride flags QTc additive', () => {
    const hits = checkPair('haloperidol', 'amisulpride');
    expect(hits.some((h) => h.mechanism === 'qtc_additive')).toBe(true);
  });

  test('olanzapine + quetiapine flags sedation additive', () => {
    const hits = checkPair('olanzapine', 'quetiapine');
    expect(hits.some((h) => h.mechanism === 'sedation_additive')).toBe(true);
  });

  test('a benign pair returns no hits', () => {
    const hits = checkPair('lurasidone', 'agomelatine');
    expect(hits).toEqual([]);
  });

  test('checkAll considers every pair', () => {
    const all = checkAll(['fluoxetine', 'sertraline', 'phenelzine']);
    // Fluoxetine+sertraline (SSRI+SSRI) AND fluoxetine+phenelzine (avoid)
    // AND sertraline+phenelzine (avoid) → at least 3 hits
    expect(all.length).toBeGreaterThanOrEqual(3);
  });
});
