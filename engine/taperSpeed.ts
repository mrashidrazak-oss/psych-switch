// Taper-speed adjustment for cross-taper schedules.
//
// Why this exists:
// Maudsley 15th edition uses a 28-day cross-taper as its standard. Real-world
// clinical practice is often faster — published audits and other guidelines
// suggest:
//
//   • Spanish national registry (real-world):  ~16 days average taper
//   • NHS / NICE inpatient with monitoring:    3–7 days
//   • Stahl's Essential Psychopharmacology:    14–28 days routine, 4–8 wks high-risk
//   • Carlat meta-analysis (n≈1,400):          7–14 days most common; immediate
//                                              switches equally effective for symptoms
//   • RANZCP / FDA aripiprazole guidance:      14-day overlap minimum
//
// The dose progression in a reviewed rule (e.g. 100% → 75% → 50% → 25% → 0)
// is the clinically reviewed component — receptor occupancy and discontinuation
// risk hinge on the dose ratios. The DAY INTERVALS between those steps are
// context-dependent: fast for stable, monitored patients; slow for first
// episode or high relapse risk.
//
// This utility lets the user pick a speed and the schedule scales accordingly,
// keeping the dose progression intact. The UI flags non-default speeds with
// a clear warning that they sit outside the reviewed Maudsley schedule.

import type { ScheduleStep } from './types';

export type TaperSpeed = 'faster' | 'standard' | 'slower';

/**
 * Speed → time-scaling factor.
 *  • faster  ≈ 0.5×  (a 28-day taper becomes ~14 days — matches NHS / Stahl /
 *                     real-world average)
 *  • standard = 1.0× (Maudsley 15th, the reviewed schedule)
 *  • slower  ≈ 1.5×  (28 days → 42 days — for first-episode psychosis,
 *                     high relapse risk, or unstable patients)
 */
const SPEED_FACTOR: Record<TaperSpeed, number> = {
  faster: 0.5,
  standard: 1,
  slower: 1.5,
};

export const TAPER_SPEEDS: TaperSpeed[] = ['faster', 'standard', 'slower'];

export const SPEED_LABEL: Record<TaperSpeed, string> = {
  faster: 'Faster',
  standard: 'Standard',
  slower: 'Slower',
};

export const SPEED_SUBLABEL: Record<TaperSpeed, string> = {
  faster: '~½ duration',
  standard: 'Maudsley',
  slower: '~1½× duration',
};

export const SPEED_BASIS: Record<TaperSpeed, string> = {
  faster:
    'Compressed taper (~½ Maudsley duration). Consistent with NHS inpatient / Stahl / real-world practice (Spanish registry average: 16 days). Use for stable patients, inpatient monitoring, or low relapse risk.',
  standard:
    'Maudsley Prescribing Guidelines 15th edition — the reviewed reference schedule. Default for outpatient use.',
  slower:
    'Extended taper (~1½× Maudsley). Use for first-episode psychosis, high relapse risk, history of poor adherence, or where discontinuation symptoms have previously been a problem.',
};

/**
 * Whether a meaningful schedule remains after compression.
 * Direct switches (1–2 day) and extremely short schedules don't benefit
 * from speed adjustment — the toggle should be hidden in those cases.
 */
export function speedToggleApplies(schedule: ScheduleStep[]): boolean {
  if (schedule.length < 3) return false;
  const lastDay = schedule[schedule.length - 1]!.day;
  return lastDay >= 10; // anything ≥10 days has room to compress/expand meaningfully
}

/**
 * Scale a schedule's day intervals by the speed factor while keeping
 * dose values, notes and step count identical.
 *
 * Day-mapping rules:
 *   • Day 1 always stays Day 1 (the start day is anchor).
 *   • Other days scale: newDay = max(prev + 1, round((day − 1) × factor + 1)).
 *     The `prev + 1` floor guarantees day numbers are strictly increasing
 *     so steps never collapse into the same day after rounding.
 *
 * For 'standard' speed this is a no-op — returns the original array.
 */
export function compressSchedule(
  schedule: ScheduleStep[],
  speed: TaperSpeed,
): ScheduleStep[] {
  if (speed === 'standard' || schedule.length === 0) return schedule;

  const factor = SPEED_FACTOR[speed];
  const out: ScheduleStep[] = [];
  let prevDay = 0;

  for (let i = 0; i < schedule.length; i++) {
    const step = schedule[i]!;
    let newDay: number;
    if (i === 0) {
      newDay = step.day; // anchor first step (typically day 1)
    } else {
      const scaled = Math.round((step.day - 1) * factor + 1);
      newDay = Math.max(prevDay + 1, scaled);
    }
    out.push({ ...step, day: newDay });
    prevDay = newDay;
  }
  return out;
}

/**
 * Approximate total schedule duration after applying speed.
 * Used by the UI to surface "X-day taper" labels without re-deriving from
 * the schedule array.
 */
export function adjustedDurationDays(
  originalDurationDays: number,
  speed: TaperSpeed,
): number {
  if (speed === 'standard') return originalDurationDays;
  return Math.max(1, Math.round(originalDurationDays * SPEED_FACTOR[speed]));
}
