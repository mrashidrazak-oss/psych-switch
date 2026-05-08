import { getCitation, gradeCitations, gradeLabel } from '../citations';

describe('citation registry', () => {
  test('curated key returns paraphrase + locator', () => {
    const c = getCitation('maudsley15_ch3_p369_table_3_7');
    expect(c.source).toBe('Maudsley15');
    expect(c.locator).toMatch(/3\.7/);
    expect(c.paraphrase).toBeTruthy();
  });

  test('uncurated maudsley key still grades A', () => {
    const c = getCitation('maudsley15_some_uncurated_thing');
    expect(c.source).toBe('Maudsley15');
    expect(c.reference).toMatch(/Maudsley/i);
  });

  test('BAP keys resolve to BAP source', () => {
    expect(getCitation('bap2020_psychosis').source).toBe('BAP');
    expect(getCitation('bap2015_switching_antidepressants').source).toBe('BAP');
    expect(getCitation('bap2016_bipolar_guidelines').source).toBe('BAP');
  });

  test('manufacturer keys resolve to manufacturer source', () => {
    expect(getCitation('invega_sustenna_pi').source).toBe('manufacturer');
    expect(getCitation('abilify_maintena_pi').source).toBe('manufacturer');
  });

  test('unknown keys fall back to "other"', () => {
    expect(getCitation('zzz_unknown_thing').source).toBe('other');
  });
});

describe('evidence grading', () => {
  test('Maudsley-only rule = grade A', () => {
    expect(gradeCitations(['maudsley15_ch3_p369_table_3_7'])).toBe('A');
  });

  test('Mixed Maudsley + BAP = grade A (best wins)', () => {
    expect(gradeCitations(['maudsley15_ch3_p369_table_3_7', 'bap2020_psychosis'])).toBe('A');
  });

  test('Horowitz alone = grade B', () => {
    expect(gradeCitations(['horowitz2020_hyperbolic_tapering'])).toBe('B');
  });

  test('Empty citations = grade D', () => {
    expect(gradeCitations([])).toBe('D');
  });

  test('Best citation wins — Horowitz + Maudsley = A', () => {
    expect(gradeCitations(['horowitz2020_hyperbolic_tapering', 'maudsley15_ch3_p374_withdrawal'])).toBe('A');
  });

  test('Manufacturer PI alone = grade A', () => {
    expect(gradeCitations(['invega_sustenna_pi'])).toBe('A');
  });

  test('gradeLabel returns human strings', () => {
    expect(gradeLabel('A')).toMatch(/Direct/);
    expect(gradeLabel('D')).toMatch(/Limited/);
  });
});
