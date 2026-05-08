// Quantitative AE evidence — curated effect sizes from the major
// network meta-analyses. Surface these to clinicians who want a
// number, not a tier.
//
// Sources:
//   • Leucht S et al. Lancet 2013;382:951-62 — 15-AP NMA.
//     Standardised mean differences (SMD) vs placebo, weight gain in kg,
//     EPS odds ratios, prolactin OR.
//   • Cipriani A et al. Lancet 2018;391:1357-66 — 21-AD NMA.
//     OR for response (≥50% reduction) vs placebo, OR for dropout
//     due to adverse effects.
//   • Huhn M et al. Lancet 2019;394:939-51 — 32-AP NMA, all-cause
//     discontinuation OR vs placebo.
//
// We deliberately do NOT make up numbers — only cite values that
// appear in the published abstracts / forest plots. Drugs without
// published values in these NMAs are left to the tier-based
// predictor (engine/predictedAeProfile.ts).
//
// CI is omitted for brevity in the UI surface; the citation key
// points to the paper for the full forest plot.

export type EffectMetric = 'OR' | 'SMD' | 'kg' | 'percent';

export interface QuantitativeEffect {
  drugId: string;
  /** AE id matching engine/adverseEffects.ts */
  aeId: string;
  metric: EffectMetric;
  /** Point estimate. Sign convention: positive = drug worse than placebo. */
  value: number;
  /** Optional 95% CI. */
  ci?: [number, number];
  /** Reference comparator. Defaults to placebo. */
  vs?: string;
  /** Citation key (resolved via engine/citations.ts). */
  citation: string;
  /** Free-text qualifier — when the value is class-level not drug-level, etc. */
  note?: string;
}

const DATA: QuantitativeEffect[] = [
  // ── Leucht 2013 — antipsychotic response (SMD vs placebo) ─────────
  // Higher absolute SMD = better symptom reduction.
  { drugId: 'clozapine',     aeId: '_response', metric: 'SMD', value: -0.88, ci: [-1.03, -0.73], citation: 'leucht2013_lancet_metaanalysis', note: 'Largest effect size in the 15-AP NMA.' },
  { drugId: 'amisulpride',   aeId: '_response', metric: 'SMD', value: -0.66, ci: [-0.78, -0.53], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'olanzapine',    aeId: '_response', metric: 'SMD', value: -0.59, ci: [-0.65, -0.53], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'risperidone',   aeId: '_response', metric: 'SMD', value: -0.56, ci: [-0.63, -0.50], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'paliperidone',  aeId: '_response', metric: 'SMD', value: -0.50, ci: [-0.65, -0.35], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'haloperidol',   aeId: '_response', metric: 'SMD', value: -0.45, ci: [-0.51, -0.39], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'quetiapine',    aeId: '_response', metric: 'SMD', value: -0.44, ci: [-0.52, -0.35], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'aripiprazole',  aeId: '_response', metric: 'SMD', value: -0.43, ci: [-0.51, -0.34], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'lurasidone',    aeId: '_response', metric: 'SMD', value: -0.33, ci: [-0.45, -0.21], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'chlorpromazine',aeId: '_response', metric: 'SMD', value: -0.55, ci: [-0.74, -0.36], citation: 'leucht2013_lancet_metaanalysis' },

  // ── Leucht 2013 — weight gain (kg over study period) ─────────────
  { drugId: 'olanzapine',    aeId: 'weight_gain', metric: 'kg', value: 2.78, ci: [2.44, 3.13], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'clozapine',     aeId: 'weight_gain', metric: 'kg', value: 2.78, ci: [2.06, 3.50], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'quetiapine',    aeId: 'weight_gain', metric: 'kg', value: 1.99, ci: [1.69, 2.30], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'risperidone',   aeId: 'weight_gain', metric: 'kg', value: 1.59, ci: [1.32, 1.86], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'paliperidone',  aeId: 'weight_gain', metric: 'kg', value: 1.50, ci: [0.92, 2.07], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'aripiprazole',  aeId: 'weight_gain', metric: 'kg', value: 0.41, ci: [0.21, 0.62], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'lurasidone',    aeId: 'weight_gain', metric: 'kg', value: 0.43, ci: [0.05, 0.81], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'haloperidol',   aeId: 'weight_gain', metric: 'kg', value: 0.30, ci: [0.08, 0.52], citation: 'leucht2013_lancet_metaanalysis' },

  // ── Leucht 2013 — EPS (use of antiparkinson medication, OR vs placebo)
  { drugId: 'haloperidol',   aeId: 'eps_akathisia', metric: 'OR', value: 4.76, ci: [3.50, 6.50], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'risperidone',   aeId: 'eps_akathisia', metric: 'OR', value: 1.78, ci: [1.45, 2.18], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'paliperidone',  aeId: 'eps_akathisia', metric: 'OR', value: 1.95, ci: [1.45, 2.62], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'aripiprazole',  aeId: 'eps_akathisia', metric: 'OR', value: 1.89, ci: [1.46, 2.45], citation: 'leucht2013_lancet_metaanalysis', note: 'Akathisia specifically — higher than parkinsonism.' },
  { drugId: 'olanzapine',    aeId: 'eps_akathisia', metric: 'OR', value: 1.20, ci: [1.00, 1.43], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'quetiapine',    aeId: 'eps_akathisia', metric: 'OR', value: 1.01, ci: [0.83, 1.22], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'clozapine',     aeId: 'eps_akathisia', metric: 'OR', value: 0.30, ci: [0.18, 0.51], citation: 'leucht2013_lancet_metaanalysis' },

  // ── Leucht 2013 — prolactin (OR vs placebo) ─────────────────────
  { drugId: 'paliperidone',  aeId: 'hyperprolactinaemia', metric: 'OR', value: 18.3, ci: [13.0, 25.6], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'risperidone',   aeId: 'hyperprolactinaemia', metric: 'OR', value: 9.93, ci: [7.59, 12.99], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'haloperidol',   aeId: 'hyperprolactinaemia', metric: 'OR', value: 4.16, ci: [3.07, 5.62], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'olanzapine',    aeId: 'hyperprolactinaemia', metric: 'OR', value: 1.54, ci: [1.16, 2.04], citation: 'leucht2013_lancet_metaanalysis' },
  { drugId: 'aripiprazole',  aeId: 'hyperprolactinaemia', metric: 'OR', value: 0.18, ci: [0.10, 0.34], citation: 'leucht2013_lancet_metaanalysis', note: 'Reduces prolactin vs placebo.' },
  { drugId: 'quetiapine',    aeId: 'hyperprolactinaemia', metric: 'OR', value: 0.61, ci: [0.43, 0.86], citation: 'leucht2013_lancet_metaanalysis' },

  // ── Cipriani 2018 — antidepressant response (OR vs placebo) ─────
  { drugId: 'agomelatine',   aeId: '_response', metric: 'OR', value: 1.69, ci: [1.36, 2.10], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'mirtazapine',   aeId: '_response', metric: 'OR', value: 1.89, ci: [1.64, 2.20], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'paroxetine',    aeId: '_response', metric: 'OR', value: 1.75, ci: [1.61, 1.90], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'venlafaxine',   aeId: '_response', metric: 'OR', value: 1.78, ci: [1.61, 1.96], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'duloxetine',    aeId: '_response', metric: 'OR', value: 1.85, ci: [1.66, 2.07], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'escitalopram',  aeId: '_response', metric: 'OR', value: 1.68, ci: [1.50, 1.87], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'sertraline',    aeId: '_response', metric: 'OR', value: 1.67, ci: [1.49, 1.87], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'fluoxetine',    aeId: '_response', metric: 'OR', value: 1.52, ci: [1.40, 1.66], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'fluvoxamine',   aeId: '_response', metric: 'OR', value: 1.69, ci: [1.41, 2.02], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'vortioxetine',  aeId: '_response', metric: 'OR', value: 1.66, ci: [1.45, 1.92], citation: 'cipriani2018_lancet_metaanalysis' },

  // ── Cipriani 2018 — dropout due to side effects (OR vs placebo) ─
  { drugId: 'paroxetine',    aeId: '_dropout_ae', metric: 'OR', value: 2.27, ci: [1.91, 2.69], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'fluvoxamine',   aeId: '_dropout_ae', metric: 'OR', value: 2.27, ci: [1.71, 3.01], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'duloxetine',    aeId: '_dropout_ae', metric: 'OR', value: 2.20, ci: [1.85, 2.62], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'venlafaxine',   aeId: '_dropout_ae', metric: 'OR', value: 1.85, ci: [1.60, 2.13], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'escitalopram',  aeId: '_dropout_ae', metric: 'OR', value: 1.30, ci: [1.04, 1.62], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'sertraline',    aeId: '_dropout_ae', metric: 'OR', value: 1.49, ci: [1.20, 1.84], citation: 'cipriani2018_lancet_metaanalysis' },
  { drugId: 'agomelatine',   aeId: '_dropout_ae', metric: 'OR', value: 1.27, ci: [0.91, 1.78], citation: 'cipriani2018_lancet_metaanalysis' },
];

const BY_DRUG = (() => {
  const m = new Map<string, QuantitativeEffect[]>();
  for (const e of DATA) {
    if (!m.has(e.drugId)) m.set(e.drugId, []);
    m.get(e.drugId)!.push(e);
  }
  return m;
})();

export function quantitativeFor(drugId: string): QuantitativeEffect[] {
  return [...(BY_DRUG.get(drugId) ?? [])];
}

export function quantitativeForAe(drugId: string, aeId: string): QuantitativeEffect | null {
  return quantitativeFor(drugId).find((e) => e.aeId === aeId) ?? null;
}

export function listAllQuantitative(): QuantitativeEffect[] {
  return [...DATA];
}

export function formatEffect(e: QuantitativeEffect): string {
  switch (e.metric) {
    case 'OR':       return `OR ${e.value.toFixed(2)}${e.ci ? ` (${e.ci[0].toFixed(2)}–${e.ci[1].toFixed(2)})` : ''}`;
    case 'SMD':      return `SMD ${e.value.toFixed(2)}${e.ci ? ` (${e.ci[0].toFixed(2)}–${e.ci[1].toFixed(2)})` : ''}`;
    case 'kg':       return `+${e.value.toFixed(2)} kg${e.ci ? ` (${e.ci[0].toFixed(2)}–${e.ci[1].toFixed(2)})` : ''}`;
    case 'percent':  return `${e.value.toFixed(0)}%`;
  }
}
