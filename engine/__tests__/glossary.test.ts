import { lookupTerm, listGlossary } from '../glossary';

describe('glossary lookups', () => {
  test('finds known terms case-insensitively', () => {
    expect(lookupTerm('esrs')).not.toBeNull();
    expect(lookupTerm('ESRS')).not.toBeNull();
    expect(lookupTerm('Esrs')).not.toBeNull();
  });

  test('returns null for unknown terms', () => {
    expect(lookupTerm('not-a-real-term')).toBeNull();
    expect(lookupTerm('')).toBeNull();
  });

  test('common abbreviations are all registered', () => {
    for (const term of ['QTc', 'EPS', 'akathisia', 'MAOI', 'LAI', 'CYP2D6', 'FBC', 'eGFR']) {
      expect(lookupTerm(term)).not.toBeNull();
    }
  });

  test('listGlossary returns alphabetical list', () => {
    const list = listGlossary();
    expect(list.length).toBeGreaterThan(15);
    for (let i = 1; i < list.length; i++) {
      expect(list[i].term.localeCompare(list[i - 1].term)).toBeGreaterThanOrEqual(0);
    }
  });

  test('every entry has a non-empty definition', () => {
    for (const e of listGlossary()) {
      expect(e.definition.length).toBeGreaterThan(0);
    }
  });
});
