// Maudsley 15th edition strategy fallback.
//
// When the engine has no specific reviewed cross-taper rule for a drug pair,
// it consults Table 3.7 from Maudsley 15th to return broad strategy guidance:
//   - direct_switch          → "Direct switch possible"
//   - cross_taper_cautiously → "Cross-taper cautiously"
//   - taper_then_wait        → "Stop the original, wait N days, then start"
//   - halve_and_add          → "Halve dose and add the new drug, then slow withdrawal"
//
// The strategy lookup is class-based (e.g. "ssri_other → snri"), not
// drug-specific, because Maudsley's table is organised that way. Drugs
// map to classes via `drugClassMap` in the JSON.

import strategyData from '../content/maudsley15/strategy-matrix.json';
import type { Drug, Maudsley15Guidance, Maudsley15Strategy } from './types';

interface MatrixRule {
  fromClass: string;
  toClass: string;
  strategy: Maudsley15Strategy;
  headline: string;
  detail: string;
  waitDays?: number;
  citations: string[];
}

interface StrategyData {
  id: string;
  rationale: string;
  drugClassMap: Record<string, string>;
  rules: MatrixRule[];
  lastReviewedISO: string;
  reviewedBy: string;
}

function getData(): StrategyData {
  return strategyData as unknown as StrategyData;
}

/**
 * Resolve a drug's Maudsley 15th class. Returns null if the drug is not
 * mapped (typically antipsychotics, mood stabilizers, LAIs — Maudsley's
 * antidepressant table doesn't cover them).
 */
function classFor(drugId: string): string | null {
  const cls = getData().drugClassMap[drugId];
  return cls ?? null;
}

/**
 * Look up the Maudsley 15th strategy for a drug pair. Returns null when
 * either drug is not in the antidepressant matrix (e.g. antipsychotics).
 */
export function lookupMaudsley15Strategy(
  fromDrug: Drug,
  toDrug: Drug,
): Maudsley15Guidance | null {
  const fromClass = classFor(fromDrug.id);
  const toClass = classFor(toDrug.id);

  if (!fromClass || !toClass) return null;

  const rule = getData().rules.find(
    (r) => r.fromClass === fromClass && r.toClass === toClass,
  );

  if (!rule) return null;

  return {
    strategy: rule.strategy,
    headline: rule.headline,
    detail: rule.detail,
    waitDays: rule.waitDays,
    citations: rule.citations,
  };
}
