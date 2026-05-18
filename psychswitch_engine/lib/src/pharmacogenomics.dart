// Pharmacogenomics quick reference — CYP2D6 and CYP2C19 metaboliser
// status implications for common psychotropics.
//
// Content summarised from CPIC guidelines (cpicpgx.org), the FDA
// Table of Pharmacogenetic Associations, and Maudsley 15e. Phenotype
// terms follow the CPIC standardised vocabulary.
//
// This is an educational quick reference, NOT a substitute for a
// CPIC-curated clinical decision-support system or a clinical
// pharmacologist's interpretation of an actual genotype result.

enum CypGene {
  cyp2d6('CYP2D6'),
  cyp2c19('CYP2C19');

  const CypGene(this.label);
  final String label;
}

enum Metaboliser {
  poor('Poor metaboliser'),
  intermediate('Intermediate metaboliser'),
  normal('Normal metaboliser'),
  rapid('Rapid metaboliser'),
  ultrarapid('Ultrarapid metaboliser');

  const Metaboliser(this.label);
  final String label;
}

class PgxEntry {
  const PgxEntry({
    required this.drugId,
    required this.drugName,
    required this.gene,
    required this.poor,
    required this.intermediate,
    required this.normal,
    required this.rapidOrUltrarapid,
  });

  final String drugId;
  final String drugName;
  final CypGene gene;

  /// Recommendation strings keyed by phenotype.
  final String poor;
  final String intermediate;
  final String normal;
  final String rapidOrUltrarapid;

  String forPhenotype(Metaboliser m) {
    switch (m) {
      case Metaboliser.poor:
        return poor;
      case Metaboliser.intermediate:
        return intermediate;
      case Metaboliser.normal:
        return normal;
      case Metaboliser.rapid:
      case Metaboliser.ultrarapid:
        return rapidOrUltrarapid;
    }
  }
}

const List<PgxEntry> kPgxTable = <PgxEntry>[
  // ── CYP2C19 — SSRIs / TCAs ───────────────────────────────────────
  PgxEntry(
    drugId: 'escitalopram',
    drugName: 'Escitalopram',
    gene: CypGene.cyp2c19,
    poor: 'Reduce starting dose ~50% and titrate slowly, OR choose a '
        'non-CYP2C19 agent. Higher exposure → QTc + adverse-effect '
        'risk.',
    intermediate: 'Initiate at standard dose; if adverse effects '
        'emerge consider a 25–50% reduction.',
    normal: 'Standard dosing.',
    rapidOrUltrarapid: 'Increased metabolism may cause '
        'non-response at standard dose. Consider an alternative '
        'agent not primarily metabolised by CYP2C19 or monitor '
        'response closely.',
  ),
  PgxEntry(
    drugId: 'citalopram',
    drugName: 'Citalopram',
    gene: CypGene.cyp2c19,
    poor: 'Reduce dose ~50%; the citalopram QTc warning is most '
        'relevant here. Max 20 mg/day if continued.',
    intermediate: 'Standard start; watch QTc at higher doses.',
    normal: 'Standard dosing (max 40 mg, 20 mg if > 65).',
    rapidOrUltrarapid: 'Possible sub-therapeutic exposure; monitor '
        'response, consider alternative.',
  ),
  PgxEntry(
    drugId: 'sertraline',
    drugName: 'Sertraline',
    gene: CypGene.cyp2c19,
    poor: 'Consider a 25–50% lower starting dose; titrate to '
        'response and tolerability.',
    intermediate: 'Standard dosing.',
    normal: 'Standard dosing.',
    rapidOrUltrarapid: 'Standard start; monitor for non-response.',
  ),
  // ── CYP2D6 — TCAs / SSRIs / antipsychotics ──────────────────────
  PgxEntry(
    drugId: 'amitriptyline',
    drugName: 'Amitriptyline',
    gene: CypGene.cyp2d6,
    poor: 'Avoid TCA, or reduce dose ~50% with plasma-level '
        'monitoring. High risk of anticholinergic + cardiac toxicity.',
    intermediate: 'Consider a 25% dose reduction with level '
        'monitoring.',
    normal: 'Standard dosing with usual level monitoring.',
    rapidOrUltrarapid: 'Avoid TCA or expect sub-therapeutic levels; '
        'use therapeutic drug monitoring to guide dosing.',
  ),
  PgxEntry(
    drugId: 'nortriptyline',
    drugName: 'Nortriptyline',
    gene: CypGene.cyp2d6,
    poor: 'Reduce dose ~50%; monitor plasma levels closely.',
    intermediate: 'Consider 25% reduction; monitor levels.',
    normal: 'Standard dosing with level monitoring.',
    rapidOrUltrarapid: 'Higher dose may be required; guide with '
        'plasma levels rather than empirically escalating.',
  ),
  PgxEntry(
    drugId: 'paroxetine',
    drugName: 'Paroxetine',
    gene: CypGene.cyp2d6,
    poor: 'Standard start but exposure is higher; be alert to '
        'adverse effects. (Paroxetine also potently inhibits its '
        'own clearance.)',
    intermediate: 'Standard dosing.',
    normal: 'Standard dosing.',
    rapidOrUltrarapid: 'Possible reduced response; consider an '
        'alternative agent or monitor response closely.',
  ),
  PgxEntry(
    drugId: 'fluoxetine',
    drugName: 'Fluoxetine',
    gene: CypGene.cyp2d6,
    poor: 'Standard start; be aware fluoxetine + norfluoxetine are '
        'strong CYP2D6 inhibitors — interaction risk dominates over '
        'genotype.',
    intermediate: 'Standard dosing.',
    normal: 'Standard dosing.',
    rapidOrUltrarapid: 'Genotype effect modest; clinical monitoring '
        'sufficient.',
  ),
  PgxEntry(
    drugId: 'venlafaxine',
    drugName: 'Venlafaxine',
    gene: CypGene.cyp2d6,
    poor: 'Higher venlafaxine : O-desmethyl ratio. Monitor for '
        'dose-related hypertension + adverse effects; consider lower '
        'titration.',
    intermediate: 'Standard dosing.',
    normal: 'Standard dosing.',
    rapidOrUltrarapid: 'Possible reduced exposure; monitor response.',
  ),
  PgxEntry(
    drugId: 'risperidone',
    drugName: 'Risperidone',
    gene: CypGene.cyp2d6,
    poor: 'Higher risperidone exposure → EPS + prolactin risk. '
        'Titrate slowly; consider a lower target dose.',
    intermediate: 'Standard dosing with EPS monitoring.',
    normal: 'Standard dosing.',
    rapidOrUltrarapid: 'Possible reduced active-moiety exposure; '
        'monitor efficacy.',
  ),
  PgxEntry(
    drugId: 'aripiprazole',
    drugName: 'Aripiprazole',
    gene: CypGene.cyp2d6,
    poor: 'Reduce dose to ~50% of usual maximum (label-recommended). '
        'Longer half-life → slower steady state.',
    intermediate: 'Standard dosing; monitor adverse effects.',
    normal: 'Standard dosing.',
    rapidOrUltrarapid: 'Possible reduced exposure; monitor response.',
  ),
  PgxEntry(
    drugId: 'haloperidol',
    drugName: 'Haloperidol',
    gene: CypGene.cyp2d6,
    poor: 'Higher exposure → EPS risk. Consider lower dose + close '
        'EPS monitoring.',
    intermediate: 'Standard dosing with EPS monitoring.',
    normal: 'Standard dosing.',
    rapidOrUltrarapid: 'Possible reduced response; monitor efficacy.',
  ),
];

/// All drugs with at least one PGx entry, de-duplicated, name-sorted.
List<({String id, String name})> pgxDrugs() {
  final seen = <String>{};
  final out = <({String id, String name})>[];
  for (final e in kPgxTable) {
    if (seen.add(e.drugId)) {
      out.add((id: e.drugId, name: e.drugName));
    }
  }
  out.sort((a, b) => a.name.compareTo(b.name));
  return out;
}

/// Entries for a given drug id (a drug may have a 2D6 + 2C19 entry).
List<PgxEntry> pgxEntriesFor(String drugId) =>
    kPgxTable.where((e) => e.drugId == drugId).toList();
