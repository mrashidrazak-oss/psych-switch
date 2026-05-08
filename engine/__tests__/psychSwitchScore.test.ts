import { computePsychSwitchScore, bandFor } from '../psychSwitchScore';
import { ADVERSE_EFFECTS } from '../adverseEffects';
import { generateSwitchPlan, getDrug } from '../switchingEngine';
import { scaleSchedule } from '../scaleSchedule';
import { gradeCitations } from '../citations';
import { checkPair } from '../ddi';
import { warningsForDrug } from '../patientContext';
import type { PatientContext } from '../patientContext';

function buildScoreInputs(opts: {
  fromId: string;
  toId: string;
  fromDose: number;
  toDose: number;
  context?: PatientContext;
  avoidAeId?: string;
}) {
  const fromDrug = getDrug(opts.fromId)!;
  const toDrug = getDrug(opts.toId)!;
  const plan = generateSwitchPlan({
    fromDrugId: opts.fromId,
    fromDoseMg: opts.fromDose,
    toDrugId: opts.toId,
    toDoseMg: opts.toDose,
  });
  if (plan.status !== 'ok') throw new Error(`Test setup expected ok plan, got ${plan.status}`);
  const scaleResult = scaleSchedule({
    rule: plan.rule,
    fromDrug,
    toDrug,
    userFromDose: opts.fromDose,
    userToDose: opts.toDose,
  });
  const ddiHits = checkPair(opts.fromId, opts.toId);
  const ctx = opts.context ?? {};
  const ctxWarnings = [
    ...warningsForDrug(ctx, opts.fromId),
    ...warningsForDrug(ctx, opts.toId),
  ];
  const evidenceGrade = gradeCitations(plan.citations);
  const avoidAe = opts.avoidAeId
    ? ADVERSE_EFFECTS.find((a) => a.id === opts.avoidAeId) ?? null
    : null;
  return {
    rule: plan.rule,
    fromDrug,
    toDrug,
    context: ctx,
    scaleResult,
    ddiHits,
    contextWarnings: ctxWarnings,
    evidenceGrade,
    avoidAe,
  };
}

describe('bandFor', () => {
  test('90+ is excellent', () => {
    expect(bandFor(100)).toBe('excellent');
    expect(bandFor(90)).toBe('excellent');
  });
  test('75-89 is good', () => {
    expect(bandFor(89)).toBe('good');
    expect(bandFor(75)).toBe('good');
  });
  test('50-74 is caution', () => {
    expect(bandFor(74)).toBe('caution');
    expect(bandFor(50)).toBe('caution');
  });
  test('<50 is poor', () => {
    expect(bandFor(49)).toBe('poor');
    expect(bandFor(0)).toBe('poor');
  });
});

describe('computePsychSwitchScore', () => {
  test('a clean reviewed switch with matched doses scores high', () => {
    const inputs = buildScoreInputs({
      fromId: 'olanzapine',
      toId: 'aripiprazole',
      fromDose: 20,    // == reference
      toDose: 15,
    });
    const score = computePsychSwitchScore(inputs);
    expect(score.total).toBeGreaterThanOrEqual(75);
    expect(['excellent', 'good']).toContain(score.band);
  });

  test('warning-grade DDI pulls the score down', () => {
    // amisulpride + haloperidol — both QT-prolongers, additive warning,
    // and there's a reviewed cross-taper rule for this pair.
    const inputs = buildScoreInputs({
      fromId: 'amisulpride',
      toId: 'haloperidol',
      fromDose: 400,
      toDose: 5,
    });
    const score = computePsychSwitchScore(inputs);
    expect(score.components.ddiSafety.delta).toBeLessThan(0);
  });

  test('AE alignment bonus when target avoids the patient\'s flagged AE', () => {
    const inputs = buildScoreInputs({
      fromId: 'olanzapine',
      toId: 'aripiprazole',
      fromDose: 20,
      toDose: 15,
      avoidAeId: 'weight_gain',
    });
    const score = computePsychSwitchScore(inputs);
    expect(score.components.aeAlignment.delta).toBeGreaterThan(0);
  });

  test('AE alignment penalty when target causes the flagged AE', () => {
    // amisulpride → quetiapine is reviewed; quetiapine causes weight gain.
    const inputs = buildScoreInputs({
      fromId: 'amisulpride',
      toId: 'quetiapine',
      fromDose: 400,
      toDose: 300,
      avoidAeId: 'weight_gain',
    });
    const score = computePsychSwitchScore(inputs);
    expect(score.components.aeAlignment.delta).toBeLessThan(0);
  });

  test('dose adaptation triggers a small penalty', () => {
    const inputs = buildScoreInputs({
      fromId: 'olanzapine',
      toId: 'aripiprazole',
      fromDose: 30,    // != reference 20
      toDose: 20,
    });
    const score = computePsychSwitchScore(inputs);
    expect(score.components.doseFidelity.delta).toBeLessThan(0);
  });

  test('headline reflects the band + grade', () => {
    const inputs = buildScoreInputs({
      fromId: 'olanzapine',
      toId: 'aripiprazole',
      fromDose: 20,
      toDose: 15,
    });
    const score = computePsychSwitchScore(inputs);
    expect(score.headline).toMatch(/grade/i);
    expect(score.headline.toLowerCase()).toContain(score.band);
  });

  test('total never escapes 0–100', () => {
    const inputs = buildScoreInputs({
      fromId: 'amisulpride',
      toId: 'haloperidol',
      fromDose: 400,
      toDose: 5,
    });
    const score = computePsychSwitchScore(inputs);
    expect(score.total).toBeGreaterThanOrEqual(0);
    expect(score.total).toBeLessThanOrEqual(100);
  });
});
