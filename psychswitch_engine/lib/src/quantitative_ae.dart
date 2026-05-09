// Quantitative AE evidence — curated effect sizes from the major
// network meta-analyses. Surface these to clinicians who want a
// number, not a tier.
//
// Sources:
//   • Leucht S et al. Lancet 2013;382:951-62 — 15-AP NMA.
//   • Cipriani A et al. Lancet 2018;391:1357-66 — 21-AD NMA.
//   • Huhn M et al. Lancet 2019;394:939-51 — 32-AP NMA.
//
// We deliberately do NOT make up numbers — only cite values that
// appear in the published abstracts / forest plots. Drugs without
// published values in these NMAs are left to the tier-based predictor.
//
// Dart port of engine/quantitativeAe.ts.

/// Effect-size metric.
enum EffectMetric {
  or('OR'),
  smd('SMD'),
  kg('kg'),
  percent('percent');

  const EffectMetric(this.jsonValue);

  final String jsonValue;

  static EffectMetric fromJson(String value) {
    for (final m in EffectMetric.values) {
      if (m.jsonValue == value) return m;
    }
    throw ArgumentError.value(value, 'value', 'unknown EffectMetric');
  }
}

/// 95% confidence interval pair.
class EffectCi {
  const EffectCi({required this.low, required this.high});

  final num low;
  final num high;
}

/// One quantitative effect record.
class QuantitativeEffect {
  const QuantitativeEffect({
    required this.drugId,
    required this.aeId,
    required this.metric,
    required this.value,
    required this.citation,
    this.ci,
    this.vs,
    this.note,
  });

  final String drugId;
  final String aeId;
  final EffectMetric metric;

  /// Point estimate. Sign convention: positive = drug worse than placebo.
  final num value;

  /// Optional 95% CI.
  final EffectCi? ci;

  /// Reference comparator. Defaults to placebo.
  final String? vs;

  /// Citation key (resolved via citations.dart).
  final String citation;

  /// Free-text qualifier — when value is class-level not drug-level.
  final String? note;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'drugId': drugId,
        'aeId': aeId,
        'metric': metric.jsonValue,
        'value': value,
        if (ci != null) 'ci': <num>[ci!.low, ci!.high],
        if (vs != null) 'vs': vs,
        'citation': citation,
        if (note != null) 'note': note,
      };
}

const List<QuantitativeEffect> _data = <QuantitativeEffect>[
  // ── Leucht 2013 — antipsychotic response (SMD vs placebo) ─────────
  QuantitativeEffect(drugId: 'clozapine',      aeId: '_response', metric: EffectMetric.smd, value: -0.88, ci: EffectCi(low: -1.03, high: -0.73), citation: 'leucht2013_lancet_metaanalysis', note: 'Largest effect size in the 15-AP NMA.'),
  QuantitativeEffect(drugId: 'amisulpride',    aeId: '_response', metric: EffectMetric.smd, value: -0.66, ci: EffectCi(low: -0.78, high: -0.53), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'olanzapine',     aeId: '_response', metric: EffectMetric.smd, value: -0.59, ci: EffectCi(low: -0.65, high: -0.53), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'risperidone',    aeId: '_response', metric: EffectMetric.smd, value: -0.56, ci: EffectCi(low: -0.63, high: -0.50), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'paliperidone',   aeId: '_response', metric: EffectMetric.smd, value: -0.50, ci: EffectCi(low: -0.65, high: -0.35), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'haloperidol',    aeId: '_response', metric: EffectMetric.smd, value: -0.45, ci: EffectCi(low: -0.51, high: -0.39), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'quetiapine',     aeId: '_response', metric: EffectMetric.smd, value: -0.44, ci: EffectCi(low: -0.52, high: -0.35), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'aripiprazole',   aeId: '_response', metric: EffectMetric.smd, value: -0.43, ci: EffectCi(low: -0.51, high: -0.34), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'lurasidone',     aeId: '_response', metric: EffectMetric.smd, value: -0.33, ci: EffectCi(low: -0.45, high: -0.21), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'chlorpromazine', aeId: '_response', metric: EffectMetric.smd, value: -0.55, ci: EffectCi(low: -0.74, high: -0.36), citation: 'leucht2013_lancet_metaanalysis'),

  // ── Leucht 2013 — weight gain (kg over study period) ─────────────
  QuantitativeEffect(drugId: 'olanzapine',    aeId: 'weight_gain', metric: EffectMetric.kg, value: 2.78, ci: EffectCi(low: 2.44, high: 3.13), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'clozapine',     aeId: 'weight_gain', metric: EffectMetric.kg, value: 2.78, ci: EffectCi(low: 2.06, high: 3.50), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'quetiapine',    aeId: 'weight_gain', metric: EffectMetric.kg, value: 1.99, ci: EffectCi(low: 1.69, high: 2.30), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'risperidone',   aeId: 'weight_gain', metric: EffectMetric.kg, value: 1.59, ci: EffectCi(low: 1.32, high: 1.86), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'paliperidone',  aeId: 'weight_gain', metric: EffectMetric.kg, value: 1.50, ci: EffectCi(low: 0.92, high: 2.07), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'aripiprazole',  aeId: 'weight_gain', metric: EffectMetric.kg, value: 0.41, ci: EffectCi(low: 0.21, high: 0.62), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'lurasidone',    aeId: 'weight_gain', metric: EffectMetric.kg, value: 0.43, ci: EffectCi(low: 0.05, high: 0.81), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'haloperidol',   aeId: 'weight_gain', metric: EffectMetric.kg, value: 0.30, ci: EffectCi(low: 0.08, high: 0.52), citation: 'leucht2013_lancet_metaanalysis'),

  // ── Leucht 2013 — EPS (use of antiparkinson medication, OR vs placebo)
  QuantitativeEffect(drugId: 'haloperidol',   aeId: 'eps_akathisia', metric: EffectMetric.or, value: 4.76, ci: EffectCi(low: 3.50, high: 6.50), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'risperidone',   aeId: 'eps_akathisia', metric: EffectMetric.or, value: 1.78, ci: EffectCi(low: 1.45, high: 2.18), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'paliperidone',  aeId: 'eps_akathisia', metric: EffectMetric.or, value: 1.95, ci: EffectCi(low: 1.45, high: 2.62), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'aripiprazole',  aeId: 'eps_akathisia', metric: EffectMetric.or, value: 1.89, ci: EffectCi(low: 1.46, high: 2.45), citation: 'leucht2013_lancet_metaanalysis', note: 'Akathisia specifically — higher than parkinsonism.'),
  QuantitativeEffect(drugId: 'olanzapine',    aeId: 'eps_akathisia', metric: EffectMetric.or, value: 1.20, ci: EffectCi(low: 1.00, high: 1.43), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'quetiapine',    aeId: 'eps_akathisia', metric: EffectMetric.or, value: 1.01, ci: EffectCi(low: 0.83, high: 1.22), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'clozapine',     aeId: 'eps_akathisia', metric: EffectMetric.or, value: 0.30, ci: EffectCi(low: 0.18, high: 0.51), citation: 'leucht2013_lancet_metaanalysis'),

  // ── Leucht 2013 — prolactin (OR vs placebo) ─────────────────────
  QuantitativeEffect(drugId: 'paliperidone',  aeId: 'hyperprolactinaemia', metric: EffectMetric.or, value: 18.3, ci: EffectCi(low: 13.0, high: 25.6), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'risperidone',   aeId: 'hyperprolactinaemia', metric: EffectMetric.or, value: 9.93, ci: EffectCi(low: 7.59, high: 12.99), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'haloperidol',   aeId: 'hyperprolactinaemia', metric: EffectMetric.or, value: 4.16, ci: EffectCi(low: 3.07, high: 5.62), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'olanzapine',    aeId: 'hyperprolactinaemia', metric: EffectMetric.or, value: 1.54, ci: EffectCi(low: 1.16, high: 2.04), citation: 'leucht2013_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'aripiprazole',  aeId: 'hyperprolactinaemia', metric: EffectMetric.or, value: 0.18, ci: EffectCi(low: 0.10, high: 0.34), citation: 'leucht2013_lancet_metaanalysis', note: 'Reduces prolactin vs placebo.'),
  QuantitativeEffect(drugId: 'quetiapine',    aeId: 'hyperprolactinaemia', metric: EffectMetric.or, value: 0.61, ci: EffectCi(low: 0.43, high: 0.86), citation: 'leucht2013_lancet_metaanalysis'),

  // ── Cipriani 2018 — antidepressant response (OR vs placebo) ─────
  QuantitativeEffect(drugId: 'agomelatine',   aeId: '_response', metric: EffectMetric.or, value: 1.69, ci: EffectCi(low: 1.36, high: 2.10), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'mirtazapine',   aeId: '_response', metric: EffectMetric.or, value: 1.89, ci: EffectCi(low: 1.64, high: 2.20), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'paroxetine',    aeId: '_response', metric: EffectMetric.or, value: 1.75, ci: EffectCi(low: 1.61, high: 1.90), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'venlafaxine',   aeId: '_response', metric: EffectMetric.or, value: 1.78, ci: EffectCi(low: 1.61, high: 1.96), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'duloxetine',    aeId: '_response', metric: EffectMetric.or, value: 1.85, ci: EffectCi(low: 1.66, high: 2.07), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'escitalopram',  aeId: '_response', metric: EffectMetric.or, value: 1.68, ci: EffectCi(low: 1.50, high: 1.87), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'sertraline',    aeId: '_response', metric: EffectMetric.or, value: 1.67, ci: EffectCi(low: 1.49, high: 1.87), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'fluoxetine',    aeId: '_response', metric: EffectMetric.or, value: 1.52, ci: EffectCi(low: 1.40, high: 1.66), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'fluvoxamine',   aeId: '_response', metric: EffectMetric.or, value: 1.69, ci: EffectCi(low: 1.41, high: 2.02), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'vortioxetine',  aeId: '_response', metric: EffectMetric.or, value: 1.66, ci: EffectCi(low: 1.45, high: 1.92), citation: 'cipriani2018_lancet_metaanalysis'),

  // ── Cipriani 2018 — dropout due to side effects (OR vs placebo) ─
  QuantitativeEffect(drugId: 'paroxetine',    aeId: '_dropout_ae', metric: EffectMetric.or, value: 2.27, ci: EffectCi(low: 1.91, high: 2.69), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'fluvoxamine',   aeId: '_dropout_ae', metric: EffectMetric.or, value: 2.27, ci: EffectCi(low: 1.71, high: 3.01), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'duloxetine',    aeId: '_dropout_ae', metric: EffectMetric.or, value: 2.20, ci: EffectCi(low: 1.85, high: 2.62), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'venlafaxine',   aeId: '_dropout_ae', metric: EffectMetric.or, value: 1.85, ci: EffectCi(low: 1.60, high: 2.13), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'escitalopram',  aeId: '_dropout_ae', metric: EffectMetric.or, value: 1.30, ci: EffectCi(low: 1.04, high: 1.62), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'sertraline',    aeId: '_dropout_ae', metric: EffectMetric.or, value: 1.49, ci: EffectCi(low: 1.20, high: 1.84), citation: 'cipriani2018_lancet_metaanalysis'),
  QuantitativeEffect(drugId: 'agomelatine',   aeId: '_dropout_ae', metric: EffectMetric.or, value: 1.27, ci: EffectCi(low: 0.91, high: 1.78), citation: 'cipriani2018_lancet_metaanalysis'),
];

final Map<String, List<QuantitativeEffect>> _byDrug = (() {
  final m = <String, List<QuantitativeEffect>>{};
  for (final e in _data) {
    (m[e.drugId] ??= <QuantitativeEffect>[]).add(e);
  }
  return m;
})();

/// All quantitative effects registered for [drugId].
List<QuantitativeEffect> quantitativeFor(String drugId) =>
    List<QuantitativeEffect>.from(_byDrug[drugId] ?? const <QuantitativeEffect>[]);

/// Specific drug × AE record, or `null`.
QuantitativeEffect? quantitativeForAe(String drugId, String aeId) {
  for (final e in quantitativeFor(drugId)) {
    if (e.aeId == aeId) return e;
  }
  return null;
}

/// Snapshot of every quantitative effect record.
List<QuantitativeEffect> listAllQuantitative() =>
    List<QuantitativeEffect>.from(_data);

/// Render an effect as a short clinician-facing string.
/// Examples:
///   • OR 1.85 (1.60–2.13)
///   • SMD -0.88 (-1.03–-0.73)
///   • +2.78 kg (2.44–3.13)
///   • 50%
String formatEffect(QuantitativeEffect e) {
  final ci = e.ci;
  final ciSuffix =
      ci != null ? ' (${ci.low.toStringAsFixed(2)}–${ci.high.toStringAsFixed(2)})' : '';
  switch (e.metric) {
    case EffectMetric.or:
      return 'OR ${e.value.toStringAsFixed(2)}$ciSuffix';
    case EffectMetric.smd:
      return 'SMD ${e.value.toStringAsFixed(2)}$ciSuffix';
    case EffectMetric.kg:
      return '+${e.value.toStringAsFixed(2)} kg$ciSuffix';
    case EffectMetric.percent:
      return '${e.value.toStringAsFixed(0)}%';
  }
}
