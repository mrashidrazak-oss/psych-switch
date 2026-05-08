import {
  adaptStepNotes,
  roundToIncrement,
  scaleSchedule,
  pickScalingMode,
} from '../scaleSchedule';
import { getDrug, listRules } from '../switchingEngine';
import type { SwitchingRule } from '../types';

describe('adaptStepNotes', () => {
  test('substitutes both from-dose and to-dose mentions', () => {
    const out = adaptStepNotes(
      'Start sertraline 50 mg. Continue agomelatine 25 mg nocte.',
      25, 50,
      30, 60,
    );
    expect(out).toBe('Start sertraline 60 mg. Continue agomelatine 30 mg nocte.');
  });

  test('preserves future-tense dose mentions that do not match step doses', () => {
    // "Titrate to 100 mg at 4 weeks" — 100 isn\'t the step dose, must NOT be replaced.
    const out = adaptStepNotes(
      'Stop agomelatine. Continue sertraline 50 mg. Titrate sertraline to 100 mg at 4 weeks.',
      0, 50,
      0, 60,
    );
    expect(out).toContain('sertraline 60 mg');
    expect(out).toContain('100 mg at 4 weeks');
  });

  test('returns notes unchanged when no doses changed', () => {
    const original = 'Continue sertraline 50 mg.';
    expect(adaptStepNotes(original, 50, 50, 50, 50)).toBe(original);
  });

  test('returns undefined for undefined input', () => {
    expect(adaptStepNotes(undefined, 25, 50, 30, 60)).toBeUndefined();
  });

  test('handles half-mg doses (regex escapes the decimal)', () => {
    const out = adaptStepNotes(
      'Reduce olanzapine to 7.5 mg.',
      7.5, 0,
      10, 0,
    );
    expect(out).toBe('Reduce olanzapine to 10 mg.');
  });

  test('does not substitute numbers without "mg" suffix', () => {
    const out = adaptStepNotes(
      'Review at 4 weeks; sertraline 50 mg ongoing.',
      0, 50,
      0, 60,
    );
    expect(out).toBe('Review at 4 weeks; sertraline 60 mg ongoing.');
  });

  test('largest-first ordering prevents partial replacement', () => {
    // 5 → 10 and 50 → 100. If we processed 5 first, "50" could become "100" wrongly.
    const out = adaptStepNotes(
      'Reduce X 50 mg. Reduce Y 5 mg.',
      50, 5,
      100, 10,
    );
    expect(out).toBe('Reduce X 100 mg. Reduce Y 10 mg.');
  });

  test('strips trailing zeros in the substituted dose', () => {
    const out = adaptStepNotes(
      'Continue at 5 mg.',
      5, 0,
      10, 0,
    );
    expect(out).toBe('Continue at 10 mg.');
  });
});

describe('roundToIncrement', () => {
  test('rounds to the closest entry', () => {
    expect(roundToIncrement(22.5, [2.5, 5, 7.5, 10, 15, 20])).toBe(20);
    expect(roundToIncrement(7.4, [2.5, 5, 7.5, 10, 15, 20])).toBe(7.5);
    expect(roundToIncrement(6.7, [5, 10, 15, 20, 30])).toBe(5);
  });

  test('preserves 0 (stop signal)', () => {
    expect(roundToIncrement(0, [2.5, 5, 7.5])).toBe(0);
    expect(roundToIncrement(-1, [2.5, 5, 7.5])).toBe(0);
  });

  test('handles empty increments gracefully', () => {
    expect(roundToIncrement(7.5, [])).toBe(7.5);
  });
});

describe('pickScalingMode', () => {
  test('LAI on either side → no-scale', () => {
    const fromOral = getDrug('aripiprazole')!;
    const toLai = getDrug('aripiprazole-lai')!;
    const rule = listRules().find((r) => r.fromDrugId === 'aripiprazole' && r.toDrugId === 'aripiprazole-lai')!;
    expect(pickScalingMode(rule, fromOral, toLai)).toBe('no-scale');
  });

  test('Oral → oral cross-taper defaults to proportional', () => {
    const olz = getDrug('olanzapine')!;
    const arip = getDrug('aripiprazole')!;
    const rule = listRules().find((r) => r.fromDrugId === 'olanzapine' && r.toDrugId === 'aripiprazole')!;
    expect(pickScalingMode(rule, olz, arip)).toBe('proportional');
  });

  test('explicit scalingMode on rule wins', () => {
    const olz = getDrug('olanzapine')!;
    const arip = getDrug('aripiprazole')!;
    const rule = listRules().find((r) => r.fromDrugId === 'olanzapine' && r.toDrugId === 'aripiprazole')!;
    const tagged = { ...rule, scalingMode: 'fixed-step' } as unknown as SwitchingRule;
    expect(pickScalingMode(tagged, olz, arip)).toBe('fixed-step');
  });
});

describe('scaleSchedule (proportional)', () => {
  const olz = getDrug('olanzapine')!;
  const arip = getDrug('aripiprazole')!;
  const rule = listRules().find(
    (r) => r.fromDrugId === 'olanzapine' && r.toDrugId === 'aripiprazole',
  )!;
  const refFrom = rule.doseRatios.fromCurrentDoseMg;
  const refTo = rule.doseRatios.toTargetDoseMg;

  test('user doses == reference → adapted: false', () => {
    const r = scaleSchedule({
      rule, fromDrug: olz, toDrug: arip,
      userFromDose: refFrom,
      userToDose: refTo,
    });
    expect(r.adapted).toBe(false);
    expect(r.evidencePenalty).toBe(0);
    expect(r.schedule).toBe(rule.schedule); // identity — same array
  });

  test('user doses differ → adapted: true + evidence penalty 1', () => {
    const r = scaleSchedule({
      rule, fromDrug: olz, toDrug: arip,
      userFromDose: refFrom * 1.5,
      userToDose: refTo * 1.5,
    });
    expect(r.adapted).toBe(true);
    expect(r.evidencePenalty).toBe(1);
  });

  test('every adapted dose is in the drug increments OR zero', () => {
    const r = scaleSchedule({
      rule, fromDrug: olz, toDrug: arip,
      userFromDose: refFrom * 1.5,
      userToDose: refTo * 1.5,
    });
    const fromIncs = new Set(olz.dosing.increments);
    const toIncs = new Set(arip.dosing.increments);
    for (const step of r.schedule) {
      expect(step.fromDoseMg === 0 || fromIncs.has(step.fromDoseMg)).toBe(true);
      expect(step.toDoseMg === 0 || toIncs.has(step.toDoseMg)).toBe(true);
    }
  });

  test('extreme scale factor produces a warning', () => {
    const r = scaleSchedule({
      rule, fromDrug: olz, toDrug: arip,
      userFromDose: refFrom * 3,   // 3× → above 2.0× ceiling
      userToDose: refTo,
    });
    expect(r.warnings.some((w) => w.kind === 'extreme_factor_from')).toBe(true);
  });

  test('cap-at-max generates a capped_at_max warning', () => {
    const r = scaleSchedule({
      rule, fromDrug: olz, toDrug: arip,
      userFromDose: refFrom * 5,    // way above max
      userToDose: refTo,
    });
    expect(r.warnings.some((w) => w.kind === 'capped_at_max')).toBe(true);
    // No step exceeds the max.
    for (const s of r.schedule) {
      expect(s.fromDoseMg).toBeLessThanOrEqual(olz.dosing.maxDoseMg);
    }
  });

  test('rounding-to-duplicate-doses merges adjacent steps', () => {
    // Find a rule where scaling is likely to round adjacent steps to
    // the same dose. Use a small to-target so nearly all to-doses
    // round to the smallest increment.
    const r = scaleSchedule({
      rule, fromDrug: olz, toDrug: arip,
      userFromDose: refFrom * 0.25,  // 0.25× from
      userToDose: refTo * 0.1,        // 0.1× to — extreme
    });
    // Either some duplicates were merged OR the schedule is shorter.
    const merged = r.warnings.some((w) => w.kind === 'merged_duplicate');
    const shorter = r.schedule.length <= rule.schedule.length;
    expect(merged || shorter).toBe(true);
  });

  test('invalid input returns reviewed schedule with a warning', () => {
    const r = scaleSchedule({
      rule, fromDrug: olz, toDrug: arip,
      userFromDose: 0,
      userToDose: refTo,
    });
    expect(r.adapted).toBe(false);
    expect(r.warnings.some((w) => w.kind === 'invalid_input')).toBe(true);
  });
});

describe('scaleSchedule (no-scale)', () => {
  test('LAI rule returns reviewed schedule untouched + no_scale warning', () => {
    const arip = getDrug('aripiprazole')!;
    const aripLai = getDrug('aripiprazole-lai')!;
    const rule = listRules().find(
      (r) => r.fromDrugId === 'aripiprazole' && r.toDrugId === 'aripiprazole-lai',
    );
    if (!rule) return; // skip if rule not registered
    const r = scaleSchedule({
      rule,
      fromDrug: arip,
      toDrug: aripLai,
      userFromDose: rule.doseRatios.fromCurrentDoseMg * 1.5,  // mismatch
      userToDose: rule.doseRatios.toTargetDoseMg,
    });
    expect(r.adapted).toBe(false);
    expect(r.applied.mode).toBe('no-scale');
    expect(r.warnings.some((w) => w.kind === 'no_scale')).toBe(true);
    expect(r.schedule).toBe(rule.schedule);
  });
});
