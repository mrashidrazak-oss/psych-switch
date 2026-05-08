// Specialty-depth orchestrator.
//
// Given a drug pair + patient context, decides which specialty
// modules apply (pregnancy, breastfeeding, pediatric, geriatric) and
// returns a unified assessment for the UI / MCP / sharing pipeline.
//
// The patient-context engine (engine/patientContextPure.ts) already
// generates *warnings* (info / warning / danger). The specialty
// engine generates *recommendations* — tier-ranked, with dose
// modifiers and additional monitoring. Different shape, complementary
// purpose.

import { ageBand, type PatientContext } from './patientContextPure';
import {
  pregnancyEntryFor,
  pregnancyTierFor,
} from './specialty/pregnancy';
import {
  pediatricEntryFor,
  pediatricTierFor,
} from './specialty/pediatric';
import {
  geriatricEntryFor,
} from './specialty/geriatric';
import type { Specialty, SpecialtyTier } from './specialty/types';

export type { Specialty, SpecialtyTier };

export interface SpecialtyRecommendation {
  specialty: Specialty;
  drugId: string;
  /** Display label, e.g. "Olanzapine". */
  drugName?: string;
  tier: SpecialtyTier;
  rationale: string;
  /** Dose modifier as a multiplier of the adult target (0–1). */
  doseFactor?: number;
  /** Extra monitoring entries (free-form). */
  additionalMonitoring?: string[];
  /** Specific risks this specialty raises. */
  knownRisks?: string;
  citations: string[];
}

export interface SpecialtyAssessment {
  /** Which specialties are active for this patient. */
  applicable: Specialty[];
  /** Tier-sorted recommendations across both drugs + active specialties. */
  recommendations: SpecialtyRecommendation[];
  /** Single-line summary for display headers. */
  headline: string;
}

/**
 * Run the full specialty assessment for a switch.
 */
export function assessSpecialty(opts: {
  fromDrugId: string;
  toDrugId: string;
  fromDrugName?: string;
  toDrugName?: string;
  context: PatientContext;
}): SpecialtyAssessment {
  const applicable = activeSpecialties(opts.context);
  const recs: SpecialtyRecommendation[] = [];

  for (const drugId of [opts.fromDrugId, opts.toDrugId]) {
    const drugName =
      drugId === opts.fromDrugId ? opts.fromDrugName : opts.toDrugName;

    if (applicable.includes('pregnancy')) {
      const e = pregnancyEntryFor(drugId);
      if (e) {
        const tier = pregnancyTierFor(drugId, opts.context.trimester) ?? e.tier;
        recs.push({
          specialty: 'pregnancy',
          drugId,
          drugName,
          tier,
          rationale: e.rationale,
          knownRisks: e.knownRisks,
          additionalMonitoring: e.additionalMonitoring,
          citations: e.citations,
        });
      }
    }

    if (applicable.includes('breastfeeding')) {
      const e = pregnancyEntryFor(drugId);
      if (e?.breastfeedingTier) {
        recs.push({
          specialty: 'breastfeeding',
          drugId,
          drugName,
          tier: e.breastfeedingTier,
          rationale: e.rationale,
          citations: e.citations,
        });
      }
    }

    if (applicable.includes('pediatric')) {
      const e = pediatricEntryFor(drugId);
      if (e) {
        const tier = pediatricTierFor(drugId, opts.context.ageYears) ?? e.tier;
        const onLabel =
          e.licensedFrom != null &&
          opts.context.ageYears != null &&
          opts.context.ageYears >= e.licensedFrom;
        recs.push({
          specialty: 'pediatric',
          drugId,
          drugName,
          tier,
          rationale:
            (onLabel ? `On-label for ${e.licensedFor}. ` : 'Off-label. ') +
            e.rationale,
          doseFactor: e.doseFactor ?? 0.5,
          citations: e.citations,
        });
      }
    }

    if (applicable.includes('geriatric')) {
      const e = geriatricEntryFor(drugId);
      if (e) {
        recs.push({
          specialty: 'geriatric',
          drugId,
          drugName,
          tier: e.tier,
          rationale: e.rationale,
          doseFactor: e.doseFactor,
          additionalMonitoring: [
            `Falls risk: ${e.fallsRisk}`,
            `Cognitive risk: ${e.cognitiveRisk}`,
          ],
          citations: e.citations,
        });
      }
    }
  }

  // Sort: most concerning tier first within each specialty group.
  recs.sort((a, b) => {
    const sp = SPECIALTY_ORDER.indexOf(a.specialty) - SPECIALTY_ORDER.indexOf(b.specialty);
    if (sp !== 0) return sp;
    return TIER_RANK[a.tier] - TIER_RANK[b.tier];
  });

  return {
    applicable,
    recommendations: recs,
    headline: buildHeadline(applicable, recs),
  };
}

// ── Helpers ─────────────────────────────────────────────────────────────────

const SPECIALTY_ORDER: Specialty[] = ['pregnancy', 'breastfeeding', 'pediatric', 'geriatric'];

const TIER_RANK: Record<SpecialtyTier, number> = {
  avoid: 0,
  caution: 1,
  acceptable: 2,
  preferred: 3,
};

/**
 * Decide which specialty modules apply given the patient context.
 */
export function activeSpecialties(ctx: PatientContext): Specialty[] {
  const out: Specialty[] = [];
  if (ctx.pregnant) out.push('pregnancy');
  if (ctx.breastfeeding) out.push('breastfeeding');
  const band = ageBand(ctx);
  if (band === 'pediatric') out.push('pediatric');
  if (band === 'older_adult') out.push('geriatric');
  return out;
}

function buildHeadline(
  applicable: Specialty[],
  recs: SpecialtyRecommendation[],
): string {
  if (applicable.length === 0) return 'No specialty considerations active for this patient.';
  const parts: string[] = [];
  for (const sp of applicable) {
    const inSpec = recs.filter((r) => r.specialty === sp);
    const avoid = inSpec.filter((r) => r.tier === 'avoid').length;
    const caution = inSpec.filter((r) => r.tier === 'caution').length;
    const summary =
      avoid > 0
        ? `${avoid} to avoid`
        : caution > 0
          ? `${caution} caution`
          : 'usable';
    parts.push(`${specialtyLabel(sp)}: ${summary}`);
  }
  return parts.join(' · ');
}

export function specialtyLabel(s: Specialty): string {
  switch (s) {
    case 'pregnancy': return 'Pregnancy';
    case 'breastfeeding': return 'Breastfeeding';
    case 'pediatric': return 'Pediatric';
    case 'geriatric': return 'Geriatric';
  }
}

export function tierLabel(t: SpecialtyTier): string {
  switch (t) {
    case 'preferred': return 'Preferred';
    case 'acceptable': return 'Acceptable';
    case 'caution': return 'Caution';
    case 'avoid': return 'Avoid';
  }
}

export function tierTint(t: SpecialtyTier): { bg: string; border: string; text: string; dot: string } {
  switch (t) {
    case 'preferred': return { bg: 'bg-to/10',      border: 'border-to/40',      text: 'text-to',      dot: 'bg-to' };
    case 'acceptable':return { bg: 'bg-accent/10',  border: 'border-accent/40',  text: 'text-accent',  dot: 'bg-accent' };
    case 'caution':   return { bg: 'bg-warning/10', border: 'border-warning/40', text: 'text-warning', dot: 'bg-warning' };
    case 'avoid':     return { bg: 'bg-danger/10',  border: 'border-danger/40',  text: 'text-danger',  dot: 'bg-danger' };
  }
}
