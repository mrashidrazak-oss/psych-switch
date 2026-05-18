// Bush-Francis Catatonia Screening Instrument (BFCSI).
//
// Bush G, Fink M, Petrides G, et al. Acta Psychiatr Scand
// 1996;93:129-36. The 14-item screening instrument is scored
// present (1) / absent (0); 2 or more positive items prompts the full
// 23-item Bush-Francis Catatonia Rating Scale and a lorazepam
// challenge. Public-domain instrument widely reproduced in textbooks.
//
// This engine surfaces the 14 screening signs + the screen-positive
// threshold + the lorazepam-challenge guidance. It is a screen, not
// the full severity scale.

class CatatoniaSign {
  const CatatoniaSign({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

const List<CatatoniaSign> kBfcsiSigns = <CatatoniaSign>[
  CatatoniaSign(
    id: 'excitement',
    name: 'Excitement',
    description: 'Extreme hyperactivity, constant motor unrest, '
        'apparently non-purposeful.',
  ),
  CatatoniaSign(
    id: 'immobility',
    name: 'Immobility / stupor',
    description: 'Extreme hypoactivity, immobile, minimally '
        'responsive to stimuli.',
  ),
  CatatoniaSign(
    id: 'mutism',
    name: 'Mutism',
    description: 'Verbally unresponsive or minimally responsive.',
  ),
  CatatoniaSign(
    id: 'staring',
    name: 'Staring',
    description: 'Fixed gaze, little or no visual scanning, reduced '
        'blinking.',
  ),
  CatatoniaSign(
    id: 'posturing',
    name: 'Posturing / catalepsy',
    description: 'Spontaneous maintenance of posture(s), including '
        'mundane ones, against gravity.',
  ),
  CatatoniaSign(
    id: 'grimacing',
    name: 'Grimacing',
    description: 'Maintenance of odd facial expressions.',
  ),
  CatatoniaSign(
    id: 'echopraxia',
    name: 'Echopraxia / echolalia',
    description: "Mimicking the examiner's movements or speech.",
  ),
  CatatoniaSign(
    id: 'stereotypy',
    name: 'Stereotypy',
    description: 'Repetitive, non-goal-directed motor activity.',
  ),
  CatatoniaSign(
    id: 'mannerisms',
    name: 'Mannerisms',
    description: 'Odd, purposeful movements (e.g. caricatured '
        'normal actions).',
  ),
  CatatoniaSign(
    id: 'verbigeration',
    name: 'Verbigeration',
    description: 'Repetition of phrases or sentences.',
  ),
  CatatoniaSign(
    id: 'rigidity',
    name: 'Rigidity',
    description: 'Maintenance of a rigid position despite efforts to '
        'be moved.',
  ),
  CatatoniaSign(
    id: 'negativism',
    name: 'Negativism',
    description: 'Apparently motiveless resistance to instructions or '
        'attempts to move / examine.',
  ),
  CatatoniaSign(
    id: 'waxy',
    name: 'Waxy flexibility',
    description: 'Initial resistance before allowing repositioning, '
        'similar to bending a candle.',
  ),
  CatatoniaSign(
    id: 'withdrawal',
    name: 'Withdrawal',
    description: 'Refusal to eat / drink and / or eye contact.',
  ),
];

class CatatoniaResult {
  const CatatoniaResult({
    required this.positiveCount,
    required this.screenPositive,
    required this.headline,
    required this.recommendation,
  });

  final int positiveCount;
  final bool screenPositive;
  final String headline;
  final String recommendation;

  String clipboardSummary() =>
      'Bush-Francis screen: $positiveCount / 14 positive — '
      '${screenPositive ? "SCREEN POSITIVE" : "screen negative"}. '
      '$recommendation';
}

/// 2+ positive signs = screen positive.
CatatoniaResult evaluateCatatonia(Set<String> positiveSignIds) {
  final n = positiveSignIds.where(
    (id) => kBfcsiSigns.any((s) => s.id == id),
  ).length;
  if (n >= 2) {
    return CatatoniaResult(
      positiveCount: n,
      screenPositive: true,
      headline: 'Screen positive — catatonia likely.',
      recommendation:
          'Proceed to the full Bush-Francis Catatonia Rating Scale and '
          'a lorazepam challenge: 1-2 mg IV/IM, observe 5-10 min '
          '(IV) / 30-60 min (IM); a partial response supports the '
          'diagnosis. Exclude NMS and a delirious / medical cause '
          'before benzodiazepine loading; avoid antipsychotics until '
          'malignant catatonia is excluded. Consider ECT if '
          'lorazepam-refractory or malignant features.',
    );
  }
  return CatatoniaResult(
    positiveCount: n,
    screenPositive: false,
    headline: 'Screen negative on current signs.',
    recommendation:
        'Catatonia unlikely on this screen. Re-screen if the picture '
        'evolves; isolated single signs can be non-specific.',
  );
}
