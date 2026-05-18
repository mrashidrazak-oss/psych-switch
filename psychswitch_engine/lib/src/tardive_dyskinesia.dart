// Tardive dyskinesia — stepwise management.
//
// Distinct from the AIMS rating scale (scoring) and the movement-
// disorder differentiator (recognition): this is the what-to-do
// ladder once TD is identified. Key traps: simply increasing the
// antipsychotic transiently masks TD while worsening the long-term
// course, and anticholinergics typically worsen TD. This engine maps
// the situation to the evidence-based steps. Summarised from the
// Maudsley 15e.

enum TdStep {
  confirm('Confirm + reversible-factor review'),
  modifyAntipsychotic('Modify the antipsychotic'),
  vmat2('VMAT-2 inhibitor treatment'),
  refractory('Refractory / specialist options');

  const TdStep(this.label);
  final String label;
}

class TdResult {
  const TdResult({
    required this.step,
    required this.headline,
    required this.options,
    required this.cautions,
  });

  final TdStep step;
  final String headline;
  final List<String> options;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Tardive dyskinesia — ${step.label}',
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

const _cautions = <String>[
  'Do NOT simply increase the antipsychotic to suppress TD — it '
      'masks transiently but worsens the long-term course.',
  'Anticholinergics generally WORSEN tardive dyskinesia (they '
      'help dystonia / parkinsonism, not TD) — review and withdraw '
      'where possible.',
  'TD can be irreversible — early recognition (serial AIMS) and '
      'minimising lifetime antipsychotic exposure are key.',
];

TdResult evaluateTardiveDyskinesia({
  bool confirmed = false,
  bool antipsychoticStillNeeded = true,
  bool persistsAfterOptimisation = false,
  bool refractory = false,
}) {
  if (!confirmed) {
    return const TdResult(
      step: TdStep.confirm,
      headline:
          'Confirm TD and address reversible contributors before '
          'changing treatment.',
      options: <String>[
        'Confirm with examination + serial AIMS; distinguish from '
            'acute EPS, withdrawal-emergent dyskinesia and other '
            'movement disorders.',
        'Review and withdraw anticholinergics; minimise other '
            'dopamine-blocking agents (incl. metoclopramide).',
        'Reassess the ongoing need for, and dose of, the '
            'antipsychotic.',
      ],
      cautions: _cautions,
    );
  }

  if (!persistsAfterOptimisation) {
    return TdResult(
      step: TdStep.modifyAntipsychotic,
      headline:
          'Optimise the antipsychotic — reduce / withdraw or '
          'switch, balancing relapse risk.',
      options: <String>[
        if (antipsychoticStillNeeded)
          'If antipsychotic still required: switch to a lower-risk '
              'agent — clozapine (best evidence) or quetiapine — '
              'and use the lowest effective dose.'
        else
          'If the antipsychotic can be stopped: withdraw slowly '
              '(abrupt withdrawal can transiently worsen TD) and '
              'monitor.',
        'Track response with serial AIMS over weeks–months before '
            'judging effect.',
        'Proceed to a VMAT-2 inhibitor if TD persists or is '
            'distressing despite this.',
      ],
      cautions: _cautions,
    );
  }

  if (!refractory) {
    return const TdResult(
      step: TdStep.vmat2,
      headline:
          'Persistent TD after optimisation — start an evidence-'
          'based VMAT-2 inhibitor.',
      options: <String>[
        'Offer a VMAT-2 inhibitor (valbenazine or '
            'deutetrabenazine) where available — the best-evidenced '
            'pharmacological treatment for TD.',
        'Continue the lowest effective dose of the lowest-risk '
            'antipsychotic alongside; keep monitoring AIMS.',
        'Where VMAT-2 inhibitors are unavailable, consider options '
            'such as tetrabenazine or trial agents per local '
            'specialist guidance.',
      ],
      cautions: _cautions,
    );
  }

  return const TdResult(
    step: TdStep.refractory,
    headline:
        'Refractory / severe TD — specialist multidisciplinary '
        'management.',
    options: <String>[
      'Refer to a movement-disorder / neuropsychiatry specialist; '
          'optimise VMAT-2 inhibitor dosing.',
      'Consider clozapine if not already used; review every '
          'contributing drug.',
      'For severe, treatment-resistant focal TD, specialist '
          'options (e.g. botulinum toxin for focal dystonic '
          'components; rarely DBS) may be considered.',
    ],
    cautions: _cautions,
  );
}
