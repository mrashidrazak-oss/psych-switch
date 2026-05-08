import {
  changeKindLabel,
  errataCount,
  errataForRule,
  errataForScope,
  errataSinceVersion,
  listErrata,
  severityColor,
  severityLabel,
  type ErrataEntry,
} from '../errata';

describe('errata feed', () => {
  test('listErrata returns at least one entry', () => {
    const all = listErrata();
    expect(all.length).toBeGreaterThan(0);
  });

  test('entries are sorted newest first', () => {
    const all = listErrata();
    for (let i = 1; i < all.length; i++) {
      expect(all[i].dateISO.localeCompare(all[i - 1].dateISO)).toBeLessThanOrEqual(0);
    }
  });

  test('every entry has required fields', () => {
    for (const e of listErrata() as ErrataEntry[]) {
      expect(e.id.length).toBeGreaterThan(0);
      expect(e.dateISO).toMatch(/^\d{4}-\d{2}-\d{2}/);
      expect(e.scope.length).toBeGreaterThan(0);
      expect(e.scopeLabel.length).toBeGreaterThan(0);
      expect(e.summary.length).toBeGreaterThan(0);
      expect(e.detail.length).toBeGreaterThan(0);
      expect(e.rationale.length).toBeGreaterThan(0);
      expect(e.reviewer.length).toBeGreaterThan(0);
      expect(e.appVersion).toMatch(/^\d+\.\d+/);
    }
  });

  test('errataCount matches listErrata length', () => {
    expect(errataCount()).toBe(listErrata().length);
  });

  test('errataForScope filters by scope', () => {
    const paroxetine = errataForScope('paroxetine');
    expect(paroxetine.every((e) => e.scope === 'paroxetine')).toBe(true);
  });

  test('errataForRule alias works the same as errataForScope', () => {
    expect(errataForRule('paroxetine').length).toBe(errataForScope('paroxetine').length);
  });

  test('errataSinceVersion ignores entries from before the given version', () => {
    const since = errataSinceVersion('0.3.0');
    expect(since.every((e) => parseFloat(e.appVersion) >= 0.3)).toBe(true);
  });

  test('errataSinceVersion("0.0.0") returns everything', () => {
    expect(errataSinceVersion('0.0.0').length).toBe(listErrata().length);
  });

  test('errataSinceVersion("99.0.0") returns nothing', () => {
    expect(errataSinceVersion('99.0.0').length).toBe(0);
  });

  test('label helpers return user-facing strings', () => {
    expect(severityLabel('critical')).toBe('Critical');
    expect(changeKindLabel('dose')).toBe('Dose');
  });

  test('severityColor returns matching tints for each severity', () => {
    for (const s of ['minor', 'moderate', 'significant', 'critical'] as const) {
      const c = severityColor(s);
      expect(c.bg.length).toBeGreaterThan(0);
      expect(c.text.length).toBeGreaterThan(0);
    }
  });
});
