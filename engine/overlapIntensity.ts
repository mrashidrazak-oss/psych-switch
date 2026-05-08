// Overlap-intensity assessment + Conservative-mode schedule transform.
//
// "Cross-taper" in Maudsley 15th ed. ch.3 explicitly allows co-pres-
// cribing two drugs while reducing one and increasing the other.
// The clinical question is HOW MUCH overlap, for HOW LONG, and
// between which receptor profiles. This module quantifies that and
// gives the clinician a single tier (low / moderate / high / severe)
// with a tappable breakdown.
//
// The Conservative-mode transform is a UX escape hatch: if the
// clinician thinks the standard schedule's Day-1 overlap looks
// aggressive for their patient, one toggle reduces the from-drug's
// Day-1 dose by 25% (rounded to formulation, clamped so the taper
// stays monotonic).
//
// Everything here is pure — no React, no I/O.

import { roundToIncrement } from './scaleSchedule';
import type { Drug, ScheduleStep } from './types';

export type OverlapTier = 'low' | 'moderate' | 'high' | 'severe';

export interface OverlapAssessment {
  tier: OverlapTier;
  /** 0–100 numeric score (clamped). */
  score: number;
  /** One-line user-facing label. */
  label: string;
  /** Plain-English explanation of how the tier was derived. */
  rationale: string;
  /** Mechanism-flag tags applied (serotonergic, qt_additive, etc.). */
  flags: string[];
  /** Component breakdown for the modal. */
  components: {
    overlapDays: number;
    /** Fraction of from-drug typical-target on Day 1. */
    day1FromFraction: number;
    /** Fraction of to-drug typical-target on Day 1. */
    day1ToFraction: number;
    /** Multiplier applied for receptor-mechanism stacking. */
    mechanismMultiplier: number;
  };
}

// ── Mechanism detection ────────────────────────────────────────────

const SEROTONERGIC_PATTERNS = ['SSRI', 'SNRI', 'NaSSA', 'SMS', 'serotonin', 'modulator'];

function isSerotonergic(drug: Drug): boolean {
  const cls = drug.drugClass.toLowerCase();
  if (SEROTONERGIC_PATTERNS.some((p) => cls.includes(p.toLowerCase()))) return true;
  // MAOIs are blocked upstream by the engine (washout strategy), but
  // count them here for completeness.
  return drug.isMAOI === true;
}

function isFGA(drug: Drug): boolean {
  return drug.drugClass.toLowerCase().includes('fga') || drug.drugClass.toLowerCase().includes('typical');
}

function risk(level: string | undefined): number {
  switch (level) {
    case 'very high': return 4;
    case 'high':      return 3;
    case 'moderate':  return 2;
    case 'low':       return 1;
    default:          return 0;
  }
}

// ── Core assessment ───────────────────────────────────────────────

export function assessOverlapIntensity(opts: {
  fromDrug: Drug;
  toDrug: Drug;
  schedule: ScheduleStep[];
}): OverlapAssessment {
  const { fromDrug, toDrug, schedule } = opts;

  if (schedule.length === 0) {
    return EMPTY_ASSESSMENT;
  }

  // Use the typical target range top as the "100%" reference. Falls
  // back to maxDoseMg so we always have a denominator.
  const fromRef = fromDrug.dosing.typicalTargetRangeMg?.[1] ?? fromDrug.dosing.maxDoseMg ?? 0;
  const toRef = toDrug.dosing.typicalTargetRangeMg?.[1] ?? toDrug.dosing.maxDoseMg ?? 0;

  // Overlap window — first day where BOTH > 0, last day where both > 0.
  const overlapSteps = schedule.filter((s) => s.fromDoseMg > 0 && s.toDoseMg > 0);
  if (overlapSteps.length === 0) {
    return {
      ...EMPTY_ASSESSMENT,
      label: 'No overlap',
      rationale: 'The schedule never has both drugs at non-zero dose simultaneously.',
    };
  }

  const overlapDays =
    overlapSteps[overlapSteps.length - 1].day - overlapSteps[0].day + 1;

  const day1 = overlapSteps[0];
  const day1FromFraction = fromRef > 0 ? day1.fromDoseMg / fromRef : 0;
  const day1ToFraction = toRef > 0 ? day1.toDoseMg / toRef : 0;

  // ── Mechanism multiplier ──
  // Stack the most concerning combinations. Each adds to the multiplier
  // independently, capped so a single rule can't go above 2.0×.
  let multiplier = 1.0;
  const flags: string[] = [];

  if (isSerotonergic(fromDrug) && isSerotonergic(toDrug)) {
    multiplier += 0.5;
    flags.push('serotonergic_stacking');
  }

  // QT additive — if both qtcRisk >= moderate
  if (risk(fromDrug.qtcRisk) >= 2 && risk(toDrug.qtcRisk) >= 2) {
    multiplier += 0.3;
    flags.push('qt_additive');
  }

  // Sedation additive — both sedation >= moderate
  if (risk(fromDrug.sedation) >= 2 && risk(toDrug.sedation) >= 2) {
    multiplier += 0.2;
    flags.push('sedation_additive');
  }

  // EPS additive — two FGAs, or one FGA + high-EPS SGA (risperidone, paliperidone, haloperidol)
  if (isFGA(fromDrug) && isFGA(toDrug)) {
    multiplier += 0.3;
    flags.push('eps_additive');
  } else if (
    (isFGA(fromDrug) && risk(toDrug.epsRisk) >= 3) ||
    (isFGA(toDrug) && risk(fromDrug.epsRisk) >= 3)
  ) {
    multiplier += 0.2;
    flags.push('eps_additive');
  }

  // Anticholinergic burden — proxy via drug class (chlorpromazine,
  // older TCAs are the prototypical examples; we don't have many in
  // our content, so this is mostly defensive)
  const hasAnticholinergic = (d: Drug) =>
    d.id === 'chlorpromazine' ||
    d.id === 'paroxetine' ||
    d.drugClass.toLowerCase().includes('tricyclic');
  if (hasAnticholinergic(fromDrug) && hasAnticholinergic(toDrug)) {
    multiplier += 0.2;
    flags.push('anticholinergic_burden');
  }

  // Cap the multiplier — even the most concerning stacking can't
  // pretend a 1-day overlap of low-dose pair is severe.
  multiplier = Math.min(multiplier, 2.2);

  // ── Score ──
  // Two factors:
  //   • Day 1 simultaneous-presence intensity  (max 50 pts)
  //   • Duration weight up to 14 days          (max 25 pts)
  // Multiplier scales the total. Then clamp to [0, 100].
  const day1Score = (day1FromFraction + day1ToFraction) * 25; // up to ~50
  const durationScore = Math.min(overlapDays / 14, 1.5) * 16;  // up to 24
  const baseScore = day1Score + durationScore;
  const score = Math.min(100, Math.max(0, baseScore * multiplier));

  // ── Tier ──
  const tier: OverlapTier =
    score < 25 ? 'low'
    : score < 50 ? 'moderate'
    : score < 75 ? 'high'
    : 'severe';

  // ── Rationale ──
  const rationale = buildRationale({
    overlapDays,
    day1FromFraction,
    day1ToFraction,
    multiplier,
    flags,
    fromName: fromDrug.genericName,
    toName: toDrug.genericName,
  });

  return {
    tier,
    score: Math.round(score),
    label: tierLabel(tier),
    rationale,
    flags,
    components: {
      overlapDays,
      day1FromFraction,
      day1ToFraction,
      mechanismMultiplier: multiplier,
    },
  };
}

const EMPTY_ASSESSMENT: OverlapAssessment = {
  tier: 'low',
  score: 0,
  label: 'No overlap',
  rationale: 'The schedule has no co-prescribed days.',
  flags: [],
  components: {
    overlapDays: 0,
    day1FromFraction: 0,
    day1ToFraction: 0,
    mechanismMultiplier: 1,
  },
};

export function tierLabel(t: OverlapTier): string {
  switch (t) {
    case 'low': return 'Low overlap';
    case 'moderate': return 'Moderate overlap';
    case 'high': return 'High overlap';
    case 'severe': return 'Severe overlap';
  }
}

export function tierTint(t: OverlapTier): { bg: string; border: string; text: string } {
  switch (t) {
    case 'low':      return { bg: 'bg-to/15',      border: 'border-to/40',      text: 'text-to' };
    case 'moderate': return { bg: 'bg-accent/15',  border: 'border-accent/40',  text: 'text-accent' };
    case 'high':     return { bg: 'bg-warning/15', border: 'border-warning/40', text: 'text-warning' };
    case 'severe':   return { bg: 'bg-danger/15',  border: 'border-danger/40',  text: 'text-danger' };
  }
}

export function tierTintHex(t: OverlapTier): string {
  switch (t) {
    case 'low':      return '#34d399';
    case 'moderate': return '#3b82f6';
    case 'high':     return '#f59e0b';
    case 'severe':   return '#ef4444';
  }
}

export function flagLabel(flag: string): string {
  switch (flag) {
    case 'serotonergic_stacking':  return 'Serotonergic stacking';
    case 'qt_additive':            return 'QTc additive';
    case 'sedation_additive':      return 'Sedation additive';
    case 'eps_additive':           return 'EPS additive';
    case 'anticholinergic_burden': return 'Anticholinergic burden';
    default: return flag;
  }
}

function buildRationale(opts: {
  overlapDays: number;
  day1FromFraction: number;
  day1ToFraction: number;
  multiplier: number;
  flags: string[];
  fromName: string;
  toName: string;
}): string {
  const parts: string[] = [];
  parts.push(
    `Day 1: ${opts.fromName} ${pctOfTarget(opts.day1FromFraction)} of typical target, ${opts.toName} ${pctOfTarget(opts.day1ToFraction)} of typical target.`,
  );
  parts.push(`Co-prescribed for ${opts.overlapDays} day${opts.overlapDays === 1 ? '' : 's'}.`);
  if (opts.flags.length > 0) {
    parts.push(
      `Mechanism stacking (${opts.multiplier.toFixed(1)}×): ${opts.flags.map(flagLabel).join(', ').toLowerCase()}.`,
    );
  } else {
    parts.push('No receptor-mechanism stacking detected.');
  }
  return parts.join(' ');
}

function pctOfTarget(fraction: number): string {
  return `${Math.round(fraction * 100)}%`;
}

// ── Conservative-mode schedule transform ─────────────────────────

/**
 * Apply Conservative mode: reduce Day 1's from-drug dose by 25% (rounded
 * to the drug's formulation increments, clamped so it can never drop
 * below the next step's dose — keeps the taper monotonic).
 *
 * Returns the schedule unchanged if:
 *   • Day 1 has fromDose === 0 (no overlap to soften).
 *   • The 25% reduction rounds to the same value as the current Day 1.
 *   • Day 2's dose is already ≥ Day 1 × 0.75.
 *
 * Pure function — input schedule is not mutated.
 */
export function applyConservativeOverlap(
  schedule: ScheduleStep[],
  fromDrug: Drug,
): { schedule: ScheduleStep[]; modified: boolean; deltaMg: number } {
  if (schedule.length < 2) return { schedule, modified: false, deltaMg: 0 };
  const day1 = schedule[0];
  if (day1.fromDoseMg <= 0) return { schedule, modified: false, deltaMg: 0 };

  const day2 = schedule[1];
  const target = day1.fromDoseMg * 0.75;
  const incs = fromDrug.dosing.increments;
  let rounded = roundToIncrement(target, incs);

  // Don't drop below day 2's from-dose — that would invert the taper.
  if (day2.fromDoseMg > 0 && rounded < day2.fromDoseMg) {
    rounded = day2.fromDoseMg;
  }

  if (rounded === day1.fromDoseMg) {
    return { schedule, modified: false, deltaMg: 0 };
  }

  const note = appendConservativeNote(day1.notes, day1.fromDoseMg, rounded);
  const newDay1: ScheduleStep = { ...day1, fromDoseMg: rounded, notes: note };
  return {
    schedule: [newDay1, ...schedule.slice(1)],
    modified: true,
    deltaMg: day1.fromDoseMg - rounded,
  };
}

function appendConservativeNote(
  existing: string | undefined,
  before: number,
  after: number,
): string {
  const tag = `(Conservative mode: ${before} → ${after} mg, –${(((before - after) / before) * 100).toFixed(0)}%)`;
  if (!existing) return tag;
  return `${existing} ${tag}`;
}
