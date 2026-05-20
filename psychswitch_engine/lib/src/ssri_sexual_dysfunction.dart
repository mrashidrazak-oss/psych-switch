// Antidepressant-induced sexual dysfunction — management ladder.
//
// One of the commonest reasons for covert non-adherence, yet rarely
// asked about. This engine turns the staged approach into an
// interactive ladder, factoring in whether the depression is in
// remission (a switch is safer) and whether symptoms are persistent.
// Summarised from the Maudsley 15e.

enum SexDysStep {
  assess('Assess + confirm cause'),
  conservative('Conservative measures'),
  switchAgent('Switch to a lower-risk agent'),
  adjunct('Adjunctive / specialist options');

  const SexDysStep(this.label);
  final String label;
}

class SexDysResult {
  const SexDysResult({
    required this.step,
    required this.headline,
    required this.options,
    required this.cautions,
  });

  final SexDysStep step;
  final String headline;
  final List<String> options;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Antidepressant sexual dysfunction — ${step.label}',
      headline,
      '',
      'Options:',
      for (final o in options) ' · $o',
      '',
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

const _lowerRiskAgents = <String>[
  'Lower-risk antidepressants: mirtazapine, agomelatine, '
      'vortioxetine, bupropion, moclobemide, trazodone — consider '
      'switching to or augmenting with one of these.',
];

const _cautions = <String>[
  'Always exclude non-drug causes: the depression itself, '
      'relationship / psychological factors, other drugs, '
      'endocrine / vascular disease, alcohol.',
  'Counsel that under-recognised sexual dysfunction is a major '
      'driver of covert non-adherence — ask routinely and '
      'normalise the discussion.',
  'Persistent symptoms after stopping the drug (post-SSRI sexual '
      'dysfunction) are described though uncommon — document the '
      'discussion if relevant.',
];

SexDysResult evaluateSexualDysfunction({
  bool confirmedDrugRelated = false,
  bool persistent4Weeks = false,
  bool inRemission = false,
}) {
  if (!confirmedDrugRelated) {
    return const SexDysResult(
      step: SexDysStep.assess,
      headline:
          'First establish that the antidepressant is the cause '
          'before changing effective treatment.',
      options: <String>[
        'Take a clear history: onset relative to the drug, the '
            'specific problem (desire / arousal / orgasm), and '
            'pre-treatment baseline.',
        'Exclude depression-related and other causes (drugs, '
            'endocrine, vascular, relationship, alcohol).',
        'If clearly drug-related, proceed down the ladder; if '
            'uncertain, treat the likely alternative cause first.',
      ],
      cautions: _cautions,
    );
  }

  if (!persistent4Weeks) {
    return const SexDysResult(
      step: SexDysStep.conservative,
      headline:
          'Confirmed drug-related but not yet persistent — try '
          'conservative measures first.',
      options: <String>[
        'Watchful waiting — some tolerance develops over the '
            'first weeks.',
        'Dose reduction to the lowest effective dose if the '
            'depression allows.',
        'A planned brief drug holiday may help with shorter '
            'half-life agents (NOT fluoxetine; weigh '
            'discontinuation and relapse risk).',
        'Time dosing relative to sexual activity where '
            'practicable.',
      ],
      cautions: _cautions,
    );
  }

  if (inRemission) {
    return const SexDysResult(
      step: SexDysStep.switchAgent,
      headline:
          'Persistent and the mood is in remission — switching to '
          'a lower-risk agent is the preferred next step.',
      options: <String>[
        ..._lowerRiskAgents,
        'Cross-taper carefully and monitor mood through the '
            'switch; allow several weeks to judge benefit.',
        'If a switch is not acceptable, move to adjunctive '
            'options.',
      ],
      cautions: _cautions,
    );
  }

  return const SexDysResult(
    step: SexDysStep.adjunct,
    headline:
        'Persistent but the depression is NOT safely in remission '
        '— prioritise mood stability; use adjunctive options.',
    options: <String>[
      'Add bupropion (augmentation) or, for erectile dysfunction '
          'in men, a PDE5 inhibitor (e.g. sildenafil) where '
          'appropriate.',
      'Consider switching only if it can be done without '
          'destabilising mood — otherwise defer until more '
          'stable.',
      ..._lowerRiskAgents,
    ],
    cautions: _cautions,
  );
}
