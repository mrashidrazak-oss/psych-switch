// Monitoring schedule generator.
//
// Given a switching plan + patient context, produce a date-stamped list
// of investigations and clinical reviews to schedule alongside the
// titration.
//
// Sources
//   • Maudsley 15th: monitoring chapters per drug class
//   • BAP 2020: schizophrenia monitoring guidance
//   • NICE NG178 (psychosis), NG222 (depression)
//   • Malaysian CPG schizophrenia, mood disorders
//
// Design
//   • Each drug declares the monitoring it triggers via [_rules].
//   • Patient context can ADD entries (e.g. ECG if cardiac flagged).
//   • Day-offsets are relative to the switch start (Day 0).
//   • Exported as a flat, sorted list that the UI can render as a checklist.
//
// Dart port of engine/monitoring.ts.

import 'package:psychswitch/src/engine/patient_context_pure.dart';

/// Category groups for [MonitoringEntry] (drives icon + filtering in UI).
enum MonitoringCategory {
  lab('lab'),
  ecg('ecg'),
  physical('physical'),
  rating('rating'),
  review('review');

  const MonitoringCategory(this.jsonValue);

  final String jsonValue;

  static MonitoringCategory fromJson(String value) {
    for (final c in MonitoringCategory.values) {
      if (c.jsonValue == value) return c;
    }
    throw ArgumentError.value(
      value,
      'value',
      'unknown MonitoringCategory',
    );
  }
}

/// Recurring schedule for a [MonitoringEntry] (e.g. weekly clozapine FBC).
class MonitoringRecurrence {
  const MonitoringRecurrence({required this.everyDays, this.untilDay});

  final int everyDays;
  final int? untilDay;
}

/// One monitoring item.
class MonitoringEntry {
  const MonitoringEntry({
    required this.dayOffset,
    required this.label,
    required this.detail,
    required this.category,
    this.drugId,
    this.citation,
    this.recurring,
  });

  final int dayOffset;
  final String label;
  final String detail;
  final MonitoringCategory category;
  final String? drugId;
  final String? citation;
  final MonitoringRecurrence? recurring;

  MonitoringEntry copyWith({
    int? dayOffset,
    String? drugId,
    MonitoringRecurrence? recurring,
    bool clearRecurring = false,
  }) =>
      MonitoringEntry(
        dayOffset: dayOffset ?? this.dayOffset,
        label: label,
        detail: detail,
        category: category,
        drugId: drugId ?? this.drugId,
        citation: citation,
        recurring: clearRecurring ? null : (recurring ?? this.recurring),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dayOffset': dayOffset,
        'label': label,
        'detail': detail,
        'category': category.jsonValue,
        if (drugId != null) 'drugId': drugId,
        if (citation != null) 'citation': citation,
        if (recurring != null)
          'recurring': <String, dynamic>{
            'everyDays': recurring!.everyDays,
            if (recurring!.untilDay != null) 'untilDay': recurring!.untilDay,
          },
      };
}

class _DrugRules {
  const _DrugRules({required this.baseline, required this.ongoing});

  final List<MonitoringEntry> baseline;
  final List<MonitoringEntry> ongoing;
}

// ── Drug-specific monitoring ────────────────────────────────────────────────

const Map<String, _DrugRules> _rules = <String, _DrugRules>{
  'lithium': _DrugRules(
    baseline: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 0, label: 'U&E + eGFR', detail: 'Baseline renal function before lithium.', category: MonitoringCategory.lab, citation: 'maudsley15_mood_lithium_monitoring'),
      MonitoringEntry(dayOffset: 0, label: 'TFT',        detail: 'Baseline thyroid function.',              category: MonitoringCategory.lab, citation: 'maudsley15_mood_lithium_monitoring'),
      MonitoringEntry(dayOffset: 0, label: 'Calcium',    detail: 'Baseline Ca²⁺ (lithium causes hyperparathyroidism).', category: MonitoringCategory.lab),
      MonitoringEntry(dayOffset: 0, label: 'ECG',        detail: 'Baseline ECG if cardiac history or age >40.',        category: MonitoringCategory.ecg),
      MonitoringEntry(dayOffset: 0, label: 'βHCG',       detail: 'Pregnancy test in women of reproductive age.',       category: MonitoringCategory.lab),
    ],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 7,   label: 'Lithium level', detail: 'Trough level 12 h post-dose, 5–7 d after each dose change.', category: MonitoringCategory.lab, citation: 'maudsley15_mood_lithium_monitoring'),
      MonitoringEntry(dayOffset: 90,  label: 'Lithium level', detail: 'Routine 3-monthly trough; aim 0.6–1.0 mmol/L.',              category: MonitoringCategory.lab, recurring: MonitoringRecurrence(everyDays: 90)),
      MonitoringEntry(dayOffset: 180, label: 'U&E + TFT',     detail: '6-monthly renal + thyroid review.',                          category: MonitoringCategory.lab, recurring: MonitoringRecurrence(everyDays: 180)),
    ],
  ),
  'valproate': _DrugRules(
    baseline: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 0, label: 'LFT',  detail: 'Baseline AST/ALT (hepatotoxicity risk).',  category: MonitoringCategory.lab, citation: 'maudsley15_mood_valproate'),
      MonitoringEntry(dayOffset: 0, label: 'FBC',  detail: 'Baseline platelets (thrombocytopenia risk).', category: MonitoringCategory.lab),
      MonitoringEntry(dayOffset: 0, label: 'βHCG', detail: 'Pregnancy test — valproate is teratogenic.', category: MonitoringCategory.lab),
    ],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 30,  label: 'LFT + FBC',   detail: '4-week LFT + platelet check.',          category: MonitoringCategory.lab),
      MonitoringEntry(dayOffset: 180, label: 'Level + LFT', detail: '6-monthly level + LFTs.',                category: MonitoringCategory.lab, recurring: MonitoringRecurrence(everyDays: 180)),
    ],
  ),
  'carbamazepine': _DrugRules(
    baseline: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 0, label: 'FBC + LFT', detail: 'Baseline (agranulocytosis, hepatitis).', category: MonitoringCategory.lab, citation: 'maudsley15_mood_carbamazepine'),
      MonitoringEntry(dayOffset: 0, label: 'U&E',       detail: 'Baseline (SIADH risk).',                  category: MonitoringCategory.lab),
    ],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 14, label: 'FBC + LFT', detail: 'Week-2 check; repeat at week 4.',                                       category: MonitoringCategory.lab),
      MonitoringEntry(dayOffset: 28, label: 'Level',     detail: 'CBZ level once auto-induction stabilises (~2 weeks at steady dose).', category: MonitoringCategory.lab),
    ],
  ),
  'lamotrigine': _DrugRules(
    baseline: <MonitoringEntry>[],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 14, label: 'Skin review', detail: 'Counsel + review for SJS/TEN — first 8 weeks.', category: MonitoringCategory.review),
    ],
  ),
  'clozapine': _DrugRules(
    baseline: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 0, label: 'FBC',          detail: 'Baseline ANC ≥2.0 required to start.', category: MonitoringCategory.lab,      citation: 'maudsley15_clozapine_monitoring'),
      MonitoringEntry(dayOffset: 0, label: 'ECG',          detail: 'Baseline ECG (myocarditis screening).', category: MonitoringCategory.ecg),
      MonitoringEntry(dayOffset: 0, label: 'Trop + CRP',   detail: 'Baseline trop/CRP (myocarditis screening).', category: MonitoringCategory.lab),
      MonitoringEntry(dayOffset: 0, label: 'BMI + lipids', detail: 'Metabolic baseline.', category: MonitoringCategory.physical),
    ],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 7,   label: 'Weekly FBC',       detail: 'Weekly FBC weeks 1–18.',     category: MonitoringCategory.lab, recurring: MonitoringRecurrence(everyDays: 7,  untilDay: 126), citation: 'maudsley15_clozapine_monitoring'),
      MonitoringEntry(dayOffset: 7,   label: 'Trop + CRP',       detail: 'Weekly trop/CRP weeks 1–4.', category: MonitoringCategory.lab, recurring: MonitoringRecurrence(everyDays: 7,  untilDay: 28)),
      MonitoringEntry(dayOffset: 126, label: 'Fortnightly FBC',  detail: 'Fortnightly FBC weeks 19–52.', category: MonitoringCategory.lab, recurring: MonitoringRecurrence(everyDays: 14, untilDay: 365)),
    ],
  ),
  'olanzapine': _DrugRules(
    baseline: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 0, label: 'BMI + waist',    detail: 'Metabolic baseline.', category: MonitoringCategory.physical, citation: 'maudsley15_aps_metabolic'),
      MonitoringEntry(dayOffset: 0, label: 'HbA1c + lipids', detail: 'Baseline glucose + lipids.', category: MonitoringCategory.lab),
    ],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 30, label: 'Weight',         detail: '4-week weight + side-effect review.', category: MonitoringCategory.physical),
      MonitoringEntry(dayOffset: 90, label: 'HbA1c + lipids', detail: '3-monthly metabolic for first year.', category: MonitoringCategory.lab, recurring: MonitoringRecurrence(everyDays: 90, untilDay: 365)),
    ],
  ),
  'quetiapine': _DrugRules(
    baseline: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 0, label: 'BMI + lipids', detail: 'Metabolic baseline.', category: MonitoringCategory.physical),
    ],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 90, label: 'HbA1c + lipids', detail: '3-monthly metabolic.', category: MonitoringCategory.lab, recurring: MonitoringRecurrence(everyDays: 90, untilDay: 365)),
    ],
  ),
  'haloperidol': _DrugRules(
    baseline: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 0, label: 'ECG',  detail: 'Baseline ECG (QTc risk, dose-dependent).', category: MonitoringCategory.ecg, citation: 'maudsley15_aps_qtc'),
      MonitoringEntry(dayOffset: 0, label: 'ESRS', detail: 'Extrapyramidal symptom rating baseline.',  category: MonitoringCategory.rating),
    ],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 14, label: 'ESRS',      detail: 'Repeat ESRS at week 2.',                                category: MonitoringCategory.rating),
      MonitoringEntry(dayOffset: 30, label: 'ECG (rpt)', detail: 'Repeat ECG at therapeutic dose, then annually.',        category: MonitoringCategory.ecg),
    ],
  ),
  'amisulpride': _DrugRules(
    baseline: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 0, label: 'eGFR', detail: 'Renal clearance — adjust dose if reduced.', category: MonitoringCategory.lab),
      MonitoringEntry(dayOffset: 0, label: 'ECG',  detail: 'Baseline ECG (dose-dependent QTc).',         category: MonitoringCategory.ecg),
    ],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 30, label: 'ECG', detail: 'Repeat ECG once at target dose if >400 mg/day.', category: MonitoringCategory.ecg),
    ],
  ),
  'risperidone': _DrugRules(
    baseline: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 0, label: 'Prolactin', detail: 'Baseline prolactin if symptomatic.', category: MonitoringCategory.lab),
    ],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 90, label: 'Prolactin', detail: '3-monthly prolactin if symptomatic.', category: MonitoringCategory.lab),
    ],
  ),
  'paliperidone': _DrugRules(
    baseline: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 0, label: 'Prolactin', detail: 'Active metabolite of risperidone — same prolactin profile.', category: MonitoringCategory.lab),
      MonitoringEntry(dayOffset: 0, label: 'eGFR',      detail: 'Renal clearance — adjust if eGFR <50.',                       category: MonitoringCategory.lab),
    ],
    ongoing: <MonitoringEntry>[],
  ),
  'aripiprazole': _DrugRules(
    baseline: <MonitoringEntry>[],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 14, label: 'Akathisia review', detail: 'Akathisia is the most common dose-limiting AE.', category: MonitoringCategory.review),
    ],
  ),
  'escitalopram': _DrugRules(
    baseline: <MonitoringEntry>[],
    ongoing: <MonitoringEntry>[
      MonitoringEntry(dayOffset: 14, label: 'Mood + suicidality', detail: '2-week mood + suicidality review.',           category: MonitoringCategory.review),
      MonitoringEntry(dayOffset: 14, label: 'ECG (if >20 mg)',    detail: 'ECG if dose >20 mg/day or cardiac history.',  category: MonitoringCategory.ecg),
    ],
  ),
};

const _DrugRules _adGeneric = _DrugRules(
  baseline: <MonitoringEntry>[],
  ongoing: <MonitoringEntry>[
    MonitoringEntry(dayOffset: 14, label: 'Mood + suicidality', detail: '2-week mood + suicidality review.', category: MonitoringCategory.review),
    MonitoringEntry(dayOffset: 28, label: 'Response check',     detail: '4-week response review (PHQ-9 / HAM-D).', category: MonitoringCategory.rating),
  ],
);

const _DrugRules _apGeneric = _DrugRules(
  baseline: <MonitoringEntry>[
    MonitoringEntry(dayOffset: 0, label: 'BMI + waist',    detail: 'Metabolic baseline (NICE / Maudsley).', category: MonitoringCategory.physical),
    MonitoringEntry(dayOffset: 0, label: 'HbA1c + lipids', detail: 'Baseline glucose + lipids.',           category: MonitoringCategory.lab),
  ],
  ongoing: <MonitoringEntry>[
    MonitoringEntry(dayOffset: 14, label: 'ESRS / EPS review', detail: '2-week side-effect review.', category: MonitoringCategory.review),
    MonitoringEntry(dayOffset: 90, label: 'HbA1c + lipids',    detail: '3-monthly first year.',       category: MonitoringCategory.lab, recurring: MonitoringRecurrence(everyDays: 90, untilDay: 365)),
  ],
);

const Set<String> _antidepressants = <String>{
  'fluoxetine',
  'sertraline',
  'paroxetine',
  'fluvoxamine',
  'escitalopram',
  'venlafaxine',
  'desvenlafaxine',
  'duloxetine',
  'mirtazapine',
  'vortioxetine',
  'agomelatine',
};
const Set<String> _antipsychoticsBasic = <String>{
  'sulpiride',
  'chlorpromazine',
  'trifluoperazine',
  'fluphenazine',
  'flupenthixol',
  'zuclopenthixol',
  'lurasidone',
};

// ── Patient-context add-ons ─────────────────────────────────────────────────

List<MonitoringEntry> _contextAddOns(PatientContext ctx) {
  final out = <MonitoringEntry>[];
  final como = ctx.comorbidities;
  if (como?.cardiac ?? false) {
    out.add(
      const MonitoringEntry(
        dayOffset: 0,
        label: 'ECG (cardiac hx)',
        detail:
            'Cardiac comorbidity flagged — baseline ECG before any QTc-prolonger.',
        category: MonitoringCategory.ecg,
      ),
    );
  }
  if ((como?.diabetes ?? false) || (como?.dyslipidemia ?? false)) {
    out.add(
      const MonitoringEntry(
        dayOffset: 30,
        label: 'HbA1c (metabolic)',
        detail: 'Existing metabolic comorbidity — earlier 4-week HbA1c.',
        category: MonitoringCategory.lab,
      ),
    );
  }
  if (ctx.pregnant ?? false) {
    out.add(
      const MonitoringEntry(
        dayOffset: 0,
        label: 'Antenatal liaison',
        detail: 'Coordinate with obstetrics; review in MDT before any change.',
        category: MonitoringCategory.review,
      ),
    );
  }
  return out;
}

// ── Generator ───────────────────────────────────────────────────────────────

class MonitoringPlan {
  const MonitoringPlan({
    required this.entries,
    required this.citations,
    required this.spanDays,
  });

  final List<MonitoringEntry> entries;
  final List<String> citations;

  /// Total days the plan extends (for calendar rendering).
  final int spanDays;
}

_DrugRules? _rulesFor(String drugId) {
  final r = _rules[drugId];
  if (r != null) return r;
  if (_antidepressants.contains(drugId)) return _adGeneric;
  if (_antipsychoticsBasic.contains(drugId)) return _apGeneric;
  return null;
}

/// Build a [MonitoringPlan] for a single switch.
MonitoringPlan generateMonitoringPlan({
  required String toDrugId,
  String? fromDrugId,
  PatientContext? context,
  int durationDays = 90,
}) {
  final all = <MonitoringEntry>[];

  void addRules(String drugId) {
    final rules = _rulesFor(drugId);
    if (rules == null) return;
    for (final e in rules.baseline) {
      all.add(e.copyWith(drugId: drugId));
    }
    for (final e in rules.ongoing) {
      all.add(e.copyWith(drugId: drugId));
    }
  }

  addRules(toDrugId);
  if (fromDrugId != null && fromDrugId != toDrugId) {
    final fromRules = _rules[fromDrugId];
    if (fromRules != null) {
      for (final e in fromRules.ongoing) {
        if (e.category == MonitoringCategory.rating ||
            e.category == MonitoringCategory.review) {
          all.add(e.copyWith(drugId: fromDrugId));
        }
      }
    }
  }

  if (context != null) all.addAll(_contextAddOns(context));

  // Deduplicate by (label + dayOffset) — keep the more detailed entry.
  final seen = <String, MonitoringEntry>{};
  for (final e in all) {
    final key = '${e.label}|${e.dayOffset}';
    final prior = seen[key];
    if (prior == null || e.detail.length > prior.detail.length) {
      seen[key] = e;
    }
  }
  final deduped = seen.values.toList();

  // Expand recurring entries up to durationDays.
  final expanded = <MonitoringEntry>[];
  for (final e in deduped) {
    expanded.add(e);
    final rec = e.recurring;
    if (rec != null) {
      final stop =
          (rec.untilDay ?? durationDays) < durationDays
              ? (rec.untilDay ?? durationDays)
              : durationDays;
      for (var d = e.dayOffset + rec.everyDays;
          d <= stop;
          d += rec.everyDays) {
        expanded.add(e.copyWith(dayOffset: d, clearRecurring: true));
      }
    }
  }

  expanded.sort((a, b) {
    final byDay = a.dayOffset.compareTo(b.dayOffset);
    return byDay != 0 ? byDay : a.label.compareTo(b.label);
  });

  final citations = <String>[];
  for (final e in expanded) {
    final c = e.citation;
    if (c != null && !citations.contains(c)) citations.add(c);
  }

  var spanDays = durationDays;
  for (final e in expanded) {
    if (e.dayOffset > spanDays) spanDays = e.dayOffset;
  }
  if (spanDays < 90) spanDays = 90;

  return MonitoringPlan(
    entries: expanded,
    citations: citations,
    spanDays: spanDays,
  );
}
