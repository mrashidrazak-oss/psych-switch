// Pharmacokinetic simulation for visualization purposes.
//
// We use a one-compartment exponential model: when the prescribed dose
// changes, the patient's effective level moves toward the new prescribed
// dose with a time constant set by the drug's effective half-life.
//
// This is DELIBERATELY SIMPLE. We ignore: two-compartment kinetics,
// non-linear dose-response (paroxetine!), CYP-mediated drug-drug
// interactions in the regimen, food effects, and inter-individual
// variability. The output is for clinical INTUITION (showing the long
// fluoxetine tail, the slow venlafaxine washout) — not for exposure
// prediction. Do NOT use these numbers to dose patients.

import type { Drug, ScheduleStep } from './types';

/**
 * Effective half-life used for visualization. For drugs with a clinically
 * significant active metabolite (fluoxetine, venlafaxine), the metabolite
 * dominates the post-cessation tail and ignoring it would mislead.
 *
 * Heuristic: if a clinically-significant metabolite exists, take the
 * larger of (parent half-life) and (metabolite half-life × 0.7). The 0.7
 * factor is a deliberately conservative weight reflecting that metabolites
 * are typically less potent on a per-mg basis than the parent.
 */
export function effectiveHalfLifeHours(drug: Drug): number {
  const parent = drug.halfLife.meanHours;
  const meta = drug.activeMetabolite;
  if (meta.clinicallySignificant && typeof meta.halfLifeHours === 'number') {
    return Math.max(parent, meta.halfLifeHours * 0.7);
  }
  return parent;
}

export interface DailyPoint {
  day: number;
  prescribedDoseMg: number;
  effectiveLevelMg: number;
}

interface SchedulePoint {
  day: number;
  doseMg: number;
}

/**
 * Look up the prescribed dose at the given day by stepping through the
 * schedule. Days before the first step inherit the first step's dose.
 * Days after the final step inherit the final step's dose (so a from-
 * drug schedule ending in 0 mg correctly stays at 0 through the trail).
 */
function prescribedAt(points: SchedulePoint[], day: number): number {
  let dose = points[0]?.doseMg ?? 0;
  for (const p of points) {
    if (p.day <= day) {
      dose = p.doseMg;
    } else {
      break;
    }
  }
  return dose;
}

/**
 * Simulate daily prescribed dose and effective level for one drug across
 * `totalDays` days. Initial effective level on day 1 is the day-1
 * prescribed dose (assumes the patient is at steady state when the
 * cross-taper begins).
 */
export function simulateDailyLevels(
  points: SchedulePoint[],
  halfLifeHours: number,
  totalDays: number,
): DailyPoint[] {
  if (points.length === 0) return [];

  // Fraction of the previous day's residual that survives 24 hours.
  // For half-life H hours, after 24h the residual is 0.5^(24/H).
  const survivePerDay = Math.pow(0.5, 24 / halfLifeHours);

  const result: DailyPoint[] = [];
  let effective = points[0].doseMg; // day-1 steady-state assumption

  for (let day = 1; day <= totalDays; day++) {
    const prescribed = prescribedAt(points, day);
    if (day > 1) {
      // Move effective toward prescribed by one day's worth of decay.
      effective = effective * survivePerDay + prescribed * (1 - survivePerDay);
    }
    result.push({
      day,
      prescribedDoseMg: prescribed,
      effectiveLevelMg: effective,
    });
  }
  return result;
}

/**
 * Convenience: run the simulation for both drugs in a switching schedule
 * and return paired daily points. Includes a configurable trailing
 * window so the post-schedule washout is visible (most useful for
 * fluoxetine, where the tail is longer than the cross-taper itself).
 */
export function simulateSwitch(
  schedule: ScheduleStep[],
  fromDrug: Drug,
  toDrug: Drug,
  options: { trailingDays?: number } = {},
): { from: DailyPoint[]; to: DailyPoint[]; totalDays: number } {
  const trailingDays = options.trailingDays ?? 14;
  const lastScheduleDay = schedule[schedule.length - 1]?.day ?? 1;
  const totalDays = lastScheduleDay + trailingDays;

  const fromPoints = schedule.map((s) => ({ day: s.day, doseMg: s.fromDoseMg }));
  const toPoints = schedule.map((s) => ({ day: s.day, doseMg: s.toDoseMg }));

  return {
    from: simulateDailyLevels(
      fromPoints,
      effectiveHalfLifeHours(fromDrug),
      totalDays,
    ),
    to: simulateDailyLevels(
      toPoints,
      effectiveHalfLifeHours(toDrug),
      totalDays,
    ),
    totalDays,
  };
}
