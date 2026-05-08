import {
  formatCounsellingCard,
  formatDischargeSummary,
  formatPdfHtml,
} from '../formatDischarge';
import { generateSwitchPlan, getDrug } from '../../engine/switchingEngine';
import { generateMonitoringPlan } from '../../engine/monitoring';
import { scaleSchedule } from '../../engine/scaleSchedule';

function buildInputs(opts: {
  fromId: string;
  toId: string;
  fromDose: number;
  toDose: number;
  caseLabel?: string;
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
  const schedule = scaleResult.adapted ? scaleResult.schedule : plan.schedule;
  const monitoring = generateMonitoringPlan({
    fromDrugId: opts.fromId,
    toDrugId: opts.toId,
    durationDays: plan.rule.durationDays,
  });
  return {
    rule: plan.rule,
    fromDrug,
    toDrug,
    schedule,
    monitoring,
    scaleResult,
    durationDays: plan.rule.durationDays,
    caseLabel: opts.caseLabel,
  };
}

describe('formatDischargeSummary', () => {
  test('produces a multi-line plain-text block', () => {
    const inputs = buildInputs({
      fromId: 'olanzapine',
      toId: 'aripiprazole',
      fromDose: 20,
      toDose: 15,
    });
    const out = formatDischargeSummary(inputs);
    expect(out).toContain('PLAN:');
    expect(out).toContain('SCHEDULE:');
    expect(out).toContain('EVIDENCE:');
    expect(out).toContain('REVIEWED:');
    expect(out).toContain('PsychSwitch');
    expect(out.split('\n').length).toBeGreaterThan(8);
  });

  test('includes case label when provided', () => {
    const inputs = buildInputs({
      fromId: 'olanzapine',
      toId: 'aripiprazole',
      fromDose: 20,
      toDose: 15,
      caseLabel: 'Mr A — 12/07',
    });
    const out = formatDischargeSummary(inputs);
    expect(out).toContain('CASE: Mr A — 12/07');
  });

  test('flags adapted schedules', () => {
    const inputs = buildInputs({
      fromId: 'olanzapine',
      toId: 'aripiprazole',
      fromDose: 30,    // != reviewed reference
      toDose: 20,
    });
    if (!inputs.scaleResult.adapted) return; // skip if engine didn't adapt
    const out = formatDischargeSummary(inputs);
    expect(out).toMatch(/adapted/i);
    expect(out).toMatch(/scaled/i);
  });
});

describe('formatCounsellingCard', () => {
  test('uses plain language and groups by week', () => {
    const inputs = buildInputs({
      fromId: 'olanzapine',
      toId: 'aripiprazole',
      fromDose: 20,
      toDose: 15,
    });
    const out = formatCounsellingCard(inputs);
    expect(out).toContain('Your medication change');
    expect(out).toMatch(/Week \d+/);
    expect(out).toContain('When to call your clinic:');
    expect(out).toMatch(/PsychSwitch/);
  });

  test('does not contain clinical jargon like "EMR" or "PLAN:"', () => {
    const inputs = buildInputs({
      fromId: 'olanzapine',
      toId: 'aripiprazole',
      fromDose: 20,
      toDose: 15,
    });
    const out = formatCounsellingCard(inputs);
    expect(out).not.toContain('PLAN:');
    expect(out).not.toContain('EMR');
    expect(out).not.toMatch(/SCHEDULE:/);
  });
});

describe('formatPdfHtml', () => {
  test('returns a valid HTML document', () => {
    const inputs = buildInputs({
      fromId: 'olanzapine',
      toId: 'aripiprazole',
      fromDose: 20,
      toDose: 15,
    });
    const html = formatPdfHtml(inputs);
    expect(html).toMatch(/^<!doctype html>/i);
    expect(html).toContain('<html>');
    expect(html).toContain('</html>');
    expect(html).toContain('Olanzapine');
    expect(html).toContain('Aripiprazole');
  });

  test('escapes HTML-significant characters in drug names', () => {
    const inputs = buildInputs({
      fromId: 'olanzapine',
      toId: 'aripiprazole',
      fromDose: 20,
      toDose: 15,
    });
    // Inject a drug name with characters that need escaping (mocked).
    const evilInputs = {
      ...inputs,
      fromDrug: { ...inputs.fromDrug, genericName: 'Evil <script>alert(1)</script>' },
    };
    const html = formatPdfHtml(evilInputs);
    expect(html).not.toContain('<script>alert');
    expect(html).toContain('&lt;script&gt;');
  });
});
