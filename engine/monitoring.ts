// Monitoring schedule generator.
//
// Given a switching plan + patient context, produce a date-stamped list
// of investigations and clinical reviews to schedule alongside the
// titration.
//
// Sources
//   • Maudsley 15th: monitoring chapters per drug class
//   • BAP 2020: schizophrenia monitoring guidance
//   • NICE NG178 (psychosis), NG222 (depression)
//   • Malaysian CPG schizophrenia, mood disorders
//
// Design
//   • Each drug declares the monitoring it triggers via MONITORING_RULES.
//   • Patient context can ADD entries (e.g. eGFR if renal fn declared).
//   • Day-offsets are relative to the switch start (Day 0).
//   • Exported as a flat, sorted list that the UI can render as a checklist.

import type { PatientContext } from './patientContext';

export type MonitoringCategory = 'lab' | 'ecg' | 'physical' | 'rating' | 'review';

export interface MonitoringEntry {
  /** Day offset from Day 0 (switch start). */
  dayOffset: number;
  /** Short label for the chip ("FBC", "ECG", "ESRS"). */
  label: string;
  /** Free-form detail for the body row. */
  detail: string;
  category: MonitoringCategory;
  /** Drug ID this monitoring is tied to (for traceability). */
  drugId?: string;
  /** Citation source key. */
  citation?: string;
  /** Whether this is a one-off or recurring (e.g. "every 4 weeks"). */
  recurring?: { everyDays: number; untilDay?: number };
}

interface DrugMonitoringRules {
  baseline: Omit<MonitoringEntry, 'drugId'>[];
  ongoing: Omit<MonitoringEntry, 'drugId'>[];
}

// ── Drug-specific monitoring ────────────────────────────────────────────────
// Keep this terse — the engine de-duplicates entries that fire from both
// the from-drug and to-drug (e.g. ECG when both have QTc risk).

const RULES: Record<string, DrugMonitoringRules> = {
  // ── Mood stabilizers ──
  lithium: {
    baseline: [
      { dayOffset: 0, label: 'U&E + eGFR',        detail: 'Baseline renal function before lithium.',                           category: 'lab',     citation: 'maudsley15_mood_lithium_monitoring' },
      { dayOffset: 0, label: 'TFT',               detail: 'Baseline thyroid function.',                                        category: 'lab',     citation: 'maudsley15_mood_lithium_monitoring' },
      { dayOffset: 0, label: 'Calcium',           detail: 'Baseline Ca²⁺ (lithium causes hyperparathyroidism).',               category: 'lab' },
      { dayOffset: 0, label: 'ECG',               detail: 'Baseline ECG if cardiac history or age >40.',                       category: 'ecg' },
      { dayOffset: 0, label: 'βHCG',              detail: 'Pregnancy test in women of reproductive age.',                      category: 'lab' },
    ],
    ongoing: [
      { dayOffset: 7,   label: 'Lithium level',  detail: 'Trough level 12 h post-dose, 5–7 d after each dose change.',        category: 'lab',     citation: 'maudsley15_mood_lithium_monitoring' },
      { dayOffset: 90,  label: 'Lithium level',  detail: 'Routine 3-monthly trough; aim 0.6–1.0 mmol/L.',                     category: 'lab',     recurring: { everyDays: 90 } },
      { dayOffset: 180, label: 'U&E + TFT',      detail: '6-monthly renal + thyroid review.',                                category: 'lab',     recurring: { everyDays: 180 } },
    ],
  },

  valproate: {
    baseline: [
      { dayOffset: 0, label: 'LFT',  detail: 'Baseline AST/ALT (hepatotoxicity risk).',                                       category: 'lab',     citation: 'maudsley15_mood_valproate' },
      { dayOffset: 0, label: 'FBC',  detail: 'Baseline platelets (thrombocytopenia risk).',                                   category: 'lab' },
      { dayOffset: 0, label: 'βHCG', detail: 'Pregnancy test — valproate is teratogenic.',                                    category: 'lab' },
    ],
    ongoing: [
      { dayOffset: 30,  label: 'LFT + FBC',     detail: '4-week LFT + platelet check.',                                       category: 'lab' },
      { dayOffset: 180, label: 'Level + LFT',   detail: '6-monthly level + LFTs.',                                           category: 'lab',     recurring: { everyDays: 180 } },
    ],
  },

  carbamazepine: {
    baseline: [
      { dayOffset: 0, label: 'FBC + LFT', detail: 'Baseline (agranulocytosis, hepatitis).',                                  category: 'lab',     citation: 'maudsley15_mood_carbamazepine' },
      { dayOffset: 0, label: 'U&E',       detail: 'Baseline (SIADH risk).',                                                  category: 'lab' },
    ],
    ongoing: [
      { dayOffset: 14, label: 'FBC + LFT', detail: 'Week-2 check; repeat at week 4.',                                       category: 'lab' },
      { dayOffset: 28, label: 'Level',     detail: 'CBZ level once auto-induction stabilises (~2 weeks at steady dose).',    category: 'lab' },
    ],
  },

  lamotrigine: {
    baseline: [],
    ongoing: [
      { dayOffset: 14, label: 'Skin review', detail: 'Counsel + review for SJS/TEN — first 8 weeks.', category: 'review' },
    ],
  },

  // ── Antipsychotics ──
  clozapine: {
    baseline: [
      { dayOffset: 0, label: 'FBC',         detail: 'Baseline ANC ≥2.0 required to start.',                                  category: 'lab',     citation: 'maudsley15_clozapine_monitoring' },
      { dayOffset: 0, label: 'ECG',         detail: 'Baseline ECG (myocarditis screening).',                                category: 'ecg' },
      { dayOffset: 0, label: 'Trop + CRP',  detail: 'Baseline trop/CRP (myocarditis screening).',                           category: 'lab' },
      { dayOffset: 0, label: 'BMI + lipids', detail: 'Metabolic baseline.',                                                  category: 'physical' },
    ],
    ongoing: [
      { dayOffset: 7,   label: 'Weekly FBC', detail: 'Weekly FBC weeks 1–18.',     category: 'lab', recurring: { everyDays: 7,  untilDay: 126 }, citation: 'maudsley15_clozapine_monitoring' },
      { dayOffset: 7,   label: 'Trop + CRP', detail: 'Weekly trop/CRP weeks 1–4.', category: 'lab', recurring: { everyDays: 7,  untilDay: 28 } },
      { dayOffset: 126, label: 'Fortnightly FBC', detail: 'Fortnightly FBC weeks 19–52.', category: 'lab', recurring: { everyDays: 14, untilDay: 365 } },
    ],
  },

  olanzapine: {
    baseline: [
      { dayOffset: 0, label: 'BMI + waist', detail: 'Metabolic baseline.',                                                   category: 'physical', citation: 'maudsley15_aps_metabolic' },
      { dayOffset: 0, label: 'HbA1c + lipids', detail: 'Baseline glucose + lipids.',                                         category: 'lab' },
    ],
    ongoing: [
      { dayOffset: 30,  label: 'Weight',         detail: '4-week weight + side-effect review.',                              category: 'physical' },
      { dayOffset: 90,  label: 'HbA1c + lipids', detail: '3-monthly metabolic for first year.',                              category: 'lab',     recurring: { everyDays: 90, untilDay: 365 } },
    ],
  },

  quetiapine: {
    baseline: [
      { dayOffset: 0, label: 'BMI + lipids', detail: 'Metabolic baseline.',                                                  category: 'physical' },
    ],
    ongoing: [
      { dayOffset: 90, label: 'HbA1c + lipids', detail: '3-monthly metabolic.', category: 'lab', recurring: { everyDays: 90, untilDay: 365 } },
    ],
  },

  haloperidol: {
    baseline: [
      { dayOffset: 0, label: 'ECG',  detail: 'Baseline ECG (QTc risk, dose-dependent).',                                     category: 'ecg',     citation: 'maudsley15_aps_qtc' },
      { dayOffset: 0, label: 'ESRS', detail: 'Extrapyramidal symptom rating baseline.',                                      category: 'rating' },
    ],
    ongoing: [
      { dayOffset: 14, label: 'ESRS',     detail: 'Repeat ESRS at week 2.',                                                 category: 'rating' },
      { dayOffset: 30, label: 'ECG (rpt)',detail: 'Repeat ECG at therapeutic dose, then annually.',                          category: 'ecg' },
    ],
  },

  amisulpride: {
    baseline: [
      { dayOffset: 0, label: 'eGFR', detail: 'Renal clearance — adjust dose if reduced.', category: 'lab' },
      { dayOffset: 0, label: 'ECG',  detail: 'Baseline ECG (dose-dependent QTc).',         category: 'ecg' },
    ],
    ongoing: [
      { dayOffset: 30, label: 'ECG', detail: 'Repeat ECG once at target dose if >400 mg/day.', category: 'ecg' },
    ],
  },

  risperidone: {
    baseline: [
      { dayOffset: 0, label: 'Prolactin', detail: 'Baseline prolactin if symptomatic.', category: 'lab' },
    ],
    ongoing: [
      { dayOffset: 90, label: 'Prolactin', detail: '3-monthly prolactin if symptomatic.', category: 'lab' },
    ],
  },

  paliperidone: {
    baseline: [
      { dayOffset: 0, label: 'Prolactin', detail: 'Active metabolite of risperidone — same prolactin profile.', category: 'lab' },
      { dayOffset: 0, label: 'eGFR',      detail: 'Renal clearance — adjust if eGFR <50.',                       category: 'lab' },
    ],
    ongoing: [],
  },

  aripiprazole: {
    baseline: [],
    ongoing: [
      { dayOffset: 14, label: 'Akathisia review', detail: 'Akathisia is the most common dose-limiting AE.', category: 'review' },
    ],
  },

  // ── Antidepressants ──
  // Most ADs need only a 2-week clinical review; the SSRIs flagged for QTc
  // (citalopram, escitalopram) get an ECG at high dose.
  escitalopram: {
    baseline: [],
    ongoing: [
      { dayOffset: 14, label: 'Mood + suicidality', detail: '2-week mood + suicidality review.', category: 'review' },
      { dayOffset: 14, label: 'ECG (if >20 mg)', detail: 'ECG if dose >20 mg/day or cardiac history.', category: 'ecg' },
    ],
  },

  // Generic AD review (used as a fallback when no specific rule)
  // — the engine adds this when an antidepressant is started.
  _AD_GENERIC: {
    baseline: [],
    ongoing: [
      { dayOffset: 14, label: 'Mood + suicidality', detail: '2-week mood + suicidality review.', category: 'review' },
      { dayOffset: 28, label: 'Response check',     detail: '4-week response review (PHQ-9 / HAM-D).',  category: 'rating' },
    ],
  },
};

// Drugs that should fall back to the generic AD bundle if no specific rule.
const ANTIDEPRESSANTS = new Set([
  'fluoxetine', 'sertraline', 'paroxetine', 'fluvoxamine', 'escitalopram',
  'venlafaxine', 'desvenlafaxine', 'duloxetine', 'mirtazapine', 'vortioxetine', 'agomelatine',
]);
const ANTIPSYCHOTICS_BASIC = new Set([
  'sulpiride', 'chlorpromazine', 'trifluoperazine', 'fluphenazine', 'flupenthixol',
  'zuclopenthixol', 'lurasidone',
]);

const _AP_GENERIC: DrugMonitoringRules = {
  baseline: [
    { dayOffset: 0, label: 'BMI + waist',  detail: 'Metabolic baseline (NICE / Maudsley).', category: 'physical' },
    { dayOffset: 0, label: 'HbA1c + lipids', detail: 'Baseline glucose + lipids.',           category: 'lab' },
  ],
  ongoing: [
    { dayOffset: 14, label: 'ESRS / EPS review', detail: '2-week side-effect review.', category: 'review' },
    { dayOffset: 90, label: 'HbA1c + lipids',    detail: '3-monthly first year.',       category: 'lab', recurring: { everyDays: 90, untilDay: 365 } },
  ],
};

// ── Patient-context add-ons ─────────────────────────────────────────────────
// These fire regardless of which drug is being started.

function contextAddOns(ctx: PatientContext): MonitoringEntry[] {
  const out: MonitoringEntry[] = [];

  if (ctx.comorbidities?.cardiac) {
    out.push({
      dayOffset: 0,
      label: 'ECG (cardiac hx)',
      detail: 'Cardiac comorbidity flagged — baseline ECG before any QTc-prolonger.',
      category: 'ecg',
    });
  }
  if (ctx.comorbidities?.diabetes || ctx.comorbidities?.dyslipidemia) {
    out.push({
      dayOffset: 30,
      label: 'HbA1c (metabolic)',
      detail: 'Existing metabolic comorbidity — earlier 4-week HbA1c.',
      category: 'lab',
    });
  }
  if (ctx.pregnant) {
    out.push({
      dayOffset: 0,
      label: 'Antenatal liaison',
      detail: 'Coordinate with obstetrics; review in MDT before any change.',
      category: 'review',
    });
  }
  return out;
}

// ── Generator ───────────────────────────────────────────────────────────────

export interface MonitoringPlan {
  entries: MonitoringEntry[];
  citations: string[];
  /** Total days the plan extends (for calendar rendering). */
  spanDays: number;
}

export function generateMonitoringPlan(opts: {
  toDrugId: string;
  fromDrugId?: string;
  context?: PatientContext;
  durationDays?: number;
}): MonitoringPlan {
  const { toDrugId, context, durationDays = 90 } = opts;
  const all: MonitoringEntry[] = [];

  const addRules = (drugId: string) => {
    const rules = RULES[drugId]
      ?? (ANTIDEPRESSANTS.has(drugId) ? RULES._AD_GENERIC : null)
      ?? (ANTIPSYCHOTICS_BASIC.has(drugId) ? _AP_GENERIC : null);
    if (!rules) return;
    rules.baseline.forEach((e) => all.push({ ...e, drugId }));
    rules.ongoing.forEach((e) => all.push({ ...e, drugId }));
  };

  addRules(toDrugId);
  if (opts.fromDrugId && opts.fromDrugId !== toDrugId) {
    // Add only the from-drug ESRS / mood reviews — not duplicate baseline labs.
    const fromRules = RULES[opts.fromDrugId];
    if (fromRules) {
      fromRules.ongoing
        .filter((e) => e.category === 'rating' || e.category === 'review')
        .forEach((e) => all.push({ ...e, drugId: opts.fromDrugId }));
    }
  }

  if (context) all.push(...contextAddOns(context));

  // Deduplicate by (label + dayOffset) — keep the more detailed entry.
  const seen = new Map<string, MonitoringEntry>();
  for (const e of all) {
    const key = `${e.label}|${e.dayOffset}`;
    const prior = seen.get(key);
    if (!prior || e.detail.length > prior.detail.length) seen.set(key, e);
  }
  const deduped = [...seen.values()];

  // Expand recurring entries up to durationDays.
  const expanded: MonitoringEntry[] = [];
  for (const e of deduped) {
    expanded.push(e);
    if (e.recurring) {
      const stop = Math.min(e.recurring.untilDay ?? durationDays, durationDays);
      for (
        let d = e.dayOffset + e.recurring.everyDays;
        d <= stop;
        d += e.recurring.everyDays
      ) {
        expanded.push({ ...e, dayOffset: d, recurring: undefined });
      }
    }
  }

  expanded.sort((a, b) => a.dayOffset - b.dayOffset || a.label.localeCompare(b.label));

  const citations = Array.from(
    new Set(expanded.map((e) => e.citation).filter((c): c is string => !!c)),
  );

  const spanDays = Math.max(durationDays, ...expanded.map((e) => e.dayOffset), 90);

  return { entries: expanded, citations, spanDays };
}
