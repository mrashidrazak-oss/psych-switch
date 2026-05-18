// Lamotrigine titration + rash / SJS triage.
//
// Lamotrigine's benefit depends on a SLOW titration — too-fast
// escalation is the key driver of serious rash (Stevens-Johnson /
// TEN / DRESS). Valproate roughly doubles lamotrigine levels (halve
// the schedule); enzyme inducers roughly halve them (faster / higher).
// This engine returns the comedication-correct schedule and triages
// any rash. Schedules are illustrative — confirm against the local
// label. Summarised from the Maudsley 15e and BNF.

enum LamotrigineComed {
  alone('Alone / non-interacting'),
  withValproate('With valproate'),
  withInducer('With an inducer, no valproate');

  const LamotrigineComed(this.label);
  final String label;
}

enum LamotrigineRashAction {
  none('No rash — continue titration'),
  reviewStop('Rash — withhold + urgent review'),
  emergency('STOP now — serious-rash emergency');

  const LamotrigineRashAction(this.label);
  final String label;
}

class LamotrigineRashFinding {
  const LamotrigineRashFinding(this.id, this.label, this.severity);
  final String id;
  final String label;

  /// 'amber' = withhold/review, 'red' = emergency stop.
  final String severity;
}

const kLamotrigineRashFindings = <LamotrigineRashFinding>[
  LamotrigineRashFinding(
      'any_rash', 'Any new rash during titration', 'amber'),
  LamotrigineRashFinding(
      'mucosal', 'Mucosal involvement (mouth / eyes / genitals)',
      'red'),
  LamotrigineRashFinding(
      'blistering', 'Blistering or skin peeling', 'red'),
  LamotrigineRashFinding(
      'systemic', 'Fever / lymphadenopathy / facial oedema',
      'red'),
  LamotrigineRashFinding(
      'unwell', 'Systemically unwell / mucositis', 'red'),
];

class LamotriginePlan {
  const LamotriginePlan({
    required this.comed,
    required this.rashAction,
    required this.headline,
    required this.schedule,
    required this.rashSteps,
    required this.cautions,
  });

  final LamotrigineComed comed;
  final LamotrigineRashAction rashAction;
  final String headline;
  final List<String> schedule;
  final List<String> rashSteps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Lamotrigine — ${comed.label} · ${rashAction.label}',
      headline,
      '',
      'Titration (illustrative):',
      for (final s in schedule) ' · $s',
      '',
      'Rash action:',
      for (final s in rashSteps) ' · $s',
      '',
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

const _alone = <String>[
  'Weeks 1–2: 25 mg once daily.',
  'Weeks 3–4: 50 mg once daily.',
  'Then increase by ~50 mg every 1–2 weeks.',
  'Usual maintenance ~100–200 mg/day (titrate to response).',
];

const _withValproate = <String>[
  'Weeks 1–2: 25 mg every OTHER day (valproate ~doubles levels).',
  'Weeks 3–4: 25 mg once daily.',
  'Then increase by ~25–50 mg every 1–2 weeks.',
  'Usual maintenance ~100–200 mg/day — lower target with '
      'valproate.',
];

const _withInducer = <String>[
  'Weeks 1–2: 50 mg once daily.',
  'Weeks 3–4: 100 mg/day in divided doses.',
  'Then increase by ~100 mg every 1–2 weeks.',
  'Usual maintenance ~200–400 mg/day (sometimes higher) with an '
      'inducer and no valproate.',
];

const _cautions = <String>[
  'Serious-rash risk is highest in the first ~8 weeks and with '
      'too-fast escalation, higher starting dose, or added '
      'valproate — never skip steps to "catch up".',
  'If lamotrigine has been missed for > ~5 days, RE-TITRATE from '
      'the start — do not resume at the previous dose.',
  'After a serious rash (SJS/TEN/DRESS) lamotrigine must NOT be '
      'restarted.',
];

LamotriginePlan buildLamotriginePlan({
  LamotrigineComed comed = LamotrigineComed.alone,
  Set<String> rashFindings = const <String>{},
}) {
  final schedule = switch (comed) {
    LamotrigineComed.alone => _alone,
    LamotrigineComed.withValproate => _withValproate,
    LamotrigineComed.withInducer => _withInducer,
  };

  final red = kLamotrigineRashFindings.any(
      (f) => f.severity == 'red' && rashFindings.contains(f.id));
  final amber = kLamotrigineRashFindings.any(
      (f) => f.severity == 'amber' && rashFindings.contains(f.id));

  LamotrigineRashAction action;
  String headline;
  List<String> rashSteps;
  if (red) {
    action = LamotrigineRashAction.emergency;
    headline =
        'Features of a serious rash (SJS / TEN / DRESS) — stop '
        'immediately and treat as an emergency.';
    rashSteps = <String>[
      'STOP lamotrigine now; urgent same-day medical / '
          'dermatology assessment.',
      'Do NOT rechallenge lamotrigine ever after a serious rash.',
      'Document, report via pharmacovigilance, and review the '
          'mood-stabiliser plan with the responsible consultant.',
    ];
  } else if (amber) {
    action = LamotrigineRashAction.reviewStop;
    headline =
        'A new rash during titration — withhold and assess for '
        'serious features before deciding.';
    rashSteps = <String>[
      'Withhold the next dose and review urgently; examine '
          'mucosae and look for systemic features.',
      'If any red feature (mucosal / blistering / systemic) — '
          'treat as a serious-rash emergency and do not '
          'rechallenge.',
      'Only consider cautious continuation if the rash is clearly '
          'benign and another cause is identified, with close '
          'review.',
    ];
  } else {
    action = LamotrigineRashAction.none;
    headline =
        'No rash entered — continue the slow titration and '
        'counsel on rash safety-netting.';
    rashSteps = <String>[
      'Continue the schedule; do not accelerate it.',
      'Counsel the patient to report ANY rash, mouth/eye '
          'involvement, fever or feeling unwell immediately.',
      'Re-titrate from the start if doses are missed for > ~5 '
          'days.',
    ];
  }

  return LamotriginePlan(
    comed: comed,
    rashAction: action,
    headline: headline,
    schedule: schedule,
    rashSteps: rashSteps,
    cautions: _cautions,
  );
}
