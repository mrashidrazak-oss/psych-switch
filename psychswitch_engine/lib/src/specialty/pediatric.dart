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
//
// Dart port of engine/specialty/pediatric.ts.

import 'package:psychswitch_engine/specialty/types.dart';

const List<PediatricEntry> _entries = <PediatricEntry>[
  // ── Antidepressants ─────────────────────────────────────────────
  PediatricEntry(
    drugId: 'fluoxetine',
    tier: SpecialtyTier.preferred,
    licensedFrom: 8,
    licensedFor: 'Major depressive disorder',
    doseFactor: 0.5,
    rationale:
        'Only SSRI with NICE-recommended efficacy for paediatric depression. First-line.',
    citations: <String>['maudsley15_ch7_ssri', 'nice_ng134'],
  ),
  PediatricEntry(
    drugId: 'sertraline',
    tier: SpecialtyTier.acceptable,
    licensedFrom: 6,
    licensedFor: 'OCD only (UK / FDA)',
    doseFactor: 0.5,
    rationale:
        'On-label for paediatric OCD ≥6 yrs. Off-label for depression.',
    citations: <String>['maudsley15_ch7_ssri'],
  ),
  PediatricEntry(
    drugId: 'fluvoxamine',
    tier: SpecialtyTier.acceptable,
    licensedFrom: 8,
    licensedFor: 'OCD (US)',
    doseFactor: 0.5,
    rationale: 'On-label for paediatric OCD in US. Off-label elsewhere.',
    citations: <String>['maudsley15_ch7_ssri'],
  ),
  PediatricEntry(
    drugId: 'escitalopram',
    tier: SpecialtyTier.acceptable,
    licensedFrom: 12,
    licensedFor: 'MDD (FDA from 12 yrs)',
    doseFactor: 0.5,
    rationale: 'FDA-approved for adolescent MDD. NICE prefers fluoxetine.',
    citations: <String>['maudsley15_ch7_ssri'],
  ),
  PediatricEntry(
    drugId: 'paroxetine',
    tier: SpecialtyTier.avoid,
    licensedFrom: null,
    licensedFor: null,
    rationale:
        'Increased suicidality signal in trials; severe withdrawal. Not recommended.',
    citations: <String>['maudsley15_ch7_ssri', 'mhra_paroxetine_paeds'],
  ),
  PediatricEntry(
    drugId: 'venlafaxine',
    tier: SpecialtyTier.caution,
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale: 'Off-label. Suicidality signal in trials. Specialist input.',
    citations: <String>['maudsley15_ch7_other'],
  ),
  PediatricEntry(
    drugId: 'mirtazapine',
    tier: SpecialtyTier.caution,
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale:
        'Off-label paediatric depression. Sometimes used for sleep / appetite stimulation.',
    citations: <String>['maudsley15_ch7_other'],
  ),
  PediatricEntry(
    drugId: 'duloxetine',
    tier: SpecialtyTier.caution,
    licensedFrom: 7,
    licensedFor: 'GAD (FDA 7-17)',
    doseFactor: 0.5,
    rationale: 'On-label for paediatric GAD (FDA). Off-label elsewhere.',
    citations: <String>['maudsley15_ch7_other'],
  ),
  PediatricEntry(
    drugId: 'desvenlafaxine',
    tier: SpecialtyTier.caution,
    licensedFrom: null,
    licensedFor: null,
    rationale: 'Limited paediatric data. Off-label.',
    citations: <String>['maudsley15_ch7_other'],
  ),
  PediatricEntry(
    drugId: 'agomelatine',
    tier: SpecialtyTier.avoid,
    licensedFrom: null,
    licensedFor: null,
    rationale:
        'Hepatotoxicity risk + limited paediatric data. Not recommended <18.',
    citations: <String>['maudsley15_ch7_other'],
  ),
  PediatricEntry(
    drugId: 'vortioxetine',
    tier: SpecialtyTier.caution,
    licensedFrom: null,
    licensedFor: null,
    rationale: 'Insufficient paediatric data. Off-label.',
    citations: <String>['maudsley15_ch7_other'],
  ),
  PediatricEntry(
    drugId: 'phenelzine',
    tier: SpecialtyTier.avoid,
    licensedFrom: null,
    licensedFor: null,
    rationale: 'MAOI: dietary + drug interactions impractical for children.',
    citations: <String>['maudsley15_ch7_maoi'],
  ),
  PediatricEntry(
    drugId: 'tranylcypromine',
    tier: SpecialtyTier.avoid,
    licensedFrom: null,
    licensedFor: null,
    rationale: 'Same as phenelzine.',
    citations: <String>['maudsley15_ch7_maoi'],
  ),
  PediatricEntry(
    drugId: 'moclobemide',
    tier: SpecialtyTier.avoid,
    licensedFrom: null,
    licensedFor: null,
    rationale: 'Limited paediatric data. Other agents preferred.',
    citations: <String>['maudsley15_ch7_maoi'],
  ),

  // ── Antipsychotics ────────────────────────────────────────────
  PediatricEntry(
    drugId: 'risperidone',
    tier: SpecialtyTier.preferred,
    licensedFrom: 5,
    licensedFor:
        'Conduct/aggression (autism), bipolar mania, schizophrenia (≥13)',
    doseFactor: 0.5,
    rationale:
        'Most paediatric data among SGAs. Approved for autism-related irritability ≥5.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'aripiprazole',
    tier: SpecialtyTier.preferred,
    licensedFrom: 6,
    licensedFor:
        'Tourette syndrome, autism irritability, schizophrenia/bipolar (≥13)',
    doseFactor: 0.5,
    rationale:
        'Lower metabolic profile preferred for paediatrics. Watch akathisia.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'olanzapine',
    tier: SpecialtyTier.caution,
    licensedFrom: 13,
    licensedFor: 'Schizophrenia / bipolar mania (FDA ≥13)',
    doseFactor: 0.5,
    rationale: 'Highest metabolic burden — only when alternatives fail.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'quetiapine',
    tier: SpecialtyTier.acceptable,
    licensedFrom: 13,
    licensedFor: 'Schizophrenia / bipolar (FDA ≥13)',
    doseFactor: 0.25,
    rationale:
        'Common adolescent prescription. Sedation + metabolic monitoring needed.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'paliperidone',
    tier: SpecialtyTier.acceptable,
    licensedFrom: 12,
    licensedFor: 'Schizophrenia (FDA ≥12)',
    doseFactor: 0.5,
    rationale:
        'On-label for paediatric schizophrenia. Same prolactin profile as risperidone.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'haloperidol',
    tier: SpecialtyTier.caution,
    licensedFrom: 3,
    licensedFor: 'Tourette, severe behavioural disorders',
    doseFactor: 0.25,
    rationale:
        'EPS rises sharply with paediatric dosing. Use lowest effective dose.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'amisulpride',
    tier: SpecialtyTier.caution,
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale: 'Off-label paediatric. Limited evidence.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'sulpiride',
    tier: SpecialtyTier.caution,
    licensedFrom: 14,
    licensedFor: 'Schizophrenia (UK label)',
    doseFactor: 0.5,
    rationale: 'UK label permits adolescent use. Less Asian data.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'clozapine',
    tier: SpecialtyTier.caution,
    licensedFrom: 16,
    licensedFor: 'Treatment-resistant schizophrenia (UK from 16)',
    doseFactor: 0.5,
    rationale:
        'Specialist initiation only. Same FBC monitoring as adults.',
    citations: <String>['maudsley15_ch7_clozapine'],
  ),
  PediatricEntry(
    drugId: 'lurasidone',
    tier: SpecialtyTier.acceptable,
    licensedFrom: 13,
    licensedFor:
        'Schizophrenia (FDA ≥13), bipolar depression (FDA ≥10)',
    doseFactor: 0.5,
    rationale:
        'Favourable metabolic profile. Take with food (≥350 kcal).',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'chlorpromazine',
    tier: SpecialtyTier.caution,
    licensedFrom: 1,
    licensedFor: 'Severe behavioural disturbance',
    doseFactor: 0.25,
    rationale:
        'Old drug, anticholinergic burden. Modern alternatives preferred.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'trifluoperazine',
    tier: SpecialtyTier.caution,
    licensedFrom: 3,
    licensedFor: 'Severe behavioural disturbance',
    doseFactor: 0.25,
    rationale: 'High EPS in this age group. Specialist use only.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'fluphenazine',
    tier: SpecialtyTier.caution,
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale: 'Off-label paediatric. Depot considerations.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'flupenthixol',
    tier: SpecialtyTier.caution,
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale: 'Off-label paediatric.',
    citations: <String>['maudsley15_ch7_ap'],
  ),
  PediatricEntry(
    drugId: 'zuclopenthixol',
    tier: SpecialtyTier.caution,
    licensedFrom: null,
    licensedFor: null,
    doseFactor: 0.5,
    rationale: 'Off-label paediatric.',
    citations: <String>['maudsley15_ch7_ap'],
  ),

  // ── Mood stabilisers ─────────────────────────────────────────
  PediatricEntry(
    drugId: 'lithium',
    tier: SpecialtyTier.acceptable,
    licensedFrom: 12,
    licensedFor: 'Bipolar mania (FDA ≥12)',
    doseFactor: 0.5,
    rationale:
        'On-label for paediatric mania. Renal + thyroid monitoring as for adults.',
    citations: <String>['maudsley15_ch7_mood'],
  ),
  PediatricEntry(
    drugId: 'valproate',
    tier: SpecialtyTier.avoid,
    licensedFrom: null,
    licensedFor: null,
    rationale:
        'Contraindicated in females of reproductive age (PPP). Fewer options for males but lamotrigine preferred.',
    citations: <String>['maudsley15_ch7_mood', 'mhra_valproate_ppp'],
  ),
  PediatricEntry(
    drugId: 'lamotrigine',
    tier: SpecialtyTier.acceptable,
    licensedFrom: 2,
    licensedFor: 'Epilepsy ≥2; bipolar maintenance off-label in <18',
    doseFactor: 0.5,
    rationale:
        'On-label for epilepsy from age 2. Off-label for bipolar in <18.',
    citations: <String>['maudsley15_ch7_mood'],
  ),
  PediatricEntry(
    drugId: 'carbamazepine',
    tier: SpecialtyTier.acceptable,
    licensedFrom: 0,
    licensedFor: 'Epilepsy any age; bipolar off-label in <18',
    doseFactor: 0.5,
    rationale: 'Long-established paediatric anticonvulsant.',
    citations: <String>['maudsley15_ch7_mood'],
  ),
];

final Map<String, PediatricEntry> _index = <String, PediatricEntry>{
  for (final e in _entries) e.drugId: e,
};

/// Look up the pediatric entry for [drugId].
PediatricEntry? pediatricEntryFor(String drugId) => _index[drugId];

/// Resolve the active tier given the patient's age. If the drug is
/// licensed at or below the patient's age, bumps tier up by one notch
/// (avoid → caution, caution → acceptable).
SpecialtyTier? pediatricTierFor(String drugId, [num? ageYears]) {
  final entry = _index[drugId];
  if (entry == null) return null;
  if (ageYears != null &&
      entry.licensedFrom != null &&
      ageYears >= entry.licensedFrom!) {
    if (entry.tier == SpecialtyTier.avoid) return SpecialtyTier.caution;
    if (entry.tier == SpecialtyTier.caution) return SpecialtyTier.acceptable;
  }
  return entry.tier;
}

/// Snapshot of all pediatric entries.
List<PediatricEntry> listPediatricEntries() =>
    List<PediatricEntry>.from(_entries);
