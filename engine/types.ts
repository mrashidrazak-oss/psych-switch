// Type definitions for clinical content and the switching engine.
// These mirror the JSON schema in /content/. If you change a JSON field
// name, update the corresponding type here AND regenerate the test data.

export type Strategy =
  | 'direct'
  | 'cross-taper'
  | 'plateau-cross-taper'
  | 'washout';

export type DiscontinuationRisk = 'low' | 'moderate' | 'high' | 'very high';

/**
 * Drug category — used for grouping in the picker and (later) for
 * disabling clinically nonsensical switches at the UI layer (e.g. a
 * cross-taper between an antidepressant and an antipsychotic, which
 * is a combination decision, not a switch).
 */
export type DrugCategory =
  | 'antidepressant'
  | 'antipsychotic'
  | 'mood-stabilizer';

export type RiskLevel = 'low' | 'moderate' | 'high' | 'very high';

export interface Drug {
  id: string;
  genericName: string;
  drugClass: string;
  /**
   * Drug category — defaults to 'antidepressant' when absent (for
   * backward compatibility with v0.1 antidepressant JSONs that didn't
   * carry the field).
   */
  category?: DrugCategory;
  /**
   * When true, the drug is excluded from the picker (listDrugs()) but
   * kept in the registry so getDrug() and rule lookups still work. Used
   * to hide MAOIs (not used in Malaysian practice) and deprecated LAI
   * formulations without breaking the switching-rule engine.
   */
  hidden?: boolean;
  /**
   * Whether this drug is a monoamine oxidase inhibitor. Triggers the
   * engine's MAOI hard-block: any switch involving an MAOI uses a
   * washout strategy, never a cross-taper, to avoid serotonin syndrome.
   */
  isMAOI?: boolean;
  /**
   * Days required after stopping THIS drug before another serotonergic
   * agent can be safely started. Only meaningful when `isMAOI` is true.
   * For reversible MAOIs (e.g. moclobemide) this is short (~1 day);
   * for irreversible MAOIs (e.g. tranylcypromine) it is 14 days.
   */
  maoiClearanceDays?: number;
  malaysianBrandNames: string[];
  halfLife: {
    meanHours: number;
    rangeHours: [number, number];
    notes?: string;
  };
  activeMetabolite: {
    name: string | null;
    halfLifeHours: number | null;
    clinicallySignificant: boolean;
    notes?: string;
  };
  cypInteractions: {
    substrateOf: string[];
    inhibitorOf: string[];
    switchingRelevance: string;
  };
  /**
   * MAOI washout windows. Required for antidepressants (used by the
   * engine's MAOI hard-block). Optional for antipsychotics where
   * the field is generally not relevant — engine falls back to a
   * conservative 14-day default if absent.
   */
  maoiWashout?: {
    daysOffBeforeMAOI: number;
    daysOffAfterMAOI: number;
    notes: string;
  };
  /**
   * Discontinuation-syndrome risk on stopping. Required for
   * antidepressants. For antipsychotics, use `reboundPsychosisRisk`
   * instead (different mechanism, different counseling).
   */
  discontinuationSyndromeRisk?: {
    score: DiscontinuationRisk;
    notes: string;
  };
  // ── Antipsychotic-specific (optional) ────────────────────────────
  /** Extrapyramidal symptom risk (akathisia, dystonia, parkinsonism). */
  epsRisk?: RiskLevel;
  /** Metabolic risk score (weight, glucose, lipids). */
  metabolicRisk?: { score: RiskLevel; notes: string };
  /** Hyperprolactinaemia risk. */
  prolactinRisk?: RiskLevel;
  /** QTc-prolongation risk. */
  qtcRisk?: RiskLevel;
  /** Sedative effect (relevant for once-daily dosing and counseling). */
  sedation?: RiskLevel;
  /** Long-acting injectable formulation availability (on the parent oral drug). */
  lai?: { available: boolean; notes: string };
  /**
   * Formulation type for THIS drug entry. LAI products are registered as
   * SEPARATE drug entries (e.g. `risperidone-lai`) rather than as
   * formulations on the oral parent — their pharmacokinetics, dosing
   * intervals and switching logic are too different to share a record.
   */
  formulation?: 'oral' | 'lai';
  /**
   * LAI-specific metadata. Required when `formulation === 'lai'`.
   * Drives the engine's oral-overlap warnings and the UI's "next
   * injection due" framing.
   */
  laiDetails?: {
    injectionIntervalDays: number;
    initiationProtocol: string;
    needsOralOverlap: boolean;
    oralOverlapDurationDays?: number;
  };
  /** Risk of rebound psychosis on abrupt discontinuation. */
  reboundPsychosisRisk?: { score: RiskLevel; notes: string };
  dosing: {
    startingDoseMg: number;
    typicalTargetRangeMg: [number, number];
    maxDoseMg: number;
    increments: number[];
    formulationsAvailableMy: string[];
  };
  formulationNotes: string;
  citations: string[];
  lastReviewedISO: string;
  reviewedBy: string;
}

export interface ScheduleStep {
  day: number;
  fromDoseMg: number;
  toDoseMg: number;
  notes?: string;
  /**
   * Optional per-step citation keys. When set, the schedule row shows
   * a small chip pointing at the source for THIS step's dose change.
   * When absent, the UI falls back to the rule-level `citations` array
   * (using its first entry as the row chip).
   *
   * Most reviewed-rule JSONs don't carry per-step citations yet — the
   * whole rule comes from a single Maudsley table. v0.4+ content can
   * use this field for rules that mix sources between steps (e.g. a
   * cross-taper where the from-drug taper rate is from Maudsley but
   * the to-drug titration is from BAP).
   */
  citations?: string[];
}

export interface SwitchingRule {
  id: string;
  fromDrugId: string;
  toDrugId: string;
  strategy: Strategy;
  rationale: string;
  durationDays: number;
  schedule: ScheduleStep[];
  doseRatios: {
    fromCurrentDoseMg: number;
    toTargetDoseMg: number;
    equivalencyNote: string;
  };
  safetyFlags: string[];
  citations: string[];
  contraindications: string[];
  lastReviewedISO: string;
  reviewedBy: string;
}

export interface SwitchInput {
  fromDrugId: string;
  fromDoseMg: number;
  toDrugId: string;
  toDoseMg: number;
}

/**
 * Maudsley 15th edition switching strategy categories from Table 3.7
 * "Antidepressants — swapping and stopping". These are the broad strategy
 * classes Maudsley uses; the engine returns one of these as a fallback
 * when no specific reviewed rule exists for the drug pair.
 */
export type Maudsley15Strategy =
  | 'direct_switch'
  | 'cross_taper_cautiously'
  | 'taper_then_wait'
  | 'halve_and_add'
  | 'special';

export interface Maudsley15Guidance {
  strategy: Maudsley15Strategy;
  /** Headline guidance string — short, fits one line. */
  headline: string;
  /** Longer detail — wait period, why this strategy, etc. */
  detail: string;
  /** Optional wait period (in days) for taper_then_wait strategies. */
  waitDays?: number;
  /** Citations for this entry (always Maudsley 15th + sometimes others). */
  citations: string[];
}

export type SwitchPlan =
  | {
      status: 'ok';
      rule: SwitchingRule;
      schedule: ScheduleStep[];
      safetyFlags: string[];
      citations: string[];
      /**
       * Whether the input doses match the rule's reviewed reference doses.
       * When false, the UI surfaces a "reference doses" banner so the
       * clinician understands the schedule is an example to be adapted
       * (rather than a precise prescription).
       */
      dosesMatchReference: boolean;
      /** The doses the input claimed (for display in the banner). */
      inputDoses: { fromMg: number; toMg: number };
    }
  | {
      /**
       * No specific reviewed rule exists, but Maudsley 15th's strategy
       * matrix has guidance for this drug pair. UI shows the strategy
       * category + accompanying detail. The clinician applies it.
       */
      status: 'maudsley_guidance';
      guidance: Maudsley15Guidance;
      safetyFlags: string[];
      fromDrugName: string;
      toDrugName: string;
    }
  | { status: 'no_rule'; reason: string }
  | {
      status: 'maoi_washout';
      direction: 'to_maoi' | 'from_maoi';
      washoutDays: number;
      reason: string;
      safetyFlags: string[];
    }
  | {
      /**
       * Switching TO clozapine is a specialist initiation decision, not a
       * cross-taper. The engine redirects the user to the dedicated
       * Clozapine module which has the full titration protocol.
       */
      status: 'clozapine_redirect';
      fromDrugName: string;
      reason: string;
      guidance: string;
    };
