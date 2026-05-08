// Pediatric specialty matrix.
//
// Per-drug guidance for the pediatric subgroup (age <18). Most
// psychotropics are off-label below 18 — we surface licensing status,
// any age-specific approvals, and dose-modification hints.
//
// Drawn from:
//   • Maudsley 15th ed., chapter 7 (Children + adolescents)
//   • NICE NG134 (Depression in children)
//   • FDA / EMA labelling
//   • IACAPAP textbook of child + adolescent psychiatry
//
// Tiers:
//   • preferred  — first-line, on-label or strong evidence in this age
//   • acceptable — usable; off-label but with reasonable evidence
//   • caution    — use only with specialist input
//   • avoid      — risk-benefit unfavourable in this age group

import type { PediatricEntry, SpecialtyTier } from './types';

const ENTRIES: PediatricEntry[] = [
  // ── Antidepressants ─────────────────────────────────────────────
  {
    drugId: 'fluoxetine',
    tier: 'preferred',
    licensedFrom: 8,
    licensedFor: 'Major depressive disorder',
    doseFactor: 0.5,
    rationale: 'Only SSRI with NICE-recommended efficacy for paediatric depression. First-line.',
    citations: ['maudsley15_ch7_ssri', 'nice_ng134'],
  },
  {
    drugId: 'sertraline',
    tier: 'acceptable',
    licensedFrom: 6,
    licensedFor: 'OCD only (UK / FDA)',
    doseFactor: 0.5,
    rationale: 'On-label for paediatric OCD ≥6 yrs. Off-label for depression.',
    citations: ['maudsley15_ch7_ssri'],
  },
  {
    drugId: 'fluvoxamine',
    tier: 'acceptable',
    licensedFrom: 8,
    licensedFor: 'OCD (US)',
    doseFactor: 0.5,
    rationale: 'On-label for paediatric OCD in US. Off-label elsewhere.',
    citations: ['maudsley15_ch7_ssri'],
  },
  {
    drugId: 'escitalopram',
    tier: 'acceptable',
    licensedFrom: 12,
    licensedFor: 'MDD (FDA from 12 yrs)',
    doseFactor: 0.5,
    rationale: 'FDA-approved for adolescent MDD. NICE prefers fluoxetine.',
    citations: ['maudsley15_ch7_ssri'],
  },
  {
    drugId: 'paroxetine',
    tier: 'avoid',
    licensedFrom: null,
    licensedFor: null,
    rationale: 'Increased suicidality signal in trials; severe withdrawal. Not recommended.',
    citations: ['maudsley15_ch7_ssri', 'mhra_paroxetine_paeds'],
  },
  {
    drugId: 'venlafaxine',
    tier: 'caution',
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale: 'Off-label. Suicidality signal in trials. Specialist input.',
    citations: ['maudsley15_ch7_other'],
  },
  {
    drugId: 'mirtazapine',
    tier: 'caution',
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale: 'Off-label paediatric depression. Sometimes used for sleep / appetite stimulation.',
    citations: ['maudsley15_ch7_other'],
  },
  {
    drugId: 'duloxetine',
    tier: 'caution',
    licensedFrom: 7,
    licensedFor: 'GAD (FDA 7-17)',
    doseFactor: 0.5,
    rationale: 'On-label for paediatric GAD (FDA). Off-label elsewhere.',
    citations: ['maudsley15_ch7_other'],
  },
  {
    drugId: 'desvenlafaxine',
    tier: 'caution',
    licensedFrom: null,
    licensedFor: null,
    rationale: 'Limited paediatric data. Off-label.',
    citations: ['maudsley15_ch7_other'],
  },
  {
    drugId: 'agomelatine',
    tier: 'avoid',
    licensedFrom: null,
    licensedFor: null,
    rationale: 'Hepatotoxicity risk + limited paediatric data. Not recommended <18.',
    citations: ['maudsley15_ch7_other'],
  },
  {
    drugId: 'vortioxetine',
    tier: 'caution',
    licensedFrom: null,
    licensedFor: null,
    rationale: 'Insufficient paediatric data. Off-label.',
    citations: ['maudsley15_ch7_other'],
  },
  {
    drugId: 'phenelzine',
    tier: 'avoid',
    licensedFrom: null,
    licensedFor: null,
    rationale: 'MAOI: dietary + drug interactions impractical for children.',
    citations: ['maudsley15_ch7_maoi'],
  },
  {
    drugId: 'tranylcypromine',
    tier: 'avoid',
    licensedFrom: null,
    licensedFor: null,
    rationale: 'Same as phenelzine.',
    citations: ['maudsley15_ch7_maoi'],
  },
  {
    drugId: 'moclobemide',
    tier: 'avoid',
    licensedFrom: null,
    licensedFor: null,
    rationale: 'Limited paediatric data. Other agents preferred.',
    citations: ['maudsley15_ch7_maoi'],
  },

  // ── Antipsychotics ────────────────────────────────────────────
  {
    drugId: 'risperidone',
    tier: 'preferred',
    licensedFrom: 5,
    licensedFor: 'Conduct/aggression (autism), bipolar mania, schizophrenia (≥13)',
    doseFactor: 0.5,
    rationale: 'Most paediatric data among SGAs. Approved for autism-related irritability ≥5.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'aripiprazole',
    tier: 'preferred',
    licensedFrom: 6,
    licensedFor: 'Tourette syndrome, autism irritability, schizophrenia/bipolar (≥13)',
    doseFactor: 0.5,
    rationale: 'Lower metabolic profile preferred for paediatrics. Watch akathisia.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'olanzapine',
    tier: 'caution',
    licensedFrom: 13,
    licensedFor: 'Schizophrenia / bipolar mania (FDA ≥13)',
    doseFactor: 0.5,
    rationale: 'Highest metabolic burden — only when alternatives fail.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'quetiapine',
    tier: 'acceptable',
    licensedFrom: 13,
    licensedFor: 'Schizophrenia / bipolar (FDA ≥13)',
    doseFactor: 0.25,
    rationale: 'Common adolescent prescription. Sedation + metabolic monitoring needed.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'paliperidone',
    tier: 'acceptable',
    licensedFrom: 12,
    licensedFor: 'Schizophrenia (FDA ≥12)',
    doseFactor: 0.5,
    rationale: 'On-label for paediatric schizophrenia. Same prolactin profile as risperidone.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'haloperidol',
    tier: 'caution',
    licensedFrom: 3,
    licensedFor: 'Tourette, severe behavioural disorders',
    doseFactor: 0.25,
    rationale: 'EPS rises sharply with paediatric dosing. Use lowest effective dose.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'amisulpride',
    tier: 'caution',
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale: 'Off-label paediatric. Limited evidence.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'sulpiride',
    tier: 'caution',
    licensedFrom: 14,
    licensedFor: 'Schizophrenia (UK label)',
    doseFactor: 0.5,
    rationale: 'UK label permits adolescent use. Less Asian data.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'clozapine',
    tier: 'caution',
    licensedFrom: 16,
    licensedFor: 'Treatment-resistant schizophrenia (UK from 16)',
    doseFactor: 0.5,
    rationale: 'Specialist initiation only. Same FBC monitoring as adults.',
    citations: ['maudsley15_ch7_clozapine'],
  },
  {
    drugId: 'lurasidone',
    tier: 'acceptable',
    licensedFrom: 13,
    licensedFor: 'Schizophrenia (FDA ≥13), bipolar depression (FDA ≥10)',
    doseFactor: 0.5,
    rationale: 'Favourable metabolic profile. Take with food (≥350 kcal).',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'chlorpromazine',
    tier: 'caution',
    licensedFrom: 1,
    licensedFor: 'Severe behavioural disturbance',
    doseFactor: 0.25,
    rationale: 'Old drug, anticholinergic burden. Modern alternatives preferred.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'trifluoperazine',
    tier: 'caution',
    licensedFrom: 3,
    licensedFor: 'Severe behavioural disturbance',
    doseFactor: 0.25,
    rationale: 'High EPS in this age group. Specialist use only.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'fluphenazine',
    tier: 'caution',
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale: 'Off-label paediatric. Depot considerations.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'flupenthixol',
    tier: 'caution',
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale: 'Off-label paediatric.',
    citations: ['maudsley15_ch7_ap'],
  },
  {
    drugId: 'zuclopenthixol',
    tier: 'caution',
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale: 'Off-label paediatric.',
    citations: ['maudsley15_ch7_ap'],
  },

  // ── Mood stabilisers ─────────────────────────────────────────
  {
    drugId: 'lithium',
    tier: 'acceptable',
    licensedFrom: 12,
    licensedFor: 'Bipolar mania (FDA ≥12)',
    doseFactor: 0.5,
    rationale: 'On-label for paediatric mania. Renal + thyroid monitoring as for adults.',
    citations: ['maudsley15_ch7_mood'],
  },
  {
    drugId: 'valproate',
    tier: 'avoid',
    licensedFrom: null,
    licensedFor: null,
    rationale: 'Contraindicated in females of reproductive age (PPP). Fewer options for males but lamotrigine preferred.',
    citations: ['maudsley15_ch7_mood', 'mhra_valproate_ppp'],
  },
  {
    drugId: 'lamotrigine',
    tier: 'acceptable',
    licensedFrom: 2,
    licensedFor: 'Epilepsy ≥2; bipolar maintenance off-label in <18',
    doseFactor: 0.5,
    rationale: 'On-label for epilepsy from age 2. Off-label for bipolar in <18.',
    citations: ['maudsley15_ch7_mood'],
  },
  {
    drugId: 'carbamazepine',
    tier: 'acceptable',
    licensedFrom: 0,
    licensedFor: 'Epilepsy any age; bipolar off-label in <18',
    doseFactor: 0.5,
    rationale: 'Long-established paediatric anticonvulsant.',
    citations: ['maudsley15_ch7_mood'],
  },
];

const INDEX = new Map<string, PediatricEntry>(ENTRIES.map((e) => [e.drugId, e]));

export function pediatricEntryFor(drugId: string): PediatricEntry | null {
  return INDEX.get(drugId) ?? null;
}

export function pediatricTierFor(drugId: string, ageYears?: number): SpecialtyTier | null {
  const entry = INDEX.get(drugId);
  if (!entry) return null;
  // If we have an age and the drug is licensed at or below it, bump tier
  // up by one notch (avoid → caution, caution → acceptable).
  if (
    ageYears != null &&
    entry.licensedFrom != null &&
    ageYears >= entry.licensedFrom
  ) {
    if (entry.tier === 'avoid') return 'caution';
    if (entry.tier === 'caution') return 'acceptable';
  }
  return entry.tier;
}

export function listPediatricEntries(): PediatricEntry[] {
  return [...ENTRIES];
}
