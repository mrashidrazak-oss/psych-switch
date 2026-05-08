// Geriatric specialty matrix.
//
// Per-drug guidance for the older-adult subgroup (age ≥65), drawn from:
//   • Maudsley 15th ed., chapter 9 (Older adults)
//   • Beers Criteria 2023 (potentially inappropriate medications)
//   • STOPP/START v3 (2023)
//   • BAP 2021 (older adults consensus)
//
// Each entry carries:
//   • tier — overall ranking for use in this subgroup
//   • doseFactor — multiplier for adult target dose ("start at 50%")
//   • fallsRisk — composite of sedation + orthostasis + EPS
//   • cognitiveRisk — anticholinergic + sedation contribution
//   • rationale + citations
//
// The orchestrator (engine/specialty.ts) consults this when the
// patient's ageBand resolves to 'older_adult'.

import type { GeriatricEntry, SpecialtyTier } from './types';

const ENTRIES: GeriatricEntry[] = [
  // ── Antidepressants ─────────────────────────────────────────────
  {
    drugId: 'sertraline',
    tier: 'preferred',
    doseFactor: 0.5,
    fallsRisk: 'low',
    cognitiveRisk: 'low',
    rationale: 'Cleanest profile for older adults. Few CYP interactions, low anticholinergic.',
    citations: ['maudsley15_ch9_ad', 'beers_2023'],
  },
  {
    drugId: 'escitalopram',
    tier: 'preferred',
    doseFactor: 0.5,
    fallsRisk: 'low',
    cognitiveRisk: 'low',
    rationale: 'Cap at 10 mg/day in older adults due to QTc concerns. Otherwise well tolerated.',
    citations: ['maudsley15_ch9_ad', 'beers_2023'],
  },
  {
    drugId: 'fluoxetine',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'low',
    cognitiveRisk: 'low',
    rationale: 'Long t½ + active metabolite makes dose adjustment slow in this group.',
    citations: ['maudsley15_ch9_ad'],
  },
  {
    drugId: 'paroxetine',
    tier: 'avoid',
    doseFactor: 0.5,
    fallsRisk: 'high',
    cognitiveRisk: 'high',
    rationale: 'Highest anticholinergic load among SSRIs — Beers list. Severe discontinuation.',
    citations: ['beers_2023'],
  },
  {
    drugId: 'fluvoxamine',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'low',
    cognitiveRisk: 'moderate',
    rationale: 'Strong CYP1A2 inhibition raises risk in poly-pharmacy. GI tolerability variable.',
    citations: ['maudsley15_ch9_ad'],
  },
  {
    drugId: 'mirtazapine',
    tier: 'preferred',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'low',
    rationale: 'Often preferred — appetite stimulant + hypnotic effect helps frail elderly.',
    citations: ['maudsley15_ch9_ad'],
  },
  {
    drugId: 'venlafaxine',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'low',
    rationale: 'Hypertension and dose-related discontinuation risk. Cap at 150 mg in CKD-prone elderly.',
    citations: ['maudsley15_ch9_ad'],
  },
  {
    drugId: 'desvenlafaxine',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'low',
    rationale: 'Like venlafaxine — hypertension + discontinuation. Renal clearance.',
    citations: ['maudsley15_ch9_ad'],
  },
  {
    drugId: 'duloxetine',
    tier: 'acceptable',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'low',
    rationale: 'Useful when comorbid neuropathic pain. LFT monitoring.',
    citations: ['maudsley15_ch9_ad'],
  },
  {
    drugId: 'agomelatine',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'low',
    cognitiveRisk: 'low',
    rationale: 'Hepatic monitoring burden grows with age + polypharmacy.',
    citations: ['maudsley15_ch9_ad'],
  },
  {
    drugId: 'vortioxetine',
    tier: 'acceptable',
    doseFactor: 0.5,
    fallsRisk: 'low',
    cognitiveRisk: 'low',
    rationale: 'Cognitive-sparing data in older adults. CYP2D6 substrate — adjust with strong inhibitors.',
    citations: ['maudsley15_ch9_ad'],
  },

  // ── MAOIs (avoid in older adults) ──
  {
    drugId: 'phenelzine',
    tier: 'avoid',
    doseFactor: 0.5,
    fallsRisk: 'very high',
    cognitiveRisk: 'high',
    rationale: 'Orthostatic hypotension + dietary tyramine restriction — high adherence burden.',
    citations: ['beers_2023'],
  },
  {
    drugId: 'tranylcypromine',
    tier: 'avoid',
    doseFactor: 0.5,
    fallsRisk: 'very high',
    cognitiveRisk: 'high',
    rationale: 'Same as phenelzine. Stimulant effect can complicate cardiac comorbidity.',
    citations: ['beers_2023'],
  },
  {
    drugId: 'moclobemide',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'low',
    rationale: 'Reversible MAOI; safer than irreversibles but less data in elderly.',
    citations: ['maudsley15_ch9_ad'],
  },

  // ── Antipsychotics ─────────────────────────────────────────────
  {
    drugId: 'aripiprazole',
    tier: 'preferred',
    doseFactor: 0.5,
    fallsRisk: 'low',
    cognitiveRisk: 'low',
    rationale: 'Lowest metabolic + sedation profile. Watch for akathisia which can mimic agitation.',
    citations: ['maudsley15_ch9_ap', 'leucht2013_lancet_metaanalysis'],
  },
  {
    drugId: 'risperidone',
    tier: 'acceptable',
    doseFactor: 0.25,
    fallsRisk: 'moderate',
    cognitiveRisk: 'moderate',
    rationale: 'Approved for dementia-related psychosis short-term. EPS at >1 mg/day in elderly.',
    citations: ['maudsley15_ch9_ap'],
  },
  {
    drugId: 'paliperidone',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'moderate',
    rationale: 'Renal clearance — adjust dose closely. EPS at active-metabolite-equivalent doses.',
    citations: ['maudsley15_ch9_ap'],
  },
  {
    drugId: 'olanzapine',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'high',
    cognitiveRisk: 'high',
    rationale: 'Sedation + metabolic + anticholinergic. Useful short-term but Beers-list for chronic use.',
    citations: ['beers_2023'],
  },
  {
    drugId: 'quetiapine',
    tier: 'acceptable',
    doseFactor: 0.25,
    fallsRisk: 'high',
    cognitiveRisk: 'moderate',
    rationale: 'Common for dementia-related psychosis. Falls risk from orthostasis.',
    citations: ['maudsley15_ch9_ap'],
  },
  {
    drugId: 'haloperidol',
    tier: 'caution',
    doseFactor: 0.25,
    fallsRisk: 'high',
    cognitiveRisk: 'moderate',
    rationale: 'Effective for delirium; QTc + EPS rise sharply with dose.',
    citations: ['maudsley15_ch9_ap'],
  },
  {
    drugId: 'amisulpride',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'low',
    rationale: 'Renal clearance — drop dose for eGFR <60. QTc at high dose.',
    citations: ['maudsley15_ch9_ap'],
  },
  {
    drugId: 'sulpiride',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'low',
    rationale: 'Renal clearance + limited geriatric data.',
    citations: ['maudsley15_ch9_ap'],
  },
  {
    drugId: 'clozapine',
    tier: 'caution',
    doseFactor: 0.25,
    fallsRisk: 'very high',
    cognitiveRisk: 'high',
    rationale: 'TRS only. Falls + cardiomyopathy + agranulocytosis risk all rise with age.',
    citations: ['maudsley15_ch9_clozapine'],
  },
  {
    drugId: 'lurasidone',
    tier: 'preferred',
    doseFactor: 0.5,
    fallsRisk: 'low',
    cognitiveRisk: 'low',
    rationale: 'Low metabolic profile, cognitive-sparing. Take with food.',
    citations: ['maudsley15_ch9_ap'],
  },
  {
    drugId: 'chlorpromazine',
    tier: 'avoid',
    doseFactor: 0.25,
    fallsRisk: 'very high',
    cognitiveRisk: 'very high',
    rationale: 'Strong anticholinergic + orthostasis. Beers-list.',
    citations: ['beers_2023'],
  },
  {
    drugId: 'trifluoperazine',
    tier: 'avoid',
    doseFactor: 0.5,
    fallsRisk: 'high',
    cognitiveRisk: 'high',
    rationale: 'High EPS in elderly. Modern alternatives preferred.',
    citations: ['beers_2023'],
  },
  {
    drugId: 'fluphenazine',
    tier: 'avoid',
    doseFactor: 0.5,
    fallsRisk: 'high',
    cognitiveRisk: 'high',
    rationale: 'Same as trifluoperazine. Depot accumulation magnifies EPS.',
    citations: ['beers_2023'],
  },
  {
    drugId: 'flupenthixol',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'moderate',
    rationale: 'Low-dose acceptable; EPS still a concern.',
    citations: ['maudsley15_ch9_ap'],
  },
  {
    drugId: 'zuclopenthixol',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'high',
    cognitiveRisk: 'high',
    rationale: 'Sedation profile complicates falls risk in elderly.',
    citations: ['maudsley15_ch9_ap'],
  },

  // ── Mood stabilisers ─────────────────────────────────────────
  {
    drugId: 'lithium',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'moderate',
    rationale: 'Renal clearance falls with age — narrower therapeutic window. Target 0.4–0.6 mmol/L.',
    citations: ['maudsley15_ch9_lithium'],
  },
  {
    drugId: 'valproate',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'moderate',
    rationale: 'Hyperammonaemic encephalopathy risk; thrombocytopenia. Beers caution.',
    citations: ['beers_2023'],
  },
  {
    drugId: 'lamotrigine',
    tier: 'preferred',
    doseFactor: 0.75,
    fallsRisk: 'low',
    cognitiveRisk: 'low',
    rationale: 'Cognitive-sparing. Slow titration even more important in elderly.',
    citations: ['maudsley15_ch9_mood'],
  },
  {
    drugId: 'carbamazepine',
    tier: 'caution',
    doseFactor: 0.5,
    fallsRisk: 'moderate',
    cognitiveRisk: 'moderate',
    rationale: 'SIADH risk; bone-marrow suppression more concerning with age.',
    citations: ['maudsley15_ch9_mood'],
  },
];

const INDEX = new Map<string, GeriatricEntry>(ENTRIES.map((e) => [e.drugId, e]));

export function geriatricEntryFor(drugId: string): GeriatricEntry | null {
  return INDEX.get(drugId) ?? null;
}

export function geriatricTierFor(drugId: string): SpecialtyTier | null {
  return INDEX.get(drugId)?.tier ?? null;
}

export function listGeriatricEntries(): GeriatricEntry[] {
  return [...ENTRIES];
}
