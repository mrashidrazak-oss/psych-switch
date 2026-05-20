// Pregnancy specialty matrix.
//
// Per-drug tier (preferred / acceptable / caution / avoid) for use in
// pregnancy + breastfeeding, derived from:
//   • Maudsley 15th ed., chapter 8 (Perinatal psychiatry)
//   • UK Teratology Information Service (UKTIS) monographs
//   • NICE NG192 (Antenatal and postnatal mental health)
//   • Larsen 2015 (BAP perinatal consensus)
//
// Tier definitions:
//   • preferred  — first-line if a switch is needed
//   • acceptable — usable; standard counselling sufficient
//   • caution    — relative concern; weigh benefits vs risks individually
//   • avoid      — known teratogen / strong concern; switch urgently if pregnant
//
// Trimester-specific overrides exist where a drug's risk profile
// changes by trimester (e.g. lithium 1st trimester Ebstein anomaly).
//
// Dart port of engine/specialty/pregnancy.ts.

import 'package:psychswitch_engine/specialty/types.dart';

const List<PregnancyEntry> _entries = <PregnancyEntry>[
  // ── Antidepressants ─────────────────────────────────────────────
  PregnancyEntry(
    drugId: 'sertraline',
    tier: SpecialtyTier.preferred,
    rationale:
        'Most data, lowest milk transfer, no consistent malformation signal.',
    breastfeedingTier: SpecialtyTier.preferred,
    citations: <String>['maudsley15_ch8_perinatal_ssri', 'uktis_sertraline'],
  ),
  PregnancyEntry(
    drugId: 'fluoxetine',
    tier: SpecialtyTier.acceptable,
    rationale:
        'Long t½, may accumulate in neonate; persistent pulmonary hypertension signal at higher doses.',
    breastfeedingTier: SpecialtyTier.caution,
    knownRisks:
        'PPHN signal at high dose. Norfluoxetine accumulation in breastfeeding.',
    citations: <String>['maudsley15_ch8_perinatal_ssri'],
  ),
  PregnancyEntry(
    drugId: 'paroxetine',
    tier: SpecialtyTier.avoid,
    trimesterOverrides: <int, SpecialtyTier>{
      1: SpecialtyTier.avoid,
      2: SpecialtyTier.caution,
      3: SpecialtyTier.caution,
    },
    rationale:
        'First-trimester cardiac defect signal (1.5–2× baseline). Switch before pregnancy if possible.',
    breastfeedingTier: SpecialtyTier.acceptable,
    knownRisks:
        '1st-trimester cardiac malformations; severe neonatal discontinuation syndrome.',
    citations: <String>['maudsley15_ch8_paroxetine', 'fda_paroxetine_pi'],
  ),
  PregnancyEntry(
    drugId: 'escitalopram',
    tier: SpecialtyTier.preferred,
    rationale:
        'Well-tolerated, modest data, no consistent teratogenic signal.',
    breastfeedingTier: SpecialtyTier.preferred,
    citations: <String>['maudsley15_ch8_perinatal_ssri'],
  ),
  PregnancyEntry(
    drugId: 'fluvoxamine',
    tier: SpecialtyTier.acceptable,
    rationale:
        'Less data than sertraline / escitalopram; no clear malformation signal.',
    breastfeedingTier: SpecialtyTier.acceptable,
    citations: <String>['maudsley15_ch8_perinatal_ssri'],
  ),
  PregnancyEntry(
    drugId: 'venlafaxine',
    tier: SpecialtyTier.caution,
    rationale:
        'Increased risk of neonatal discontinuation syndrome; hypertension at high dose.',
    breastfeedingTier: SpecialtyTier.acceptable,
    knownRisks:
        'Severe neonatal discontinuation; maternal hypertension >225 mg/d.',
    citations: <String>['maudsley15_ch8_perinatal_snri'],
  ),
  PregnancyEntry(
    drugId: 'desvenlafaxine',
    tier: SpecialtyTier.caution,
    rationale:
        'Limited human data; assume similar concerns to venlafaxine.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_perinatal_snri'],
  ),
  PregnancyEntry(
    drugId: 'duloxetine',
    tier: SpecialtyTier.caution,
    rationale: 'Limited data. Postnatal adaptation syndrome reported.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_perinatal_snri'],
  ),
  PregnancyEntry(
    drugId: 'mirtazapine',
    tier: SpecialtyTier.acceptable,
    rationale:
        'Limited but reassuring data. Useful for hyperemesis-related insomnia.',
    breastfeedingTier: SpecialtyTier.acceptable,
    citations: <String>['maudsley15_ch8_perinatal_other'],
  ),
  PregnancyEntry(
    drugId: 'agomelatine',
    tier: SpecialtyTier.caution,
    rationale:
        'Limited human pregnancy data; hepatotoxicity baseline concern continues.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_perinatal_other'],
  ),
  PregnancyEntry(
    drugId: 'vortioxetine',
    tier: SpecialtyTier.caution,
    rationale:
        'Insufficient pregnancy data — choose better-characterised alternative if possible.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_perinatal_other'],
  ),

  // ── MAOIs ──
  PregnancyEntry(
    drugId: 'phenelzine',
    tier: SpecialtyTier.avoid,
    rationale: 'MAOI: hypertensive crisis risk + limited safety data.',
    breastfeedingTier: SpecialtyTier.avoid,
    citations: <String>['maudsley15_ch8_maoi'],
  ),
  PregnancyEntry(
    drugId: 'tranylcypromine',
    tier: SpecialtyTier.avoid,
    rationale: 'MAOI: hypertensive crisis risk + limited safety data.',
    breastfeedingTier: SpecialtyTier.avoid,
    citations: <String>['maudsley15_ch8_maoi'],
  ),
  PregnancyEntry(
    drugId: 'moclobemide',
    tier: SpecialtyTier.caution,
    rationale:
        'Reversible MAOI; less data but lower interaction risk than irreversibles.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_maoi'],
  ),

  // ── Antipsychotics ─────────────────────────────────────────────
  PregnancyEntry(
    drugId: 'olanzapine',
    tier: SpecialtyTier.acceptable,
    rationale:
        'Most data among SGAs. Maternal weight gain + gestational diabetes risk.',
    breastfeedingTier: SpecialtyTier.acceptable,
    additionalMonitoring: <String>[
      'Maternal HbA1c each trimester',
      'Neonatal glucose at birth',
    ],
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'quetiapine',
    tier: SpecialtyTier.acceptable,
    rationale: 'Modest data; commonly used; metabolic monitoring needed.',
    breastfeedingTier: SpecialtyTier.acceptable,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'risperidone',
    tier: SpecialtyTier.acceptable,
    rationale:
        'Hyperprolactinaemia may impair fertility but no consistent teratogenic signal.',
    breastfeedingTier: SpecialtyTier.acceptable,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'paliperidone',
    tier: SpecialtyTier.caution,
    rationale: 'Limited data. Same prolactin concerns as risperidone.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'aripiprazole',
    tier: SpecialtyTier.acceptable,
    rationale:
        'Increasing data. Lower metabolic risk than olanzapine / quetiapine.',
    breastfeedingTier: SpecialtyTier.acceptable,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'haloperidol',
    tier: SpecialtyTier.acceptable,
    rationale:
        'Older drug, extensive (older) data. EPS risk in neonate at birth.',
    breastfeedingTier: SpecialtyTier.acceptable,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'amisulpride',
    tier: SpecialtyTier.caution,
    rationale: 'Limited human pregnancy data; hyperprolactinaemia.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'sulpiride',
    tier: SpecialtyTier.caution,
    rationale:
        'Limited data; renal clearance concerns intensify with pregnancy haemodynamics.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'clozapine',
    tier: SpecialtyTier.caution,
    rationale:
        'TRS only — risk-benefit favours continuation if effective. Neonatal agranulocytosis monitoring needed.',
    breastfeedingTier: SpecialtyTier.avoid,
    additionalMonitoring: <String>[
      'Neonatal FBC at birth, weeks 2 + 4',
      'Avoid breastfeeding',
    ],
    knownRisks:
        'Neonatal floppy infant syndrome; case reports of agranulocytosis.',
    citations: <String>['maudsley15_ch8_clozapine'],
  ),
  PregnancyEntry(
    drugId: 'lurasidone',
    tier: SpecialtyTier.caution,
    rationale: 'Limited human data despite favourable metabolic profile.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'chlorpromazine',
    tier: SpecialtyTier.caution,
    rationale:
        'Old data, anticholinergic burden; still acceptable in acute settings.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'trifluoperazine',
    tier: SpecialtyTier.caution,
    rationale: 'Limited modern data. Similar to other phenothiazines.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'fluphenazine',
    tier: SpecialtyTier.caution,
    rationale:
        'Limited modern data; depot accumulation extends in vivo exposure.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'flupenthixol',
    tier: SpecialtyTier.caution,
    rationale: 'Limited modern data; depot considerations.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_aps'],
  ),
  PregnancyEntry(
    drugId: 'zuclopenthixol',
    tier: SpecialtyTier.caution,
    rationale: 'Limited modern data; depot considerations.',
    breastfeedingTier: SpecialtyTier.caution,
    citations: <String>['maudsley15_ch8_aps'],
  ),

  // ── Mood stabilisers ──────────────────────────────────────────
  PregnancyEntry(
    drugId: 'lithium',
    tier: SpecialtyTier.caution,
    trimesterOverrides: <int, SpecialtyTier>{
      1: SpecialtyTier.avoid,
      2: SpecialtyTier.caution,
      3: SpecialtyTier.caution,
    },
    rationale:
        '1st trimester Ebstein anomaly signal (~0.05–0.1%); fetal echo at 18–20w.',
    breastfeedingTier: SpecialtyTier.avoid,
    knownRisks:
        'Ebstein anomaly (1st trimester). Neonatal toxicity if not held pre-delivery.',
    additionalMonitoring: <String>[
      'Fetal echocardiogram at 18–20 weeks',
      'Lithium levels every 2 weeks; weekly in 3rd trimester',
      'Hold lithium 24-48h pre-delivery; restart promptly post-partum',
    ],
    citations: <String>['maudsley15_ch8_lithium', 'nice_ng192_perinatal'],
  ),
  PregnancyEntry(
    drugId: 'valproate',
    tier: SpecialtyTier.avoid,
    rationale:
        '30–40% major malformation rate; neurodevelopmental impairment. Contraindicated in women of reproductive age unless PPP.',
    breastfeedingTier: SpecialtyTier.caution,
    knownRisks:
        'Major malformations 30–40%, neural tube defects, autism + ID risk.',
    citations: <String>['maudsley15_valproate_pregnancy', 'mhra_valproate_ppp'],
  ),
  PregnancyEntry(
    drugId: 'lamotrigine',
    tier: SpecialtyTier.preferred,
    rationale:
        'Preferred bipolar maintenance in pregnancy. Monitor levels — clearance rises 65–230% by 3rd trimester.',
    breastfeedingTier: SpecialtyTier.caution,
    additionalMonitoring: <String>[
      'Lamotrigine levels each trimester',
      'Folate 5 mg/day pre-conception + 1st trimester',
      'Postpartum dose reduction (clearance returns rapidly)',
    ],
    citations: <String>['maudsley15_ch8_lamotrigine'],
  ),
  PregnancyEntry(
    drugId: 'carbamazepine',
    tier: SpecialtyTier.avoid,
    rationale:
        'Neural tube defects ~1%, major malformations 4–7%. Switch where possible.',
    breastfeedingTier: SpecialtyTier.caution,
    knownRisks:
        'Neural tube defects 1%, craniofacial defects, developmental delay.',
    additionalMonitoring: <String>['Folate 5 mg/day', 'Detailed anomaly scan'],
    citations: <String>['maudsley15_ch8_carbamazepine'],
  ),
];

final Map<String, PregnancyEntry> _index = <String, PregnancyEntry>{
  for (final e in _entries) e.drugId: e,
};

/// Resolve the active tier given trimester. Handles trimester-specific
/// overrides (e.g. paroxetine 1st trimester = avoid, 2nd-3rd = caution).
SpecialtyTier? pregnancyTierFor(String drugId, [int? trimester]) {
  final entry = _index[drugId];
  if (entry == null) return null;
  if (trimester != null && entry.trimesterOverrides != null) {
    final override = entry.trimesterOverrides![trimester];
    if (override != null) return override;
  }
  return entry.tier;
}

/// Look up the full pregnancy entry for [drugId].
PregnancyEntry? pregnancyEntryFor(String drugId) => _index[drugId];

/// Snapshot of all pregnancy entries.
List<PregnancyEntry> listPregnancyEntries() =>
    List<PregnancyEntry>.from(_entries);
