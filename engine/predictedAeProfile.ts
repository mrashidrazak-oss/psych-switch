// Predicted adverse-effect profile for the to-drug.
//
// Cross-references our existing ADVERSE_EFFECTS table (engine/adverseEffects.ts)
// and the to-drug's per-AE risk fields (sedation, epsRisk, prolactinRisk,
// qtcRisk, metabolicRisk, discontinuationSyndromeRisk) to surface a
// prioritized list of "watch out for these on the new drug".
//
// Two data sources, in priority order:
//   1. Per-drug risk fields on the JSON (qualitative 'low' | 'moderate'
//      | 'high' | 'very high'). Maps directly to a likelihood tier.
//   2. The reverse-lookup table in adverseEffects.ts (drug appears in
//      `causedBy` → likely; drug appears in `switchCandidates` → unlikely
//      relative to the from-drug).
//
// We deliberately don't try to give a numeric percentage. Cipriani 2018
// and Leucht 2013 NMAs report drug-vs-placebo odds ratios, not absolute
// risks, and copying those out of context would be misleading. Instead
// we surface tiers — clinicians know what "high prolactin risk" looks
// like for risperidone, they don't need a percentage.

import { ADVERSE_EFFECTS, type AdverseEffect } from './adverseEffects';
import type { Drug } from './types';

export type AeLikelihood = 'high' | 'moderate' | 'low' | 'lower-than-current' | 'unknown';

export interface PredictedAe {
  /** Reference to the adverse-effect entry (id, label, summary, etc.). */
  ae: AdverseEffect;
  likelihood: AeLikelihood;
  /** Why we chose this tier — for the "?" tooltip / breakdown row. */
  reason: string;
}

export interface PredictedAeProfile {
  toDrug: Drug;
  /** Sorted list — high → moderate → low → lower-than-current → unknown. */
  predictions: PredictedAe[];
}

const RISK_TO_LIKELIHOOD: Record<string, AeLikelihood> = {
  'very high': 'high',
  high: 'high',
  moderate: 'moderate',
  low: 'low',
};

/**
 * Generate a predicted AE profile for the to-drug, optionally
 * comparing against the from-drug to highlight what's *better* on the
 * new agent.
 */
export function predictAeProfile(toDrug: Drug, fromDrug?: Drug): PredictedAeProfile {
  const predictions: PredictedAe[] = [];

  for (const ae of ADVERSE_EFFECTS) {
    const pred = predictOne(ae, toDrug, fromDrug);
    if (pred) predictions.push(pred);
  }

  predictions.sort((a, b) => likelihoodRank(b.likelihood) - likelihoodRank(a.likelihood));

  return { toDrug, predictions };
}

function predictOne(
  ae: AdverseEffect,
  toDrug: Drug,
  fromDrug?: Drug,
): PredictedAe | null {
  // Two signal sources. We compute BOTH then take the higher tier so
  // that, e.g., aripiprazole shows high akathisia risk (reverse-lookup
  // says yes — it's the hallmark dose-limiting AE) even though its
  // overall epsRisk field reads 'low' (which is correct for the
  // parkinsonism subtype but misleading on its own for akathisia).

  // Source 1 — per-drug typed risk fields. Graded but coarse-bucketed.
  const fieldRisk = pickRiskField(toDrug, ae.id);
  const fieldTier: AeLikelihood | null = fieldRisk ? (RISK_TO_LIKELIHOOD[fieldRisk] ?? null) : null;

  // Source 2 — ADVERSE_EFFECTS reverse-lookup. Binary but specific.
  const inCauses = ae.causedBy.includes(toDrug.id);
  const inAvoids = ae.switchCandidates.includes(toDrug.id);
  const fromCauses = fromDrug ? ae.causedBy.includes(fromDrug.id) : false;

  let lookupTier: AeLikelihood | null = null;
  let lookupReason = '';
  if (inCauses && inAvoids) {
    // Edge case — shouldn't happen with curated data, but defensive.
    lookupTier = 'moderate';
    lookupReason = 'Listed in both candidates and causes.';
  } else if (inCauses) {
    lookupTier = 'high';
    lookupReason = 'Commonly caused by this drug.';
  } else if (inAvoids && fromCauses) {
    lookupTier = 'lower-than-current';
    lookupReason = `Recommended switch target for ${ae.label.toLowerCase()}.`;
  } else if (inAvoids) {
    lookupTier = 'low';
    lookupReason = 'Not typically caused by this drug.';
  }

  // Comparative hint always wins — it's the most useful signal in
  // a switching context.
  if (lookupTier === 'lower-than-current') {
    return { ae, likelihood: 'lower-than-current', reason: lookupReason };
  }

  if (!fieldTier && !lookupTier) return null;

  // Pick the higher-severity tier between the two signals.
  const winner: AeLikelihood = takeHigher(fieldTier, lookupTier);
  const reason =
    fieldTier && lookupTier
      ? winner === fieldTier
        ? `Drug profile: ${fieldRisk} risk.`
        : lookupReason
      : fieldTier
        ? `Drug profile: ${fieldRisk} risk.`
        : lookupReason;
  return { ae, likelihood: winner, reason };
}

function takeHigher(a: AeLikelihood | null, b: AeLikelihood | null): AeLikelihood {
  if (!a && !b) return 'unknown';
  if (!a) return b!;
  if (!b) return a;
  return likelihoodRank(a) >= likelihoodRank(b) ? a : b;
}

/**
 * Map an AE id to the matching risk field on the Drug object. We only
 * surface a few common AEs through the typed fields; everything else
 * falls through to the reverse-lookup table.
 */
function pickRiskField(drug: Drug, aeId: string): string | null {
  switch (aeId) {
    case 'sedation':
      return drug.sedation ?? null;
    case 'eps_akathisia':
      return drug.epsRisk ?? null;
    case 'hyperprolactinaemia':
      return drug.prolactinRisk ?? null;
    case 'qtc_prolongation':
      return drug.qtcRisk ?? null;
    case 'weight_gain':
      return drug.metabolicRisk?.score ?? null;
    case 'discontinuation_difficult':
      return drug.discontinuationSyndromeRisk?.score ?? null;
    default:
      return null;
  }
}

function likelihoodRank(l: AeLikelihood): number {
  switch (l) {
    case 'high': return 4;
    case 'moderate': return 3;
    case 'low': return 2;
    case 'lower-than-current': return 1;
    case 'unknown': return 0;
  }
}

export function likelihoodLabel(l: AeLikelihood): string {
  switch (l) {
    case 'high': return 'High likelihood';
    case 'moderate': return 'Moderate likelihood';
    case 'low': return 'Low likelihood';
    case 'lower-than-current': return 'Lower than current drug';
    case 'unknown': return 'Unknown';
  }
}

export function likelihoodColor(l: AeLikelihood): { bg: string; text: string } {
  switch (l) {
    case 'high':                 return { bg: 'bg-danger/15',  text: 'text-danger' };
    case 'moderate':             return { bg: 'bg-warning/15', text: 'text-warning' };
    case 'low':                  return { bg: 'bg-accent/15',  text: 'text-accent' };
    case 'lower-than-current':   return { bg: 'bg-to/15',      text: 'text-to' };
    case 'unknown':              return { bg: 'bg-border',     text: 'text-muted' };
  }
}
