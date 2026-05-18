// Corticosteroid-induced psychiatric disturbance.
//
// High-dose / systemic corticosteroids commonly cause psychiatric
// disturbance — most often hypomania/mania or psychosis early, and
// depression (sometimes on withdrawal). This engine maps the
// scenario to a management plan and the key safeguards. Summarised
// from the Maudsley 15e.

enum SteroidScenario {
  preTreatment('Risk assessment before high-dose steroids'),
  maniaPsychosis('Established mania / psychosis'),
  depression('Established depression'),
  delirium('Confusion / delirium');

  const SteroidScenario(this.label);
  final String label;
}

class SteroidPsychResult {
  const SteroidPsychResult({
    required this.scenario,
    required this.highDose,
    required this.headline,
    required this.steps,
    required this.cautions,
  });

  final SteroidScenario scenario;
  final bool highDose;
  final String headline;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Steroid-induced psychiatric disturbance — ${scenario.label}'
          '${highDose ? ' (high dose)' : ''}',
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
  'Risk is dose-related — markedly higher above ~40 mg/day '
      'prednisolone-equivalent; can occur at any dose and at any '
      'time, including on dose reduction / withdrawal.',
  'Do not stop systemic steroids abruptly (adrenal crisis / '
      'disease flare) — change the steroid only with the '
      'prescribing physician.',
  'A past steroid-induced reaction does not reliably predict the '
      'next; previous psychiatric history is an imperfect '
      'predictor — monitor everyone on high dose.',
];

SteroidPsychResult evaluateSteroidPsychiatric({
  SteroidScenario scenario = SteroidScenario.preTreatment,
  bool highDose = true,
}) {
  switch (scenario) {
    case SteroidScenario.preTreatment:
      return SteroidPsychResult(
        scenario: scenario,
        highDose: highDose,
        headline: highDose
            ? 'High-dose course — counsel, document, and plan '
                'monitoring; do not routinely pre-medicate.'
            : 'Lower-dose course — counsel and safety-net; risk is '
                'lower but not zero.',
        steps: <String>[
          'Counsel the patient and family about possible mood / '
              'psychotic / sleep changes and to report them early.',
          'Use the lowest effective steroid dose and duration; '
              'document baseline mental state.',
          'Arrange proactive monitoring during the course and '
              'across dose reductions.',
          'Do not give prophylactic psychotropics routinely — '
              'evidence does not support it.',
        ],
        cautions: _cautions,
      );
    case SteroidScenario.maniaPsychosis:
      return SteroidPsychResult(
        scenario: scenario,
        highDose: highDose,
        headline:
            'Mania / psychosis is the commonest early picture — '
            'reduce the steroid where possible and treat '
            'symptomatically.',
        steps: <String>[
          'Liaise with the prescriber to reduce / withdraw the '
              'steroid as fast as the physical illness safely '
              'allows.',
          'Treat with an antipsychotic (e.g. olanzapine / '
              'risperidone) at the lowest effective dose; it can '
              'usually be tapered once the steroid is reduced and '
              'symptoms settle.',
          'Avoid where possible agents that add risk; ensure '
              'safety, sleep and a clear review plan.',
        ],
        cautions: _cautions,
      );
    case SteroidScenario.depression:
      return SteroidPsychResult(
        scenario: scenario,
        highDose: highDose,
        headline:
            'Depression is more typical later or on withdrawal — '
            'assess severity and risk.',
        steps: <String>[
          'Assess suicide risk and severity; review the steroid '
              'dose / taper with the prescriber.',
          'Treat moderate–severe depression on its merits '
              '(antidepressant ± psychological therapy); mild may '
              'resolve as the steroid is reduced.',
          'Watch for emergence of depression specifically during '
              'dose reduction and after stopping.',
        ],
        cautions: _cautions,
      );
    case SteroidScenario.delirium:
      return SteroidPsychResult(
        scenario: scenario,
        highDose: highDose,
        headline:
            'Confusion / delirium — exclude other causes; steroids '
            'may be one contributor among several.',
        steps: <String>[
          'Full delirium work-up — do not attribute to steroids '
              'until other causes (infection, metabolic, drugs) '
              'are excluded.',
          'Reduce the steroid where the physical condition '
              'permits; supportive delirium management.',
          'Short-term low-dose antipsychotic only if severe '
              'distress / risk, per delirium guidance.',
        ],
        cautions: _cautions,
      );
  }
}
