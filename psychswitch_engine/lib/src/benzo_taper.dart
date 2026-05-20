// Benzodiazepine / Z-drug withdrawal planner.
//
// Two-step Ashton-manual approach (Ashton 2002; Maudsley 15e):
//   1. Convert the patient's agent to the long-acting diazepam
//      equivalent.
//   2. Reduce the diazepam-equivalent dose gradually — a fixed
//      proportion of the CURRENT dose every 1-2 weeks, with the
//      absolute steps naturally getting smaller toward the end
//      (Ashton: "the rate should be slower at lower doses").
//
// Equivalents are approximate and intended for switching, not for
// precise pharmacokinetic claims. Clinical judgement + patient
// tolerability govern the pace at every step.

class BenzoDrug {
  const BenzoDrug({
    required this.id,
    required this.name,
    required this.mgPer10Diazepam,
    required this.note,
  });

  final String id;
  final String name;

  /// Milligrams of THIS drug approximately equivalent to 10 mg
  /// diazepam.
  final double mgPer10Diazepam;

  final String note;
}

const List<BenzoDrug> kBenzoDrugs = <BenzoDrug>[
  BenzoDrug(
    id: 'diazepam',
    name: 'Diazepam',
    mgPer10Diazepam: 10,
    note: 'Reference long-acting agent; taper is performed on '
        'diazepam itself.',
  ),
  BenzoDrug(
    id: 'alprazolam',
    name: 'Alprazolam',
    mgPer10Diazepam: 0.5,
    note: 'Short-acting, high potency — inter-dose withdrawal is '
        'common; cross-taper to diazepam before reducing.',
  ),
  BenzoDrug(
    id: 'lorazepam',
    name: 'Lorazepam',
    mgPer10Diazepam: 1,
    note: 'Short-acting; switch to diazepam to smooth the trough.',
  ),
  BenzoDrug(
    id: 'clonazepam',
    name: 'Clonazepam',
    mgPer10Diazepam: 0.5,
    note: 'Long-acting; some clinicians taper clonazepam directly, '
        'but diazepam allows finer dose decrements.',
  ),
  BenzoDrug(
    id: 'chlordiazepoxide',
    name: 'Chlordiazepoxide',
    mgPer10Diazepam: 25,
    note: 'Long-acting; common in alcohol-withdrawal regimens.',
  ),
  BenzoDrug(
    id: 'nitrazepam',
    name: 'Nitrazepam',
    mgPer10Diazepam: 10,
    note: 'Hypnotic; convert to diazepam for tapering.',
  ),
  BenzoDrug(
    id: 'temazepam',
    name: 'Temazepam',
    mgPer10Diazepam: 20,
    note: 'Hypnotic; short-acting.',
  ),
  BenzoDrug(
    id: 'oxazepam',
    name: 'Oxazepam',
    mgPer10Diazepam: 30,
    note: 'Short-acting, no active metabolites; sometimes preferred '
        'in hepatic impairment / the elderly.',
  ),
  BenzoDrug(
    id: 'zopiclone',
    name: 'Zopiclone',
    mgPer10Diazepam: 15,
    note: 'Z-drug hypnotic; cross-tolerant with benzodiazepines.',
  ),
  BenzoDrug(
    id: 'zolpidem',
    name: 'Zolpidem',
    mgPer10Diazepam: 20,
    note: 'Z-drug hypnotic; cross-tolerant with benzodiazepines.',
  ),
];

BenzoDrug? benzoDrugById(String id) {
  for (final d in kBenzoDrugs) {
    if (d.id == id) return d;
  }
  return null;
}

/// Diazepam-equivalent (mg) of [doseMg] of [drug].
double diazepamEquivalent(BenzoDrug drug, double doseMg) =>
    (doseMg / drug.mgPer10Diazepam) * 10.0;

enum BenzoTaperSpeed {
  cautious('cautious'),
  moderate('moderate'),
  faster('faster');

  const BenzoTaperSpeed(this.jsonValue);
  final String jsonValue;
}

String benzoTaperSpeedLabel(BenzoTaperSpeed s) {
  switch (s) {
    case BenzoTaperSpeed.cautious:
      return 'Cautious';
    case BenzoTaperSpeed.moderate:
      return 'Moderate';
    case BenzoTaperSpeed.faster:
      return 'Faster';
  }
}

double _reduction(BenzoTaperSpeed s) {
  switch (s) {
    case BenzoTaperSpeed.cautious:
      return 0.08;
    case BenzoTaperSpeed.moderate:
      return 0.125;
    case BenzoTaperSpeed.faster:
      return 0.20;
  }
}

int benzoStepIntervalDays(BenzoTaperSpeed s) {
  switch (s) {
    case BenzoTaperSpeed.cautious:
      return 14;
    case BenzoTaperSpeed.moderate:
      return 10;
    case BenzoTaperSpeed.faster:
      return 7;
  }
}

int benzoReductionPercent(BenzoTaperSpeed s) =>
    (_reduction(s) * 100).round();

class BenzoStep {
  const BenzoStep({
    required this.diazepamMg,
    required this.holdDays,
    required this.cumulativeDay,
  });

  final double diazepamMg;
  final int holdDays;
  final int cumulativeDay;
}

class BenzoTaperPlan {
  const BenzoTaperPlan({
    required this.startDiazepamMg,
    required this.speed,
    required this.steps,
    required this.totalDays,
  });

  final double startDiazepamMg;
  final BenzoTaperSpeed speed;
  final List<BenzoStep> steps;
  final int totalDays;

  String clipboardSummary() {
    final lines = <String>[
      'Benzodiazepine taper (diazepam-equivalent) — '
          '${benzoTaperSpeedLabel(speed)}: '
          '${benzoReductionPercent(speed)}% of current dose every '
          '${benzoStepIntervalDays(speed)} days',
      'Start: ${_fmt(startDiazepamMg)} mg diazepam-equivalent',
      '',
      for (final s in steps)
        'Week ${(s.cumulativeDay / 7).ceil()} '
            '(day ${s.cumulativeDay}): '
            '${s.diazepamMg == 0 ? "STOP" : "${_fmt(s.diazepamMg)} mg diazepam"}',
      '',
      'Approx. duration ${(totalDays / 7).ceil()} weeks. Hold or slow '
          'if withdrawal symptoms emerge; never accelerate. Split the '
          'daily diazepam dose (e.g. BD/TDS) for steadier levels.',
    ];
    return lines.join('\n');
  }
}

String _fmt(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

double _round(double mg) {
  if (mg >= 5) return (mg).roundToDouble();
  return (mg * 2).round() / 2; // nearest 0.5 mg at low doses
}

/// Build a proportional diazepam taper. Final step is 0 (STOP) once
/// the next practical dose would be ≤ 1 mg.
BenzoTaperPlan buildBenzoTaper({
  required double startDiazepamMg,
  required BenzoTaperSpeed speed,
}) {
  final frac = _reduction(speed);
  final hold = benzoStepIntervalDays(speed);
  final steps = <BenzoStep>[];

  var current = _round(startDiazepamMg);
  var day = 0;
  steps.add(BenzoStep(
    diazepamMg: current,
    holdDays: hold,
    cumulativeDay: day,
  ));

  for (var guard = 0; guard < 80; guard++) {
    day += hold;
    final next = _round(current * (1 - frac));
    if (next <= 1 || next >= current) {
      steps.add(BenzoStep(
        diazepamMg: 0,
        holdDays: 0,
        cumulativeDay: day,
      ));
      break;
    }
    current = next;
    steps.add(BenzoStep(
      diazepamMg: current,
      holdDays: hold,
      cumulativeDay: day,
    ));
  }

  return BenzoTaperPlan(
    startDiazepamMg: _round(startDiazepamMg),
    speed: speed,
    steps: steps,
    totalDays: day,
  );
}
