import { search } from '../search';

describe('search', () => {
  test('finds drug by generic name', () => {
    const hits = search('olanz');
    expect(hits.some((h) => h.kind === 'drug' && h.title === 'Olanzapine')).toBe(true);
  });

  test('"olanz to arip" finds the rule', () => {
    const hits = search('olanz to arip');
    expect(hits.some((h) => h.kind === 'rule' && h.title.includes('Olanzapine'))).toBe(true);
  });

  test('"X → Y" arrow form works', () => {
    const hits = search('olanzapine → aripiprazole');
    expect(hits.some((h) => h.kind === 'rule')).toBe(true);
  });

  test('finds tools by keyword', () => {
    const hits = search('qtc');
    expect(hits.some((h) => h.kind === 'tool' && h.title === 'QTc stacker')).toBe(true);
  });

  test('finds modules', () => {
    const hits = search('clozapine');
    expect(hits.some((h) => h.kind === 'module' && h.title === 'Clozapine')).toBe(true);
  });

  test('no results for short queries', () => {
    expect(search('o')).toEqual([]);
  });

  test('limits results', () => {
    const hits = search('a', 5);
    expect(hits.length).toBeLessThanOrEqual(5);
  });
});
