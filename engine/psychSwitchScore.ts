// PsychSwitch Score — a single 0–100 number that summarises everything
// the engine knows about a switch. Inspired by Stripe's Elements
// confidence score, FICO scores, and clinical risk indices like
// CHA₂DS₂-VASc — clinicians scan one number then dive into the
// breakdown if it looks off.
//
// Composition (start at 100, subtract penalties, floor at 0):
//
//   • Evidence (max 30 penalty): A=0, B=10, C=20, D=30
//   • Adverse-effect alignment (max 20 penalty / +5 bonus when avoids):
//       to-drug causes patient's flagged AE → -20
//       to-drug avoids patient's flagged AE → +5 (cap at 100)
//   • Patient-context safety (max 30 penalty): -8 per warning,
//       -25 per danger-level warning
//   • DDI safety (max 35 penalty):
//       caution → -5, warning → -15, avoid → -35
//   • Dose fidelity (max 10 penalty):
//       exact match → 0, mild adaptation → -3, extreme adaptation → -10
//
// Bands:
//   90+ excellent  · 75-89 good  · 50-74 caution  · <50 poor
//
// All inputs are already-computed engine outputs — this module is pure
// composition, no engine reruns. Easy to test, easy to render.

import type { CitationEntry, EvidenceGrade } from './citations';
import type { ScaleResult } from './scaleSchedule';
import type { DdiHit } from './ddi';
import type { ContextWarning, PatientContext } from './patientContext';
import type { AdverseEffect } from './adverseEffects';
import type { Drug, SwitchingRule } from './types';

export type ScoreBand = 'excellent' | 'good' | 'caution' | 'poor';

export interface ScoreComponent {
  /** 0 = no penalty, negative = penalty applied. */
  delta: number;
  /** One-line clinician-facing explanation of the delta. */
  note: string;
}

export interface PsychSwitchScore {
  total: number; // 0–100
  band: ScoreBand;
  /** Short headline like "Excellent fit · grade A · no contraindications". */
  headline: string;
  components: {
    evidence: ScoreComponent;
    aeAlignment: ScoreComponent;
    contextSafety: ScoreComponent;
    ddiSafety: ScoreComponent;
    doseFidelity: ScoreComponent;
  };
}

export interface ScoreInputs {
  rule: SwitchingRule;
  fromDrug: Drug;
  toDrug: Drug;
  context: PatientContext;
  scaleResult: ScaleResult;
  ddiHits: DdiHit[];
  contextWarnings: ContextWarning[];
  evidenceGrade: EvidenceGrade;
  /** When the patient context flags an AE the switch is fleeing. */
  avoidAe?: AdverseEffect | null;
}

const EVIDENCE_PENALTY: Record<EvidenceGrade, number> = {
  A: 0,
  B: 10,
  C: 20,
  D: 30,
};

export function computePsychSwitchScore(input: ScoreInputs): PsychSwitchScore {
  const evidence = scoreEvidence(input.evidenceGrade);
  const aeAlignment = scoreAeAlignment(input.toDrug, input.avoidAe ?? null);
  const contextSafety = scoreContextSafety(input.contextWarnings);
  const ddiSafety = scoreDdiSafety(input.ddiHits);
  const doseFidelity = scoreDoseFidelity(input.scaleResult);

  const total = clamp(
    100 +
      evidence.delta +
      aeAlignment.delta +
      contextSafety.delta +
      ddiSafety.delta +
      doseFidelity.delta,
    0,
    100,
  );
  const band = bandFor(total);

  return {
    total,
    band,
    headline: buildHeadline(band, input),
    components: { evidence, aeAlignment, contextSafety, ddiSafety, doseFidelity },
  };
}

// ── Component scorers ────────────────────────────────────────────────────────

function scoreEvidence(grade: EvidenceGrade): ScoreComponent {
  const penalty = -EVIDENCE_PENALTY[grade];
  if (grade === 'A') return { delta: 0, note: 'Direct guideline source.' };
  return {
    delta: penalty,
    note: `Evidence grade ${grade} — ${penalty < 0 ? `${Math.abs(penalty)} pt deduction` : 'no deduction'}.`,
  };
}

function scoreAeAlignment(
  toDrug: Drug,
  avoidAe: AdverseEffect | null,
): ScoreComponent {
  if (!avoidAe) return { delta: 0, note: 'No AE filter set.' };
  if (avoidAe.switchCandidates.includes(toDrug.id)) {
    return { delta: 5, note: `Target drug avoids ${avoidAe.label.toLowerCase()}.` };
  }
  if (avoidAe.causedBy.includes(toDrug.id)) {
    return { delta: -20, note: `Target drug commonly causes ${avoidAe.label.toLowerCase()}.` };
  }
  return { delta: 0, note: `Target drug not flagged for ${avoidAe.label.toLowerCase()}.` };
}

function scoreContextSafety(warnings: ContextWarning[]): ScoreComponent {
  if (warnings.length === 0) {
    return { delta: 0, note: 'No context-driven warnings.' };
  }
  let delta = 0;
  let dangerCount = 0;
  let warningCount = 0;
  let infoCount = 0;
  for (const w of warnings) {
    if (w.severity === 'danger') {
      delta -= 25;
      dangerCount++;
    } else if (w.severity === 'warning') {
      delta -= 8;
      warningCount++;
    } else {
      delta -= 2;
      infoCount++;
    }
  }
  // Cap at -30 — any single danger flag dominates; multiples don't
  // multiply linearly otherwise the score gets nuked from one missing
  // toggle in the patient context.
  delta = Math.max(delta, -30);
  const parts: string[] = [];
  if (dangerCount) parts.push(`${dangerCount} contraindication${dangerCount > 1 ? 's' : ''}`);
  if (warningCount) parts.push(`${warningCount} warning${warningCount > 1 ? 's' : ''}`);
  if (infoCount) parts.push(`${infoCount} note${infoCount > 1 ? 's' : ''}`);
  return { delta, note: `Patient context: ${parts.join(', ')}.` };
}

function scoreDdiSafety(hits: DdiHit[]): ScoreComponent {
  if (hits.length === 0) {
    return { delta: 0, note: 'No overlap-window interactions.' };
  }
  let worst = 0;
  let countAvoid = 0;
  let countWarning = 0;
  let countCaution = 0;
  for (const h of hits) {
    const r = { info: 0, caution: 1, warning: 2, avoid: 3 }[h.severity];
    if (r > worst) worst = r;
    if (h.severity === 'avoid') countAvoid++;
    else if (h.severity === 'warning') countWarning++;
    else if (h.severity === 'caution') countCaution++;
  }
  let delta = 0;
  if (worst === 3) delta = -35;
  else if (worst === 2) delta = -15;
  else if (worst === 1) delta = -5;
  const summary =
    worst === 3
      ? `${countAvoid} contraindicated interaction${countAvoid > 1 ? 's' : ''}`
      : worst === 2
        ? `${countWarning} interaction warning${countWarning > 1 ? 's' : ''}`
        : `${countCaution} interaction caution${countCaution > 1 ? 's' : ''}`;
  return { delta, note: `Overlap window: ${summary}.` };
}

function scoreDoseFidelity(scale: ScaleResult): ScoreComponent {
  if (!scale.adapted) {
    return { delta: 0, note: 'Doses match the reviewed reference.' };
  }
  const fromF = scale.applied.fromFactor;
  const toF = scale.applied.toFactor;
  const extreme = (f: number) => f < 0.5 || f > 2.0;
  if (extreme(fromF) || extreme(toF)) {
    return { delta: -10, note: `Extreme dose adaptation (${fromF.toFixed(2)}× / ${toF.toFixed(2)}×).` };
  }
  return { delta: -3, note: `Mild dose adaptation (${fromF.toFixed(2)}× / ${toF.toFixed(2)}×).` };
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function clamp(n: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, n));
}

export function bandFor(total: number): ScoreBand {
  if (total >= 90) return 'excellent';
  if (total >= 75) return 'good';
  if (total >= 50) return 'caution';
  return 'poor';
}

export function bandLabel(b: ScoreBand): string {
  switch (b) {
    case 'excellent': return 'Excellent fit';
    case 'good': return 'Good fit';
    case 'caution': return 'Use with caution';
    case 'poor': return 'Poor fit';
  }
}

export function bandColor(b: ScoreBand): { bg: string; border: string; text: string } {
  switch (b) {
    case 'excellent': return { bg: 'bg-to/15',      border: 'border-to/40',      text: 'text-to' };
    case 'good':      return { bg: 'bg-accent/15',  border: 'border-accent/40',  text: 'text-accent' };
    case 'caution':   return { bg: 'bg-warning/15', border: 'border-warning/40', text: 'text-warning' };
    case 'poor':      return { bg: 'bg-danger/15',  border: 'border-danger/40',  text: 'text-danger' };
  }
}

function buildHeadline(band: ScoreBand, input: ScoreInputs): string {
  const parts: string[] = [bandLabel(band)];
  parts.push(`grade ${input.evidenceGrade}`);
  if (input.contextWarnings.some((w) => w.severity === 'danger')) {
    parts.push('contraindication flagged');
  } else if (input.ddiHits.some((h) => h.severity === 'avoid')) {
    parts.push('avoid-grade DDI');
  } else if (input.contextWarnings.length === 0 && input.ddiHits.length === 0) {
    parts.push('no warnings');
  }
  return parts.join(' · ');
}

// ── Citation re-export so card UI can lazy-import without a deeper path. */
export type { CitationEntry };
