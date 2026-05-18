// Serotonergic opioid + serotonergic psychotropic — interaction.
//
// Some opioids add serotonergic activity on top of analgesia and can
// precipitate serotonin toxicity with SSRIs/SNRIs/MAOIs etc. The
// classic catastrophe is pethidine (meperidine) + MAOI. This engine
// grades the opioid's serotonergic risk against the concurrent
// serotonergic agent and suggests safer choices. Summarised from the
// Maudsley 15e and the Hunter serotonin-toxicity literature.

enum OpioidSerotonergicRisk {
  contraindicated('Contraindicated combination'),
  highRisk('High risk — avoid / specialist only'),
  caution('Use with caution + monitor'),
  lowRisk('Low serotonergic risk');

  const OpioidSerotonergicRisk(this.label);
  final String label;
}

class SerotonergicOpioid {
  const SerotonergicOpioid(this.id, this.name, this.tier);
  final String id;
  final String name;

  /// 'strong' | 'weak' | 'none'
  final String tier;
}

const kSerotonergicOpioids = <SerotonergicOpioid>[
  SerotonergicOpioid('pethidine', 'Pethidine (meperidine)', 'strong'),
  SerotonergicOpioid('tramadol', 'Tramadol', 'strong'),
  SerotonergicOpioid('tapentadol', 'Tapentadol', 'strong'),
  SerotonergicOpioid('fentanyl', 'Fentanyl', 'weak'),
  SerotonergicOpioid('methadone', 'Methadone', 'weak'),
  SerotonergicOpioid('oxycodone', 'Oxycodone', 'weak'),
  SerotonergicOpioid('morphine', 'Morphine', 'none'),
  SerotonergicOpioid('codeine', 'Codeine / dihydrocodeine', 'none'),
  SerotonergicOpioid('buprenorphine', 'Buprenorphine', 'none'),
];

class SerotonergicAgent {
  const SerotonergicAgent(this.id, this.name, this.tier);
  final String id;
  final String name;

  /// 'maoi' | 'strong' | 'moderate'
  final String tier;
}

const kSerotonergicAgents = <SerotonergicAgent>[
  SerotonergicAgent('maoi', 'MAOI (incl. moclobemide, linezolid)',
      'maoi'),
  SerotonergicAgent('ssri', 'SSRI', 'strong'),
  SerotonergicAgent('snri', 'SNRI (venlafaxine, duloxetine)',
      'strong'),
  SerotonergicAgent('clomipramine', 'Clomipramine', 'strong'),
  SerotonergicAgent('mirtazapine', 'Mirtazapine', 'moderate'),
  SerotonergicAgent('tca_other', 'Other TCA', 'moderate'),
  SerotonergicAgent('lithium', 'Lithium', 'moderate'),
];

class SerotonergicOpioidResult {
  const SerotonergicOpioidResult({
    required this.risk,
    required this.headline,
    required this.saferAlternatives,
    required this.steps,
    required this.cautions,
  });

  final OpioidSerotonergicRisk risk;
  final String headline;
  final List<String> saferAlternatives;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Serotonergic opioid interaction — ${risk.label}',
      headline,
      '',
      'Safer opioid options:',
      for (final s in saferAlternatives) ' · $s',
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

const _saferOpioids = <String>[
  'Morphine, oxycodone, buprenorphine, codeine / dihydrocodeine '
      'have minimal serotonergic activity — prefer these for '
      'analgesia where opioids are needed.',
];

const _cautions = <String>[
  'Serotonin toxicity is a clinical diagnosis (Hunter criteria) — '
      'clonus, hyperreflexia, agitation, autonomic instability, '
      'hyperthermia; onset is usually rapid.',
  'Risk is dose-related and additive with every serotonergic '
      'agent (incl. anti-emetics e.g. ondansetron, metoclopramide '
      'and St John’s wort).',
];

OpioidSerotonergicRisk _grade(String opioidTier, String agentTier) {
  if (agentTier == 'maoi') {
    if (opioidTier == 'strong') {
      return OpioidSerotonergicRisk.contraindicated;
    }
    if (opioidTier == 'weak') return OpioidSerotonergicRisk.highRisk;
    return OpioidSerotonergicRisk.caution;
  }
  if (opioidTier == 'strong') {
    return agentTier == 'strong'
        ? OpioidSerotonergicRisk.highRisk
        : OpioidSerotonergicRisk.caution;
  }
  if (opioidTier == 'weak') {
    return agentTier == 'strong'
        ? OpioidSerotonergicRisk.caution
        : OpioidSerotonergicRisk.lowRisk;
  }
  return OpioidSerotonergicRisk.lowRisk;
}

SerotonergicOpioidResult evaluateSerotonergicOpioid({
  required String opioidId,
  required String agentId,
}) {
  final opioid = kSerotonergicOpioids.firstWhere(
    (o) => o.id == opioidId,
    orElse: () => kSerotonergicOpioids.last,
  );
  final agent = kSerotonergicAgents.firstWhere(
    (a) => a.id == agentId,
    orElse: () => kSerotonergicAgents[1],
  );
  final risk = _grade(opioid.tier, agent.tier);

  switch (risk) {
    case OpioidSerotonergicRisk.contraindicated:
      return SerotonergicOpioidResult(
        risk: risk,
        headline:
            '${opioid.name} + ${agent.name} — classic, potentially '
            'fatal serotonin-toxicity / excitatory reaction. Do '
            'NOT co-administer.',
        saferAlternatives: _saferOpioids,
        steps: <String>[
          'Do not give ${opioid.name}. Choose a non-serotonergic '
              'opioid (morphine / oxycodone / buprenorphine).',
          'Observe MAOI washout rules if switching antidepressants; '
              'never bridge with a serotonergic opioid.',
          'If serotonin toxicity is suspected: stop the agent, '
              'supportive care, escalate (Hunter criteria).',
        ],
        cautions: _cautions,
      );
    case OpioidSerotonergicRisk.highRisk:
      return SerotonergicOpioidResult(
        risk: risk,
        headline:
            '${opioid.name} + ${agent.name} — high serotonin-'
            'toxicity risk; avoid or specialist-only with close '
            'monitoring.',
        saferAlternatives: _saferOpioids,
        steps: <String>[
          'Prefer a non-serotonergic opioid; if ${opioid.name} is '
              'truly required, use the lowest dose, shortest '
              'duration, with explicit monitoring.',
          'Counsel the patient on serotonin-toxicity symptoms and '
              'when to seek urgent help.',
        ],
        cautions: _cautions,
      );
    case OpioidSerotonergicRisk.caution:
      return SerotonergicOpioidResult(
        risk: risk,
        headline:
            '${opioid.name} + ${agent.name} — usable with caution; '
            'additive serotonergic load.',
        saferAlternatives: _saferOpioids,
        steps: <String>[
          'Use the lowest effective dose; review total serotonergic '
              'burden (anti-emetics, other agents).',
          'Monitor for early serotonin-toxicity features after '
              'starting / dose increases.',
        ],
        cautions: _cautions,
      );
    case OpioidSerotonergicRisk.lowRisk:
      return SerotonergicOpioidResult(
        risk: risk,
        headline:
            '${opioid.name} + ${agent.name} — low serotonergic '
            'risk; standard analgesic care.',
        saferAlternatives: _saferOpioids,
        steps: <String>[
          'Routine analgesic prescribing; remain alert if multiple '
              'serotonergic agents are combined.',
        ],
        cautions: _cautions,
      );
  }
}
