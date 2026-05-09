// Adverse-effect reverse lookup.
//
// Clinical reality: the question is rarely "switch X to Y" — it's
// "patient on X has problem Z, what should I switch to?". This module
// answers that.
//
// For each common adverse effect, we list:
//   • drugs likely to cause it (so the clinician can identify the culprit)
//   • drugs unlikely to cause it (candidate switch targets)
//   • brief management notes
//
// Sources
//   • Maudsley 15th, side-effect tables per chapter
//   • Leucht 2013 Lancet network meta-analysis (antipsychotic AEs)
//   • Cipriani 2018 Lancet network meta-analysis (antidepressant AEs)
//
// Dart port of engine/adverseEffects.ts — entries byte-equivalent.

/// Top-level grouping for the AE picker UI.
enum AdverseEffectCategory {
  metabolic('metabolic'),
  extrapyramidal('extrapyramidal'),
  sexual('sexual'),
  sedation('sedation'),
  cardiovascular('cardiovascular'),
  gastrointestinal('gastrointestinal'),
  hematologic('hematologic'),
  cognitive('cognitive'),
  discontinuation('discontinuation');

  const AdverseEffectCategory(this.jsonValue);

  /// String literal used in JSON, mirrors TS union.
  final String jsonValue;

  static AdverseEffectCategory fromJson(String value) {
    for (final c in AdverseEffectCategory.values) {
      if (c.jsonValue == value) return c;
    }
    throw ArgumentError.value(
      value,
      'value',
      'unknown AdverseEffectCategory',
    );
  }
}

/// One adverse-effect record.
class AdverseEffect {
  const AdverseEffect({
    required this.id,
    required this.category,
    required this.label,
    required this.summary,
    required this.causedBy,
    required this.switchCandidates,
    required this.management,
    required this.citations,
  });

  final String id;
  final AdverseEffectCategory category;

  /// Patient-friendly label (e.g. "Weight gain").
  final String label;

  /// One-line description shown in the picker.
  final String summary;

  /// Drug IDs that commonly cause this AE.
  final List<String> causedBy;

  /// Drug IDs that rarely cause this AE — candidate switch targets.
  final List<String> switchCandidates;

  /// Free-form management tip ("first try dose reduction").
  final String management;

  final List<String> citations;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'category': category.jsonValue,
        'label': label,
        'summary': summary,
        'causedBy': causedBy,
        'switchCandidates': switchCandidates,
        'management': management,
        'citations': citations,
      };
}

/// All adverse-effect records.
const List<AdverseEffect> adverseEffects = <AdverseEffect>[
  // ── Antipsychotic AEs ──
  AdverseEffect(
    id: 'weight_gain',
    category: AdverseEffectCategory.metabolic,
    label: 'Weight gain / metabolic syndrome',
    summary:
        'Weight gain, dyslipidemia or new diabetes on an antipsychotic.',
    causedBy: <String>[
      'olanzapine',
      'clozapine',
      'quetiapine',
      'chlorpromazine',
      'risperidone',
      'paliperidone',
    ],
    switchCandidates: <String>[
      'aripiprazole',
      'lurasidone',
      'amisulpride',
      'haloperidol',
    ],
    management:
        'First: dose review + metformin + lifestyle. If sustained ≥7% weight gain → switch (Maudsley algorithm).',
    citations: <String>[
      'Leucht S, et al. Comparative efficacy and tolerability of 15 antipsychotic drugs. Lancet 2013;382:951–62.',
      'Maudsley Prescribing Guidelines, 15th ed. Table 4.16.',
    ],
  ),
  AdverseEffect(
    id: 'eps_akathisia',
    category: AdverseEffectCategory.extrapyramidal,
    label: 'EPS / akathisia',
    summary: 'Parkinsonism, dystonia, akathisia, tardive dyskinesia.',
    causedBy: <String>[
      'haloperidol',
      'risperidone',
      'paliperidone',
      'fluphenazine',
      'trifluoperazine',
      'aripiprazole',
      'amisulpride',
    ],
    switchCandidates: <String>[
      'olanzapine',
      'quetiapine',
      'clozapine',
      'lurasidone',
    ],
    management:
        'Akathisia → propranolol 20–80 mg or mirtazapine 15 mg. Parkinsonism → reduce dose or anticholinergic. Tardive → switch to clozapine.',
    citations: <String>['maudsley15_eps_management'],
  ),
  AdverseEffect(
    id: 'hyperprolactinaemia',
    category: AdverseEffectCategory.sexual,
    label: 'Hyperprolactinaemia',
    summary: 'Galactorrhoea, amenorrhoea, sexual dysfunction, low libido.',
    causedBy: <String>[
      'risperidone',
      'paliperidone',
      'amisulpride',
      'sulpiride',
      'haloperidol',
    ],
    switchCandidates: <String>[
      'aripiprazole',
      'quetiapine',
      'olanzapine',
      'clozapine',
    ],
    management:
        'Confirm prolactin >1000 mIU/L is drug-related. Aripiprazole adjunct (5–15 mg) often normalises levels without switch.',
    citations: <String>['maudsley15_prolactin'],
  ),
  AdverseEffect(
    id: 'sedation',
    category: AdverseEffectCategory.sedation,
    label: 'Sedation / cognitive blunting',
    summary: 'Excess somnolence, daytime drowsiness or "feeling flat".',
    causedBy: <String>[
      'olanzapine',
      'quetiapine',
      'clozapine',
      'chlorpromazine',
      'mirtazapine',
    ],
    switchCandidates: <String>[
      'aripiprazole',
      'lurasidone',
      'amisulpride',
      'haloperidol',
    ],
    management:
        'Try once-daily nocte dosing first. If persistent, switch to a less sedating agent.',
    citations: <String>['maudsley15_sedation'],
  ),
  AdverseEffect(
    id: 'qtc_prolongation',
    category: AdverseEffectCategory.cardiovascular,
    label: 'QTc prolongation',
    summary: 'QTc >450 ms (M) or >470 ms (F), or rising on serial ECG.',
    causedBy: <String>[
      'haloperidol',
      'sulpiride',
      'amisulpride',
      'chlorpromazine',
      'citalopram',
      'escitalopram',
    ],
    switchCandidates: <String>[
      'aripiprazole',
      'olanzapine',
      'lurasidone',
      'sertraline',
    ],
    management:
        'Stop QT-prolonger if QTc >500 ms. Correct K⁺/Mg²⁺. Switch to lowest-risk agent.',
    citations: <String>['maudsley15_qtc'],
  ),

  // ── Antidepressant AEs ──
  AdverseEffect(
    id: 'ssri_sexual',
    category: AdverseEffectCategory.sexual,
    label: 'SSRI sexual dysfunction',
    summary: 'Anorgasmia, ↓libido, erectile dysfunction.',
    causedBy: <String>[
      'paroxetine',
      'sertraline',
      'fluoxetine',
      'fluvoxamine',
      'escitalopram',
      'venlafaxine',
    ],
    switchCandidates: <String>['mirtazapine', 'agomelatine', 'vortioxetine'],
    management:
        'First: dose reduction or drug holiday. PDE5 inhibitor adjunct in men. Switch if persistent ≥4 weeks.',
    citations: <String>['maudsley15_sexual_ad'],
  ),
  AdverseEffect(
    id: 'gi_nausea',
    category: AdverseEffectCategory.gastrointestinal,
    label: 'GI nausea / dyspepsia',
    summary:
        'Persistent nausea, dyspepsia, diarrhoea on starting an antidepressant.',
    causedBy: <String>[
      'sertraline',
      'fluvoxamine',
      'venlafaxine',
      'duloxetine',
    ],
    switchCandidates: <String>['mirtazapine', 'escitalopram', 'agomelatine'],
    management:
        'Most resolve in 1–2 weeks. Take with food. If persistent → switch.',
    citations: <String>[],
  ),
  AdverseEffect(
    id: 'discontinuation_difficult',
    category: AdverseEffectCategory.discontinuation,
    label: 'Difficult discontinuation',
    summary: 'Severe rebound symptoms on missed dose or stopping.',
    causedBy: <String>['paroxetine', 'venlafaxine', 'duloxetine'],
    switchCandidates: <String>['fluoxetine'],
    management:
        'Bridge with fluoxetine (long t½ self-tapers) — Maudsley discontinuation algorithm.',
    citations: <String>['maudsley15_discontinuation'],
  ),
  AdverseEffect(
    id: 'insomnia',
    category: AdverseEffectCategory.sedation,
    label: 'Insomnia / activation',
    summary: 'Initial insomnia or activation on starting an SSRI/SNRI.',
    causedBy: <String>[
      'fluoxetine',
      'venlafaxine',
      'desvenlafaxine',
      'sertraline',
    ],
    switchCandidates: <String>['mirtazapine', 'agomelatine', 'paroxetine'],
    management:
        'Dose in the morning. If persistent → switch to a sedating agent (mirtazapine) or trazodone adjunct.',
    citations: <String>[],
  ),

  // ── Mood stabilizer AEs ──
  AdverseEffect(
    id: 'lithium_toxicity',
    category: AdverseEffectCategory.cognitive,
    label: 'Lithium tremor / cognitive blunting',
    summary: 'Fine tremor, "fogginess", or rising creatinine on lithium.',
    causedBy: <String>['lithium'],
    switchCandidates: <String>['valproate', 'lamotrigine', 'quetiapine'],
    management:
        'First: check level (target 0.6–0.8 in maintenance). If ≤0.8 and symptomatic, consider alternative mood stabilizer.',
    citations: <String>['maudsley15_lithium_tox'],
  ),
  AdverseEffect(
    id: 'valproate_teratogenicity',
    category: AdverseEffectCategory.metabolic,
    label: 'Valproate in woman of reproductive age',
    summary:
        'Patient on valproate becomes pregnant or planning pregnancy.',
    causedBy: <String>['valproate'],
    switchCandidates: <String>['lamotrigine', 'lithium', 'quetiapine'],
    management:
        'Urgent switch off valproate. Lamotrigine is preferred for bipolar maintenance in pregnancy (with folate 5 mg).',
    citations: <String>['maudsley15_valproate_pregnancy'],
  ),
];

/// Group AEs by category. Returns a map keyed by every
/// [AdverseEffectCategory], with empty lists when none registered.
Map<AdverseEffectCategory, List<AdverseEffect>> listByCategory() {
  final out = <AdverseEffectCategory, List<AdverseEffect>>{
    for (final c in AdverseEffectCategory.values) c: <AdverseEffect>[],
  };
  for (final ae in adverseEffects) {
    out[ae.category]!.add(ae);
  }
  return out;
}

/// Find the AE entries for a given drug, optionally filtered by category.
/// Used to surface a "this is a known issue" badge from other engines.
List<AdverseEffect> findAeFor(
  String drugId, {
  AdverseEffectCategory? category,
}) {
  return adverseEffects
      .where(
        (ae) =>
            ae.causedBy.contains(drugId) &&
            (category == null || ae.category == category),
      )
      .toList();
}

/// Display labels for each category. Mirrors TS `CATEGORY_LABELS`.
const Map<AdverseEffectCategory, String> categoryLabels =
    <AdverseEffectCategory, String>{
  AdverseEffectCategory.metabolic: 'Metabolic',
  AdverseEffectCategory.extrapyramidal: 'Extrapyramidal',
  AdverseEffectCategory.sexual: 'Sexual / endocrine',
  AdverseEffectCategory.sedation: 'Sedation / activation',
  AdverseEffectCategory.cardiovascular: 'Cardiovascular',
  AdverseEffectCategory.gastrointestinal: 'Gastrointestinal',
  AdverseEffectCategory.hematologic: 'Haematologic',
  AdverseEffectCategory.cognitive: 'Cognitive',
  AdverseEffectCategory.discontinuation: 'Discontinuation',
};
