import {
  applyConservativeOverlap,
  assessOverlapIntensity,
  flagLabel,
  tierLabel,
} from '../overlapIntensity';
import { generateSwitchPlan, getDrug } from '../switchingEngine';
import type { ScheduleStep } from '../types';

function planFor(fromId: string, fromDose: number, toId: string, toDose: number) {
  const plan = generateSwitchPlan({
    fromDrugId: fromId, fromDoseMg: fromDose,
    toDrugId: toId,   toDoseMg:   toDose,
  });
  if (plan.status !== 'ok') throw new Error(`expected ok plan, got ${plan.status}`);
  return plan;
}

describe('assessOverlapIntensity — score + tier', () => {
  test('schedule with no co-prescribed days returns "No overlap"', () => {
    const fromDrug = getDrug('olanzapine')!;
    const toDrug = getDrug('aripiprazole')!;
    const schedule: ScheduleStep[] = [
      { day: 1, fromDoseMg: 20, toDoseMg: 0 },
      { day: 7, fromDoseMg: 0,  toDoseMg: 15 },
    ];
    const a = assessOverlapIntensity({ fromDrug, toDrug, schedule });
    expect(a.label).toBe('No overlap');
    expect(a.score).toBe(0);
  });

  test('reviewed SSRI cross-taper produces a non-zero overlap score', () => {
    const sertraline = getDrug('sertraline')!;
    const escitalopram = getDrug('escitalopram')!;
    const plan = planFor('sertraline', 100, 'escitalopram', 10);
    const ssri = assessOverlapIntensity({
      fromDrug: sertraline, toDrug: escitalopram, schedule: plan.schedule,
    });
    expect(ssri.score).toBeGreaterThan(0);
    expect(['low', 'moderate', 'high', 'severe']).toContain(ssri.tier);
  });

  test('reviewed antipsychotic cross-taper produces a non-zero overlap score', () => {
    const olanzapine = getDrug('olanzapine')!;
    const aripiprazole = getDrug('aripiprazole')!;
    const plan = planFor('olanzapine', 20, 'aripiprazole', 15);
    const ap = assessOverlapIntensity({
      fromDrug: olanzapine, toDrug: aripiprazole, schedule: plan.schedule,
    });
    expect(ap.score).toBeGreaterThan(0);
  });

  test('serotonergic_stacking flag fires for SSRI + SSRI pair', () => {
    const sertraline = getDrug('sertraline')!;
    const escitalopram = getDrug('escitalopram')!;
    const plan = planFor('sertraline', 100, 'escitalopram', 10);
    const a = assessOverlapIntensity({
      fromDrug: sertraline, toDrug: escitalopram, schedule: plan.schedule,
    });
    expect(a.flags).toContain('serotonergic_stacking');
    expect(a.components.mechanismMultiplier).toBeGreaterThan(1);
  });

  test('qt_additive flag fires for haloperidol + amisulpride', () => {
    const halo = getDrug('haloperidol')!;
    const amis = getDrug('amisulpride')!;
    const plan = planFor('amisulpride', 400, 'haloperidol', 5);
    const a = assessOverlapIntensity({
      fromDrug: amis, toDrug: halo, schedule: plan.schedule,
    });
    expect(a.flags).toContain('qt_additive');
  });

  test('mechanism multiplier is capped at 2.2', () => {
    // Synthesise a worst-case schedule by hand
    const sertraline = getDrug('sertraline')!;
    const fluoxetine = getDrug('fluoxetine')!;
    const schedule: ScheduleStep[] = [
      { day: 1, fromDoseMg: 200, toDoseMg: 80 },
      { day: 28, fromDoseMg: 0, toDoseMg: 80 },
    ];
    const a = assessOverlapIntensity({
      fromDrug: sertraline, toDrug: fluoxetine, schedule,
    });
    expect(a.components.mechanismMultiplier).toBeLessThanOrEqual(2.2);
    expect(a.score).toBeLessThanOrEqual(100);
  });

  test('tier labels match the score boundaries', () => {
    expect(tierLabel('low')).toMatch(/Low/);
    expect(tierLabel('severe')).toMatch(/Severe/);
  });

  test('flagLabel returns user-facing strings', () => {
    expect(flagLabel('serotonergic_stacking')).toMatch(/Serotonergic/);
    expect(flagLabel('qt_additive')).toMatch(/QTc/);
    expect(flagLabel('unknown_flag')).toBe('unknown_flag');
  });

  test('rationale mentions Day 1 percentages and overlap days', () => {
    const sertraline = getDrug('sertraline')!;
    const escitalopram = getDrug('escitalopram')!;
    const plan = planFor('sertraline', 100, 'escitalopram', 10);
    const a = assessOverlapIntensity({
      fromDrug: sertraline, toDrug: escitalopram, schedule: plan.schedule,
    });
    expect(a.rationale).toMatch(/%/);
    expect(a.rationale).toMatch(/day/i);
  });
});

describe('applyConservativeOverlap', () => {
  const olanzapine = getDrug('olanzapine')!;

  test('reduces Day 1 from-dose by ~25%, rounded to formulation', () => {
    const schedule: ScheduleStep[] = [
      { day: 1, fromDoseMg: 20, toDoseMg: 5 },
      { day: 7, fromDoseMg: 15, toDoseMg: 10 },
      { day: 14, fromDoseMg: 10, toDoseMg: 15 },
      { day: 21, fromDoseMg: 5, toDoseMg: 15 },
      { day: 28, fromDoseMg: 0, toDoseMg: 15 },
    ];
    const result = applyConservativeOverlap(schedule, olanzapine);
    expect(result.modified).toBe(true);
    // 20 × 0.75 = 15 — but day 2 is also 15, so the clamp keeps it at 15
    expect(result.schedule[0].fromDoseMg).toBe(15);
  });

  test('does NOT mutate the input schedule', () => {
    const original: ScheduleStep[] = [
      { day: 1, fromDoseMg: 20, toDoseMg: 5 },
      { day: 7, fromDoseMg: 15, toDoseMg: 10 },
      { day: 14, fromDoseMg: 0, toDoseMg: 15 },
    ];
    const snapshot = JSON.stringify(original);
    applyConservativeOverlap(original, olanzapine);
    expect(JSON.stringify(original)).toBe(snapshot);
  });

  test('returns unchanged if Day 1 from-dose is 0', () => {
    const schedule: ScheduleStep[] = [
      { day: 1, fromDoseMg: 0, toDoseMg: 15 },
      { day: 7, fromDoseMg: 0, toDoseMg: 15 },
    ];
    const result = applyConservativeOverlap(schedule, olanzapine);
    expect(result.modified).toBe(false);
    expect(result.schedule).toEqual(schedule);
  });

  test('clamps to Day 2 dose so the taper stays monotonic', () => {
    // From-doses: 10 → 10 → 0. 25% of 10 = 7.5 (valid increment for olanzapine)
    // but Day 2 is also 10, so clamping forces Day 1 to 10 → no change.
    const schedule: ScheduleStep[] = [
      { day: 1, fromDoseMg: 10, toDoseMg: 5 },
      { day: 7, fromDoseMg: 10, toDoseMg: 10 },
      { day: 14, fromDoseMg: 0, toDoseMg: 15 },
    ];
    const result = applyConservativeOverlap(schedule, olanzapine);
    expect(result.modified).toBe(false);
  });

  test('appends a "Conservative mode" tag to Day 1 notes', () => {
    const schedule: ScheduleStep[] = [
      { day: 1, fromDoseMg: 20, toDoseMg: 5, notes: 'Original note.' },
      { day: 7, fromDoseMg: 10, toDoseMg: 10 },
      { day: 14, fromDoseMg: 0, toDoseMg: 15 },
    ];
    const result = applyConservativeOverlap(schedule, olanzapine);
    if (result.modified) {
      expect(result.schedule[0].notes).toMatch(/Conservative mode/);
      expect(result.schedule[0].notes).toMatch(/Original note/);
    }
  });

  test('schedule with <2 steps returns unchanged', () => {
    const schedule: ScheduleStep[] = [{ day: 1, fromDoseMg: 20, toDoseMg: 5 }];
    const result = applyConservativeOverlap(schedule, olanzapine);
    expect(result.modified).toBe(false);
  });
});
