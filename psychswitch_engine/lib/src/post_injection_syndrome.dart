// Olanzapine long-acting injection — post-injection syndrome (PDSS).
//
// Olanzapine pamoate can cause a post-injection delirium / sedation
// syndrome (accidental intravascular delivery → rapid high plasma
// olanzapine). It is uncommon but potentially severe, which is why a
// mandatory post-dose observation period exists. This engine gives
// the observation protocol and triages entered features into
// continue-observation vs suspected-PDSS. Summarised from the
// Maudsley 15e and the olanzapine pamoate risk-management programme.

enum PdssAction {
  continueObservation('Continue the observation period'),
  suspectedPdss('Suspected PDSS — treat as emergency');

  const PdssAction(this.label);
  final String label;
}

class PdssFeature {
  const PdssFeature(this.id, this.label);
  final String id;
  final String label;
}

const kPdssFeatures = <PdssFeature>[
  PdssFeature('sedation', 'Marked / excessive sedation'),
  PdssFeature('confusion', 'Confusion or disorientation'),
  PdssFeature('dysarthria', 'Slurred speech / dysarthria'),
  PdssFeature('ataxia', 'Ataxia / unsteadiness'),
  PdssFeature('dizziness', 'Dizziness or weakness'),
  PdssFeature('agitation', 'Agitation / unusual behaviour'),
  PdssFeature('extrapyramidal', 'Acute extrapyramidal signs'),
  PdssFeature('reduced_gcs', 'Reduced consciousness'),
];

class PdssResult {
  const PdssResult({
    required this.action,
    required this.headline,
    required this.protocol,
    required this.steps,
    required this.cautions,
  });

  final PdssAction action;
  final String headline;
  final List<String> protocol;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Olanzapine LAI post-injection — ${action.label}',
      headline,
      '',
      'Observation protocol:',
      for (final p in protocol) ' · $p',
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

const _protocol = <String>[
  'Administer ONLY in a registered healthcare facility with '
      'resuscitation and trained staff available.',
  'Observe the patient for at least 3 hours after every '
      'injection, alert for sedation / confusion / delirium.',
  'Confirm the patient is alert, oriented and free of PDSS '
      'features before discharge.',
  'The patient must not drive or operate machinery for the rest '
      'of the day; arrange accompanied transport home.',
  'Counsel the patient/carers to seek urgent help if delayed '
      'symptoms develop after leaving.',
];

const _cautions = <String>[
  'PDSS arises from accidental partial intravascular delivery — '
      'use correct gluteal technique and aspirate; it can still '
      'occur with correct technique.',
  'There is no specific antidote — management is supportive; the '
      'depot cannot be removed once given.',
  'Most cases occur within the first 1–3 hours but later onset '
      'is described — do not shorten the observation period.',
];

PdssResult evaluatePostInjection({
  Set<String> features = const <String>{},
}) {
  final any = kPdssFeatures.any((f) => features.contains(f.id));
  if (any) {
    return const PdssResult(
      action: PdssAction.suspectedPdss,
      headline:
          'Post-injection features present — manage as suspected '
          'PDSS until it resolves.',
      protocol: _protocol,
      steps: <String>[
        'Do not discharge. Initiate close medical monitoring '
            '(airway, breathing, circulation, conscious level, '
            'vitals) and treat supportively.',
        'Escalate for medical / critical-care support; extend '
            'observation well beyond 3 hours until fully resolved.',
        'Document the event, report via pharmacovigilance, and '
            'review suitability of continued olanzapine LAI with '
            'the responsible consultant.',
      ],
      cautions: _cautions,
    );
  }
  return const PdssResult(
    action: PdssAction.continueObservation,
    headline:
        'No post-injection features entered — complete the full '
        'observation period before discharge.',
    protocol: _protocol,
    steps: <String>[
      'Continue structured observation for the full ≥ 3 hours.',
      'Re-check alertness and orientation before discharge and '
          'confirm accompanied transport.',
      'Reassess immediately if any feature develops.',
    ],
    cautions: _cautions,
  );
}
