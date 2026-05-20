// Clozapine-induced myocarditis — first-weeks surveillance + triage.
//
// Myocarditis is an early (usually first 6–8 weeks), potentially
// fatal clozapine reaction that routine FBC monitoring does NOT
// detect. Structured troponin / CRP / HR surveillance during titration
// catches it. This engine gives the surveillance schedule and triages
// a set of entered findings into continue / urgent review / STOP.
// Summarised from the Maudsley 15e and the Ronaldson/clozapine
// myocarditis monitoring protocol.

enum MyocarditisAction {
  continueMonitoring('Continue + keep monitoring'),
  urgentReview('Urgent cardiology review — hold dose'),
  stopNow('STOP clozapine now — emergency');

  const MyocarditisAction(this.label);
  final String label;
}

class MyocarditisFinding {
  const MyocarditisFinding(this.id, this.label, this.severity);
  final String id;
  final String label;

  /// 'amber' = needs urgent review, 'red' = stop now.
  final String severity;
}

const kMyocarditisFindings = <MyocarditisFinding>[
  MyocarditisFinding(
      'troponin_2x', 'Troponin > 2× upper limit of normal', 'red'),
  MyocarditisFinding(
      'troponin_mild', 'Troponin mildly raised (≤ 2× ULN)', 'amber'),
  MyocarditisFinding('crp_100', 'CRP > 100 mg/L', 'red'),
  MyocarditisFinding(
      'crp_50', 'CRP 50–100 mg/L (or rising)', 'amber'),
  MyocarditisFinding(
      'tachycardia', 'Persistent resting HR > 120 (or +30 over '
          'baseline, sustained)', 'amber'),
  MyocarditisFinding(
      'chest_pain', 'Chest pain / dyspnoea / palpitations', 'amber'),
  MyocarditisFinding(
      'flu_like', 'Fever / flu-like illness in titration weeks',
      'amber'),
  MyocarditisFinding(
      'hf_signs', 'Signs of heart failure / haemodynamic '
          'compromise', 'red'),
];

class MyocarditisResult {
  const MyocarditisResult({
    required this.action,
    required this.headline,
    required this.schedule,
    required this.steps,
    required this.cautions,
  });

  final MyocarditisAction action;
  final String headline;
  final List<String> schedule;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Clozapine myocarditis surveillance — ${action.label}',
      headline,
      '',
      'Baseline + surveillance schedule:',
      for (final s in schedule) ' · $s',
      '',
      'Action now:',
      for (final s in steps) ' · $s',
      '',
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

const _schedule = <String>[
  'Baseline (before / day 0): troponin, CRP, FBC, ECG, plus '
      'resting HR + temperature; echo if any cardiac history.',
  'Weekly troponin + CRP for the first 4 weeks of titration '
      '(the highest-risk window).',
  'Resting HR + temperature at every clinical contact through '
      'weeks 1–6; ask actively about chest pain / dyspnoea / '
      'flu-like symptoms.',
  'Have a low threshold to recheck troponin/CRP and get an echo '
      'if symptomatic at any point in the first ~8 weeks.',
];

const _cautions = <String>[
  'Routine clozapine FBC monitoring does NOT detect myocarditis '
      '— this is a separate surveillance stream.',
  'Eosinophilia and an unexplained tachycardia can be early '
      'clues; tachycardia alone is common but persistent / rising '
      'tachycardia with any biomarker rise is concerning.',
  'Restarting clozapine after confirmed myocarditis is high-risk '
      'and only by specialist decision with cardiology input.',
];

MyocarditisResult evaluateClozapineMyocarditis({
  Set<String> findings = const <String>{},
}) {
  final red = kMyocarditisFindings
      .where((f) => f.severity == 'red' && findings.contains(f.id))
      .isNotEmpty;
  final amberCount = kMyocarditisFindings
      .where((f) => f.severity == 'amber' && findings.contains(f.id))
      .length;

  if (red || amberCount >= 2) {
    final stop = red;
    return MyocarditisResult(
      action: stop
          ? MyocarditisAction.stopNow
          : MyocarditisAction.urgentReview,
      headline: stop
          ? 'Findings strongly suggest myocarditis — treat as an '
              'emergency.'
          : 'Two or more concerning features — treat as suspected '
              'myocarditis until excluded.',
      schedule: _schedule,
      steps: <String>[
        if (stop)
          'STOP clozapine immediately and arrange emergency '
              'cardiology assessment (ECG, troponin, CRP, echo).'
        else
          'Withhold the next dose and arrange same-day cardiology '
              'review with repeat troponin/CRP and an echo.',
        'Do not re-titrate until myocarditis is actively '
            'excluded by the cardiology team.',
        'Document the decision and the monitoring trail; inform '
            'the responsible consultant.',
      ],
      cautions: _cautions,
    );
  }

  if (amberCount == 1) {
    return MyocarditisResult(
      action: MyocarditisAction.urgentReview,
      headline:
          'One concerning feature — investigate before continuing '
          'titration.',
      schedule: _schedule,
      steps: <String>[
        'Repeat troponin + CRP promptly and reassess HR / '
            'symptoms; consider holding the dose pending results.',
        'Seek cardiology / senior advice early — a single feature '
            'can be the first sign.',
        'Resume the schedule only once the picture is clearly '
            'reassuring.',
      ],
      cautions: _cautions,
    );
  }

  return MyocarditisResult(
    action: MyocarditisAction.continueMonitoring,
    headline:
        'No concerning features entered — continue titration with '
        'active surveillance.',
    schedule: _schedule,
    steps: const <String>[
      'Continue the planned clozapine titration.',
      'Keep to the weekly troponin/CRP schedule for the first 4 '
          'weeks and check HR / symptoms at every contact.',
      'Re-evaluate immediately if any new feature appears.',
    ],
    cautions: _cautions,
  );
}
