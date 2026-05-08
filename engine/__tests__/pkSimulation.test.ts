import { getDrug } from '../switchingEngine';
import {
  effectiveHalfLifeHours,
  simulateDailyLevels,
  simulateSwitch,
} from '../pkSimulation';

describe('effectiveHalfLifeHours', () => {
  test('uses parent half-life when no clinically significant metabolite', () => {
    const sertraline = getDrug('sertraline')!;
    // Sertraline's metabolite is not clinically significant, so parent only.
    expect(effectiveHalfLifeHours(sertraline)).toBe(
      sertraline.halfLife.meanHours,
    );
  });

  test('extends half-life when active metabolite is clinically significant (fluoxetine)', () => {
    const fluoxetine = getDrug('fluoxetine')!;
    // Fluoxetine has norfluoxetine, clinically significant. Effective
    // half-life should be substantially longer than parent's 72h.
    const eff = effectiveHalfLifeHours(fluoxetine);
    expect(eff).toBeGreaterThan(fluoxetine.halfLife.meanHours);
    // norfluoxetine ~240h × 0.7 = 168h, larger than parent's 72h.
    expect(eff).toBe(168);
  });
});

describe('simulateDailyLevels', () => {
  test('starts at day-1 prescribed dose (assumes steady state at start)', () => {
    const points = [
      { day: 1, doseMg: 100 },
      { day: 4, doseMg: 50 },
    ];
    const sim = simulateDailyLevels(points, 26, 14);
    expect(sim[0]).toEqual({
      day: 1,
      prescribedDoseMg: 100,
      effectiveLevelMg: 100,
    });
  });

  test('effective level decays exponentially toward 0 after drug stopped', () => {
    // If prescribed drops to 0, the effective should follow the half-life curve.
    const points = [
      { day: 1, doseMg: 100 },
      { day: 2, doseMg: 0 },
    ];
    const sim = simulateDailyLevels(points, 24, 10); // exactly 1-day half-life
    // After 1 day at 0 (day 2): effective ≈ 100 * 0.5 + 0 * 0.5 = 50
    expect(sim[1].effectiveLevelMg).toBeCloseTo(50, 1);
    // Day 3: 50 * 0.5 = 25
    expect(sim[2].effectiveLevelMg).toBeCloseTo(25, 1);
    // Day 5: ~6.25
    expect(sim[4].effectiveLevelMg).toBeLessThan(10);
  });

  test('long-half-life drug shows long washout tail (fluoxetine)', () => {
    const fluoxetine = getDrug('fluoxetine')!;
    const points = [
      { day: 1, doseMg: 20 },
      { day: 4, doseMg: 0 }, // stop fluoxetine
    ];
    const sim = simulateDailyLevels(
      points,
      effectiveHalfLifeHours(fluoxetine),
      30,
    );
    // 14 days after stopping (day 18), level should still be measurably above 0
    // because effective half-life is 168h = 7 days.
    const day18 = sim.find((p) => p.day === 18)!;
    expect(day18.effectiveLevelMg).toBeGreaterThan(2); // still ~25% of original 20mg
  });
});

describe('simulateSwitch', () => {
  test('returns matched-length from and to series with trailing days', () => {
    const fromDrug = getDrug('sertraline')!;
    const toDrug = getDrug('escitalopram')!;
    const schedule = [
      { day: 1, fromDoseMg: 100, toDoseMg: 5 },
      { day: 11, fromDoseMg: 0, toDoseMg: 10 },
    ];
    const sim = simulateSwitch(schedule, fromDrug, toDrug);
    // Default trailing 14 days => 11 + 14 = 25
    expect(sim.totalDays).toBe(25);
    expect(sim.from.length).toBe(25);
    expect(sim.to.length).toBe(25);
    // From-drug effective decays after day 11
    expect(sim.from[24].effectiveLevelMg).toBeLessThan(sim.from[0].effectiveLevelMg);
    // To-drug effective rises toward target
    expect(sim.to[24].effectiveLevelMg).toBeGreaterThan(sim.to[0].effectiveLevelMg);
  });
});
