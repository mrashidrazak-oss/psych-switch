// Discontinuation-symptom flagger.
//
// Surfaces severity of the expected discontinuation syndrome on STOPPING
// the from-drug, plus mitigating strategies. Used by the Result screen to
// add a banner above the schedule when relevant.
//
// Sources
//   • Maudsley 15th, ch.3 "Discontinuation symptoms".
//   • Horowitz & Taylor 2019 (hyperbolic taper).
//
// Dart port of engine/discontinuation.ts.

/// Severity tier for a discontinuation flag.
enum DiscontinuationSeverity {
  low('low'),
  moderate('moderate'),
  high('high'),
  veryHigh('very_high');

  const DiscontinuationSeverity(this.jsonValue);

  final String jsonValue;

  static DiscontinuationSeverity fromJson(String value) {
    for (final s in DiscontinuationSeverity.values) {
      if (s.jsonValue == value) return s;
    }
    throw ArgumentError.value(
      value,
      'value',
      'unknown DiscontinuationSeverity',
    );
  }
}

/// Per-drug discontinuation flag.
class DiscontinuationFlag {
  const DiscontinuationFlag({
    required this.drugId,
    required this.severity,
    required this.symptoms,
    required this.strategy,
    this.halfLifeHours,
    this.citation,
  });

  final String drugId;
  final DiscontinuationSeverity severity;

  /// Patient-friendly summary.
  final String symptoms;

  /// What to do — the clinical recommendation.
  final String strategy;

  /// Half-life in hours, if relevant for the message.
  final num? halfLifeHours;

  final String? citation;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'drugId': drugId,
        'severity': severity.jsonValue,
        'symptoms': symptoms,
        'strategy': strategy,
        if (halfLifeHours != null) 'halfLifeHours': halfLifeHours,
        if (citation != null) 'citation': citation,
      };
}

class _Entry {
  const _Entry({
    required this.severity,
    required this.symptoms,
    required this.strategy,
    this.halfLifeHours,
    this.citation,
  });

  final DiscontinuationSeverity severity;
  final String symptoms;
  final String strategy;
  final num? halfLifeHours;
  final String? citation;
}

const Map<String, _Entry> _flags = <String, _Entry>{
  'paroxetine': _Entry(
    severity: DiscontinuationSeverity.veryHigh,
    symptoms:
        'Dizziness, electric-shock sensations, irritability, flu-like symptoms — onset 1–3 d.',
    strategy:
        'Hyperbolic taper over 8+ weeks, OR bridge with fluoxetine (Maudsley algorithm).',
    halfLifeHours: 21,
    citation: 'maudsley15_discontinuation_paroxetine',
  ),
  'venlafaxine': _Entry(
    severity: DiscontinuationSeverity.veryHigh,
    symptoms:
        'Severe rebound: dizziness, nausea, agitation. Patients often describe missed-dose symptoms.',
    strategy:
        'Switch to fluoxetine 20 mg (long t½) for 1–2 weeks before stopping, then taper fluoxetine.',
    halfLifeHours: 5,
    citation: 'maudsley15_discontinuation_venlafaxine',
  ),
  'desvenlafaxine': _Entry(
    severity: DiscontinuationSeverity.high,
    symptoms: 'Similar to venlafaxine but slightly less severe.',
    strategy: 'Cross-taper to fluoxetine, or hyperbolic taper.',
    halfLifeHours: 11,
  ),
  'duloxetine': _Entry(
    severity: DiscontinuationSeverity.high,
    symptoms: 'Dizziness, headache, paraesthesia.',
    strategy: 'Step down via 30 mg capsule for 2–4 weeks before stopping.',
    halfLifeHours: 12,
  ),
  'fluvoxamine': _Entry(
    severity: DiscontinuationSeverity.moderate,
    symptoms: 'Mild flu-like symptoms; less severe than paroxetine.',
    strategy: 'Standard cross-taper sufficient for most patients.',
    halfLifeHours: 15,
  ),
  'sertraline': _Entry(
    severity: DiscontinuationSeverity.moderate,
    symptoms: 'Mild dizziness, headache; usually self-limiting.',
    strategy: 'Standard cross-taper. Counsel patient about expected timeline.',
    halfLifeHours: 26,
  ),
  'escitalopram': _Entry(
    severity: DiscontinuationSeverity.moderate,
    symptoms: 'Mild — dizziness, sleep disturbance.',
    strategy: 'Standard cross-taper.',
    halfLifeHours: 30,
  ),
  'fluoxetine': _Entry(
    severity: DiscontinuationSeverity.low,
    symptoms: 'Long half-life provides intrinsic taper. Symptoms rare.',
    strategy:
        'Direct discontinuation usually tolerated. Patient may not even notice.',
    halfLifeHours: 96,
  ),
  'agomelatine': _Entry(
    severity: DiscontinuationSeverity.low,
    symptoms: 'No characteristic discontinuation syndrome.',
    strategy: 'Direct discontinuation acceptable.',
  ),
  'vortioxetine': _Entry(
    severity: DiscontinuationSeverity.low,
    symptoms: 'Limited data — appears mild.',
    strategy: 'Standard taper.',
  ),
  'mirtazapine': _Entry(
    severity: DiscontinuationSeverity.moderate,
    symptoms: 'Insomnia, anxiety, paraesthesia.',
    strategy: 'Reduce by 7.5 mg every 2 weeks.',
  ),

  // Antipsychotics — rebound psychosis / dyskinesia
  'clozapine': _Entry(
    severity: DiscontinuationSeverity.veryHigh,
    symptoms:
        'Severe rebound psychosis within 48–72 h; cholinergic rebound (sweating, GI).',
    strategy:
        'Cross-taper to another antipsychotic over ≥4 weeks. Never abrupt unless agranulocytosis.',
    citation: 'maudsley15_clozapine_stopping',
  ),
  'quetiapine': _Entry(
    severity: DiscontinuationSeverity.moderate,
    symptoms: 'Insomnia, nausea, rebound anxiety.',
    strategy:
        'Taper over 1–2 weeks if low-dose, longer if antipsychotic dose.',
  ),
  'olanzapine': _Entry(
    severity: DiscontinuationSeverity.moderate,
    symptoms:
        'Insomnia, agitation; cholinergic rebound (cramping, sweats).',
    strategy: 'Cross-taper over 2–4 weeks.',
  ),

  // Mood stabilizers
  'lithium': _Entry(
    severity: DiscontinuationSeverity.high,
    symptoms: 'Rebound mania within 90 days of abrupt stop.',
    strategy:
        'Taper over ≥3 months unless toxicity. Maintain alternative cover.',
    citation: 'maudsley15_lithium_stopping',
  ),
  'valproate': _Entry(
    severity: DiscontinuationSeverity.low,
    symptoms: 'Generally well-tolerated stopping.',
    strategy: 'Taper over 1–2 weeks if epilepsy comorbid; otherwise direct.',
  ),
  'lamotrigine': _Entry(
    severity: DiscontinuationSeverity.low,
    symptoms: 'Generally well-tolerated stopping.',
    strategy:
        'Taper over 2 weeks to avoid seizure risk if epilepsy comorbid.',
  ),
};

/// Get the flag for a single drug. Returns `null` if not registered (in
/// which case the engine should default to "low risk" silently).
DiscontinuationFlag? getDiscontinuationFlag(String drugId) {
  final entry = _flags[drugId];
  if (entry == null) return null;
  return DiscontinuationFlag(
    drugId: drugId,
    severity: entry.severity,
    symptoms: entry.symptoms,
    strategy: entry.strategy,
    halfLifeHours: entry.halfLifeHours,
    citation: entry.citation,
  );
}

/// Numeric rank for [DiscontinuationSeverity] — useful for sort/comparison.
/// low=0, moderate=1, high=2, veryHigh=3.
int severityRank(DiscontinuationSeverity s) {
  switch (s) {
    case DiscontinuationSeverity.low:
      return 0;
    case DiscontinuationSeverity.moderate:
      return 1;
    case DiscontinuationSeverity.high:
      return 2;
    case DiscontinuationSeverity.veryHigh:
      return 3;
  }
}
