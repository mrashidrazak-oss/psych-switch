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
// The orchestrator (engine/specialty.dart) consults this when the
// patient's ageBand resolves to [AgeBand.olderAdult].
//
// Dart port of engine/specialty/geriatric.ts.

import 'package:psychswitch/src/engine/specialty/types.dart';

const List<GeriatricEntry> _entries = <GeriatricEntry>[
  // ── Antidepressants ─────────────────────────────────────────────
  GeriatricEntry(
    drugId: 'sertraline',
    tier: SpecialtyTier.preferred,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.low,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Cleanest profile for older adults. Few CYP interactions, low anticholinergic.',
    citations: <String>['maudsley15_ch9_ad', 'beers_2023'],
  ),
  GeriatricEntry(
    drugId: 'escitalopram',
    tier: SpecialtyTier.preferred,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.low,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Cap at 10 mg/day in older adults due to QTc concerns. Otherwise well tolerated.',
    citations: <String>['maudsley15_ch9_ad', 'beers_2023'],
  ),
  GeriatricEntry(
    drugId: 'fluoxetine',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.low,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Long t½ + active metabolite makes dose adjustment slow in this group.',
    citations: <String>['maudsley15_ch9_ad'],
  ),
  GeriatricEntry(
    drugId: 'paroxetine',
    tier: SpecialtyTier.avoid,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.high,
    cognitiveRisk: SubgroupRiskBand.high,
    rationale:
        'Highest anticholinergic load among SSRIs — Beers list. Severe discontinuation.',
    citations: <String>['beers_2023'],
  ),
  GeriatricEntry(
    drugId: 'fluvoxamine',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.low,
    cognitiveRisk: SubgroupRiskBand.moderate,
    rationale:
        'Strong CYP1A2 inhibition raises risk in poly-pharmacy. GI tolerability variable.',
    citations: <String>['maudsley15_ch9_ad'],
  ),
  GeriatricEntry(
    drugId: 'mirtazapine',
    tier: SpecialtyTier.preferred,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Often preferred — appetite stimulant + hypnotic effect helps frail elderly.',
    citations: <String>['maudsley15_ch9_ad'],
  ),
  GeriatricEntry(
    drugId: 'venlafaxine',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Hypertension and dose-related discontinuation risk. Cap at 150 mg in CKD-prone elderly.',
    citations: <String>['maudsley15_ch9_ad'],
  ),
  GeriatricEntry(
    drugId: 'desvenlafaxine',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Like venlafaxine — hypertension + discontinuation. Renal clearance.',
    citations: <String>['maudsley15_ch9_ad'],
  ),
  GeriatricEntry(
    drugId: 'duloxetine',
    tier: SpecialtyTier.acceptable,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale: 'Useful when comorbid neuropathic pain. LFT monitoring.',
    citations: <String>['maudsley15_ch9_ad'],
  ),
  GeriatricEntry(
    drugId: 'agomelatine',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.low,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale: 'Hepatic monitoring burden grows with age + polypharmacy.',
    citations: <String>['maudsley15_ch9_ad'],
  ),
  GeriatricEntry(
    drugId: 'vortioxetine',
    tier: SpecialtyTier.acceptable,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.low,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Cognitive-sparing data in older adults. CYP2D6 substrate — adjust with strong inhibitors.',
    citations: <String>['maudsley15_ch9_ad'],
  ),

  // ── MAOIs (avoid in older adults) ──
  GeriatricEntry(
    drugId: 'phenelzine',
    tier: SpecialtyTier.avoid,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.veryHigh,
    cognitiveRisk: SubgroupRiskBand.high,
    rationale:
        'Orthostatic hypotension + dietary tyramine restriction — high adherence burden.',
    citations: <String>['beers_2023'],
  ),
  GeriatricEntry(
    drugId: 'tranylcypromine',
    tier: SpecialtyTier.avoid,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.veryHigh,
    cognitiveRisk: SubgroupRiskBand.high,
    rationale:
        'Same as phenelzine. Stimulant effect can complicate cardiac comorbidity.',
    citations: <String>['beers_2023'],
  ),
  GeriatricEntry(
    drugId: 'moclobemide',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Reversible MAOI; safer than irreversibles but less data in elderly.',
    citations: <String>['maudsley15_ch9_ad'],
  ),

  // ── Antipsychotics ─────────────────────────────────────────────
  GeriatricEntry(
    drugId: 'aripiprazole',
    tier: SpecialtyTier.preferred,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.low,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Lowest metabolic + sedation profile. Watch for akathisia which can mimic agitation.',
    citations: <String>['maudsley15_ch9_ap', 'leucht2013_lancet_metaanalysis'],
  ),
  GeriatricEntry(
    drugId: 'risperidone',
    tier: SpecialtyTier.acceptable,
    doseFactor: 0.25,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.moderate,
    rationale:
        'Approved for dementia-related psychosis short-term. EPS at >1 mg/day in elderly.',
    citations: <String>['maudsley15_ch9_ap'],
  ),
  GeriatricEntry(
    drugId: 'paliperidone',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.moderate,
    rationale:
        'Renal clearance — adjust dose closely. EPS at active-metabolite-equivalent doses.',
    citations: <String>['maudsley15_ch9_ap'],
  ),
  GeriatricEntry(
    drugId: 'olanzapine',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.high,
    cognitiveRisk: SubgroupRiskBand.high,
    rationale:
        'Sedation + metabolic + anticholinergic. Useful short-term but Beers-list for chronic use.',
    citations: <String>['beers_2023'],
  ),
  GeriatricEntry(
    drugId: 'quetiapine',
    tier: SpecialtyTier.acceptable,
    doseFactor: 0.25,
    fallsRisk: SubgroupRiskBand.high,
    cognitiveRisk: SubgroupRiskBand.moderate,
    rationale:
        'Common for dementia-related psychosis. Falls risk from orthostasis.',
    citations: <String>['maudsley15_ch9_ap'],
  ),
  GeriatricEntry(
    drugId: 'haloperidol',
    tier: SpecialtyTier.caution,
    doseFactor: 0.25,
    fallsRisk: SubgroupRiskBand.high,
    cognitiveRisk: SubgroupRiskBand.moderate,
    rationale:
        'Effective for delirium; QTc + EPS rise sharply with dose.',
    citations: <String>['maudsley15_ch9_ap'],
  ),
  GeriatricEntry(
    drugId: 'amisulpride',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Renal clearance — drop dose for eGFR <60. QTc at high dose.',
    citations: <String>['maudsley15_ch9_ap'],
  ),
  GeriatricEntry(
    drugId: 'sulpiride',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale: 'Renal clearance + limited geriatric data.',
    citations: <String>['maudsley15_ch9_ap'],
  ),
  GeriatricEntry(
    drugId: 'clozapine',
    tier: SpecialtyTier.caution,
    doseFactor: 0.25,
    fallsRisk: SubgroupRiskBand.veryHigh,
    cognitiveRisk: SubgroupRiskBand.high,
    rationale:
        'TRS only. Falls + cardiomyopathy + agranulocytosis risk all rise with age.',
    citations: <String>['maudsley15_ch9_clozapine'],
  ),
  GeriatricEntry(
    drugId: 'lurasidone',
    tier: SpecialtyTier.preferred,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.low,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Low metabolic profile, cognitive-sparing. Take with food.',
    citations: <String>['maudsley15_ch9_ap'],
  ),
  GeriatricEntry(
    drugId: 'chlorpromazine',
    tier: SpecialtyTier.avoid,
    doseFactor: 0.25,
    fallsRisk: SubgroupRiskBand.veryHigh,
    cognitiveRisk: SubgroupRiskBand.veryHigh,
    rationale: 'Strong anticholinergic + orthostasis. Beers-list.',
    citations: <String>['beers_2023'],
  ),
  GeriatricEntry(
    drugId: 'trifluoperazine',
    tier: SpecialtyTier.avoid,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.high,
    cognitiveRisk: SubgroupRiskBand.high,
    rationale: 'High EPS in elderly. Modern alternatives preferred.',
    citations: <String>['beers_2023'],
  ),
  GeriatricEntry(
    drugId: 'fluphenazine',
    tier: SpecialtyTier.avoid,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.high,
    cognitiveRisk: SubgroupRiskBand.high,
    rationale:
        'Same as trifluoperazine. Depot accumulation magnifies EPS.',
    citations: <String>['beers_2023'],
  ),
  GeriatricEntry(
    drugId: 'flupenthixol',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.moderate,
    rationale: 'Low-dose acceptable; EPS still a concern.',
    citations: <String>['maudsley15_ch9_ap'],
  ),
  GeriatricEntry(
    drugId: 'zuclopenthixol',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.high,
    cognitiveRisk: SubgroupRiskBand.high,
    rationale: 'Sedation profile complicates falls risk in elderly.',
    citations: <String>['maudsley15_ch9_ap'],
  ),

  // ── Mood stabilisers ─────────────────────────────────────────
  GeriatricEntry(
    drugId: 'lithium',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.moderate,
    rationale:
        'Renal clearance falls with age — narrower therapeutic window. Target 0.4–0.6 mmol/L.',
    citations: <String>['maudsley15_ch9_lithium'],
  ),
  GeriatricEntry(
    drugId: 'valproate',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.moderate,
    rationale:
        'Hyperammonaemic encephalopathy risk; thrombocytopenia. Beers caution.',
    citations: <String>['beers_2023'],
  ),
  GeriatricEntry(
    drugId: 'lamotrigine',
    tier: SpecialtyTier.preferred,
    doseFactor: 0.75,
    fallsRisk: SubgroupRiskBand.low,
    cognitiveRisk: SubgroupRiskBand.low,
    rationale:
        'Cognitive-sparing. Slow titration even more important in elderly.',
    citations: <String>['maudsley15_ch9_mood'],
  ),
  GeriatricEntry(
    drugId: 'carbamazepine',
    tier: SpecialtyTier.caution,
    doseFactor: 0.5,
    fallsRisk: SubgroupRiskBand.moderate,
    cognitiveRisk: SubgroupRiskBand.moderate,
    rationale:
        'SIADH risk; bone-marrow suppression more concerning with age.',
    citations: <String>['maudsley15_ch9_mood'],
  ),
];

final Map<String, GeriatricEntry> _index = <String, GeriatricEntry>{
  for (final e in _entries) e.drugId: e,
};

/// Look up the geriatric entry for [drugId].
GeriatricEntry? geriatricEntryFor(String drugId) => _index[drugId];

/// Look up the geriatric tier for [drugId], or `null`.
SpecialtyTier? geriatricTierFor(String drugId) => _index[drugId]?.tier;

/// Snapshot of all geriatric entries.
List<GeriatricEntry> listGeriatricEntries() =>
    List<GeriatricEntry>.from(_entries);
