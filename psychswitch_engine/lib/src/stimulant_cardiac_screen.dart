// Pre-stimulant cardiovascular screening (ADHD).
//
// Stimulants (and atomoxetine) modestly raise heart rate and blood
// pressure. Routine ECG/echo is not needed for everyone, but a
// focused cardiac history + exam is mandatory before starting, and
// specific findings require cardiology clearance first. This engine
// turns that screen into a clear gate. Summarised from the Maudsley
// 15e and NICE NG87 (ADHD).

enum StimulantCardiacVerdict {
  proceed('Proceed with baseline monitoring'),
  cardiologyFirst('Cardiology assessment BEFORE starting');

  const StimulantCardiacVerdict(this.label);
  final String label;
}

class CardiacRiskFactor {
  const CardiacRiskFactor(this.id, this.label);
  final String id;
  final String label;
}

const kStimulantCardiacRiskFactors = <CardiacRiskFactor>[
  CardiacRiskFactor('structural',
      'Known structural / congenital heart disease'),
  CardiacRiskFactor(
      'cardiomyopathy', 'Cardiomyopathy or significant arrhythmia'),
  CardiacRiskFactor('exertional',
      'Exertional chest pain or unexplained syncope'),
  CardiacRiskFactor('fh_scd',
      'Family history of sudden cardiac death / inherited cardiac '
          'condition < 40 y'),
  CardiacRiskFactor(
      'uncontrolled_htn', 'Uncontrolled hypertension'),
  CardiacRiskFactor(
      'abnormal_exam', 'Abnormal cardiovascular examination'),
];

class StimulantCardiacResult {
  const StimulantCardiacResult({
    required this.verdict,
    required this.headline,
    required this.steps,
    required this.cautions,
  });

  final StimulantCardiacVerdict verdict;
  final String headline;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Pre-stimulant cardiac screen — ${verdict.label}',
      headline,
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

const _cautions = <String>[
  'Routine ECG / echo is not required for everyone — a focused '
      'cardiac history and examination is the screen.',
  'Record baseline HR, BP, height and weight; monitor at every '
      'dose change and at least every 6 months thereafter.',
  'Review and refer if exertional symptoms, syncope, or a new '
      'murmur develop on treatment.',
];

StimulantCardiacResult evaluateStimulantCardiacScreen({
  Set<String> riskFactors = const <String>{},
}) {
  final flagged = kStimulantCardiacRiskFactors
      .where((f) => riskFactors.contains(f.id))
      .map((f) => f.label)
      .toList();

  if (flagged.isNotEmpty) {
    return StimulantCardiacResult(
      verdict: StimulantCardiacVerdict.cardiologyFirst,
      headline:
          'A cardiac red flag is present — obtain cardiology '
          'assessment and clearance before starting a stimulant.',
      steps: <String>[
        'Do not start the stimulant yet; refer for cardiology '
            'evaluation of: ${flagged.join('; ')}.',
        'Optimise modifiable factors (e.g. treat hypertension) and '
            'document the discussion of risks/benefits.',
        'Start only with cardiology agreement, then follow the '
            'standard baseline + ongoing monitoring schedule.',
      ],
      cautions: _cautions,
    );
  }

  return const StimulantCardiacResult(
    verdict: StimulantCardiacVerdict.proceed,
    headline:
        'No cardiac red flags entered — proceed with standard '
        'baseline measurement and ongoing monitoring.',
    steps: <String>[
      'Record baseline HR, BP, height and weight before the first '
          'dose.',
      'Start at a low dose and titrate; recheck HR/BP at each dose '
          'change and at least 6-monthly.',
      'Safety-net: review urgently if exertional chest pain, '
          'syncope, palpitations or a new murmur appear.',
    ],
    cautions: _cautions,
  );
}
