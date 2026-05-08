import { generateSwitchPlan, getDrug } from '../../engine/switchingEngine';
import { formatPlanForShare } from '../sharePlan';

describe('formatPlanForShare', () => {
  test('contains drug names, dose mapping, every schedule step, monitoring flags, citations, and disclaimer', () => {
    const fromDrug = getDrug('sertraline')!;
    const toDrug = getDrug('escitalopram')!;
    const plan = generateSwitchPlan({
      fromDrugId: 'sertraline',
      fromDoseMg: 100,
      toDrugId: 'escitalopram',
      toDoseMg: 10,
    });
    if (plan.status !== 'ok') throw new Error('expected ok plan');

    const out = formatPlanForShare(fromDrug, toDrug, plan);

    // Drug names present in header
    expect(out).toContain('Sertraline');
    expect(out).toContain('Escitalopram');

    // Dose mapping section present
    expect(out).toContain('DOSE MAPPING');

    // Every day in the schedule shows up
    for (const step of plan.schedule) {
      expect(out).toContain(`Day ${step.day}`);
    }

    // Schedule section header present
    expect(out).toContain('SCHEDULE');

    // Citations present (as numbered list in new format)
    for (const citation of plan.citations) {
      expect(out).toContain(citation);
    }

    // Disclaimer must always be present (clinical-safety rule)
    expect(out).toContain('Decision support only');
    expect(out).toContain('not medical advice');
  });
});
