import { getDiscontinuationFlag, severityRank } from '../discontinuation';

describe('discontinuation flagger', () => {
  test('paroxetine = very_high severity', () => {
    const f = getDiscontinuationFlag('paroxetine');
    expect(f?.severity).toBe('very_high');
    expect(f?.halfLifeHours).toBe(21);
  });

  test('venlafaxine bridge-to-fluoxetine strategy', () => {
    const f = getDiscontinuationFlag('venlafaxine');
    expect(f?.severity).toBe('very_high');
    expect(f?.strategy).toMatch(/fluoxetine/i);
  });

  test('fluoxetine itself = low (long t½ self-tapers)', () => {
    expect(getDiscontinuationFlag('fluoxetine')?.severity).toBe('low');
  });

  test('clozapine = very_high (rebound psychosis)', () => {
    const f = getDiscontinuationFlag('clozapine');
    expect(f?.severity).toBe('very_high');
    expect(f?.symptoms).toMatch(/rebound|psychosis/i);
  });

  test('unknown drug returns null', () => {
    expect(getDiscontinuationFlag('imaginary')).toBeNull();
  });

  test('severityRank ordering', () => {
    expect(severityRank('very_high')).toBeGreaterThan(severityRank('low'));
  });
});
