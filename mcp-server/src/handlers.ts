// Tool handlers — the real implementations that call into the
// PsychSwitch engine. Each function maps an MCP tool's input args to
// the appropriate engine call and returns a serialisable result.
//
// All imports here are PURE engine modules. None of them touch React
// or AsyncStorage; they only consume types + JSON content. That's
// deliberate — we split engine/patientContext into a pure file
// (patientContextPure) specifically so this layer can stay
// dependency-light.

import {
  getDrug,
  listAllDrugs,
  listDrugs,
  listRules,
  generateSwitchPlan,
  deriveSafetyFlags,
} from '../../engine/switchingEngine';
import { gradeCitations, getCitation } from '../../engine/citations';
import { checkAll, checkPair } from '../../engine/ddi';
import { predictAeProfile } from '../../engine/predictedAeProfile';
import { computePsychSwitchScore } from '../../engine/psychSwitchScore';
import {
  scaleSchedule,
  pickScalingMode,
} from '../../engine/scaleSchedule';
import { search as runSearch } from '../../engine/search';
import { lookupTerm } from '../../engine/glossary';
import {
  EQUIVALENCY_FAMILIES,
  convertWithinFamily,
  doseInReferenceUnits,
  type EquivalencyFamily,
} from '../../engine/doseEquivalents';
import { generateMonitoringPlan } from '../../engine/monitoring';
import {
  warningsForDrug,
  type PatientContext,
} from '../../engine/patientContextPure';
import { assessSpecialty } from '../../engine/specialty';
import {
  errataForScope,
  errataSinceVersion,
  listErrata,
} from '../../engine/errata';
import {
  formatEffect,
  quantitativeFor,
} from '../../engine/quantitativeAe';
import {
  costFor,
  formatMyr,
  tierLabel as costTierLabel,
} from '../../engine/costData';
import { assessOverlapIntensity } from '../../engine/overlapIntensity';

// ── Helpers ────────────────────────────────────────────────────────────────

function asString(v: unknown, name: string): string {
  if (typeof v !== 'string' || v.length === 0) {
    throw new Error(`Argument '${name}' is required (string).`);
  }
  return v;
}

function asNumber(v: unknown, name: string): number {
  if (typeof v !== 'number' || !Number.isFinite(v)) {
    throw new Error(`Argument '${name}' is required (number).`);
  }
  return v;
}

function asPatientContext(v: unknown): PatientContext {
  if (v == null) return {};
  if (typeof v !== 'object') return {};
  return v as PatientContext;
}

function notFound(kind: string, id: string): never {
  throw new Error(`${kind} not found: '${id}'.`);
}

// ── Tool implementations ──────────────────────────────────────────────────

type Args = Record<string, unknown>;

export const handlers = {
  /**
   * List drugs in the registry. Returns shallow projection to keep
   * the AI assistant's context window tidy — full profile available
   * via psychswitch_get_drug.
   */
  psychswitch_list_drugs: async (args: Args) => {
    const all = args.includeHidden ? listAllDrugs() : listDrugs();
    const category = typeof args.category === 'string' ? args.category : null;
    return all
      .filter((d) => !category || d.category === category)
      .map((d) => ({
        id: d.id,
        genericName: d.genericName,
        drugClass: d.drugClass,
        category: d.category,
        formulation: d.formulation,
        hidden: d.hidden ?? false,
      }));
  },

  /**
   * Look up a drug profile by id. Returns the full Drug object.
   */
  psychswitch_get_drug: async (args: Args) => {
    const id = asString(args.id, 'id');
    const drug = getDrug(id);
    if (!drug) notFound('Drug', id);
    return drug;
  },

  /**
   * List reviewed switching rules. Optionally filtered.
   */
  psychswitch_list_rules: async (args: Args) => {
    const fromId = typeof args.fromDrugId === 'string' ? args.fromDrugId : null;
    const toId = typeof args.toDrugId === 'string' ? args.toDrugId : null;
    return listRules()
      .filter((r) => (!fromId || r.fromDrugId === fromId) && (!toId || r.toDrugId === toId))
      .map((r) => ({
        id: r.id,
        fromDrugId: r.fromDrugId,
        toDrugId: r.toDrugId,
        strategy: r.strategy,
        durationDays: r.durationDays,
        evidenceGrade: gradeCitations(r.citations),
        lastReviewedISO: r.lastReviewedISO,
        reviewedBy: r.reviewedBy,
      }));
  },

  /**
   * The main API — generate a complete switching plan.
   * Returns the engine's full SwitchPlan + score + adapted schedule
   * + monitoring plan + AE profile, in one call.
   */
  psychswitch_generate_plan: async (args: Args) => {
    const fromDrugId = asString(args.fromDrugId, 'fromDrugId');
    const fromDoseMg = asNumber(args.fromDoseMg, 'fromDoseMg');
    const toDrugId = asString(args.toDrugId, 'toDrugId');
    const toDoseMg = asNumber(args.toDoseMg, 'toDoseMg');
    const ctx = asPatientContext(args.patientContext);

    const fromDrug = getDrug(fromDrugId) ?? notFound('Drug', fromDrugId);
    const toDrug = getDrug(toDrugId) ?? notFound('Drug', toDrugId);

    const plan = generateSwitchPlan({ fromDrugId, fromDoseMg, toDrugId, toDoseMg });

    // Compute full envelope only when we actually have a reviewed rule.
    if (plan.status !== 'ok') {
      return {
        plan,
        evidenceGrade: 'D' as const,
      };
    }

    const scaleResult = scaleSchedule({
      rule: plan.rule,
      fromDrug,
      toDrug,
      userFromDose: fromDoseMg,
      userToDose: toDoseMg,
    });
    const ddiHits = checkPair(fromDrugId, toDrugId);
    const ctxWarnings = [
      ...warningsForDrug(ctx, fromDrugId),
      ...warningsForDrug(ctx, toDrugId),
    ];
    const evidenceGrade = gradeCitations(plan.citations);
    const score = computePsychSwitchScore({
      rule: plan.rule,
      fromDrug,
      toDrug,
      context: ctx,
      scaleResult,
      ddiHits,
      contextWarnings: ctxWarnings,
      evidenceGrade,
    });
    const monitoring = generateMonitoringPlan({
      fromDrugId,
      toDrugId,
      context: ctx,
      durationDays: plan.rule.durationDays + 14,
    });
    const aeProfile = predictAeProfile(toDrug, fromDrug);
    const profileFlags = deriveSafetyFlags(fromDrug, toDrug);

    return {
      plan,
      adaptedSchedule: scaleResult.schedule,
      adaptedFromReviewed: scaleResult.adapted,
      adaptedFactors: scaleResult.applied,
      adaptedWarnings: scaleResult.warnings,
      ddiHits,
      contextWarnings: ctxWarnings,
      evidenceGrade,
      score,
      monitoring,
      adverseEffectProfile: aeProfile,
      additionalSafetyFlags: profileFlags,
    };
  },

  /**
   * Apply adaptive scaling without going through the full plan.
   */
  psychswitch_scale_schedule: async (args: Args) => {
    const fromDrugId = asString(args.fromDrugId, 'fromDrugId');
    const fromDoseMg = asNumber(args.fromDoseMg, 'fromDoseMg');
    const toDrugId = asString(args.toDrugId, 'toDrugId');
    const toDoseMg = asNumber(args.toDoseMg, 'toDoseMg');

    const fromDrug = getDrug(fromDrugId) ?? notFound('Drug', fromDrugId);
    const toDrug = getDrug(toDrugId) ?? notFound('Drug', toDrugId);
    const plan = generateSwitchPlan({ fromDrugId, fromDoseMg, toDrugId, toDoseMg });
    if (plan.status !== 'ok') {
      return { adapted: false, plan, schedule: null, warnings: ['No reviewed rule for this pair.'] };
    }
    const result = scaleSchedule({
      rule: plan.rule,
      fromDrug,
      toDrug,
      userFromDose: fromDoseMg,
      userToDose: toDoseMg,
    });
    return {
      adapted: result.adapted,
      mode: pickScalingMode(plan.rule, fromDrug, toDrug),
      applied: result.applied,
      schedule: result.schedule,
      warnings: result.warnings,
      evidencePenalty: result.evidencePenalty,
    };
  },

  /**
   * Convert a dose between drugs in the same equivalency family.
   */
  psychswitch_dose_equivalent: async (args: Args) => {
    const family = asString(args.family, 'family') as EquivalencyFamily;
    if (!(family in EQUIVALENCY_FAMILIES)) {
      throw new Error(`Unknown family '${family}'. Use 'cpz', 'fluoxetine', or 'diazepam'.`);
    }
    const fromDrugId = asString(args.fromDrugId, 'fromDrugId');
    const fromDoseMg = asNumber(args.fromDoseMg, 'fromDoseMg');
    const toDrugId = typeof args.toDrugId === 'string' ? args.toDrugId : null;

    const refUnits = doseInReferenceUnits(family, fromDrugId, fromDoseMg);
    if (!refUnits) {
      throw new Error(`'${fromDrugId}' is not in the ${family} family.`);
    }
    if (toDrugId) {
      const conv = convertWithinFamily(family, fromDrugId, fromDoseMg, toDrugId);
      if (!conv) throw new Error(`'${toDrugId}' is not in the ${family} family.`);
      return {
        family,
        reference: EQUIVALENCY_FAMILIES[family].reference,
        from: { id: fromDrugId, doseMg: fromDoseMg },
        to: { id: toDrugId, doseMg: conv.toDoseMg },
        referenceUnits: conv.refUnits,
      };
    }
    return {
      family,
      reference: EQUIVALENCY_FAMILIES[family].reference,
      from: { id: fromDrugId, doseMg: fromDoseMg },
      referenceUnits: refUnits.refUnits,
      referenceDoseMg: refUnits.referenceDoseMg,
    };
  },

  /**
   * Predicted side-effect profile for a target drug.
   */
  psychswitch_predict_ae: async (args: Args) => {
    const toDrugId = asString(args.toDrugId, 'toDrugId');
    const fromDrugId = typeof args.fromDrugId === 'string' ? args.fromDrugId : null;
    const toDrug = getDrug(toDrugId) ?? notFound('Drug', toDrugId);
    const fromDrug = fromDrugId ? getDrug(fromDrugId) ?? undefined : undefined;
    return predictAeProfile(toDrug, fromDrug);
  },

  /**
   * Pairwise DDI check for the cross-taper overlap window.
   */
  psychswitch_check_ddi: async (args: Args) => {
    const drugIds = args.drugIds;
    if (!Array.isArray(drugIds) || drugIds.length < 2) {
      throw new Error("'drugIds' must be an array of two or more drug ids.");
    }
    const ids = drugIds.map((id, i) => asString(id, `drugIds[${i}]`));
    if (ids.length === 2) {
      return checkPair(ids[0], ids[1]);
    }
    return checkAll(ids);
  },

  /**
   * Compute the PsychSwitch Score in isolation (without re-running
   * generate_plan). Useful for what-if exploration.
   */
  psychswitch_compute_score: async (args: Args) => {
    const fromDrugId = asString(args.fromDrugId, 'fromDrugId');
    const fromDoseMg = asNumber(args.fromDoseMg, 'fromDoseMg');
    const toDrugId = asString(args.toDrugId, 'toDrugId');
    const toDoseMg = asNumber(args.toDoseMg, 'toDoseMg');
    const ctx = asPatientContext(args.patientContext);

    const fromDrug = getDrug(fromDrugId) ?? notFound('Drug', fromDrugId);
    const toDrug = getDrug(toDrugId) ?? notFound('Drug', toDrugId);
    const plan = generateSwitchPlan({ fromDrugId, fromDoseMg, toDrugId, toDoseMg });
    if (plan.status !== 'ok') {
      throw new Error(`No reviewed rule for ${fromDrugId} → ${toDrugId}; cannot score.`);
    }
    const scaleResult = scaleSchedule({
      rule: plan.rule,
      fromDrug,
      toDrug,
      userFromDose: fromDoseMg,
      userToDose: toDoseMg,
    });
    const ddiHits = checkPair(fromDrugId, toDrugId);
    const ctxWarnings = [
      ...warningsForDrug(ctx, fromDrugId),
      ...warningsForDrug(ctx, toDrugId),
    ];
    return computePsychSwitchScore({
      rule: plan.rule,
      fromDrug,
      toDrug,
      context: ctx,
      scaleResult,
      ddiHits,
      contextWarnings: ctxWarnings,
      evidenceGrade: gradeCitations(plan.citations),
    });
  },

  /**
   * Cross-content search — drugs, rules, tools, modules.
   */
  psychswitch_search: async (args: Args) => {
    const query = asString(args.query, 'query');
    const limit = typeof args.limit === 'number' ? args.limit : 12;
    return runSearch(query, limit);
  },

  /**
   * Define a clinical term.
   */
  psychswitch_lookup_glossary: async (args: Args) => {
    const term = asString(args.term, 'term');
    const entry = lookupTerm(term);
    if (!entry) throw new Error(`Unknown term '${term}'.`);
    return entry;
  },

  /**
   * Resolve a citation key to a full reference + paraphrase.
   */
  psychswitch_get_citation: async (args: Args) => {
    const key = asString(args.key, 'key');
    return getCitation(key);
  },

  /**
   * Patient-context warnings for a single drug.
   */
  psychswitch_context_warnings: async (args: Args) => {
    const drugId = asString(args.drugId, 'drugId');
    const ctx = asPatientContext(args.patientContext);
    return warningsForDrug(ctx, drugId);
  },

  /**
   * Errata feed — every accepted clinical-content correction.
   */
  psychswitch_list_errata: async (args: Args) => {
    const scope = typeof args.scope === 'string' ? args.scope : null;
    const sinceVersion = typeof args.sinceVersion === 'string' ? args.sinceVersion : null;
    if (scope) return errataForScope(scope);
    if (sinceVersion) return errataSinceVersion(sinceVersion);
    return listErrata();
  },

  /**
   * Quantitative effect sizes from the major NMAs.
   */
  psychswitch_quantitative_ae: async (args: Args) => {
    const drugId = asString(args.drugId, 'drugId');
    const effects = quantitativeFor(drugId);
    return {
      drugId,
      effects: effects.map((e) => ({
        ...e,
        formatted: formatEffect(e),
      })),
    };
  },

  /**
   * Affordability hint — Malaysian formulary cost.
   */
  psychswitch_cost: async (args: Args) => {
    const ids = args.drugIds;
    if (!Array.isArray(ids) || ids.length === 0) {
      throw new Error("'drugIds' must be a non-empty array.");
    }
    const drugIds = ids.map((id, i) => asString(id, `drugIds[${i}]`));
    const entries = drugIds.map((id) => {
      const c = costFor(id);
      return {
        drugId: id,
        entry: c,
        display: c
          ? `${formatMyr(c.monthlyCostMyr)}/mo · ${costTierLabel(c.tier)}`
          : 'No cost data',
      };
    });
    if (entries.length === 2 && entries[0].entry && entries[1].entry) {
      const delta =
        entries[1].entry.monthlyCostMyr - entries[0].entry.monthlyCostMyr;
      return {
        entries,
        deltaMyr: delta,
        deltaLabel:
          delta === 0
            ? 'No cost change'
            : delta > 0
              ? `RM ${delta.toFixed(0)}/mo more`
              : `RM ${Math.abs(delta).toFixed(0)}/mo less`,
      };
    }
    return { entries };
  },

  /**
   * Cross-taper overlap intensity assessment.
   */
  psychswitch_overlap_intensity: async (args: Args) => {
    const fromDrugId = asString(args.fromDrugId, 'fromDrugId');
    const fromDoseMg = asNumber(args.fromDoseMg, 'fromDoseMg');
    const toDrugId = asString(args.toDrugId, 'toDrugId');
    const toDoseMg = asNumber(args.toDoseMg, 'toDoseMg');

    const fromDrug = getDrug(fromDrugId) ?? notFound('Drug', fromDrugId);
    const toDrug = getDrug(toDrugId) ?? notFound('Drug', toDrugId);
    const plan = generateSwitchPlan({ fromDrugId, fromDoseMg, toDrugId, toDoseMg });
    if (plan.status !== 'ok') {
      return {
        applicable: false,
        reason: `No reviewed cross-taper rule for ${fromDrugId} → ${toDrugId}; overlap intensity not assessed.`,
      };
    }
    return assessOverlapIntensity({
      fromDrug,
      toDrug,
      schedule: plan.schedule,
    });
  },

  /**
   * Specialty-depth assessment — pregnancy / breastfeeding / pediatric /
   * geriatric tiers + dose modifiers + additional monitoring.
   */
  psychswitch_assess_specialty: async (args: Args) => {
    const fromDrugId = asString(args.fromDrugId, 'fromDrugId');
    const toDrugId = asString(args.toDrugId, 'toDrugId');
    const ctx = asPatientContext(args.patientContext);
    const fromDrug = getDrug(fromDrugId) ?? notFound('Drug', fromDrugId);
    const toDrug = getDrug(toDrugId) ?? notFound('Drug', toDrugId);
    return assessSpecialty({
      fromDrugId,
      toDrugId,
      fromDrugName: fromDrug.genericName,
      toDrugName: toDrug.genericName,
      context: ctx,
    });
  },
};

export type HandlerName = keyof typeof handlers;
