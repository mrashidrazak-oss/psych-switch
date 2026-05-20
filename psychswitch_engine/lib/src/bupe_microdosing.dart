// Buprenorphine micro-dosing induction (Bernese method).
//
// Distinct from standard COWS-gated induction: micro-dosing starts
// very low overlapping buprenorphine doses WHILE the full agonist
// continues, escalating over days, then stopping the full agonist —
// avoiding the withdrawal-then-induct step. Useful for transfer from
// methadone or from fentanyl/long-acting opioids where precipitated
// withdrawal risk is high. Schedules are illustrative templates —
// follow local addiction-medicine protocols. Summarised from the
// Maudsley 15e and published Bernese / rapid micro-induction
// protocols.

enum MicrodoseSource {
  methadone('From methadone'),
  fullAgonist('From heroin / fentanyl / other full agonist');

  const MicrodoseSource(this.label);
  final String label;
}

enum MicrodosePace {
  standard('Standard (~7 days)'),
  rapid('Rapid (~4 days)');

  const MicrodosePace(this.label);
  final String label;
}

class MicrodosePlan {
  const MicrodosePlan({
    required this.source,
    required this.pace,
    required this.headline,
    required this.schedule,
    required this.cautions,
  });

  final MicrodoseSource source;
  final MicrodosePace pace;
  final String headline;

  /// Day-by-day buprenorphine steps (sublingual).
  final List<String> schedule;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Buprenorphine micro-dosing — ${source.label} · '
          '${pace.label}',
      headline,
      '',
      'Schedule (sublingual buprenorphine):',
      for (final s in schedule) ' · $s',
      '',
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

const _standard = <String>[
  'Day 1: 0.5 mg once (continue the usual full agonist '
      'unchanged).',
  'Day 2: 0.5 mg twice daily.',
  'Day 3: 1 mg twice daily.',
  'Day 4: 2 mg twice daily.',
  'Day 5: 4 mg twice daily.',
  'Day 6: 8 mg twice daily; STOP the full agonist on this day.',
  'Day 7: consolidate to a single maintenance dose '
      '(e.g. 12–16 mg/day), then titrate to response.',
];

const _rapid = <String>[
  'Day 1: 0.5 mg AM then 1 mg PM (continue the full agonist).',
  'Day 2: 2 mg twice daily.',
  'Day 3: 4 mg twice daily, then 8 mg evening; reduce / stop the '
      'full agonist as tolerated.',
  'Day 4: STOP the full agonist; give 12–16 mg as a single '
      'maintenance dose and titrate to response.',
];

MicrodosePlan buildMicrodosePlan({
  MicrodoseSource source = MicrodoseSource.fullAgonist,
  MicrodosePace pace = MicrodosePace.standard,
}) {
  final cautions = <String>[
    'Specialist addiction-medicine procedure — use only with a '
        'local protocol and the ability to monitor closely.',
    'The principle: tiny overlapping buprenorphine doses while '
        'the full agonist continues avoid the precipitated-'
        'withdrawal step of standard induction.',
    'Use small commercial dose forms / splitting as per local '
        'practice; review withdrawal and craving at each step and '
        'slow down if needed.',
  ];
  if (source == MicrodoseSource.methadone) {
    cautions.insert(
      1,
      'From methadone: its long half-life means overlap is '
          'longer and the stop point may need individualising — '
          'higher methadone doses generally need the slower pace.',
    );
  } else {
    cautions.insert(
      1,
      'From fentanyl: tissue accumulation can prolong risk — a '
          'cautious pace and extended monitoring are preferred '
          'even if a rapid schedule is requested.',
    );
  }

  final schedule =
      pace == MicrodosePace.rapid ? _rapid : _standard;
  return MicrodosePlan(
    source: source,
    pace: pace,
    headline: pace == MicrodosePace.rapid
        ? 'Rapid overlapping micro-induction — only with close '
            'inpatient-level monitoring.'
        : 'Gradual overlapping micro-induction — continue the '
            'full agonist until the specified stop day.',
    schedule: schedule,
    cautions: cautions,
  );
}
