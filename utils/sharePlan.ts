// Format a switch plan as a plain-text message suitable for the native
// share sheet (WhatsApp, SMS, email). Pure function — no React Native
// imports — so it's trivially unit-testable.
//
// v0.2: richer output — includes rationale summary, full step notes,
// monitoring checklist, dose equivalency, and citations.
//
// PNG export of the Gantt chart is deferred until we move off Expo Go
// onto a custom dev client (react-native-view-shot not bundled in Expo Go).

import { SPEED_BASIS, SPEED_LABEL, type TaperSpeed } from '../engine/taperSpeed';
import type {
  Drug,
  ScheduleStep,
  SwitchPlan,
  SwitchingRule,
} from '../engine/types';
import { getFlagDisplay } from './safetyFlags';

interface PlanOk {
  rule: SwitchingRule;
  schedule: ScheduleStep[];
  safetyFlags: string[];
  citations: string[];
  dosesMatchReference: boolean;
  inputDoses: { fromMg: number; toMg: number };
}

type WashoutPlan = Extract<SwitchPlan, { status: 'maoi_washout' }>;

const STRATEGY_DISPLAY: Record<string, string> = {
  direct: 'Direct switch',
  'cross-taper': 'Cross-taper',
  'plateau-cross-taper': 'Plateau cross-taper',
  washout: 'Washout',
};

/** Trim the internal audit suffix before including rationale in shares. */
function cleanRationale(text: string): string {
  return text.replace(/\s*PENDING_CLINICAL_REVIEW\.?\s*$/i, '').trim();
}

/** Trim the internal audit suffix from equivalency notes. */
function cleanNote(text: string): string {
  return text.replace(/\s*PENDING_CLINICAL_REVIEW\.?\s*$/i, '').trim();
}

/**
 * Format a reviewed cross-taper plan for sharing via the native share sheet.
 * Includes: header, dose equivalency, speed note, rationale summary,
 * day-by-day schedule with step notes, monitoring checklist, citations.
 */
export function formatPlanForShare(
  fromDrug: Drug,
  toDrug: Drug,
  plan: PlanOk,
  taperSpeed: TaperSpeed = 'standard',
  adjustedDuration?: number,
): string {
  const totalDays = adjustedDuration ?? plan.rule.durationDays;
  const strategyLabel = STRATEGY_DISPLAY[plan.rule.strategy] ?? plan.rule.strategy;
  const lines: string[] = [];

  // ── Header ────────────────────────────────────────────────────────────
  lines.push('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  lines.push('PsychSwitch — Cross-taper plan');
  lines.push('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  lines.push(`${fromDrug.genericName} → ${toDrug.genericName}`);
  lines.push(
    `${strategyLabel} · ${totalDays} days` +
      (taperSpeed !== 'standard' ? ` · ${SPEED_LABEL[taperSpeed]} speed` : ''),
  );
  lines.push('');

  // ── Dose equivalency ──────────────────────────────────────────────────
  lines.push('DOSE MAPPING');
  lines.push(
    `${fromDrug.genericName} ${plan.rule.doseRatios.fromCurrentDoseMg} mg ≈ ${toDrug.genericName} ${plan.rule.doseRatios.toTargetDoseMg} mg`,
  );
  const equivNote = cleanNote(plan.rule.doseRatios.equivalencyNote);
  if (equivNote) lines.push(`  ${equivNote}`);
  if (!plan.dosesMatchReference) {
    lines.push(
      `  Note: You entered ${plan.inputDoses.fromMg} mg → ${plan.inputDoses.toMg} mg. ` +
        `Schedule below is the reviewed reference — adapt doses proportionally.`,
    );
  }
  lines.push('');

  // ── Speed note ────────────────────────────────────────────────────────
  if (taperSpeed !== 'standard') {
    lines.push(`⚠ ${SPEED_LABEL[taperSpeed].toUpperCase()} TAPER — outside reviewed schedule`);
    lines.push(SPEED_BASIS[taperSpeed]);
    lines.push('');
  }

  // ── Rationale summary ─────────────────────────────────────────────────
  const rationale = cleanRationale(plan.rule.rationale);
  if (rationale) {
    lines.push('WHY THIS STRATEGY');
    // Wrap at ~80 chars for WhatsApp/SMS legibility
    lines.push(rationale.length > 300 ? rationale.slice(0, 300) + '…' : rationale);
    lines.push('');
  }

  // ── Day-by-day schedule ───────────────────────────────────────────────
  const fromUnit = fromDrug.formulation === 'lai' ? 'mg/inj' : 'mg';
  const toUnit = toDrug.formulation === 'lai' ? 'mg/inj' : 'mg';

  lines.push('SCHEDULE');
  for (const step of plan.schedule) {
    const fromLabel = step.fromDoseMg === 0 ? 'STOP' : `${step.fromDoseMg} ${fromUnit}`;
    const toLabel = step.toDoseMg === 0 ? '—' : `${step.toDoseMg} ${toUnit}`;
    lines.push(
      `Day ${String(step.day).padEnd(3)}  ${fromDrug.genericName} ${fromLabel}  |  ${toDrug.genericName} ${toLabel}`,
    );
    if (step.notes) {
      lines.push(`         → ${step.notes}`);
    }
  }
  lines.push('');

  // ── Monitoring checklist ──────────────────────────────────────────────
  if (plan.safetyFlags.length > 0) {
    lines.push('MONITORING CHECKLIST');
    for (const key of plan.safetyFlags) {
      const d = getFlagDisplay(key);
      const prefix = d.severity === 'danger' ? '🔴' : d.severity === 'warning' ? '🟡' : '🔵';
      lines.push(`${prefix} ${d.title}`);
      // Include one-line body for critical danger flags
      if (d.severity === 'danger') {
        const body =
          d.body.length > 120 ? d.body.slice(0, 120) + '…' : d.body;
        lines.push(`   ${body}`);
      }
    }
    lines.push('');
  }

  // ── Citations ─────────────────────────────────────────────────────────
  lines.push('REFERENCES');
  plan.citations.forEach((c, i) => lines.push(`[${i + 1}] ${c}`));
  lines.push(`Reviewed by: ${plan.rule.reviewedBy}`);
  lines.push(`Last reviewed: ${plan.rule.lastReviewedISO}`);
  lines.push('');

  // ── Footer ────────────────────────────────────────────────────────────
  lines.push('─────────────────────────────────');
  lines.push('Decision support only — not medical advice.');
  lines.push('Verify against primary references (Maudsley, BAP, NICE) and');
  lines.push('the patient\'s individual context before prescribing.');
  lines.push('Generated by PsychSwitch v0.1');

  return lines.join('\n');
}

/**
 * Format an MAOI washout plan for sharing. Kept entirely separate from
 * the cross-taper formatter — the clinical framing must make the
 * serotonin-syndrome risk unmistakable.
 */
export function formatWashoutForShare(
  fromDrug: Drug,
  toDrug: Drug,
  fromDoseMg: number,
  plan: WashoutPlan,
): string {
  const lines: string[] = [];

  lines.push('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  lines.push('PsychSwitch — ⚠ MAOI WASHOUT REQUIRED');
  lines.push('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  lines.push(`${fromDrug.genericName} ${fromDoseMg} mg → ${toDrug.genericName}`);
  lines.push(
    `Washout: ${plan.washoutDays} day${plan.washoutDays === 1 ? '' : 's'} ` +
      `(${plan.direction === 'to_maoi' ? 'before starting MAOI' : 'after stopping MAOI'})`,
  );
  lines.push('');

  lines.push('🔴 FATAL INTERACTION RISK — NO OVERLAP PERMITTED');
  lines.push(
    plan.direction === 'to_maoi'
      ? `Combining ${fromDrug.genericName} or its active metabolites with an MAOI can cause fatal serotonin syndrome.`
      : `Starting ${toDrug.genericName} before MAO-A activity recovers risks fatal serotonin syndrome.`,
  );
  lines.push('');

  lines.push('STEPS');
  lines.push(`1. Day 0:  Stop ${fromDrug.genericName} ${fromDoseMg} mg`);
  lines.push(`2. Days 1–${plan.washoutDays}: No antidepressant — complete washout`);
  lines.push(
    `3. Day ${plan.washoutDays + 1}+: Start ${toDrug.genericName} at ${toDrug.dosing.startingDoseMg} mg. Titrate per standard regimen.`,
  );
  lines.push('');

  lines.push('AVOID DURING WASHOUT');
  if (plan.direction === 'to_maoi') {
    lines.push(
      'All serotonergic agents: SSRIs, SNRIs, tramadol, triptans, linezolid, methylene blue, dextromethorphan, St John\'s wort.',
    );
  } else {
    lines.push(
      'Sympathomimetics and tyramine-rich foods until washout is complete (aged cheese, cured meats, fermented foods, beer/wine).',
    );
  }
  lines.push('');

  if (plan.safetyFlags.length > 0) {
    lines.push('SAFETY FLAGS');
    for (const key of plan.safetyFlags) {
      lines.push(`🔴 ${getFlagDisplay(key).title}`);
    }
    lines.push('');
  }

  lines.push('REASON');
  lines.push(plan.reason);
  lines.push('');

  lines.push('─────────────────────────────────');
  lines.push('Decision support only — not medical advice.');
  lines.push('Generated by PsychSwitch v0.1');

  return lines.join('\n');
}
