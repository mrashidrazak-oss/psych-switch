// Antidepressant deprescribing — hyperbolic taper planner.
//
// Receptor (serotonin-transporter) occupancy is a hyperbolic, not
// linear, function of dose: the last few milligrams account for a
// disproportionate share of occupancy. Linear dose reductions
// therefore produce accelerating occupancy drops at the low end and
// drive withdrawal. Hyperbolic tapering reduces by a fixed proportion
// of the CURRENT dose so each step delivers an approximately equal
// reduction in occupancy.
//
// Method paraphrased from Horowitz & Taylor, Maudsley Deprescribing
// Guidelines (2024) and Lancet Psychiatry 2019;6:538-46.
//
// This is decision support. Confirm against the patient's response,
// available formulations (tablet / dispersible / liquid), and the
// patient's preference at each step.

class DeprescribeDrug {
  const DeprescribeDrug({
    required this.id,
    required this.name,
    required this.startDoseMg,
    required this.minPracticalDoseMg,
    required this.note,
  });

  final String id;
  final String name;

  /// Typical full therapeutic dose used to seed the planner.
  final double startDoseMg;

  /// The smallest dose realistically achievable with a liquid /
  /// compounded preparation before stopping. Below this, stop.
  final double minPracticalDoseMg;

  /// Formulation note (what makes the small steps possible).
  final String note;
}

const List<DeprescribeDrug> kDeprescribeDrugs = <DeprescribeDrug>[
  DeprescribeDrug(
    id: 'paroxetine',
    name: 'Paroxetine',
    startDoseMg: 20,
    minPracticalDoseMg: 0.5,
    note: 'Highest withdrawal risk SSRI (short t½, muscarinic '
        'rebound). Liquid 2 mg/mL enables sub-milligram steps.',
  ),
  DeprescribeDrug(
    id: 'venlafaxine',
    name: 'Venlafaxine',
    startDoseMg: 150,
    minPracticalDoseMg: 1,
    note: 'Severe, rapid discontinuation syndrome. Use the immediate-'
        'release liquid or bead-counting from XR capsules for small '
        'steps.',
  ),
  DeprescribeDrug(
    id: 'sertraline',
    name: 'Sertraline',
    startDoseMg: 50,
    minPracticalDoseMg: 1,
    note: 'Moderate withdrawal risk. Oral suspension 20 mg/mL '
        'available for tapering.',
  ),
  DeprescribeDrug(
    id: 'escitalopram',
    name: 'Escitalopram',
    startDoseMg: 10,
    minPracticalDoseMg: 0.5,
    note: 'Liquid 10 mg/mL. Steep occupancy curve — final steps '
        'must be small.',
  ),
  DeprescribeDrug(
    id: 'citalopram',
    name: 'Citalopram',
    startDoseMg: 20,
    minPracticalDoseMg: 0.5,
    note: 'Liquid 40 mg/mL. QTc caution if temporarily up-titrating '
        'is considered (it should not be).',
  ),
  DeprescribeDrug(
    id: 'fluoxetine',
    name: 'Fluoxetine',
    startDoseMg: 20,
    minPracticalDoseMg: 1,
    note: 'Long t½ self-tapers somewhat; still benefits from a '
        'structured reduction. Liquid 20 mg/5 mL.',
  ),
  DeprescribeDrug(
    id: 'duloxetine',
    name: 'Duloxetine',
    startDoseMg: 60,
    minPracticalDoseMg: 1,
    note: 'Enteric beads — counting beads from the capsule is the '
        'usual way to make small steps; no licensed liquid.',
  ),
  DeprescribeDrug(
    id: 'mirtazapine',
    name: 'Mirtazapine',
    startDoseMg: 30,
    minPracticalDoseMg: 0.5,
    note: 'Lower withdrawal risk; can usually taper faster. Oral '
        'solution 15 mg/mL.',
  ),
];

DeprescribeDrug? deprescribeDrugById(String id) {
  for (final d in kDeprescribeDrugs) {
    if (d.id == id) return d;
  }
  return null;
}

enum TaperSpeed {
  cautious('cautious'),
  moderate('moderate'),
  faster('faster');

  const TaperSpeed(this.jsonValue);
  final String jsonValue;
}

String taperSpeedLabel(TaperSpeed s) {
  switch (s) {
    case TaperSpeed.cautious:
      return 'Cautious';
    case TaperSpeed.moderate:
      return 'Moderate';
    case TaperSpeed.faster:
      return 'Faster';
  }
}

/// Reduction fraction of the *current* dose applied at each step.
double _reductionFraction(TaperSpeed s) {
  switch (s) {
    case TaperSpeed.cautious:
      return 0.10;
    case TaperSpeed.moderate:
      return 0.25;
    case TaperSpeed.faster:
      return 0.40;
  }
}

/// Public accessor for the per-step reduction percentage (of the
/// current dose) — used by the UI to describe the schedule.
int taperReductionPercent(TaperSpeed s) =>
    (_reductionFraction(s) * 100).round();

/// Days held at each dose before the next reduction.
int taperIntervalDays(TaperSpeed s) {
  switch (s) {
    case TaperSpeed.cautious:
      return 28;
    case TaperSpeed.moderate:
      return 21;
    case TaperSpeed.faster:
      return 14;
  }
}

class TaperStep {
  const TaperStep({
    required this.index,
    required this.doseMg,
    required this.holdDays,
    required this.cumulativeDay,
  });

  final int index;

  /// Dose to hold during this step.
  final double doseMg;

  /// Days to hold this dose before the next reduction.
  final int holdDays;

  /// Day number (from start) on which this step begins.
  final int cumulativeDay;
}

class TaperPlan {
  const TaperPlan({
    required this.drug,
    required this.speed,
    required this.startDoseMg,
    required this.steps,
    required this.totalDays,
  });

  final DeprescribeDrug drug;
  final TaperSpeed speed;
  final double startDoseMg;
  final List<TaperStep> steps;
  final int totalDays;

  String clipboardSummary() {
    final lines = <String>[
      '${drug.name} hyperbolic taper '
          '(${taperSpeedLabel(speed)} — '
          '${taperReductionPercent(speed)}% of current dose every '
          '${taperIntervalDays(speed)} days)',
      'Start: ${_fmt(startDoseMg)} mg',
      '',
      for (final s in steps)
        'Week ${(s.cumulativeDay / 7).ceil()} '
            '(day ${s.cumulativeDay}): ${_fmt(s.doseMg)} mg'
            '${s.doseMg == 0 ? "  — STOP" : ""}',
      '',
      'Approx. total duration: '
          '${(totalDays / 7).ceil()} weeks. Slow further if '
          'withdrawal symptoms emerge; never accelerate to "get it '
          'over with".',
    ];
    return lines.join('\n');
  }
}

String _fmt(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  if ((v * 10) == (v * 10).roundToDouble()) return v.toStringAsFixed(1);
  return v.toStringAsFixed(2);
}

/// Round a dose to something a liquid / bead count can plausibly
/// deliver: 2+ mg → nearest 0.5, below 2 mg → nearest 0.1.
double _practicalRound(double mg) {
  if (mg >= 2) return (mg * 2).round() / 2;
  return (mg * 10).round() / 10;
}

/// Build a hyperbolic taper. Steps reduce by a fixed proportion of the
/// current dose; once the practical-rounded next dose is at or below
/// the drug's minimum practical dose, the final step is 0 (STOP).
TaperPlan buildTaperPlan({
  required DeprescribeDrug drug,
  required TaperSpeed speed,
  double? startDoseMg,
}) {
  final start = startDoseMg ?? drug.startDoseMg;
  final frac = _reductionFraction(speed);
  final hold = taperIntervalDays(speed);

  final steps = <TaperStep>[];
  var current = start;
  var day = 0;
  var index = 0;

  // Initial hold at the starting dose.
  steps.add(TaperStep(
    index: index++,
    doseMg: _practicalRound(current),
    holdDays: hold,
    cumulativeDay: day,
  ));

  // Cap iterations defensively so a pathological input can't loop
  // forever.
  for (var guard = 0; guard < 60; guard++) {
    day += hold;
    final next = _practicalRound(current * (1 - frac));
    if (next <= drug.minPracticalDoseMg || next >= current) {
      // Final step: stop.
      steps.add(TaperStep(
        index: index++,
        doseMg: 0,
        holdDays: 0,
        cumulativeDay: day,
      ));
      break;
    }
    current = next;
    steps.add(TaperStep(
      index: index++,
      doseMg: current,
      holdDays: hold,
      cumulativeDay: day,
    ));
  }

  return TaperPlan(
    drug: drug,
    speed: speed,
    startDoseMg: start,
    steps: steps,
    totalDays: day,
  );
}
