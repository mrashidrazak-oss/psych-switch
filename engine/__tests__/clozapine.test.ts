// Clozapine module tests.
//
// Per CLAUDE.md: clinical calculations get unit tests with edge cases.
// Clozapine is the highest-stakes molecule in the app — these tests
// pin down the protocol shape and the FBC traffic-light boundaries.

import {
  classifyFbc,
  getMonitoringSchedule,
  getSafetyConsiderations,
  getTitration,
} from '../clozapine';

describe('clozapine titration protocols (Maudsley 15)', () => {
  const ALL_VARIANTS = [
    { sex: 'female', smoker: false } as const,
    { sex: 'female', smoker: true } as const,
    { sex: 'male', smoker: false } as const,
    { sex: 'male', smoker: true } as const,
  ];

  test('all 4 variants start at 6.25 mg evening on day 1', () => {
    for (const variant of ALL_VARIANTS) {
      const p = getTitration(variant);
      expect(p.steps[0].day).toBe(1);
      expect(p.steps[0].morningMg).toBe(0);
      expect(p.steps[0].eveningMg).toBe(6.25);
      expect(p.steps[0].totalMg).toBe(6.25);
    }
  });

  test('targets reflect sex × smoker pharmacokinetics', () => {
    expect(getTitration({ sex: 'female', smoker: false }).targetDoseMg).toBe(225);
    expect(getTitration({ sex: 'female', smoker: true }).targetDoseMg).toBe(300);
    expect(getTitration({ sex: 'male', smoker: false }).targetDoseMg).toBe(250);
    expect(getTitration({ sex: 'male', smoker: true }).targetDoseMg).toBe(375);
  });

  test('smokers reach a higher target than non-smokers (CYP1A2 induction)', () => {
    expect(getTitration({ sex: 'female', smoker: true }).targetDoseMg).toBeGreaterThan(
      getTitration({ sex: 'female', smoker: false }).targetDoseMg,
    );
    expect(getTitration({ sex: 'male', smoker: true }).targetDoseMg).toBeGreaterThan(
      getTitration({ sex: 'male', smoker: false }).targetDoseMg,
    );
  });

  test('males reach a higher target than females within smoking-status (CYP1A2 sex difference)', () => {
    expect(getTitration({ sex: 'male', smoker: false }).targetDoseMg).toBeGreaterThan(
      getTitration({ sex: 'female', smoker: false }).targetDoseMg,
    );
    expect(getTitration({ sex: 'male', smoker: true }).targetDoseMg).toBeGreaterThan(
      getTitration({ sex: 'female', smoker: true }).targetDoseMg,
    );
  });

  test('every titration step has totalMg = morning + evening (data integrity)', () => {
    for (const variant of ALL_VARIANTS) {
      const p = getTitration(variant);
      for (const step of p.steps) {
        expect(step.totalMg).toBe(step.morningMg + step.eveningMg);
      }
    }
  });

  test('all 4 variants are 20-day protocols and end at the target dose', () => {
    for (const variant of ALL_VARIANTS) {
      const p = getTitration(variant);
      expect(p.totalDays).toBe(20);
      expect(p.steps.length).toBe(20);
      const lastStep = p.steps[p.steps.length - 1];
      expect(lastStep.totalMg).toBe(p.targetDoseMg);
    }
  });

  test('all 4 variants document the >48h missed-dose retitration rule', () => {
    for (const variant of ALL_VARIANTS) {
      const p = getTitration(variant);
      expect(p.missedDoseRule).toMatch(/48/);
    }
  });

  test('citations reference Maudsley 15 schizophrenia chapter', () => {
    for (const variant of ALL_VARIANTS) {
      const p = getTitration(variant);
      const hasMaudsley15 = p.citations.some((c) => c.includes('maudsley15'));
      expect(hasMaudsley15).toBe(true);
    }
  });
});

describe('clozapine monitoring schedule', () => {
  test('first phase is weekly FBC for 18 weeks', () => {
    const m = getMonitoringSchedule();
    const weekly = m.phases.find((p) => p.phase === 'weekly');
    expect(weekly).toBeDefined();
    expect(weekly!.weekStart).toBe(1);
    expect(weekly!.weekEnd).toBe(18);
    expect(weekly!.test).toMatch(/FBC/);
  });

  test('monthly phase is indefinite (weekEnd = null)', () => {
    const m = getMonitoringSchedule();
    const monthly = m.phases.find((p) => p.phase === 'monthly');
    expect(monthly).toBeDefined();
    expect(monthly!.weekEnd).toBeNull();
  });

  test('baseline milestone includes ECG and troponin (cardiac safety)', () => {
    const m = getMonitoringSchedule();
    const baseline = m.milestones.find((x) => x.id === 'baseline');
    expect(baseline).toBeDefined();
    expect(baseline!.tests).toContain('ECG');
    expect(baseline!.tests).toContain('troponin');
    expect(baseline!.tests).toContain('FBC');
  });
});

describe('classifyFbc — CPMS traffic-light thresholds', () => {
  test('green when ANC and WBC both above green threshold', () => {
    const r = classifyFbc({ ancE9PerL: 3.0, wbcE9PerL: 5.0 });
    expect(r.zone).toBe('green');
  });

  test('amber when ANC below green but above red (eg 1.7)', () => {
    const r = classifyFbc({ ancE9PerL: 1.7, wbcE9PerL: 5.0 });
    expect(r.zone).toBe('amber');
  });

  test('red when ANC below red threshold (eg 1.2)', () => {
    const r = classifyFbc({ ancE9PerL: 1.2, wbcE9PerL: 5.0 });
    expect(r.zone).toBe('red');
  });

  test('red when WBC below red threshold even if ANC ok', () => {
    const r = classifyFbc({ ancE9PerL: 3.0, wbcE9PerL: 2.5 });
    expect(r.zone).toBe('red');
  });

  test('BEN-adjusted green: ANC 1.6 is GREEN with applyBen=true (above BEN green threshold 1.5)', () => {
    const r = classifyFbc({
      ancE9PerL: 1.6,
      wbcE9PerL: 3.2,
      applyBen: true,
    });
    expect(r.zone).toBe('green');
  });

  test('BEN-adjusted amber: ANC 1.2 is AMBER with applyBen=true (between BEN amber 1.0–1.5)', () => {
    const r = classifyFbc({
      ancE9PerL: 1.2,
      wbcE9PerL: 3.2,
      applyBen: true,
    });
    expect(r.zone).toBe('amber');
  });

  test('BEN-adjusted red: ANC 0.9 is RED with applyBen=true (below BEN red threshold 1.0)', () => {
    const r = classifyFbc({
      ancE9PerL: 0.9,
      wbcE9PerL: 3.2,
      applyBen: true,
    });
    expect(r.zone).toBe('red');
  });

  test('non-BEN ANC 1.2 is RED (below standard red threshold 1.5)', () => {
    // Non-BEN patient with ANC 1.2 is below the standard 1.5 red line — stop.
    const r = classifyFbc({ ancE9PerL: 1.2, wbcE9PerL: 5.0 });
    expect(r.zone).toBe('red');
  });
});

describe('clozapine safety considerations', () => {
  test('includes the four highest-stakes considerations', () => {
    const ids = getSafetyConsiderations().considerations.map((c) => c.id);
    expect(ids).toContain('agranulocytosis');
    expect(ids).toContain('myocarditis');
    expect(ids).toContain('constipation-ileus');
    expect(ids).toContain('interruption-rule');
  });

  test('agranulocytosis and myocarditis are danger severity (not warning)', () => {
    const list = getSafetyConsiderations().considerations;
    const agra = list.find((c) => c.id === 'agranulocytosis')!;
    const myo = list.find((c) => c.id === 'myocarditis')!;
    expect(agra.severity).toBe('danger');
    expect(myo.severity).toBe('danger');
  });
});
