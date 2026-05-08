// Smart drug-picker relevance ranking.
//
// When a clinician picks the from-drug, this ranks the to-drug list by
// what's clinically relevant for THIS pair + THIS patient context:
//
//   1. Reviewed switching rule exists (+ explicit rule beats Maudsley fallback)
//   2. Pair won't trigger an "avoid"-severity DDI hit
//   3. Drug doesn't trigger a danger-severity context warning for this patient
//   4. Drug *avoids* the AE the patient is having (when AE filter is set)
//
// The ranker doesn't HIDE drugs — it just sorts and tags them, so the
// clinician can still pick something the engine considers low-relevance
// (e.g. a no-rule pair with the explicit understanding it's a fallback).
import { listRules } from './switchingEngine';
import { checkPair, severityRank as ddiSeverityRank } from './ddi';
import {
  warningsForDrug,
  type PatientContext,
} from './patientContext';
import {
  ADVERSE_EFFECTS,
  type AdverseEffect,
} from './adverseEffects';
import type { Drug } from './types';

export interface RankInput {
  fromDrugId: string | null;
  context?: PatientContext;
  /** When set, prefer drugs that AVOID this AE (i.e. listed in switchCandidates). */
  avoidAeId?: string | null;
}

export type RelevanceTier = 'top' | 'reviewed' | 'fallback' | 'caution' | 'avoid';

export interface RankedDrug {
  drug: Drug;
  tier: RelevanceTier;
  /** Score used for sort within tier (higher = more relevant). */
  score: number;
  /** Short tags shown next to the drug name in the picker. */
  tags: string[];
  /** True when picking this drug would trigger an "avoid"-grade DDI or context flag. */
  blocked: boolean;
}

const TIER_RANK: Record<RelevanceTier, number> = {
  top:      4,
  reviewed: 3,
  fallback: 2,
  caution:  1,
  avoid:    0,
};

/**
 * Rank a list of candidate to-drugs against a given from-drug + context.
 * Pure function — easy to test.
 */
export function rankDrugs(drugs: Drug[], input: RankInput): RankedDrug[] {
  const { fromDrugId, context, avoidAeId } = input;
  const ae = avoidAeId ? ADVERSE_EFFECTS.find((a) => a.id === avoidAeId) ?? null : null;

  // Pre-compute the set of to-drugs that have an explicit reviewed rule from this from.
  const reviewedToIds = new Set<string>();
  if (fromDrugId) {
    for (const r of listRules()) {
      if (r.fromDrugId === fromDrugId) reviewedToIds.add(r.toDrugId);
    }
  }

  return drugs.map((d) => rankOne(d, fromDrugId, reviewedToIds, context, ae))
    .sort((a, b) => {
      if (TIER_RANK[a.tier] !== TIER_RANK[b.tier]) return TIER_RANK[b.tier] - TIER_RANK[a.tier];
      if (a.score !== b.score) return b.score - a.score;
      return a.drug.genericName.localeCompare(b.drug.genericName);
    });
}

function rankOne(
  d: Drug,
  fromDrugId: string | null,
  reviewedToIds: Set<string>,
  context: PatientContext | undefined,
  ae: AdverseEffect | null,
): RankedDrug {
  const tags: string[] = [];
  let score = 0;
  let tier: RelevanceTier = 'fallback';
  let blocked = false;

  const reviewed = fromDrugId ? reviewedToIds.has(d.id) : false;
  if (reviewed) {
    score += 100;
    tags.push('Reviewed');
    tier = 'reviewed';
  }

  // AE filter — preferred candidate?
  if (ae) {
    if (ae.switchCandidates.includes(d.id)) {
      score += 60;
      tags.push(`avoids ${ae.label.split(' ')[0].toLowerCase()}`);
      tier = tier === 'reviewed' ? 'top' : 'reviewed';
    } else if (ae.causedBy.includes(d.id)) {
      score -= 40;
      tags.push(`causes ${ae.label.split(' ')[0].toLowerCase()}`);
      tier = 'caution';
    }
  }

  // Context warnings on this drug
  if (context) {
    const warnings = warningsForDrug(context, d.id);
    if (warnings.some((w) => w.severity === 'danger')) {
      score -= 200;
      tags.push('contra');
      tier = 'avoid';
      blocked = true;
    } else if (warnings.some((w) => w.severity === 'warning')) {
      score -= 30;
      if (tier === 'top' || tier === 'reviewed') {
        tags.push('caution');
        tier = 'caution';
      } else {
        tags.push('caution');
      }
    }
  }

  // DDI on the pair
  if (fromDrugId && fromDrugId !== d.id) {
    const hits = checkPair(fromDrugId, d.id);
    const worst = hits.reduce((acc, h) => Math.max(acc, ddiSeverityRank(h.severity)), 0);
    if (worst >= 3) {
      // 'avoid'-grade DDI
      score -= 200;
      tags.push('avoid');
      tier = 'avoid';
      blocked = true;
    } else if (worst >= 2) {
      // 'warning'-grade DDI
      score -= 20;
      if (tier !== 'avoid') tier = tier === 'top' || tier === 'reviewed' ? 'caution' : tier;
      tags.push('DDI');
    }
  }

  return { drug: d, tier, score, tags, blocked };
}
