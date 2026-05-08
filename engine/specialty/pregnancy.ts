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

import type { PregnancyEntry, SpecialtyTier } from './types';

const ENTRIES: PregnancyEntry[] = [
  // ── Antidepressants ─────────────────────────────────────────────
  {
    drugId: 'sertraline',
    tier: 'preferred',
    rationale: 'Most data, lowest milk transfer, no consistent malformation signal.',
    breastfeedingTier: 'preferred',
    citations: ['maudsley15_ch8_perinatal_ssri', 'uktis_sertraline'],
  },
  {
    drugId: 'fluoxetine',
    tier: 'acceptable',
    rationale: 'Long t½, may accumulate in neonate; persistent pulmonary hypertension signal at higher doses.',
    breastfeedingTier: 'caution',
    knownRisks: 'PPHN signal at high dose. Norfluoxetine accumulation in breastfeeding.',
    citations: ['maudsley15_ch8_perinatal_ssri'],
  },
  {
    drugId: 'paroxetine',
    tier: 'avoid',
    trimesterOverrides: { 1: 'avoid', 2: 'caution', 3: 'caution' },
    rationale: 'First-trimester cardiac defect signal (1.5–2× baseline). Switch before pregnancy if possible.',
    breastfeedingTier: 'acceptable',
    knownRisks: '1st-trimester cardiac malformations; severe neonatal discontinuation syndrome.',
    citations: ['maudsley15_ch8_paroxetine', 'fda_paroxetine_pi'],
  },
  {
    drugId: 'escitalopram',
    tier: 'preferred',
    rationale: 'Well-tolerated, modest data, no consistent teratogenic signal.',
    breastfeedingTier: 'preferred',
    citations: ['maudsley15_ch8_perinatal_ssri'],
  },
  {
    drugId: 'fluvoxamine',
    tier: 'acceptable',
    rationale: 'Less data than sertraline / escitalopram; no clear malformation signal.',
    breastfeedingTier: 'acceptable',
    citations: ['maudsley15_ch8_perinatal_ssri'],
  },
  {
    drugId: 'venlafaxine',
    tier: 'caution',
    rationale: 'Increased risk of neonatal discontinuation syndrome; hypertension at high dose.',
    breastfeedingTier: 'acceptable',
    knownRisks: 'Severe neonatal discontinuation; maternal hypertension >225 mg/d.',
    citations: ['maudsley15_ch8_perinatal_snri'],
  },
  {
    drugId: 'desvenlafaxine',
    tier: 'caution',
    rationale: 'Limited human data; assume similar concerns to venlafaxine.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_perinatal_snri'],
  },
  {
    drugId: 'duloxetine',
    tier: 'caution',
    rationale: 'Limited data. Postnatal adaptation syndrome reported.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_perinatal_snri'],
  },
  {
    drugId: 'mirtazapine',
    tier: 'acceptable',
    rationale: 'Limited but reassuring data. Useful for hyperemesis-related insomnia.',
    breastfeedingTier: 'acceptable',
    citations: ['maudsley15_ch8_perinatal_other'],
  },
  {
    drugId: 'agomelatine',
    tier: 'caution',
    rationale: 'Limited human pregnancy data; hepatotoxicity baseline concern continues.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_perinatal_other'],
  },
  {
    drugId: 'vortioxetine',
    tier: 'caution',
    rationale: 'Insufficient pregnancy data — choose better-characterised alternative if possible.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_perinatal_other'],
  },

  // ── MAOIs ──
  {
    drugId: 'phenelzine',
    tier: 'avoid',
    rationale: 'MAOI: hypertensive crisis risk + limited safety data.',
    breastfeedingTier: 'avoid',
    citations: ['maudsley15_ch8_maoi'],
  },
  {
    drugId: 'tranylcypromine',
    tier: 'avoid',
    rationale: 'MAOI: hypertensive crisis risk + limited safety data.',
    breastfeedingTier: 'avoid',
    citations: ['maudsley15_ch8_maoi'],
  },
  {
    drugId: 'moclobemide',
    tier: 'caution',
    rationale: 'Reversible MAOI; less data but lower interaction risk than irreversibles.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_maoi'],
  },

  // ── Antipsychotics ─────────────────────────────────────────────
  {
    drugId: 'olanzapine',
    tier: 'acceptable',
    rationale: 'Most data among SGAs. Maternal weight gain + gestational diabetes risk.',
    breastfeedingTier: 'acceptable',
    additionalMonitoring: ['Maternal HbA1c each trimester', 'Neonatal glucose at birth'],
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'quetiapine',
    tier: 'acceptable',
    rationale: 'Modest data; commonly used; metabolic monitoring needed.',
    breastfeedingTier: 'acceptable',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'risperidone',
    tier: 'acceptable',
    rationale: 'Hyperprolactinaemia may impair fertility but no consistent teratogenic signal.',
    breastfeedingTier: 'acceptable',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'paliperidone',
    tier: 'caution',
    rationale: 'Limited data. Same prolactin concerns as risperidone.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'aripiprazole',
    tier: 'acceptable',
    rationale: 'Increasing data. Lower metabolic risk than olanzapine / quetiapine.',
    breastfeedingTier: 'acceptable',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'haloperidol',
    tier: 'acceptable',
    rationale: 'Older drug, extensive (older) data. EPS risk in neonate at birth.',
    breastfeedingTier: 'acceptable',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'amisulpride',
    tier: 'caution',
    rationale: 'Limited human pregnancy data; hyperprolactinaemia.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'sulpiride',
    tier: 'caution',
    rationale: 'Limited data; renal clearance concerns intensify with pregnancy haemodynamics.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'clozapine',
    tier: 'caution',
    rationale: 'TRS only — risk-benefit favours continuation if effective. Neonatal agranulocytosis monitoring needed.',
    breastfeedingTier: 'avoid',
    additionalMonitoring: ['Neonatal FBC at birth, weeks 2 + 4', 'Avoid breastfeeding'],
    knownRisks: 'Neonatal floppy infant syndrome; case reports of agranulocytosis.',
    citations: ['maudsley15_ch8_clozapine'],
  },
  {
    drugId: 'lurasidone',
    tier: 'caution',
    rationale: 'Limited human data despite favourable metabolic profile.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'chlorpromazine',
    tier: 'caution',
    rationale: 'Old data, anticholinergic burden; still acceptable in acute settings.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'trifluoperazine',
    tier: 'caution',
    rationale: 'Limited modern data. Similar to other phenothiazines.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'fluphenazine',
    tier: 'caution',
    rationale: 'Limited modern data; depot accumulation extends in vivo exposure.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'flupenthixol',
    tier: 'caution',
    rationale: 'Limited modern data; depot considerations.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_aps'],
  },
  {
    drugId: 'zuclopenthixol',
    tier: 'caution',
    rationale: 'Limited modern data; depot considerations.',
    breastfeedingTier: 'caution',
    citations: ['maudsley15_ch8_aps'],
  },

  // ── Mood stabilisers ──────────────────────────────────────────
  {
    drugId: 'lithium',
    tier: 'caution',
    trimesterOverrides: { 1: 'avoid', 2: 'caution', 3: 'caution' },
    rationale: '1st trimester Ebstein anomaly signal (~0.05–0.1%); fetal echo at 18–20w.',
    breastfeedingTier: 'avoid',
    knownRisks: 'Ebstein anomaly (1st trimester). Neonatal toxicity if not held pre-delivery.',
    additionalMonitoring: [
      'Fetal echocardiogram at 18–20 weeks',
      'Lithium levels every 2 weeks; weekly in 3rd trimester',
      'Hold lithium 24-48h pre-delivery; restart promptly post-partum',
    ],
    citations: ['maudsley15_ch8_lithium', 'nice_ng192_perinatal'],
  },
  {
    drugId: 'valproate',
    tier: 'avoid',
    rationale: '30–40% major malformation rate; neurodevelopmental impairment. Contraindicated in women of reproductive age unless PPP.',
    breastfeedingTier: 'caution',
    knownRisks: 'Major malformations 30–40%, neural tube defects, autism + ID risk.',
    citations: ['maudsley15_valproate_pregnancy', 'mhra_valproate_ppp'],
  },
  {
    drugId: 'lamotrigine',
    tier: 'preferred',
    rationale: 'Preferred bipolar maintenance in pregnancy. Monitor levels — clearance rises 65–230% by 3rd trimester.',
    breastfeedingTier: 'caution',
    additionalMonitoring: [
      'Lamotrigine levels each trimester',
      'Folate 5 mg/day pre-conception + 1st trimester',
      'Postpartum dose reduction (clearance returns rapidly)',
    ],
    citations: ['maudsley15_ch8_lamotrigine'],
  },
  {
    drugId: 'carbamazepine',
    tier: 'avoid',
    rationale: 'Neural tube defects ~1%, major malformations 4–7%. Switch where possible.',
    breastfeedingTier: 'caution',
    knownRisks: 'Neural tube defects 1%, craniofacial defects, developmental delay.',
    additionalMonitoring: ['Folate 5 mg/day', 'Detailed anomaly scan'],
    citations: ['maudsley15_ch8_carbamazepine'],
  },
];

const INDEX = new Map<string, PregnancyEntry>(ENTRIES.map((e) => [e.drugId, e]));

/**
 * Resolve the active tier given trimester. Handles trimester-specific
 * overrides (e.g. paroxetine 1st trimester = avoid, 2nd-3rd = caution).
 */
export function pregnancyTierFor(
  drugId: string,
  trimester?: 1 | 2 | 3,
): SpecialtyTier | null {
  const entry = INDEX.get(drugId);
  if (!entry) return null;
  if (trimester && entry.trimesterOverrides?.[trimester]) {
    return entry.trimesterOverrides[trimester]!;
  }
  return entry.tier;
}

export function pregnancyEntryFor(drugId: string): PregnancyEntry | null {
  return INDEX.get(drugId) ?? null;
}

export function listPregnancyEntries(): PregnancyEntry[] {
  return [...ENTRIES];
}
