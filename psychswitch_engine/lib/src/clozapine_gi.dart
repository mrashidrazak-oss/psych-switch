// Clozapine-induced GI hypomotility — prevention + escalation.
//
// Clozapine slows the whole gut; constipation can progress silently
// to ileus, bowel ischaemia, perforation and death — with a higher
// case-fatality than agranulocytosis. Prophylaxis is the default and
// abdominal red flags are a surgical emergency. This engine triages
// entered findings into continue-prophylaxis / escalate / emergency.
// Summarised from the Maudsley 15e.

enum ClozapineGiAction {
  prophylaxis('Continue + prophylaxis'),
  escalate('Escalate laxatives + review'),
  emergency('Surgical emergency — STOP + image');

  const ClozapineGiAction(this.label);
  final String label;
}

class ClozapineGiFinding {
  const ClozapineGiFinding(this.id, this.label, this.severity);
  final String id;
  final String label;

  /// 'amber' = escalate, 'red' = emergency.
  final String severity;
}

const kClozapineGiFindings = <ClozapineGiFinding>[
  ClozapineGiFinding(
      'no_bm_3d', 'No bowel motion for ≥ 3 days', 'amber'),
  ClozapineGiFinding(
      'hard_infrequent', 'Hard / infrequent stools, straining',
      'amber'),
  ClozapineGiFinding(
      'mild_discomfort', 'Mild abdominal discomfort / bloating',
      'amber'),
  ClozapineGiFinding(
      'reduced_intake', 'Reduced oral intake / poor mobility',
      'amber'),
  ClozapineGiFinding(
      'distension_pain',
      'Abdominal distension WITH pain', 'red'),
  ClozapineGiFinding(
      'vomiting', 'Vomiting', 'red'),
  ClozapineGiFinding(
      'no_flatus', 'No flatus / obstipation', 'red'),
  ClozapineGiFinding(
      'absent_bowel_sounds',
      'Absent bowel sounds / rigid abdomen', 'red'),
];

class ClozapineGiResult {
  const ClozapineGiResult({
    required this.action,
    required this.headline,
    required this.steps,
    required this.cautions,
  });

  final ClozapineGiAction action;
  final String headline;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Clozapine GI hypomotility — ${action.label}',
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
  'Clozapine GI hypomotility has a HIGHER case-fatality than '
      'agranulocytosis and is often silent — ask about bowels at '
      'every contact, do not rely on the patient volunteering it.',
  'Sedation / anticholinergic co-medication and other '
      'constipating drugs compound the risk — review the whole '
      'chart.',
  'Stimulant + osmotic laxatives are generally preferred; avoid '
      'bulk-forming laxatives in established hypomotility.',
];

ClozapineGiResult evaluateClozapineGi({
  Set<String> findings = const <String>{},
}) {
  final red = kClozapineGiFindings.any(
      (f) => f.severity == 'red' && findings.contains(f.id));
  final amber = kClozapineGiFindings.any(
      (f) => f.severity == 'amber' && findings.contains(f.id));

  if (red) {
    return const ClozapineGiResult(
      action: ClozapineGiAction.emergency,
      headline:
          'Red flags suggest ileus / obstruction — a surgical '
          'emergency with high mortality.',
      steps: <String>[
        'Treat as an emergency: nil by mouth, urgent senior '
            'medical / surgical review and abdominal imaging.',
        'Withhold clozapine and stop other constipating / '
            'anticholinergic drugs; do not give bulk laxatives.',
        'Escalate immediately; restarting clozapine afterwards is '
            'a specialist risk–benefit decision.',
      ],
      cautions: _cautions,
    );
  }
  if (amber) {
    return const ClozapineGiResult(
      action: ClozapineGiAction.escalate,
      headline:
          'Established constipation — escalate treatment and '
          'monitor closely for progression.',
      steps: <String>[
        'Optimise / escalate laxatives (stimulant + osmotic); '
            'ensure hydration, mobility and dietary measures.',
        'Review and reduce constipating co-medication where '
            'possible; reassess bowel function within a short, '
            'defined interval.',
        'Safety-net explicitly: seek urgent help if pain, '
            'distension, vomiting or no flatus develops.',
      ],
      cautions: _cautions,
    );
  }
  return const ClozapineGiResult(
    action: ClozapineGiAction.prophylaxis,
    headline:
        'No GI findings entered — maintain default prophylaxis '
        'and active surveillance.',
    steps: <String>[
      'Default to prophylactic laxatives from clozapine '
          'initiation in most patients; encourage fluids, fibre '
          'and activity.',
      'Ask about bowel frequency at every clinical contact and '
          'document it.',
      'Re-evaluate immediately if any constipation or abdominal '
          'feature appears.',
    ],
    cautions: _cautions,
  );
}
