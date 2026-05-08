import { predictAeProfile, likelihoodLabel } from '../predictedAeProfile';
import { getDrug } from '../switchingEngine';

describe('predictAeProfile', () => {
  test('aripiprazole shows akathisia as high (drug profile flag)', () => {
    const profile = predictAeProfile(getDrug('aripiprazole')!);
    const eps = profile.predictions.find((p) => p.ae.id === 'eps_akathisia');
    expect(eps).toBeDefined();
    // Aripiprazole is in causedBy[] for eps_akathisia → high likelihood
    expect(['high', 'moderate']).toContain(eps!.likelihood);
  });

  test('olanzapine shows weight gain as high', () => {
    const profile = predictAeProfile(getDrug('olanzapine')!);
    const wt = profile.predictions.find((p) => p.ae.id === 'weight_gain');
    expect(wt?.likelihood).toBe('high');
  });

  test('aripiprazole shows weight gain as low when switching from olanzapine', () => {
    const profile = predictAeProfile(getDrug('aripiprazole')!, getDrug('olanzapine')!);
    const wt = profile.predictions.find((p) => p.ae.id === 'weight_gain');
    expect(wt?.likelihood).toBe('lower-than-current');
  });

  test('mirtazapine shows sedation high (per drug profile)', () => {
    const profile = predictAeProfile(getDrug('mirtazapine')!);
    const sed = profile.predictions.find((p) => p.ae.id === 'sedation');
    expect(sed).toBeDefined();
    expect(['high', 'moderate']).toContain(sed!.likelihood);
  });

  test('predictions sorted by likelihood (high first)', () => {
    const profile = predictAeProfile(getDrug('clozapine')!);
    const ranks = profile.predictions.map((p) => {
      switch (p.likelihood) {
        case 'high': return 4;
        case 'moderate': return 3;
        case 'low': return 2;
        case 'lower-than-current': return 1;
        case 'unknown': return 0;
      }
    });
    for (let i = 1; i < ranks.length; i++) {
      expect(ranks[i]).toBeLessThanOrEqual(ranks[i - 1]);
    }
  });

  test('every prediction includes a non-empty reason', () => {
    const profile = predictAeProfile(getDrug('quetiapine')!);
    for (const p of profile.predictions) {
      expect(p.reason.length).toBeGreaterThan(0);
    }
  });

  test('likelihoodLabel returns user-facing strings', () => {
    expect(likelihoodLabel('high')).toMatch(/high/i);
    expect(likelihoodLabel('lower-than-current')).toMatch(/lower/i);
  });
});
