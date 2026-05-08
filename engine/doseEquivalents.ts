// Dose-equivalency tables — the calculator clinicians ask for daily.
//
// Three families:
//   1. Antipsychotics  → chlorpromazine equivalents (CPZ-eq, mg)
//   2. Antidepressants → fluoxetine equivalents (FLX-eq, mg)
//   3. Benzodiazepines → diazepam equivalents (DZP-eq, mg)
//
// IMPORTANT — clinical caveats:
//   • Equivalents are *approximate*. They are useful for orientation
//     (e.g. "is this a high or low dose for this drug?") and for
//     informing cross-titration decisions, NOT for prescribing.
//   • Receptor profiles differ. Switching at "equivalent dose" can still
//     cause loss of efficacy (e.g. olanzapine → aripiprazole) or
//     intolerable side effects.
//   • Always titrate to clinical effect.
//
// Sources
//   • Antipsychotics: Leucht S et al. "Dose-equivalents revisited",
//     Schizophr Bull 2016 (DDD method); Maudsley 15th, Table 4.1.
//   • Antidepressants: Hayasaka Y et al. "Dose equivalents of
//     antidepressants", J Affect Disord 2015 (PMID 25911132).
//   • Benzodiazepines: Ashton CH "The Ashton Manual" (Newcastle 2002);
//     BNF 86 (2023-24); Maudsley 15th, Table 5.3.

export type EquivalencyFamily = 'cpz' | 'fluoxetine' | 'diazepam';

export interface EquivalencyEntry {
  /** Drug ID — matches /content/drugs/<id>.json when possible. */
  id: string;
  /** Display name (free-form, may include trailing notes in parens). */
  genericName: string;
  /** Reference dose (mg) that equals 1 unit of the family reference. */
  equivalentMg: number;
  /** Optional caveat or footnote shown next to the entry. */
  notes?: string;
  /** Whether this entry is a deprecated/MAOI/specialist drug — sorted lower. */
  specialist?: boolean;
}

export interface EquivalencyFamilyMeta {
  family: EquivalencyFamily;
  title: string;
  shortLabel: string;
  /** The reference drug + dose (e.g. "Chlorpromazine 100 mg"). */
  reference: { name: string; mg: number };
  /** What the calculator is good for. */
  intendedUse: string;
  /** What the calculator is NOT good for. */
  limitations: string[];
  /** Citations for the equivalency table. */
  citations: string[];
  /** ISO date the table was last reviewed. */
  lastReviewedISO: string;
  entries: EquivalencyEntry[];
}

// ── Chlorpromazine equivalents ────────────────────────────────────────────────
// Reference: chlorpromazine 100 mg/day = 1 CPZ-eq.
// Method: Leucht 2016 DDD-based equivalents, cross-checked against Maudsley 15th.
//
// "Specialist" drugs (clozapine, agonist-only aripiprazole) carry caveats —
// the equivalence is mechanistically weak and clinicians should be reminded.

const CPZ_ENTRIES: EquivalencyEntry[] = [
  { id: 'haloperidol',    genericName: 'Haloperidol',    equivalentMg: 2,   notes: 'High EPS, low metabolic.' },
  { id: 'risperidone',    genericName: 'Risperidone',    equivalentMg: 2,   notes: 'Prolactin↑ at >4 mg/d.' },
  { id: 'paliperidone',   genericName: 'Paliperidone',   equivalentMg: 1.5, notes: 'Active metabolite of risperidone.' },
  { id: 'olanzapine',     genericName: 'Olanzapine',     equivalentMg: 5,   notes: 'Metabolic risk; avoid in cardiometabolic disease.' },
  { id: 'quetiapine',     genericName: 'Quetiapine',     equivalentMg: 100, notes: 'Sedating; >300 mg/d for antipsychotic effect.' },
  { id: 'aripiprazole',   genericName: 'Aripiprazole',   equivalentMg: 7.5, notes: 'D2 partial agonist — equivalence approximate.', specialist: true },
  { id: 'amisulpride',    genericName: 'Amisulpride',    equivalentMg: 100, notes: 'Renal clearance; reduce in CKD.' },
  { id: 'sulpiride',      genericName: 'Sulpiride',      equivalentMg: 200, notes: 'Limited Asian RCT data.' },
  { id: 'lurasidone',     genericName: 'Lurasidone',     equivalentMg: 40,  notes: 'Take with food (≥350 kcal) for absorption.' },
  { id: 'clozapine',      genericName: 'Clozapine',      equivalentMg: 50,  notes: 'TRS only. Equivalence is weak; use plasma level.', specialist: true },
  { id: 'trifluoperazine',genericName: 'Trifluoperazine',equivalentMg: 5,   notes: 'High EPS.' },
  { id: 'fluphenazine',   genericName: 'Fluphenazine',   equivalentMg: 2,   notes: 'High EPS; depot available.' },
  { id: 'flupenthixol',   genericName: 'Flupenthixol',   equivalentMg: 3,   notes: 'Depot available; activating at low dose.' },
  { id: 'zuclopenthixol', genericName: 'Zuclopenthixol', equivalentMg: 25,  notes: 'Sedating; depot available.' },
  { id: 'chlorpromazine', genericName: 'Chlorpromazine', equivalentMg: 100, notes: 'Reference drug. Anticholinergic, hypotension.' },
];

// ── Fluoxetine equivalents ───────────────────────────────────────────────────
// Reference: fluoxetine 40 mg/day = 1 FLX-eq.
// Method: Hayasaka 2015 individual-patient meta-analysis (J Affect Disord).
//
// Mirtazapine, vortioxetine and agomelatine are non-SSRI/SNRI mechanisms —
// equivalence is approximate at best; flagged "specialist".

const FLX_ENTRIES: EquivalencyEntry[] = [
  { id: 'fluoxetine',     genericName: 'Fluoxetine',     equivalentMg: 40,  notes: 'Reference. Long t½, self-tapering.' },
  { id: 'escitalopram',   genericName: 'Escitalopram',   equivalentMg: 18,  notes: 'Round to 20 mg in practice.' },
  { id: 'sertraline',     genericName: 'Sertraline',     equivalentMg: 100, notes: 'GI side effects most common.' },
  { id: 'paroxetine',     genericName: 'Paroxetine',     equivalentMg: 25,  notes: 'High discontinuation risk; CYP2D6 inhibitor.' },
  { id: 'fluvoxamine',    genericName: 'Fluvoxamine',    equivalentMg: 100, notes: 'CYP1A2 inhibitor — major DDI source.' },
  { id: 'venlafaxine',    genericName: 'Venlafaxine',    equivalentMg: 150, notes: 'Above 150 mg/d adds NA reuptake.' },
  { id: 'desvenlafaxine', genericName: 'Desvenlafaxine', equivalentMg: 75,  notes: 'Active metabolite of venlafaxine.' },
  { id: 'duloxetine',     genericName: 'Duloxetine',     equivalentMg: 60 },
  { id: 'mirtazapine',    genericName: 'Mirtazapine',    equivalentMg: 30,  notes: 'NaSSA — equivalence is approximate.', specialist: true },
  { id: 'vortioxetine',   genericName: 'Vortioxetine',   equivalentMg: 15,  notes: 'Multimodal — equivalence approximate.', specialist: true },
  { id: 'agomelatine',    genericName: 'Agomelatine',    equivalentMg: 50,  notes: 'MT1/MT2 agonist — limited equivalence data.', specialist: true },
];

// ── Diazepam equivalents ──────────────────────────────────────────────────────
// Reference: diazepam 10 mg = 1 DZP-eq.
// Method: Ashton manual 2002, cross-checked against BNF and Maudsley 15th.
//
// Z-drugs (zolpidem, zopiclone) listed for completeness — useful when
// switching a patient off them or estimating sedative load.

const DZP_ENTRIES: EquivalencyEntry[] = [
  { id: 'diazepam',         genericName: 'Diazepam',         equivalentMg: 10,   notes: 'Reference. Long t½ (~30 h).' },
  { id: 'lorazepam',        genericName: 'Lorazepam',        equivalentMg: 1,    notes: 'Short t½, no active metabolites.' },
  { id: 'clonazepam',       genericName: 'Clonazepam',       equivalentMg: 0.5,  notes: 'Long t½ (~30 h).' },
  { id: 'alprazolam',       genericName: 'Alprazolam',       equivalentMg: 0.5,  notes: 'Short t½, high dependence risk.' },
  { id: 'temazepam',        genericName: 'Temazepam',        equivalentMg: 20,   notes: 'Hypnotic.' },
  { id: 'nitrazepam',       genericName: 'Nitrazepam',       equivalentMg: 10,   notes: 'Hypnotic, long t½.' },
  { id: 'midazolam',        genericName: 'Midazolam (oral)', equivalentMg: 7.5,  notes: 'IV/IM use is acute; dose differs.' },
  { id: 'oxazepam',         genericName: 'Oxazepam',         equivalentMg: 20 },
  { id: 'chlordiazepoxide', genericName: 'Chlordiazepoxide', equivalentMg: 25,   notes: 'Used in alcohol withdrawal.' },
  { id: 'bromazepam',       genericName: 'Bromazepam',       equivalentMg: 6 },
  { id: 'zopiclone',        genericName: 'Zopiclone',        equivalentMg: 7.5,  notes: 'Z-drug — pharmacology differs.', specialist: true },
  { id: 'zolpidem',         genericName: 'Zolpidem',         equivalentMg: 10,   notes: 'Z-drug — pharmacology differs.', specialist: true },
];

export const EQUIVALENCY_FAMILIES: Record<EquivalencyFamily, EquivalencyFamilyMeta> = {
  cpz: {
    family: 'cpz',
    title: 'Chlorpromazine equivalents',
    shortLabel: 'CPZ-eq',
    reference: { name: 'Chlorpromazine', mg: 100 },
    intendedUse: 'Estimating cumulative antipsychotic load and orienting cross-titrations.',
    limitations: [
      'Receptor profiles differ — equivalent dose ≠ equivalent efficacy or side-effect profile.',
      'Aripiprazole and clozapine equivalence is mechanistically weak. Use with caution.',
      'Not validated for LAI doses — convert to oral equivalent first.',
    ],
    citations: [
      'Leucht S, Samara M, Heres S, Davis JM. Dose equivalents for antipsychotic drugs: the DDD method. Schizophr Bull. 2016;42(suppl 1):S90–S94.',
      'Maudsley Prescribing Guidelines, 15th ed. Table 4.1 (2024).',
    ],
    lastReviewedISO: '2026-05-04',
    entries: CPZ_ENTRIES,
  },
  fluoxetine: {
    family: 'fluoxetine',
    title: 'Fluoxetine equivalents',
    shortLabel: 'FLX-eq',
    reference: { name: 'Fluoxetine', mg: 40 },
    intendedUse: 'Orienting antidepressant dose during cross-tapers and audit.',
    limitations: [
      'Equivalents are approximate and assume monotherapy.',
      'Mirtazapine, vortioxetine and agomelatine have non-SSRI mechanisms — equivalence is weaker.',
      'Does not account for CYP-mediated interactions during cross-taper.',
    ],
    citations: [
      'Hayasaka Y, et al. Dose equivalents of antidepressants based on individual data. J Affect Disord 2015;180:179–84.',
      'Maudsley Prescribing Guidelines, 15th ed. (2024).',
    ],
    lastReviewedISO: '2026-05-04',
    entries: FLX_ENTRIES,
  },
  diazepam: {
    family: 'diazepam',
    title: 'Diazepam equivalents',
    shortLabel: 'DZP-eq',
    reference: { name: 'Diazepam', mg: 10 },
    intendedUse: 'Quantifying sedative load and supporting benzodiazepine tapers (Ashton method).',
    limitations: [
      'Approximate for short-acting agents — clinical effect differs from total exposure.',
      'Z-drug equivalence is for orientation only; mechanism differs.',
      'Tolerance and dependence vary widely between agents.',
    ],
    citations: [
      'Ashton CH. Benzodiazepines: How They Work and How to Withdraw. Newcastle, 2002.',
      'BNF 86 (2023–24).',
      'Maudsley Prescribing Guidelines, 15th ed. Table 5.3 (2024).',
    ],
    lastReviewedISO: '2026-05-04',
    entries: DZP_ENTRIES,
  },
};

/**
 * Convert a dose of one drug to an equivalent dose of another within the
 * same family. Returns null if either drug is not in the family table.
 */
export function convertWithinFamily(
  family: EquivalencyFamily,
  fromId: string,
  fromDoseMg: number,
  toId: string,
): { toDoseMg: number; refUnits: number } | null {
  const meta = EQUIVALENCY_FAMILIES[family];
  const fromEntry = meta.entries.find((e) => e.id === fromId);
  const toEntry = meta.entries.find((e) => e.id === toId);
  if (!fromEntry || !toEntry || fromDoseMg <= 0) return null;
  const refUnits = fromDoseMg / fromEntry.equivalentMg;
  const toDoseMg = refUnits * toEntry.equivalentMg;
  return { toDoseMg, refUnits };
}

/**
 * For a given dose of a drug, return the dose expressed in family
 * reference units (e.g. "200 mg sertraline = 2 FLX-eq = 80 mg fluoxetine").
 */
export function doseInReferenceUnits(
  family: EquivalencyFamily,
  drugId: string,
  doseMg: number,
): { refUnits: number; referenceDoseMg: number } | null {
  const meta = EQUIVALENCY_FAMILIES[family];
  const entry = meta.entries.find((e) => e.id === drugId);
  if (!entry || doseMg <= 0) return null;
  const refUnits = doseMg / entry.equivalentMg;
  return { refUnits, referenceDoseMg: refUnits * meta.reference.mg };
}

/**
 * Round to a sensible clinical dose. Uses the half-up convention to the
 * nearest 0.5 mg below 5 mg, 1 mg up to 50 mg, 5 mg up to 200 mg, and
 * 25 mg above. Real prescribers will round again to formulation.
 */
export function roundToClinicalDose(mg: number): number {
  if (mg <= 0) return 0;
  if (mg < 5) return Math.round(mg * 2) / 2;
  if (mg < 50) return Math.round(mg);
  if (mg < 200) return Math.round(mg / 5) * 5;
  return Math.round(mg / 25) * 25;
}
