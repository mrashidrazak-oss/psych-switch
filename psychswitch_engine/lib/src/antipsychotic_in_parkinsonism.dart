// Antipsychotic selection in Parkinsonism, Lewy body disease and
// dementia.
//
// These groups need a different rule set: severe neuroleptic
// sensitivity in Lewy body disease (potentially fatal), worsening
// motor function in Parkinson's, and the stroke / mortality signal
// of antipsychotics in dementia. This engine maps the context to
// safe choices, agents to avoid, and the safeguards. Summarised from
// the Maudsley 15e and NICE dementia / Parkinson's guidance.

enum NeuroContext {
  parkinsonsPsychosis("Parkinson's disease psychosis"),
  lewyBody('Lewy body disease (DLB / PDD)'),
  alzheimersVascularBpsd('Alzheimer / vascular dementia (BPSD)');

  const NeuroContext(this.label);
  final String label;
}

class NeuroAntipsychoticResult {
  const NeuroAntipsychoticResult({
    required this.context,
    required this.headline,
    required this.firstSteps,
    required this.preferred,
    required this.avoid,
    required this.cautions,
  });

  final NeuroContext context;
  final String headline;
  final List<String> firstSteps;
  final List<String> preferred;
  final List<String> avoid;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Antipsychotic in ${context.label}',
      headline,
      '',
      'Before any antipsychotic:',
      for (final s in firstSteps) ' · $s',
      '',
      'Preferred (if a drug is unavoidable):',
      for (final p in preferred) ' · $p',
      '',
      'Avoid:',
      for (final a in avoid) ' · $a',
      '',
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

const _firstSteps = <String>[
  'Look for and treat reversible causes first (delirium, '
      'infection, pain, constipation, dehydration, drugs incl. '
      'dopaminergic / anticholinergic burden).',
  'Non-pharmacological management is first-line; reserve drugs '
      'for severe distress or risk and use the lowest dose for '
      'the shortest time.',
];

const _dementiaCautions = <String>[
  'Antipsychotics in dementia carry an increased risk of stroke '
      'and death — document the explicit risk/benefit discussion '
      'and consent (best-interests where applicable).',
  'Set a review date (e.g. ~6 weeks) and a stop plan; do not '
      'continue indefinitely.',
];

NeuroAntipsychoticResult evaluateNeuroAntipsychotic(
  NeuroContext context,
) {
  switch (context) {
    case NeuroContext.parkinsonsPsychosis:
      return const NeuroAntipsychoticResult(
        context: NeuroContext.parkinsonsPsychosis,
        headline:
            'Protect motor function — most antipsychotics worsen '
            'Parkinson’s.',
        firstSteps: <String>[
          ..._firstSteps,
          'Review and simplify anti-parkinsonian medication with '
              'neurology (reduce the most psychotogenic, least '
              'motor-critical agents first).',
        ],
        preferred: <String>[
          'Quetiapine (low dose) — commonly used first for its low '
              'extrapyramidal burden.',
          'Clozapine — best evidence in Parkinson’s psychosis but '
              'needs the full clozapine monitoring framework.',
          'Pimavanserin where available / licensed.',
          'Consider a cholinesterase inhibitor where cognitive '
              'impairment coexists.',
        ],
        avoid: <String>[
          'Typical antipsychotics (haloperidol etc.) and most '
              'other D2-blocking atypicals (risperidone, '
              'olanzapine) — marked motor worsening.',
        ],
        cautions: _dementiaCautions,
      );
    case NeuroContext.lewyBody:
      return const NeuroAntipsychoticResult(
        context: NeuroContext.lewyBody,
        headline:
            'SEVERE neuroleptic sensitivity — reactions can be '
            'severe and fatal; avoid antipsychotics if at all '
            'possible.',
        firstSteps: <String>[
          ..._firstSteps,
          'Trial a cholinesterase inhibitor (e.g. rivastigmine) '
              'for neuropsychiatric symptoms before considering '
              'any antipsychotic.',
        ],
        preferred: <String>[
          'If genuinely unavoidable: very low-dose quetiapine or '
              'clozapine ONLY, started low, titrated slowly, with '
              'close monitoring for neuroleptic sensitivity.',
        ],
        avoid: <String>[
          'ALL typical antipsychotics and risperidone / olanzapine '
              '— high risk of severe neuroleptic sensitivity '
              '(rigidity, autonomic instability, rapid '
              'deterioration, death).',
        ],
        cautions: <String>[
          'Warn carers/staff to seek urgent help if rigidity, '
              'reduced consciousness or rapid decline follows any '
              'dose — treat as a neuroleptic-sensitivity emergency.',
          ..._dementiaCautions,
        ],
      );
    case NeuroContext.alzheimersVascularBpsd:
      return const NeuroAntipsychoticResult(
        context: NeuroContext.alzheimersVascularBpsd,
        headline:
            'BPSD — non-drug first; if a drug is needed use the '
            'lowest dose for the shortest time.',
        firstSteps: <String>[
          ..._firstSteps,
          'Trial structured non-pharmacological / environmental '
              'interventions and treat unmet needs before any '
              'antipsychotic.',
        ],
        preferred: <String>[
          'Risperidone is the agent with the clearest evidence / '
              'limited licence for short-term severe aggression or '
              'psychosis — lowest effective dose, time-limited.',
          'Consider whether the presentation is depression / pain '
              '/ delirium that would respond to a non-antipsychotic '
              'approach.',
        ],
        avoid: <String>[
          'Long-term or default antipsychotic use; high doses; '
              'using a drug for wandering, calling out or non-'
              'distressing behaviours.',
        ],
        cautions: _dementiaCautions,
      );
  }
}
