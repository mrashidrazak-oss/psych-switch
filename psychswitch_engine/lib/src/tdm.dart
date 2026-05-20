// Therapeutic drug monitoring interpreter.
//
// Maps a serum level (with units) to a subtherapeutic / therapeutic /
// supratherapeutic / toxic tier with a one-line clinical action.
// Limited (for now) to the four most-monitored psychotropics:
//   • lithium       (mmol/L)
//   • clozapine     (ng/mL)
//   • valproate     (μg/mL)
//   • lamotrigine   (μg/mL)
//
// Reference ranges paraphrased from Maudsley 15e + Stahl 7e + Cooper
// PK consensus.

enum TdmTier {
  subtherapeutic('subtherapeutic'),
  therapeuticLow('therapeutic_low'),
  therapeutic('therapeutic'),
  therapeuticHigh('therapeutic_high'),
  supratherapeutic('supratherapeutic'),
  toxic('toxic');

  const TdmTier(this.jsonValue);
  final String jsonValue;
}

String tdmTierLabel(TdmTier t) {
  switch (t) {
    case TdmTier.subtherapeutic:
      return 'Subtherapeutic';
    case TdmTier.therapeuticLow:
      return 'Lower therapeutic';
    case TdmTier.therapeutic:
      return 'Therapeutic';
    case TdmTier.therapeuticHigh:
      return 'Upper therapeutic';
    case TdmTier.supratherapeutic:
      return 'Supratherapeutic';
    case TdmTier.toxic:
      return 'Toxic';
  }
}

class TdmDrug {
  const TdmDrug({
    required this.id,
    required this.name,
    required this.unit,
    required this.subMax,
    required this.therapeuticLowMax,
    required this.therapeuticMax,
    required this.upperMax,
    required this.toxicFrom,
    required this.targetCopy,
    required this.timingCopy,
  });

  final String id;
  final String name;
  final String unit;

  /// Upper bound of each tier (inclusive).
  final double subMax;
  final double therapeuticLowMax;
  final double therapeuticMax;
  final double upperMax;

  /// Lower bound of frank toxicity (inclusive).
  final double toxicFrom;

  /// Display string for the therapeutic window.
  final String targetCopy;

  /// When to draw the sample.
  final String timingCopy;
}

const List<TdmDrug> kTdmDrugs = <TdmDrug>[
  TdmDrug(
    id: 'lithium',
    name: 'Lithium',
    unit: 'mmol/L',
    subMax: 0.4,
    therapeuticLowMax: 0.6,
    therapeuticMax: 0.8,
    upperMax: 1.0,
    toxicFrom: 1.5,
    targetCopy: 'Maintenance: 0.6–0.8 mmol/L · acute mania: 0.8–1.0',
    timingCopy: 'Trough — 12 h post-dose; weekly until stable, then '
        '6-monthly + 12-month TFT / U&E.',
  ),
  TdmDrug(
    id: 'clozapine',
    name: 'Clozapine',
    unit: 'ng/mL',
    subMax: 350,
    therapeuticLowMax: 450,
    therapeuticMax: 600,
    upperMax: 800,
    toxicFrom: 1000,
    targetCopy: 'Therapeutic: ≥ 350 ng/mL; aim 450–600 for refractory '
        'psychosis.',
    timingCopy: 'Trough — 12 h post-dose at steady state (week 1–2). '
        'Repeat after dose change or smoking change.',
  ),
  TdmDrug(
    id: 'valproate',
    name: 'Valproate',
    unit: 'μg/mL',
    subMax: 50,
    therapeuticLowMax: 75,
    therapeuticMax: 100,
    upperMax: 125,
    toxicFrom: 150,
    targetCopy: 'Bipolar / migraine: 50–100 μg/mL; epilepsy may '
        'require higher.',
    timingCopy: 'Trough — pre-dose. Check after 3–5 days at steady '
        'state.',
  ),
  TdmDrug(
    id: 'lamotrigine',
    name: 'Lamotrigine',
    unit: 'μg/mL',
    subMax: 3,
    therapeuticLowMax: 6,
    therapeuticMax: 12,
    upperMax: 15,
    toxicFrom: 20,
    targetCopy: 'Mood stabilisation: 3–12 μg/mL; many patients '
        'respond at lower end.',
    timingCopy: 'Trough — pre-dose. Steady state in ~5 days at a '
        'stable dose.',
  ),
];

TdmDrug? tdmDrugById(String id) {
  for (final d in kTdmDrugs) {
    if (d.id == id) return d;
  }
  return null;
}

class TdmInterpretation {
  const TdmInterpretation({
    required this.drug,
    required this.level,
    required this.tier,
    required this.headline,
    required this.action,
  });

  final TdmDrug drug;
  final double level;
  final TdmTier tier;
  final String headline;
  final String action;

  String clipboardSummary() {
    return '${drug.name} level ${level.toStringAsFixed(1)} '
        '${drug.unit} — ${tdmTierLabel(tier)}. $action';
  }
}

TdmInterpretation interpretLevel(TdmDrug drug, double level) {
  TdmTier tier;
  String headline;
  String action;
  if (level < drug.subMax) {
    tier = TdmTier.subtherapeutic;
    headline = 'Below therapeutic window.';
    action =
        'Confirm adherence + sampling time. Consider dose increase per '
        'clinical response.';
  } else if (level <= drug.therapeuticLowMax) {
    tier = TdmTier.therapeuticLow;
    headline = 'Lower end of the therapeutic window.';
    action =
        'Acceptable if clinically well; otherwise dose-up to mid-range.';
  } else if (level <= drug.therapeuticMax) {
    tier = TdmTier.therapeutic;
    headline = 'Within target window.';
    action =
        'Maintain current dose. Continue monitoring per protocol.';
  } else if (level <= drug.upperMax) {
    tier = TdmTier.therapeuticHigh;
    headline = 'Upper end of the therapeutic window.';
    action =
        'Tolerated if no adverse effects; review for early toxicity. '
        'Avoid further dose escalation unless refractory.';
  } else if (level < drug.toxicFrom) {
    tier = TdmTier.supratherapeutic;
    headline = 'Above the usual therapeutic window.';
    action =
        'Hold the next dose and recheck. Look for toxicity symptoms; '
        'reduce dose 20–30% on resumption.';
  } else {
    tier = TdmTier.toxic;
    headline = 'TOXIC range — clinical emergency.';
    action =
        'HOLD the drug immediately. Senior medical / toxicology review. '
        'Hydration, electrolytes, ECG, consider haemodialysis (lithium '
        'levels > 4 mmol/L or symptomatic at 2.5–4).';
  }
  return TdmInterpretation(
    drug: drug,
    level: level,
    tier: tier,
    headline: headline,
    action: action,
  );
}
