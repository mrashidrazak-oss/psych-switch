// Adverse-effect reverse lookup.
//
// Clinical reality: the question is rarely "switch X to Y" — it's
// "patient on X has problem Z, what should I switch to?". This module
// answers that.
//
// For each common adverse effect, we list:
//   • drugs likely to cause it (so the clinician can identify the culprit)
//   • drugs unlikely to cause it (candidate switch targets)
//   • brief management notes
//
// Sources
//   • Maudsley 15th, side-effect tables per chapter
//   • Leucht 2013 Lancet network meta-analysis (antipsychotic AEs)
//   • Cipriani 2018 Lancet network meta-analysis (antidepressant AEs)

export type AdverseEffectCategory =
  | 'metabolic'
  | 'extrapyramidal'
  | 'sexual'
  | 'sedation'
  | 'cardiovascular'
  | 'gastrointestinal'
  | 'hematologic'
  | 'cognitive'
  | 'discontinuation';

export interface AdverseEffect {
  id: string;
  category: AdverseEffectCategory;
  /** Patient-friendly label ("Weight gain"). */
  label: string;
  /** One-line description shown in the picker. */
  summary: string;
  /** Drug IDs that commonly cause this AE. */
  causedBy: string[];
  /** Drug IDs that rarely cause this AE — candidate switch targets. */
  switchCandidates: string[];
  /** Free-form management tip ("first try dose reduction"). */
  management: string;
  citations: string[];
}

export const ADVERSE_EFFECTS: AdverseEffect[] = [
  // ── Antipsychotic AEs ──
  {
    id: 'weight_gain',
    category: 'metabolic',
    label: 'Weight gain / metabolic syndrome',
    summary: 'Weight gain, dyslipidemia or new diabetes on an antipsychotic.',
    causedBy: ['olanzapine', 'clozapine', 'quetiapine', 'chlorpromazine', 'risperidone', 'paliperidone'],
    switchCandidates: ['aripiprazole', 'lurasidone', 'amisulpride', 'haloperidol'],
    management:
      'First: dose review + metformin + lifestyle. If sustained ≥7% weight gain → switch (Maudsley algorithm).',
    citations: [
      'Leucht S, et al. Comparative efficacy and tolerability of 15 antipsychotic drugs. Lancet 2013;382:951–62.',
      'Maudsley Prescribing Guidelines, 15th ed. Table 4.16.',
    ],
  },
  {
    id: 'eps_akathisia',
    category: 'extrapyramidal',
    label: 'EPS / akathisia',
    summary: 'Parkinsonism, dystonia, akathisia, tardive dyskinesia.',
    causedBy: ['haloperidol', 'risperidone', 'paliperidone', 'fluphenazine', 'trifluoperazine', 'aripiprazole', 'amisulpride'],
    switchCandidates: ['olanzapine', 'quetiapine', 'clozapine', 'lurasidone'],
    management:
      'Akathisia → propranolol 20–80 mg or mirtazapine 15 mg. Parkinsonism → reduce dose or anticholinergic. Tardive → switch to clozapine.',
    citations: ['maudsley15_eps_management'],
  },
  {
    id: 'hyperprolactinaemia',
    category: 'sexual',
    label: 'Hyperprolactinaemia',
    summary: 'Galactorrhoea, amenorrhoea, sexual dysfunction, low libido.',
    causedBy: ['risperidone', 'paliperidone', 'amisulpride', 'sulpiride', 'haloperidol'],
    switchCandidates: ['aripiprazole', 'quetiapine', 'olanzapine', 'clozapine'],
    management:
      'Confirm prolactin >1000 mIU/L is drug-related. Aripiprazole adjunct (5–15 mg) often normalises levels without switch.',
    citations: ['maudsley15_prolactin'],
  },
  {
    id: 'sedation',
    category: 'sedation',
    label: 'Sedation / cognitive blunting',
    summary: 'Excess somnolence, daytime drowsiness or "feeling flat".',
    causedBy: ['olanzapine', 'quetiapine', 'clozapine', 'chlorpromazine', 'mirtazapine'],
    switchCandidates: ['aripiprazole', 'lurasidone', 'amisulpride', 'haloperidol'],
    management:
      'Try once-daily nocte dosing first. If persistent, switch to a less sedating agent.',
    citations: ['maudsley15_sedation'],
  },
  {
    id: 'qtc_prolongation',
    category: 'cardiovascular',
    label: 'QTc prolongation',
    summary: 'QTc >450 ms (M) or >470 ms (F), or rising on serial ECG.',
    causedBy: ['haloperidol', 'sulpiride', 'amisulpride', 'chlorpromazine', 'citalopram', 'escitalopram'],
    switchCandidates: ['aripiprazole', 'olanzapine', 'lurasidone', 'sertraline'],
    management:
      'Stop QT-prolonger if QTc >500 ms. Correct K⁺/Mg²⁺. Switch to lowest-risk agent.',
    citations: ['maudsley15_qtc'],
  },

  // ── Antidepressant AEs ──
  {
    id: 'ssri_sexual',
    category: 'sexual',
    label: 'SSRI sexual dysfunction',
    summary: 'Anorgasmia, ↓libido, erectile dysfunction.',
    causedBy: ['paroxetine', 'sertraline', 'fluoxetine', 'fluvoxamine', 'escitalopram', 'venlafaxine'],
    switchCandidates: ['mirtazapine', 'agomelatine', 'vortioxetine'],
    management:
      'First: dose reduction or drug holiday. PDE5 inhibitor adjunct in men. Switch if persistent ≥4 weeks.',
    citations: ['maudsley15_sexual_ad'],
  },
  {
    id: 'gi_nausea',
    category: 'gastrointestinal',
    label: 'GI nausea / dyspepsia',
    summary: 'Persistent nausea, dyspepsia, diarrhoea on starting an antidepressant.',
    causedBy: ['sertraline', 'fluvoxamine', 'venlafaxine', 'duloxetine'],
    switchCandidates: ['mirtazapine', 'escitalopram', 'agomelatine'],
    management:
      'Most resolve in 1–2 weeks. Take with food. If persistent → switch.',
    citations: [],
  },
  {
    id: 'discontinuation_difficult',
    category: 'discontinuation',
    label: 'Difficult discontinuation',
    summary: 'Severe rebound symptoms on missed dose or stopping.',
    causedBy: ['paroxetine', 'venlafaxine', 'duloxetine'],
    switchCandidates: ['fluoxetine'],
    management:
      'Bridge with fluoxetine (long t½ self-tapers) — Maudsley discontinuation algorithm.',
    citations: ['maudsley15_discontinuation'],
  },
  {
    id: 'insomnia',
    category: 'sedation',
    label: 'Insomnia / activation',
    summary: 'Initial insomnia or activation on starting an SSRI/SNRI.',
    causedBy: ['fluoxetine', 'venlafaxine', 'desvenlafaxine', 'sertraline'],
    switchCandidates: ['mirtazapine', 'agomelatine', 'paroxetine'],
    management:
      'Dose in the morning. If persistent → switch to a sedating agent (mirtazapine) or trazodone adjunct.',
    citations: [],
  },

  // ── Mood stabilizer AEs ──
  {
    id: 'lithium_toxicity',
    category: 'cognitive',
    label: 'Lithium tremor / cognitive blunting',
    summary: 'Fine tremor, "fogginess", or rising creatinine on lithium.',
    causedBy: ['lithium'],
    switchCandidates: ['valproate', 'lamotrigine', 'quetiapine'],
    management:
      'First: check level (target 0.6–0.8 in maintenance). If ≤0.8 and symptomatic, consider alternative mood stabilizer.',
    citations: ['maudsley15_lithium_tox'],
  },
  {
    id: 'valproate_teratogenicity',
    category: 'metabolic',
    label: 'Valproate in woman of reproductive age',
    summary: 'Patient on valproate becomes pregnant or planning pregnancy.',
    causedBy: ['valproate'],
    switchCandidates: ['lamotrigine', 'lithium', 'quetiapine'],
    management:
      'Urgent switch off valproate. Lamotrigine is preferred for bipolar maintenance in pregnancy (with folate 5 mg).',
    citations: ['maudsley15_valproate_pregnancy'],
  },
];

/**
 * Filter adverse effects by category.
 */
export function listByCategory(): Record<AdverseEffectCategory, AdverseEffect[]> {
  const out: Record<string, AdverseEffect[]> = {};
  for (const ae of ADVERSE_EFFECTS) {
    (out[ae.category] ??= []).push(ae);
  }
  return out as Record<AdverseEffectCategory, AdverseEffect[]>;
}

/**
 * Find the AE entry for a given drug + category — used by other engines
 * to surface a "this is a known issue" badge.
 */
export function findAeFor(drugId: string, category?: AdverseEffectCategory): AdverseEffect[] {
  return ADVERSE_EFFECTS.filter(
    (ae) => ae.causedBy.includes(drugId) && (!category || ae.category === category),
  );
}

export const CATEGORY_LABELS: Record<AdverseEffectCategory, string> = {
  metabolic:       'Metabolic',
  extrapyramidal:  'Extrapyramidal',
  sexual:          'Sexual / endocrine',
  sedation:        'Sedation / activation',
  cardiovascular:  'Cardiovascular',
  gastrointestinal:'Gastrointestinal',
  hematologic:     'Haematologic',
  cognitive:       'Cognitive',
  discontinuation: 'Discontinuation',
};
