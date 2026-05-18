// The febrile patient on clozapine — differential + action.
//
// Fever on clozapine is common (often a benign transient rise early
// in titration) but can be the first sign of life-threatening
// myocarditis, agranulocytosis/sepsis, NMS or serotonin toxicity.
// The safe approach is a structured work-up, not reassurance. This
// engine weights the differential from the entered features and
// returns the action. Summarised from the Maudsley 15e.

enum ClozapineFeverAction {
  workupMonitor('Work up + monitor (often benign)'),
  urgentWithhold('Urgent work-up — withhold clozapine'),
  emergency('Emergency — withhold + escalate now');

  const ClozapineFeverAction(this.label);
  final String label;
}

class ClozapineFeverFinding {
  const ClozapineFeverFinding(
      this.id, this.label, this.points, this.severity);
  final String id;
  final String label;

  /// Differential this finding points to.
  final String points;

  /// 'amber' = urgent/withhold, 'red' = emergency.
  final String severity;
}

const kClozapineFeverFindings = <ClozapineFeverFinding>[
  ClozapineFeverFinding('sore_throat',
      'Sore throat / mouth ulcers / signs of infection',
      'agranulocytosis / sepsis', 'amber'),
  ClozapineFeverFinding('chest_dyspnoea',
      'Chest pain / dyspnoea / sustained tachycardia',
      'myocarditis', 'red'),
  ClozapineFeverFinding('rigidity_autonomic',
      'Rigidity / altered consciousness / autonomic instability',
      'NMS', 'red'),
  ClozapineFeverFinding('clonus_hyperreflexia',
      'Clonus / hyperreflexia / serotonergic co-medication',
      'serotonin toxicity', 'red'),
  ClozapineFeverFinding('haemodynamic',
      'Hypotension / signs of shock', 'sepsis / myocarditis',
      'red'),
  ClozapineFeverFinding('isolated_benign',
      'Isolated low-grade fever, otherwise well, early titration',
      'benign transient fever', 'amber'),
];

class ClozapineFeverResult {
  const ClozapineFeverResult({
    required this.action,
    required this.headline,
    required this.differential,
    required this.investigations,
    required this.cautions,
  });

  final ClozapineFeverAction action;
  final String headline;
  final List<String> differential;
  final List<String> investigations;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Febrile on clozapine — ${action.label}',
      headline,
      '',
      'Differential to consider:',
      for (final d in differential) ' · $d',
      '',
      'Investigate / act:',
      for (final i in investigations) ' · $i',
      '',
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

const _baseInvestigations = <String>[
  'Urgent FBC (exclude neutropenia/agranulocytosis), CRP, '
      'troponin, ECG, U&E/LFT, cultures and a clinical exam.',
  'Full observations incl. temperature, HR, BP and conscious '
      'level; look for a source of infection.',
];

const _cautions = <String>[
  'A benign transient fever is common in the first ~3 weeks but '
      'is a diagnosis of EXCLUSION — never assume it without the '
      'work-up.',
  'Myocarditis and agranulocytosis are the time-critical, '
      'high-mortality causes — a normal appearance does not '
      'exclude them early.',
  'Decisions to withhold / rechallenge clozapine are specialist '
      'risk–benefit calls; document and involve the consultant.',
];

ClozapineFeverResult evaluateClozapineFever({
  bool titrationPhase = true,
  Set<String> findings = const <String>{},
}) {
  final red = kClozapineFeverFindings.any(
      (f) => f.severity == 'red' && findings.contains(f.id));
  final amberSerious = kClozapineFeverFindings.any((f) =>
      f.id == 'sore_throat' && findings.contains(f.id));

  final differential = <String>[
    for (final f in kClozapineFeverFindings)
      if (findings.contains(f.id)) '${f.label} → ${f.points}',
    if (titrationPhase)
      'Titration phase — benign transient fever is common but '
          'remains a diagnosis of exclusion.',
  ];
  if (differential.isEmpty) {
    differential.add(
      'Consider infection, benign transient fever, myocarditis, '
          'agranulocytosis/sepsis, NMS and serotonin toxicity.',
    );
  }

  if (red) {
    return ClozapineFeverResult(
      action: ClozapineFeverAction.emergency,
      headline:
          'Red-flag features — treat as a clozapine-related '
          'emergency until excluded.',
      differential: differential,
      investigations: const <String>[
        'Withhold clozapine now and escalate immediately '
            '(medical / critical care as appropriate).',
        ..._baseInvestigations,
        'Targeted work-up for the suspected cause (e.g. echo for '
            'myocarditis; treat sepsis per protocol; NMS / '
            'serotonin-toxicity management).',
      ],
      cautions: _cautions,
    );
  }

  if (amberSerious) {
    return ClozapineFeverResult(
      action: ClozapineFeverAction.urgentWithhold,
      headline:
          'Infection / agranulocytosis features — urgent FBC and '
          'withhold clozapine pending the result.',
      differential: differential,
      investigations: const <String>[
        'Withhold clozapine pending an urgent FBC; treat '
            'infection and follow the clozapine neutropenia '
            'protocol if counts are low.',
        ..._baseInvestigations,
      ],
      cautions: _cautions,
    );
  }

  return ClozapineFeverResult(
    action: ClozapineFeverAction.workupMonitor,
    headline:
        'No red flags entered — still work up actively; benign '
        'transient fever is a diagnosis of exclusion.',
    differential: differential,
    investigations: const <String>[
      'Do the baseline work-up (FBC/CRP/troponin/ECG/obs) even '
          'if the patient looks well early in titration.',
      ..._baseInvestigations,
      'Monitor closely and re-evaluate immediately if any '
          'cardiac, haematological or neurological feature '
          'appears; decide on continuation with the clozapine '
          'service.',
    ],
    cautions: _cautions,
  );
}
