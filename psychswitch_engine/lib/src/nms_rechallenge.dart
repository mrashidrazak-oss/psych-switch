// Restarting an antipsychotic after a resolved NMS episode.
//
// Distinct from acute NMS management: this is the rechallenge
// decision. Recurrence risk is real but a substantial proportion
// can be safely rechallenged if it is delayed until full recovery
// and done cautiously with a lower-risk agent. This engine returns
// the readiness verdict and the safer-restart plan. Summarised from
// the Maudsley 15e.

enum NmsRechallengeVerdict {
  notReady('Not ready — wait'),
  proceedCautious('May rechallenge — cautious protocol'),
  avoid('Avoid antipsychotic rechallenge if possible');

  const NmsRechallengeVerdict(this.label);
  final String label;
}

class NmsRechallengeResult {
  const NmsRechallengeResult({
    required this.verdict,
    required this.headline,
    required this.steps,
    required this.cautions,
  });

  final NmsRechallengeVerdict verdict;
  final String headline;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'NMS rechallenge — ${verdict.label}',
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
  'NMS can recur on rechallenge — the patient and team must be '
      'briefed and monitoring (temperature, CK, autonomic obs) '
      'must be in place.',
  'Highest-risk practices to avoid: high-potency typicals, rapid '
      'titration, parenteral / depot routes, dehydration and '
      'concurrent lithium.',
  'Document the risk–benefit discussion and consent; ensure a '
      'clear escalation plan if early features recur.',
];

NmsRechallengeResult evaluateNmsRechallenge({
  bool fullyRecovered = false,
  bool atLeastTwoWeeksSinceRecovery = false,
  bool antipsychoticEssential = true,
  bool priorEpisodeSevereOrComplicated = false,
}) {
  if (!fullyRecovered || !atLeastTwoWeeksSinceRecovery) {
    return const NmsRechallengeResult(
      verdict: NmsRechallengeVerdict.notReady,
      headline:
          'Do not rechallenge yet — wait for full clinical + '
          'biochemical recovery and a clear delay.',
      steps: <String>[
        'Confirm complete resolution of rigidity, pyrexia, '
            'autonomic instability and normalisation of CK before '
            'considering any antipsychotic.',
        'Allow a clear interval (commonly ≥ ~2 weeks after full '
            'recovery) before rechallenge.',
        'Manage the psychiatric illness in the interim with non-'
            'antipsychotic measures / a safe environment; consider '
            'benzodiazepines or ECT if urgently needed.',
      ],
      cautions: _cautions,
    );
  }

  if (!antipsychoticEssential) {
    return const NmsRechallengeResult(
      verdict: NmsRechallengeVerdict.avoid,
      headline:
          'If an antipsychotic is not essential, prefer to avoid '
          'rechallenge and use alternatives.',
      steps: <String>[
        'Reserve antipsychotics for clear ongoing need; consider '
            'non-antipsychotic strategies or ECT where '
            'appropriate.',
        'If treatment of psychosis becomes essential later, follow '
            'the cautious rechallenge protocol.',
      ],
      cautions: _cautions,
    );
  }

  final steps = <String>[
    'Choose a LOW-potency / lower-risk agent of a DIFFERENT '
        'class from the one implicated (e.g. a low-potency '
        'atypical; quetiapine / clozapine are often preferred).',
    'Start at a low dose and titrate very slowly; oral route; '
        'avoid depot until well established.',
    'Ensure hydration, avoid concurrent lithium, and monitor '
        'temperature, pulse/BP and CK regularly during titration.',
    'Brief the patient and team on early NMS features with a '
        'clear stop-and-escalate plan.',
  ];
  if (priorEpisodeSevereOrComplicated) {
    return NmsRechallengeResult(
      verdict: NmsRechallengeVerdict.proceedCautious,
      headline:
          'Rechallenge possible but the prior episode was severe — '
          'lowest-risk agent, inpatient-level monitoring.',
      steps: <String>[
        'Given the severe index episode, conduct rechallenge in a '
            'closely monitored (inpatient-level) setting.',
        ...steps,
      ],
      cautions: _cautions,
    );
  }
  return NmsRechallengeResult(
    verdict: NmsRechallengeVerdict.proceedCautious,
    headline:
        'Recovered, delayed and antipsychotic essential — cautious '
        'rechallenge is reasonable.',
    steps: steps,
    cautions: _cautions,
  );
}
