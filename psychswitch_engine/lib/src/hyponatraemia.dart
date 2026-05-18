// Psychotropic-induced hyponatraemia / SIADH — workup + management.
//
// SSRIs/SNRIs, carbamazepine/oxcarbazepine, antipsychotics and (less
// commonly) other psychotropics are a frequently-missed cause of
// hyponatraemia, usually via SIADH. This engine bands severity by
// serum sodium AND symptoms, flags acute vs chronic (correction-rate
// risk), and gives a culprit-aware management plan. Summarised from
// the Maudsley 15e, NICE, and UK hyponatraemia consensus guidance.

enum HypoNaSeverity {
  none('No hyponatraemia'),
  mild('Mild'),
  moderate('Moderate'),
  severe('Severe');

  const HypoNaSeverity(this.label);
  final String label;
}

/// Symptom tokens accepted by [evaluateHyponatraemia].
const kHypoNaSevereFeatures = <String>{
  'seizures',
  'reduced_gcs',
  'coma',
  'cardiorespiratory_distress',
};
const kHypoNaModerateFeatures = <String>{
  'confusion',
  'vomiting',
  'headache',
  'unsteadiness',
  'drowsiness',
};

class HypoNaResult {
  const HypoNaResult({
    required this.severity,
    required this.headline,
    required this.steps,
    required this.cautions,
    required this.culprit,
    required this.acute,
  });

  final HypoNaSeverity severity;
  final String headline;
  final List<String> steps;
  final List<String> cautions;
  final String culprit;
  final bool acute;

  String clipboardSummary() {
    final lines = <String>[
      'Psychotropic hyponatraemia — ${severity.label}'
          '${acute ? ' (acute <48 h)' : ' (chronic / unknown onset)'}',
      headline,
      '',
      'Suspected culprit: $culprit',
      '',
      'Steps:',
      for (final s in steps) ' · $s',
      '',
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

HypoNaSeverity _bandFromSodium(double? na) {
  if (na == null) return HypoNaSeverity.none;
  if (na >= 135) return HypoNaSeverity.none;
  if (na >= 130) return HypoNaSeverity.mild;
  if (na >= 125) return HypoNaSeverity.moderate;
  return HypoNaSeverity.severe;
}

HypoNaSeverity _bandFromFeatures(Set<String> f) {
  if (f.any(kHypoNaSevereFeatures.contains)) return HypoNaSeverity.severe;
  if (f.any(kHypoNaModerateFeatures.contains)) {
    return HypoNaSeverity.moderate;
  }
  return HypoNaSeverity.none;
}

HypoNaResult evaluateHyponatraemia({
  double? sodium,
  Set<String> features = const <String>{},
  String culprit = 'SSRI / SNRI',
  bool acuteOnset = false,
}) {
  final byNa = _bandFromSodium(sodium);
  final bySx = _bandFromFeatures(features);
  final severity =
      byNa.index >= bySx.index ? byNa : bySx;

  final cautions = <String>[
    'Correct slowly: do NOT raise serum sodium by more than '
        '8–10 mmol/L in 24 h (≤ 8 mmol/L if chronic / high-risk) — '
        'over-rapid correction risks osmotic demyelination.',
    'Confirm SIADH only after excluding hypovolaemia, '
        'hypothyroidism, adrenal insufficiency and other causes '
        '(paired serum + urine osmolality and urine sodium).',
  ];
  if (acuteOnset) {
    cautions.insert(
      0,
      'Acute (<48 h) symptomatic hyponatraemia is the main setting '
          'where prompt hypertonic saline is justified — the '
          'demyelination risk is lower than in chronic.',
    );
  }

  switch (severity) {
    case HypoNaSeverity.none:
      return HypoNaResult(
        severity: severity,
        headline: sodium == null
            ? 'No sodium entered and no significant features.'
            : 'Sodium ${sodium.toStringAsFixed(0)} mmol/L — within '
                'or near range; no hyponatraemic features.',
        culprit: culprit,
        acute: acuteOnset,
        steps: const <String>[
          'No acute action. If on a high-risk drug, recheck sodium '
              'at ~2 and ~4 weeks after start / dose change, then '
              'periodically (esp. elderly, low body weight, '
              'diuretics, low baseline).',
        ],
        cautions: const <String>[],
      );
    case HypoNaSeverity.mild:
      return HypoNaResult(
        severity: severity,
        headline: 'Mild (130–134 mmol/L), little or no symptoms.',
        culprit: culprit,
        acute: acuteOnset,
        steps: <String>[
          'Confirm with a repeat sample; review fluid status and '
              'all contributing drugs (diuretics, NSAIDs, other '
              'psychotropics).',
          'Send paired serum/urine osmolality + urine sodium to '
              'characterise SIADH before changing treatment.',
          'Often manageable with fluid restriction and close '
              'monitoring; review the need for the culprit ($culprit) '
              'and consider a lower-risk alternative if continuing '
              'psychotropic treatment.',
        ],
        cautions: cautions,
      );
    case HypoNaSeverity.moderate:
      return HypoNaResult(
        severity: severity,
        headline:
            'Moderate (125–129 mmol/L) and/or moderate symptoms '
            '(confusion, vomiting, headache, unsteadiness).',
        culprit: culprit,
        acute: acuteOnset,
        steps: <String>[
          'Treat as a medical issue — involve / refer to acute '
              'medicine; do not manage in isolation on a psychiatric '
              'ward.',
          'Stop or switch the likely culprit ($culprit); fluid '
              'restriction; investigate and treat SIADH per medical '
              'team.',
          'Monitor sodium at least daily (more often if falling or '
              'symptomatic) and track the correction rate.',
        ],
        cautions: cautions,
      );
    case HypoNaSeverity.severe:
      return HypoNaResult(
        severity: severity,
        headline:
            'Severe (< 125 mmol/L) or severe symptoms (seizures, '
            'reduced GCS, coma) — medical emergency.',
        culprit: culprit,
        acute: acuteOnset,
        steps: <String>[
          'EMERGENCY: escalate now — acute medical / critical care. '
              'Severe symptomatic hyponatraemia may need controlled '
              'hypertonic (3%) saline boluses with senior medical '
              'oversight.',
          'Stop the culprit ($culprit) and all other contributors '
              'immediately.',
          'Sodium and neuro-obs frequently (e.g. every 2–4 h '
              'initially); strictly cap the 24 h rise.',
        ],
        cautions: cautions,
      );
  }
}
