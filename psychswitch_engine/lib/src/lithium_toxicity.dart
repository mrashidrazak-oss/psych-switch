// Lithium toxicity — graded recognition + management.
//
// The TDM interpreter flags that a level is high; this engine grades
// the toxicity (level + clinical severity), gives the staged
// management, and surfaces the haemodialysis criteria. Summarised
// from the Maudsley 15e, EXTRIP workgroup recommendations
// (Decker 2015), and UK Renal / toxicology guidance.
//
// Severity is driven by the WORSE of (a) serum level band and
// (b) clinical features — a "therapeutic" level with cerebellar
// signs is still moderate toxicity (e.g. chronic toxicity in the
// elderly / renal impairment).

enum LithiumToxTier {
  none('No toxicity'),
  mild('Mild'),
  moderate('Moderate'),
  severe('Severe');

  const LithiumToxTier(this.label);
  final String label;
}

/// Clinical-feature buckets the clinician ticks.
class LithiumFeature {
  const LithiumFeature({
    required this.id,
    required this.label,
    required this.tier,
  });

  final String id;
  final String label;

  /// Severity this feature implies: 'mild' | 'moderate' | 'severe'.
  final String tier;
}

const List<LithiumFeature> kLithiumFeatures = <LithiumFeature>[
  LithiumFeature(
    id: 'gi',
    label: 'Nausea / vomiting / diarrhoea',
    tier: 'mild',
  ),
  LithiumFeature(
    id: 'fine_tremor',
    label: 'Fine tremor / mild lethargy',
    tier: 'mild',
  ),
  LithiumFeature(
    id: 'coarse_tremor',
    label: 'Coarse tremor / muscle weakness',
    tier: 'moderate',
  ),
  LithiumFeature(
    id: 'ataxia',
    label: 'Ataxia / dysarthria / nystagmus',
    tier: 'moderate',
  ),
  LithiumFeature(
    id: 'confusion',
    label: 'Confusion / disorientation',
    tier: 'moderate',
  ),
  LithiumFeature(
    id: 'seizures',
    label: 'Seizures',
    tier: 'severe',
  ),
  LithiumFeature(
    id: 'reduced_gcs',
    label: 'Reduced consciousness / coma',
    tier: 'severe',
  ),
  LithiumFeature(
    id: 'arrhythmia',
    label: 'Cardiac arrhythmia / haemodynamic instability',
    tier: 'severe',
  ),
  LithiumFeature(
    id: 'renal_failure',
    label: 'Acute kidney injury / unable to excrete lithium',
    tier: 'severe',
  ),
];

class LithiumToxResult {
  const LithiumToxResult({
    required this.tier,
    required this.level,
    required this.headline,
    required this.management,
    required this.dialysisIndicated,
    required this.dialysisRationale,
  });

  final LithiumToxTier tier;

  /// Serum level used (mmol/L); null if not entered.
  final double? level;

  final String headline;
  final String management;
  final bool dialysisIndicated;
  final String dialysisRationale;

  String clipboardSummary() {
    final lvl = level == null
        ? 'level not entered'
        : 'level ${level!.toStringAsFixed(2)} mmol/L';
    return 'Lithium toxicity — ${tier.label} ($lvl). $management '
        '${dialysisIndicated ? "Haemodialysis indicated: $dialysisRationale" : "Haemodialysis not indicated on current data."}';
  }
}

LithiumToxTier _tierFromLevel(double? level) {
  if (level == null) return LithiumToxTier.none;
  if (level >= 3.5) return LithiumToxTier.severe;
  if (level >= 2.5) return LithiumToxTier.moderate;
  if (level >= 1.5) return LithiumToxTier.mild;
  return LithiumToxTier.none;
}

LithiumToxTier _tierFromFeatures(Set<String> ticked) {
  var worst = LithiumToxTier.none;
  for (final f in kLithiumFeatures) {
    if (!ticked.contains(f.id)) continue;
    final t = switch (f.tier) {
      'severe' => LithiumToxTier.severe,
      'moderate' => LithiumToxTier.moderate,
      _ => LithiumToxTier.mild,
    };
    if (t.index > worst.index) worst = t;
  }
  return worst;
}

LithiumToxResult evaluateLithiumToxicity({
  double? level,
  required Set<String> features,
}) {
  final byLevel = _tierFromLevel(level);
  final byFeat = _tierFromFeatures(features);
  final tier =
      byLevel.index >= byFeat.index ? byLevel : byFeat;

  // EXTRIP-aligned dialysis triggers.
  final renalFailure = features.contains('renal_failure');
  final severeClinical = features.contains('seizures') ||
      features.contains('reduced_gcs') ||
      features.contains('arrhythmia');
  var dialysis = false;
  var rationale = '';
  if (level != null && level >= 4.0) {
    dialysis = true;
    rationale = 'level ≥ 4.0 mmol/L.';
  } else if (level != null &&
      level >= 2.5 &&
      (severeClinical || renalFailure)) {
    dialysis = true;
    rationale =
        'level ≥ 2.5 mmol/L with severe clinical toxicity and/or '
        'renal impairment limiting excretion.';
  } else if (severeClinical && renalFailure) {
    dialysis = true;
    rationale =
        'severe clinical toxicity with impaired lithium excretion.';
  }

  String headline;
  String management;
  switch (tier) {
    case LithiumToxTier.none:
      headline = 'No evidence of lithium toxicity.';
      management =
          'Continue routine monitoring. Re-check a level + U&E if '
          'symptoms develop, on dose change, or with any new '
          'interacting drug (NSAID / ACE-i / ARB / thiazide / '
          'dehydration).';
    case LithiumToxTier.mild:
      headline = 'Mild lithium toxicity.';
      management =
          'Withhold lithium. Encourage oral fluids; consider IV 0.9% '
          'saline. Recheck level + U&E in 6–12 h. Review for a '
          'precipitant (dehydration, NSAID/ACE-i/diuretic, intercurrent '
          'illness, dose error). Restart only when level + symptoms '
          'have settled.';
    case LithiumToxTier.moderate:
      headline = 'Moderate lithium toxicity.';
      management =
          'STOP lithium. IV 0.9% saline to restore euvolaemia + '
          'enhance renal excretion. Serial levels + U&E every 6 h, '
          'ECG, neuro-obs. Stop interacting drugs. Discuss with '
          'medical / toxicology; admit to a monitored bed.';
    case LithiumToxTier.severe:
      headline = 'Severe lithium toxicity — medical emergency.';
      management =
          'STOP lithium. Resuscitate (airway, IV access, 0.9% saline). '
          'Continuous cardiac + neuro monitoring; treat seizures with '
          'benzodiazepines. Urgent toxicology + renal + ICU referral. '
          'Levels every 4–6 h until clearly falling.';
  }

  return LithiumToxResult(
    tier: tier,
    level: level,
    headline: headline,
    management: management,
    dialysisIndicated: dialysis,
    dialysisRationale: dialysis
        ? rationale
        : 'Criteria not met — but reassess as levels / clinical '
            'state evolve, especially if excretion is impaired.',
  );
}
