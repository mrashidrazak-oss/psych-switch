// Adaptive schedule scaler.
//
// Goal: when the clinician enters doses that differ from the rule's
// reviewed reference, produce a schedule that uses the user's doses —
// rounded to real formulations, capped at clinical maxima, with honest
// signaling about how much adaptation happened.
//
// Three modes (per-rule, with safe defaults):
//
//   • proportional — scale every step by the user/reference ratio for
//     each drug, round to the drug's `dosing.increments`, merge any
//     adjacent steps that round to identical dose pairs. Default mode
//     for cross-tapers and titrations.
//
//   • fixed-step — taper at the rule's reviewed mg-decrement-per-step,
//     adjusting the *number* of steps to match the user's starting
//     dose. Right for lithium tapers and other absolute-rate schedules.
//
//   • no-scale — return the reviewed schedule untouched. Right for LAI
//     loading regimens and any protocol where the doses are dictated by
//     the product PI rather than the patient's current dose.
//
// Strong opinions baked in:
//   1. Rounding is a deterministic function. Don't ask an LLM to do it.
//   2. Schedules with non-formulation doses (e.g. 22.5 mg olanzapine)
//      are worse than no schedule. Always round to drug increments.
//   3. Capping at max generates a warning, never silently truncates.
//   4. Adapted schedules drop evidence grade by 1 ("A → B (adapted)").
//      The strategy is still reviewed; only the doses were derived.

import type { Drug, ScheduleStep, SwitchingRule } from './types';

export type ScalingMode = 'proportional' | 'fixed-step' | 'no-scale';

export interface ScaleWarning {
  kind:
    | 'capped_at_max'
    | 'rounded_to_zero'
    | 'merged_duplicate'
    | 'extreme_factor'
    | 'extreme_factor_from'
    | 'extreme_factor_to'
    | 'invalid_input'
    | 'no_scale';
  message: string;
  day?: number;
}

export interface ScaleResult {
  schedule: ScheduleStep[];
  applied: {
    mode: ScalingMode;
    fromFactor: number;
    toFactor: number;
  };
  /** True when the schedule was actually changed from the reviewed reference. */
  adapted: boolean;
  warnings: ScaleWarning[];
  /** Evidence grade penalty: 0 if no change, 1 if adapted (drop one grade). */
  evidencePenalty: 0 | 1;
}

const FACTOR_LO = 0.5;
const FACTOR_HI = 2.0;

/**
 * Pick the appropriate scaling mode for a rule. Heuristic:
 *   • LAI rules (either side LAI) → no-scale (PI-defined doses).
 *   • Rule has explicit `scalingMode` field → use that.
 *   • Otherwise → proportional.
 *
 * The optional `scalingMode` field on `SwitchingRule` is read via index
 * access rather than a typed property so legacy JSON without the field
 * still parses. New JSONs may set it explicitly.
 */
export function pickScalingMode(
  rule: SwitchingRule,
  fromDrug: Drug,
  toDrug: Drug,
): ScalingMode {
  // Explicit override on the rule wins.
  const explicit = (rule as unknown as { scalingMode?: ScalingMode }).scalingMode;
  if (explicit === 'proportional' || explicit === 'fixed-step' || explicit === 'no-scale') {
    return explicit;
  }
  // LAI on either side → no-scale.
  if (fromDrug.formulation === 'lai' || toDrug.formulation === 'lai') return 'no-scale';
  return 'proportional';
}

// ── Notes adaptation ─────────────────────────────────────────────────────────
// When we scale a step's doses, the step's `notes` string still references
// the reviewed reference doses verbatim ("Start sertraline 50 mg. Continue
// agomelatine 25 mg nocte..."). Without dose substitution the schedule
// would say "scaled to 60 mg / 30 mg" in the dose columns but still read
// "50 mg" / "25 mg" in the notes — clinically confusing and a v0.3 bug
// the user spotted.
//
// Strategy: for each step we know the reference (from-rule) doses AND
// the adapted (post-scaling) doses. Substitute exact `\bN\s*mg\b`
// matches for each. Word boundaries protect us from collateral
// substitutions (e.g. "in 25 days" won't match "25 mg"). We deliberately
// only substitute step-level doses — not other numbers in the notes —
// so future-tense mentions like "titrate to 100 mg at 4 weeks" stay
// untouched.

function escapeRegex(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function formatDoseForNotes(n: number): string {
  // Strip trailing .0 so "5.0" becomes "5". Keep "7.5" as-is.
  if (Number.isInteger(n)) return String(n);
  return n.toFixed(2).replace(/\.?0+$/, '');
}

/**
 * Substitute reference dose mentions in a step's notes with their
 * adapted equivalents. Pure function — no side effects, easy to test.
 */
export function adaptStepNotes(
  notes: string | undefined,
  refStepFrom: number,
  refStepTo: number,
  newStepFrom: number,
  newStepTo: number,
): string | undefined {
  if (!notes) return notes;

  // Build the replacement map. Skip identity replacements and 0-mg
  // (which means "stop" — usually written as a verb in notes anyway).
  const map = new Map<number, number>();
  if (refStepFrom > 0 && newStepFrom !== refStepFrom) map.set(refStepFrom, newStepFrom);
  if (refStepTo > 0 && newStepTo !== refStepTo) map.set(refStepTo, newStepTo);
  if (map.size === 0) return notes;

  // Process largest first so that "5 mg" never accidentally substitutes
  // a leading digit of "50 mg" (word boundaries should prevent this,
  // but ordering is defensive against future regex tweaks).
  const sorted = [...map.entries()].sort(([a], [b]) => b - a);
  let result = notes;
  for (const [ref, adapted] of sorted) {
    const escaped = escapeRegex(String(ref));
    const pattern = new RegExp(`\\b${escaped}\\s*mg\\b`, 'gi');
    result = result.replace(pattern, `${formatDoseForNotes(adapted)} mg`);
  }
  return result;
}

/**
 * Round a value to the nearest entry in a sorted increments array.
 * Returns 0 unchanged (it's a clinically meaningful "stop" signal).
 * If the value rounds to the smallest increment but the input was
 * exactly 0, keep 0.
 */
export function roundToIncrement(value: number, increments: number[]): number {
  if (value <= 0) return 0;
  if (increments.length === 0) return value;
  let best = increments[0];
  let bestDelta = Math.abs(value - best);
  for (const inc of increments) {
    const delta = Math.abs(value - inc);
    if (delta < bestDelta) {
      best = inc;
      bestDelta = delta;
    }
  }
  return best;
}

/**
 * Apply scaling. Defaults to proportional unless a different mode is
 * specified on the rule (or auto-detected for LAI products).
 */
export function scaleSchedule(opts: {
  rule: SwitchingRule;
  fromDrug: Drug;
  toDrug: Drug;
  userFromDose: number;
  userToDose: number;
}): ScaleResult {
  const { rule, fromDrug, toDrug, userFromDose, userToDose } = opts;
  const mode = pickScalingMode(rule, fromDrug, toDrug);

  const refFrom = rule.doseRatios.fromCurrentDoseMg;
  const refTo = rule.doseRatios.toTargetDoseMg;

  // Input sanity checks.
  if (userFromDose <= 0 || userToDose < 0 || refFrom <= 0 || refTo < 0) {
    return {
      schedule: rule.schedule,
      applied: { mode, fromFactor: 1, toFactor: 1 },
      adapted: false,
      warnings: [{ kind: 'invalid_input', message: 'Invalid dose input — using reviewed schedule.' }],
      evidencePenalty: 0,
    };
  }

  const matchedReference =
    Math.abs(userFromDose - refFrom) < 1e-6 &&
    (refTo === 0 ? userToDose === 0 : Math.abs(userToDose - refTo) < 1e-6);

  if (mode === 'no-scale' || matchedReference) {
    return {
      schedule: rule.schedule,
      applied: { mode, fromFactor: 1, toFactor: 1 },
      adapted: false,
      warnings: mode === 'no-scale' && !matchedReference
        ? [{
            kind: 'no_scale',
            message:
              'Fixed protocol — doses set by product / pharmacokinetics, not scaled to entered values.',
          }]
        : [],
      evidencePenalty: 0,
    };
  }

  if (mode === 'fixed-step') {
    return scaleFixedStep(opts, refFrom);
  }

  // proportional ──────────────────────────────────────────────────────────────
  return scaleProportional({ rule, fromDrug, toDrug, userFromDose, userToDose, refFrom, refTo });
}

// ── Proportional ─────────────────────────────────────────────────────────────

function scaleProportional(opts: {
  rule: SwitchingRule;
  fromDrug: Drug;
  toDrug: Drug;
  userFromDose: number;
  userToDose: number;
  refFrom: number;
  refTo: number;
}): ScaleResult {
  const { rule, fromDrug, toDrug, userFromDose, userToDose, refFrom, refTo } = opts;

  const fromFactor = userFromDose / refFrom;
  const toFactor = refTo > 0 ? userToDose / refTo : 1;

  const warnings: ScaleWarning[] = [];

  if (fromFactor < FACTOR_LO || fromFactor > FACTOR_HI) {
    warnings.push({
      kind: 'extreme_factor_from',
      message: `From-drug scale ${fromFactor.toFixed(2)}× — verify carefully against the drug profile.`,
    });
  }
  if (refTo > 0 && (toFactor < FACTOR_LO || toFactor > FACTOR_HI)) {
    warnings.push({
      kind: 'extreme_factor_to',
      message: `To-drug scale ${toFactor.toFixed(2)}× — verify carefully against the drug profile.`,
    });
  }

  const fromIncrements = fromDrug.dosing.increments;
  const toIncrements = toDrug.dosing.increments;
  const fromMax = fromDrug.dosing.maxDoseMg;
  const toMax = toDrug.dosing.maxDoseMg;

  // Step 1: scale each step + round to formulation, with cap warnings.
  const intermediate: ScheduleStep[] = rule.schedule.map((step) => {
    let scaledFrom = step.fromDoseMg * fromFactor;
    let scaledTo = step.toDoseMg * toFactor;

    let cappedFrom = false;
    let cappedTo = false;
    if (scaledFrom > fromMax) {
      scaledFrom = fromMax;
      cappedFrom = true;
    }
    if (scaledTo > toMax) {
      scaledTo = toMax;
      cappedTo = true;
    }

    const fromDoseMg = step.fromDoseMg === 0 ? 0 : roundToIncrement(scaledFrom, fromIncrements);
    const toDoseMg = step.toDoseMg === 0 ? 0 : roundToIncrement(scaledTo, toIncrements);

    if (cappedFrom) {
      warnings.push({
        kind: 'capped_at_max',
        day: step.day,
        message: `Day ${step.day}: ${fromDrug.genericName} capped at max ${fromMax} mg.`,
      });
    }
    if (cappedTo) {
      warnings.push({
        kind: 'capped_at_max',
        day: step.day,
        message: `Day ${step.day}: ${toDrug.genericName} capped at max ${toMax} mg.`,
      });
    }

    // Substitute the reviewed-dose mentions in the notes ("Continue
    // agomelatine 25 mg nocte") with the adapted equivalents so the
    // notes match the doses shown in the row. See adaptStepNotes() above.
    const notes = adaptStepNotes(
      step.notes,
      step.fromDoseMg,
      step.toDoseMg,
      fromDoseMg,
      toDoseMg,
    );

    return { day: step.day, fromDoseMg, toDoseMg, notes };
  });

  // Step 2: merge adjacent steps that scaled to identical dose pairs.
  const merged: ScheduleStep[] = [];
  for (const step of intermediate) {
    const last = merged[merged.length - 1];
    if (
      last &&
      last.fromDoseMg === step.fromDoseMg &&
      last.toDoseMg === step.toDoseMg
    ) {
      // Same dose pair — drop the duplicate but keep the earlier day +
      // surface a warning so the clinician knows we collapsed a step.
      warnings.push({
        kind: 'merged_duplicate',
        day: step.day,
        message: `Day ${step.day} rounded to the same doses as Day ${last.day} — step merged.`,
      });
      continue;
    }
    merged.push(step);
  }

  return {
    schedule: merged,
    applied: { mode: 'proportional', fromFactor, toFactor },
    adapted: true,
    warnings,
    evidencePenalty: 1,
  };
}

// ── Fixed-step ──────────────────────────────────────────────────────────────
// Used for tapers where the rate is absolute (e.g. lithium 200 mg every
// 2 weeks) rather than proportional. Number of steps adapts to the
// user's starting dose.

function scaleFixedStep(
  opts: {
    rule: SwitchingRule;
    fromDrug: Drug;
    toDrug: Drug;
    userFromDose: number;
    userToDose: number;
  },
  refFrom: number,
): ScaleResult {
  const { rule, fromDrug, toDrug, userFromDose, userToDose } = opts;
  const fromIncrements = fromDrug.dosing.increments;
  const toIncrements = toDrug.dosing.increments;
  const warnings: ScaleWarning[] = [];

  // Heuristic: take the largest dose-decrement seen between adjacent
  // steps in the reviewed schedule as the "step size". If the schedule
  // is shorter than 2 steps, fall back to proportional behaviour.
  if (rule.schedule.length < 2) {
    return scaleProportional({
      rule, fromDrug, toDrug,
      userFromDose, userToDose,
      refFrom, refTo: rule.doseRatios.toTargetDoseMg,
    });
  }

  let stepDecrement = 0;
  let intervalDays = 0;
  for (let i = 1; i < rule.schedule.length; i++) {
    const dec = rule.schedule[i - 1].fromDoseMg - rule.schedule[i].fromDoseMg;
    const dDay = rule.schedule[i].day - rule.schedule[i - 1].day;
    if (dec > stepDecrement) {
      stepDecrement = dec;
      intervalDays = Math.max(intervalDays, dDay);
    }
  }

  if (stepDecrement <= 0) {
    return scaleProportional({
      rule, fromDrug, toDrug, userFromDose, userToDose,
      refFrom, refTo: rule.doseRatios.toTargetDoseMg,
    });
  }

  // Build the new schedule by stepping down `userFromDose` by
  // `stepDecrement` every `intervalDays` until we reach 0.
  const startDay = rule.schedule[0]?.day ?? 0;
  const out: ScheduleStep[] = [];
  let dose = userFromDose;
  let day = startDay;
  let i = 0;
  // Hard guard against runaway loops if intervalDays is 0.
  const maxSteps = 64;
  while (dose > 0 && i < maxSteps) {
    const nextDose = Math.max(0, dose - stepDecrement);
    out.push({
      day,
      fromDoseMg: roundToIncrement(dose, fromIncrements),
      toDoseMg: userToDose === 0
        ? 0
        : roundToIncrement(userToDose, toIncrements),
    });
    if (nextDose === 0) {
      // Final step: drug stopped.
      out.push({
        day: day + (intervalDays || 14),
        fromDoseMg: 0,
        toDoseMg: userToDose === 0
          ? 0
          : roundToIncrement(userToDose, toIncrements),
        notes: 'Stop',
      });
    }
    dose = nextDose;
    day += intervalDays || 14;
    i++;
  }

  if (i >= maxSteps) {
    warnings.push({
      kind: 'extreme_factor_from',
      message: 'Starting dose generated an unusually long taper — verify against the drug profile.',
    });
  }

  return {
    schedule: out,
    applied: {
      mode: 'fixed-step',
      fromFactor: userFromDose / refFrom,
      toFactor: 1,
    },
    adapted: true,
    warnings,
    evidencePenalty: 1,
  };
}
