// Mood-stabilizer tapering tests.
//
// Per CLAUDE.md: clinical content gets unit tests.
// These pin down the Maudsley 15 lithium reduction regimen (Box 2.3)
// and the withdrawal effects table (Table 2.13).

import { getLithiumTapering } from '../moodStabilizerTapering';

describe('lithium tapering protocol (Maudsley 15)', () => {
  test('returns the Maudsley Box 2.3 regimen with 4 phases', () => {
    const data = getLithiumTapering();
    expect(data.tapering.maudsleyRegimen.steps.length).toBe(4);
  });

  test('regimen step doses follow the hyperbolic principle (200 → 100 → 50 → 25 mg)', () => {
    const steps = getLithiumTapering().tapering.maudsleyRegimen.steps;
    expect(steps[0].stepDoseMg).toBe(200);
    expect(steps[1].stepDoseMg).toBe(100);
    expect(steps[2].stepDoseMg).toBe(50);
    expect(steps[3].stepDoseMg).toBe(25);
    // Each successive step is half the previous — hyperbolic.
    for (let i = 1; i < steps.length; i++) {
      expect(steps[i].stepDoseMg).toBeLessThan(steps[i - 1].stepDoseMg);
    }
  });

  test('regimen reaches zero by the final phase', () => {
    const steps = getLithiumTapering().tapering.maudsleyRegimen.steps;
    expect(steps[steps.length - 1].untilDoseMg).toBe(0);
  });

  test('withdrawal effects include both physical and psychological symptoms', () => {
    const we = getLithiumTapering().withdrawalEffects;
    expect(we.physical.length).toBeGreaterThanOrEqual(3);
    expect(we.psychological.length).toBeGreaterThanOrEqual(3);
    // Mania is the highest-stakes withdrawal symptom — must be present.
    const psychLower = we.psychological.map((s) => s.toLowerCase());
    expect(psychLower.some((s) => s.includes('mania'))).toBe(true);
  });

  test('rationale includes the sevenfold relapse-rate finding', () => {
    const rationale = getLithiumTapering().rationale;
    expect(rationale.toLowerCase()).toMatch(/sevenfold|seven|7×|7 times/);
  });

  test('citations reference Maudsley 15 bipolar chapter', () => {
    const citations = getLithiumTapering().citations;
    const hasMaudsley15 = citations.some((c) => c.includes('maudsley15_bipolar'));
    expect(hasMaudsley15).toBe(true);
  });

  test('warns against abrupt cessation in the neverDoThis list', () => {
    const never = getLithiumTapering().neverDoThis;
    const hasAbruptWarning = never.some((s) =>
      s.toLowerCase().includes('abrupt'),
    );
    expect(hasAbruptWarning).toBe(true);
  });
});
