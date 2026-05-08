// Case pulse — derives "what's due today / soon" across all saved
// cases, used by the Home-screen TodayPulseCard and the smart in-app
// reminder banner.
//
// Computed live each time Home renders. No persistent state of its
// own — pulls from caseManager (saved cases) + monitoring (per-case
// monitoring plan derivation).
//
// Semantics:
//   • A "pulse" is one due / overdue / upcoming monitoring item.
//   • Day offsets are computed from the case's `startedISO` (the
//     date the case was first saved). If the case is older than its
//     monitoring plan's spanDays, no future pulses remain — just
//     the closeout suggestion.
//   • "Today" = within ±1 day of now. "Soon" = 2-7 days out.
//     "Overdue" = past + within 14 days (older just falls off).

import type { SavedCase } from './caseManager';
import { generateMonitoringPlan, type MonitoringEntry } from './monitoring';
import { getDrug } from './switchingEngine';

export type PulseTier = 'overdue' | 'today' | 'soon';

export interface CasePulse {
  caseId: string;
  caseLabel: string;
  fromDrugId: string;
  toDrugId: string;
  /** Day offset from the case's start date that this pulse refers to. */
  dayOffset: number;
  /** Calendar days from now (negative = past, 0 = today, positive = upcoming). */
  daysFromNow: number;
  tier: PulseTier;
  entry: MonitoringEntry;
}

const MS_PER_DAY = 24 * 60 * 60 * 1000;

export function computeCasePulses(
  cases: SavedCase[],
  now: Date = new Date(),
): CasePulse[] {
  const out: CasePulse[] = [];
  const today = startOfDay(now);

  for (const c of cases) {
    const fromDrug = getDrug(c.fromDrugId);
    const toDrug = getDrug(c.toDrugId);
    if (!fromDrug || !toDrug) continue;

    let plan;
    try {
      plan = generateMonitoringPlan({
        fromDrugId: c.fromDrugId,
        toDrugId: c.toDrugId,
      });
    } catch {
      continue;
    }

    const start = startOfDay(new Date(c.startedISO));
    if (Number.isNaN(start.getTime())) continue;

    for (const e of plan.entries) {
      const fireDay = new Date(start.getTime() + e.dayOffset * MS_PER_DAY);
      const daysFromNow = Math.round(
        (fireDay.getTime() - today.getTime()) / MS_PER_DAY,
      );
      const tier = pulseTier(daysFromNow);
      if (!tier) continue;

      out.push({
        caseId: c.id,
        caseLabel: c.label || `${fromDrug.genericName} → ${toDrug.genericName}`,
        fromDrugId: c.fromDrugId,
        toDrugId: c.toDrugId,
        dayOffset: e.dayOffset,
        daysFromNow,
        tier,
        entry: e,
      });
    }
  }

  // Sort: overdue first, then today, then soon — within tier by daysFromNow.
  out.sort((a, b) => {
    const r = TIER_RANK[a.tier] - TIER_RANK[b.tier];
    if (r !== 0) return r;
    return a.daysFromNow - b.daysFromNow;
  });

  return out;
}

const TIER_RANK: Record<PulseTier, number> = { overdue: 0, today: 1, soon: 2 };

function pulseTier(daysFromNow: number): PulseTier | null {
  if (daysFromNow >= -1 && daysFromNow <= 1) return 'today';
  if (daysFromNow >= 2 && daysFromNow <= 7) return 'soon';
  if (daysFromNow >= -14 && daysFromNow < -1) return 'overdue';
  return null;
}

function startOfDay(d: Date): Date {
  const out = new Date(d);
  out.setHours(0, 0, 0, 0);
  return out;
}

/**
 * Convenience: count pulses by tier — used by the Home pulse card to
 * show "3 overdue · 1 today · 5 this week" in a header.
 */
export function pulseCountsByTier(pulses: CasePulse[]): Record<PulseTier, number> {
  const counts: Record<PulseTier, number> = { overdue: 0, today: 0, soon: 0 };
  for (const p of pulses) counts[p.tier]++;
  return counts;
}

export function tierLabel(t: PulseTier): string {
  switch (t) {
    case 'overdue': return 'Overdue';
    case 'today': return 'Today';
    case 'soon': return 'This week';
  }
}

export function tierColor(t: PulseTier): { dot: string; text: string } {
  switch (t) {
    case 'overdue': return { dot: 'bg-danger',  text: 'text-danger' };
    case 'today':   return { dot: 'bg-warning', text: 'text-warning' };
    case 'soon':    return { dot: 'bg-accent',  text: 'text-accent' };
  }
}

export function tierColorHex(t: PulseTier): string {
  switch (t) {
    case 'overdue': return '#ef4444';
    case 'today':   return '#f59e0b';
    case 'soon':    return '#3b82f6';
  }
}
