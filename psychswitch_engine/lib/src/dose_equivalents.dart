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
//
// Dart port of engine/doseEquivalents.ts.

/// Equivalency family selector.
enum EquivalencyFamily {
  cpz('cpz'),
  fluoxetine('fluoxetine'),
  diazepam('diazepam');

  const EquivalencyFamily(this.jsonValue);

  final String jsonValue;

  static EquivalencyFamily fromJson(String value) {
    for (final f in EquivalencyFamily.values) {
      if (f.jsonValue == value) return f;
    }
    throw ArgumentError.value(value, 'value', 'unknown EquivalencyFamily');
  }
}

/// One drug row inside an equivalency family table.
class EquivalencyEntry {
  const EquivalencyEntry({
    required this.id,
    required this.genericName,
    required this.equivalentMg,
    this.notes,
    this.specialist = false,
  });

  /// Drug ID — matches `/content/drugs/<id>.json` when possible.
  final String id;

  /// Display name (free-form, may include trailing notes in parens).
  final String genericName;

  /// Reference dose (mg) that equals 1 unit of the family reference.
  final num equivalentMg;

  /// Optional caveat or footnote shown next to the entry.
  final String? notes;

  /// Whether this entry is a deprecated/MAOI/specialist drug — sorted
  /// lower in clinician-facing pickers.
  final bool specialist;
}

/// Reference drug + dose pairing (e.g. "Chlorpromazine 100 mg").
class EquivalencyReference {
  const EquivalencyReference({required this.name, required this.mg});

  final String name;
  final num mg;
}

/// Top-level metadata for one equivalency family.
class EquivalencyFamilyMeta {
  const EquivalencyFamilyMeta({
    required this.family,
    required this.title,
    required this.shortLabel,
    required this.reference,
    required this.intendedUse,
    required this.limitations,
    required this.citations,
    required this.lastReviewedISO,
    required this.entries,
  });

  final EquivalencyFamily family;
  final String title;
  final String shortLabel;
  final EquivalencyReference reference;

  /// What the calculator is good for.
  final String intendedUse;

  /// What the calculator is NOT good for.
  final List<String> limitations;

  /// Citations for the equivalency table.
  final List<String> citations;

  /// ISO date the table was last reviewed.
  final String lastReviewedISO;

  final List<EquivalencyEntry> entries;
}

// ── Chlorpromazine equivalents ────────────────────────────────────────────────
// Reference: chlorpromazine 100 mg/day = 1 CPZ-eq.
// Method: Leucht 2016 DDD-based equivalents, cross-checked against Maudsley 15th.

const List<EquivalencyEntry> _cpzEntries = <EquivalencyEntry>[
  EquivalencyEntry(id: 'haloperidol',     genericName: 'Haloperidol',     equivalentMg: 2,   notes: 'High EPS, low metabolic.'),
  EquivalencyEntry(id: 'risperidone',     genericName: 'Risperidone',     equivalentMg: 2,   notes: 'Prolactin↑ at >4 mg/d.'),
  EquivalencyEntry(id: 'paliperidone',    genericName: 'Paliperidone',    equivalentMg: 1.5, notes: 'Active metabolite of risperidone.'),
  EquivalencyEntry(id: 'olanzapine',      genericName: 'Olanzapine',      equivalentMg: 5,   notes: 'Metabolic risk; avoid in cardiometabolic disease.'),
  EquivalencyEntry(id: 'quetiapine',      genericName: 'Quetiapine',      equivalentMg: 100, notes: 'Sedating; >300 mg/d for antipsychotic effect.'),
  EquivalencyEntry(id: 'aripiprazole',    genericName: 'Aripiprazole',    equivalentMg: 7.5, notes: 'D2 partial agonist — equivalence approximate.', specialist: true),
  EquivalencyEntry(id: 'amisulpride',     genericName: 'Amisulpride',     equivalentMg: 100, notes: 'Renal clearance; reduce in CKD.'),
  EquivalencyEntry(id: 'sulpiride',       genericName: 'Sulpiride',       equivalentMg: 200, notes: 'Limited Asian RCT data.'),
  EquivalencyEntry(id: 'lurasidone',      genericName: 'Lurasidone',      equivalentMg: 40,  notes: 'Take with food (≥350 kcal) for absorption.'),
  EquivalencyEntry(id: 'clozapine',       genericName: 'Clozapine',       equivalentMg: 50,  notes: 'TRS only. Equivalence is weak; use plasma level.', specialist: true),
  EquivalencyEntry(id: 'trifluoperazine', genericName: 'Trifluoperazine', equivalentMg: 5,   notes: 'High EPS.'),
  EquivalencyEntry(id: 'fluphenazine',    genericName: 'Fluphenazine',    equivalentMg: 2,   notes: 'High EPS; depot available.'),
  EquivalencyEntry(id: 'flupenthixol',    genericName: 'Flupenthixol',    equivalentMg: 3,   notes: 'Depot available; activating at low dose.'),
  EquivalencyEntry(id: 'zuclopenthixol',  genericName: 'Zuclopenthixol',  equivalentMg: 25,  notes: 'Sedating; depot available.'),
  EquivalencyEntry(id: 'chlorpromazine',  genericName: 'Chlorpromazine',  equivalentMg: 100, notes: 'Reference drug. Anticholinergic, hypotension.'),
];

// ── Fluoxetine equivalents ───────────────────────────────────────────────────
// Reference: fluoxetine 40 mg/day = 1 FLX-eq.

const List<EquivalencyEntry> _flxEntries = <EquivalencyEntry>[
  EquivalencyEntry(id: 'fluoxetine',     genericName: 'Fluoxetine',     equivalentMg: 40,  notes: 'Reference. Long t½, self-tapering.'),
  EquivalencyEntry(id: 'escitalopram',   genericName: 'Escitalopram',   equivalentMg: 18,  notes: 'Round to 20 mg in practice.'),
  EquivalencyEntry(id: 'sertraline',     genericName: 'Sertraline',     equivalentMg: 100, notes: 'GI side effects most common.'),
  EquivalencyEntry(id: 'paroxetine',     genericName: 'Paroxetine',     equivalentMg: 25,  notes: 'High discontinuation risk; CYP2D6 inhibitor.'),
  EquivalencyEntry(id: 'fluvoxamine',    genericName: 'Fluvoxamine',    equivalentMg: 100, notes: 'CYP1A2 inhibitor — major DDI source.'),
  EquivalencyEntry(id: 'venlafaxine',    genericName: 'Venlafaxine',    equivalentMg: 150, notes: 'Above 150 mg/d adds NA reuptake.'),
  EquivalencyEntry(id: 'desvenlafaxine', genericName: 'Desvenlafaxine', equivalentMg: 75,  notes: 'Active metabolite of venlafaxine.'),
  EquivalencyEntry(id: 'duloxetine',     genericName: 'Duloxetine',     equivalentMg: 60),
  EquivalencyEntry(id: 'mirtazapine',    genericName: 'Mirtazapine',    equivalentMg: 30,  notes: 'NaSSA — equivalence is approximate.', specialist: true),
  EquivalencyEntry(id: 'vortioxetine',   genericName: 'Vortioxetine',   equivalentMg: 15,  notes: 'Multimodal — equivalence approximate.', specialist: true),
  EquivalencyEntry(id: 'agomelatine',    genericName: 'Agomelatine',    equivalentMg: 50,  notes: 'MT1/MT2 agonist — limited equivalence data.', specialist: true),
];

// ── Diazepam equivalents ──────────────────────────────────────────────────────
// Reference: diazepam 10 mg = 1 DZP-eq.

const List<EquivalencyEntry> _dzpEntries = <EquivalencyEntry>[
  EquivalencyEntry(id: 'diazepam',         genericName: 'Diazepam',         equivalentMg: 10,   notes: 'Reference. Long t½ (~30 h).'),
  EquivalencyEntry(id: 'lorazepam',        genericName: 'Lorazepam',        equivalentMg: 1,    notes: 'Short t½, no active metabolites.'),
  EquivalencyEntry(id: 'clonazepam',       genericName: 'Clonazepam',       equivalentMg: 0.5,  notes: 'Long t½ (~30 h).'),
  EquivalencyEntry(id: 'alprazolam',       genericName: 'Alprazolam',       equivalentMg: 0.5,  notes: 'Short t½, high dependence risk.'),
  EquivalencyEntry(id: 'temazepam',        genericName: 'Temazepam',        equivalentMg: 20,   notes: 'Hypnotic.'),
  EquivalencyEntry(id: 'nitrazepam',       genericName: 'Nitrazepam',       equivalentMg: 10,   notes: 'Hypnotic, long t½.'),
  EquivalencyEntry(id: 'midazolam',        genericName: 'Midazolam (oral)', equivalentMg: 7.5,  notes: 'IV/IM use is acute; dose differs.'),
  EquivalencyEntry(id: 'oxazepam',         genericName: 'Oxazepam',         equivalentMg: 20),
  EquivalencyEntry(id: 'chlordiazepoxide', genericName: 'Chlordiazepoxide', equivalentMg: 25,   notes: 'Used in alcohol withdrawal.'),
  EquivalencyEntry(id: 'bromazepam',       genericName: 'Bromazepam',       equivalentMg: 6),
  EquivalencyEntry(id: 'zopiclone',        genericName: 'Zopiclone',        equivalentMg: 7.5,  notes: 'Z-drug — pharmacology differs.', specialist: true),
  EquivalencyEntry(id: 'zolpidem',         genericName: 'Zolpidem',         equivalentMg: 10,   notes: 'Z-drug — pharmacology differs.', specialist: true),
];

/// Top-level family metadata, keyed by [EquivalencyFamily].
const Map<EquivalencyFamily, EquivalencyFamilyMeta> equivalencyFamilies =
    <EquivalencyFamily, EquivalencyFamilyMeta>{
  EquivalencyFamily.cpz: EquivalencyFamilyMeta(
    family: EquivalencyFamily.cpz,
    title: 'Chlorpromazine equivalents',
    shortLabel: 'CPZ-eq',
    reference: EquivalencyReference(name: 'Chlorpromazine', mg: 100),
    intendedUse:
        'Estimating cumulative antipsychotic load and orienting cross-titrations.',
    limitations: <String>[
      'Receptor profiles differ — equivalent dose ≠ equivalent efficacy or side-effect profile.',
      'Aripiprazole and clozapine equivalence is mechanistically weak. Use with caution.',
      'Not validated for LAI doses — convert to oral equivalent first.',
    ],
    citations: <String>[
      'Leucht S, Samara M, Heres S, Davis JM. Dose equivalents for antipsychotic drugs: the DDD method. Schizophr Bull. 2016;42(suppl 1):S90–S94.',
      'Maudsley Prescribing Guidelines, 15th ed. Table 4.1 (2024).',
    ],
    lastReviewedISO: '2026-05-04',
    entries: _cpzEntries,
  ),
  EquivalencyFamily.fluoxetine: EquivalencyFamilyMeta(
    family: EquivalencyFamily.fluoxetine,
    title: 'Fluoxetine equivalents',
    shortLabel: 'FLX-eq',
    reference: EquivalencyReference(name: 'Fluoxetine', mg: 40),
    intendedUse:
        'Orienting antidepressant dose during cross-tapers and audit.',
    limitations: <String>[
      'Equivalents are approximate and assume monotherapy.',
      'Mirtazapine, vortioxetine and agomelatine have non-SSRI mechanisms — equivalence is weaker.',
      'Does not account for CYP-mediated interactions during cross-taper.',
    ],
    citations: <String>[
      'Hayasaka Y, et al. Dose equivalents of antidepressants based on individual data. J Affect Disord 2015;180:179–84.',
      'Maudsley Prescribing Guidelines, 15th ed. (2024).',
    ],
    lastReviewedISO: '2026-05-04',
    entries: _flxEntries,
  ),
  EquivalencyFamily.diazepam: EquivalencyFamilyMeta(
    family: EquivalencyFamily.diazepam,
    title: 'Diazepam equivalents',
    shortLabel: 'DZP-eq',
    reference: EquivalencyReference(name: 'Diazepam', mg: 10),
    intendedUse:
        'Quantifying sedative load and supporting benzodiazepine tapers (Ashton method).',
    limitations: <String>[
      'Approximate for short-acting agents — clinical effect differs from total exposure.',
      'Z-drug equivalence is for orientation only; mechanism differs.',
      'Tolerance and dependence vary widely between agents.',
    ],
    citations: <String>[
      'Ashton CH. Benzodiazepines: How They Work and How to Withdraw. Newcastle, 2002.',
      'BNF 86 (2023–24).',
      'Maudsley Prescribing Guidelines, 15th ed. Table 5.3 (2024).',
    ],
    lastReviewedISO: '2026-05-04',
    entries: _dzpEntries,
  ),
};

/// Result of a cross-drug conversion within a single family.
class WithinFamilyConversion {
  const WithinFamilyConversion({
    required this.toDoseMg,
    required this.refUnits,
  });

  final num toDoseMg;
  final num refUnits;
}

/// Result of expressing a single dose in family reference units.
class ReferenceUnitsResult {
  const ReferenceUnitsResult({
    required this.refUnits,
    required this.referenceDoseMg,
  });

  final num refUnits;
  final num referenceDoseMg;
}

/// Convert a dose of one drug to an equivalent dose of another within the
/// same family. Returns `null` if either drug is not in the family table
/// or the input dose is non-positive.
WithinFamilyConversion? convertWithinFamily(
  EquivalencyFamily family,
  String fromId,
  num fromDoseMg,
  String toId,
) {
  final meta = equivalencyFamilies[family]!;
  final fromEntry =
      meta.entries.where((e) => e.id == fromId).cast<EquivalencyEntry?>().firstWhere(
            (e) => true,
            orElse: () => null,
          );
  final toEntry =
      meta.entries.where((e) => e.id == toId).cast<EquivalencyEntry?>().firstWhere(
            (e) => true,
            orElse: () => null,
          );
  if (fromEntry == null || toEntry == null || fromDoseMg <= 0) return null;
  final refUnits = fromDoseMg / fromEntry.equivalentMg;
  final toDoseMg = refUnits * toEntry.equivalentMg;
  return WithinFamilyConversion(toDoseMg: toDoseMg, refUnits: refUnits);
}

/// For a given dose of a drug, return the dose expressed in family
/// reference units (e.g. "200 mg sertraline = 2 FLX-eq = 80 mg fluoxetine").
ReferenceUnitsResult? doseInReferenceUnits(
  EquivalencyFamily family,
  String drugId,
  num doseMg,
) {
  final meta = equivalencyFamilies[family]!;
  final entry =
      meta.entries.where((e) => e.id == drugId).cast<EquivalencyEntry?>().firstWhere(
            (e) => true,
            orElse: () => null,
          );
  if (entry == null || doseMg <= 0) return null;
  final refUnits = doseMg / entry.equivalentMg;
  return ReferenceUnitsResult(
    refUnits: refUnits,
    referenceDoseMg: refUnits * meta.reference.mg,
  );
}

/// Round to a sensible clinical dose. Uses the half-up convention to the
/// nearest 0.5 mg below 5 mg, 1 mg up to 50 mg, 5 mg up to 200 mg, and
/// 25 mg above. Real prescribers will round again to formulation.
num roundToClinicalDose(num mg) {
  if (mg <= 0) return 0;
  if (mg < 5) return (mg * 2).round() / 2;
  if (mg < 50) return mg.round();
  if (mg < 200) return (mg / 5).round() * 5;
  return (mg / 25).round() * 25;
}
