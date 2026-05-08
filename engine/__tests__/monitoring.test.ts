import { generateMonitoringPlan } from '../monitoring';

describe('monitoring schedule generator', () => {
  test('lithium baseline includes U&E + TFT + Ca + ECG', () => {
    const plan = generateMonitoringPlan({ toDrugId: 'lithium' });
    const labels = plan.entries.map((e) => e.label);
    expect(labels).toEqual(expect.arrayContaining(['U&E + eGFR', 'TFT', 'Calcium', 'ECG']));
  });

  test('lithium recurring level expands at 90-day interval', () => {
    const plan = generateMonitoringPlan({ toDrugId: 'lithium', durationDays: 365 });
    const days = plan.entries
      .filter((e) => e.label === 'Lithium level')
      .map((e) => e.dayOffset);
    // Should include the initial 7-day, then 90/180/270/360
    expect(days).toEqual(expect.arrayContaining([7, 90, 180, 270]));
  });

  test('clozapine generates weekly FBC for 18 weeks', () => {
    const plan = generateMonitoringPlan({ toDrugId: 'clozapine', durationDays: 365 });
    const weeklyFbc = plan.entries.filter((e) => e.label === 'Weekly FBC');
    // 18 weeks × weekly = 18 entries
    expect(weeklyFbc.length).toBe(18);
  });

  test('antidepressant fallback includes mood/suicidality review at D14', () => {
    const plan = generateMonitoringPlan({ toDrugId: 'sertraline' });
    const review = plan.entries.find(
      (e) => e.label === 'Mood + suicidality' && e.dayOffset === 14,
    );
    expect(review).toBeDefined();
  });

  test('cardiac comorbidity adds baseline ECG even without QT-prolonger', () => {
    const plan = generateMonitoringPlan({
      toDrugId: 'mirtazapine',
      context: { ageYears: 50, sex: 'male', comorbidities: { cardiac: true } },
    });
    expect(plan.entries.some((e) => e.label === 'ECG (cardiac hx)')).toBe(true);
  });

  test('plan has citations and a non-zero span', () => {
    const plan = generateMonitoringPlan({ toDrugId: 'lithium' });
    expect(plan.citations.length).toBeGreaterThan(0);
    expect(plan.spanDays).toBeGreaterThan(0);
  });

  test('entries are sorted by dayOffset', () => {
    const plan = generateMonitoringPlan({ toDrugId: 'olanzapine' });
    for (let i = 1; i < plan.entries.length; i++) {
      expect(plan.entries[i].dayOffset).toBeGreaterThanOrEqual(plan.entries[i - 1].dayOffset);
    }
  });
});
