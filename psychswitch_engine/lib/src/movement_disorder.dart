// Drug-induced movement disorder identifier.
//
// Five differentials we ask about on every antipsychotic-treated
// patient: parkinsonism, acute dystonia, akathisia, tardive
// dyskinesia, drug-induced tremor.
//
// The engine takes a checked-set of clinical features and ranks each
// differential by how many of its anchoring features match. UI shows
// the top differential plus the first-line management plan.

class MovementFeature {
  const MovementFeature({
    required this.id,
    required this.label,
    required this.subtitle,
  });
  final String id;
  final String label;
  final String subtitle;
}

class MovementDifferential {
  const MovementDifferential({
    required this.id,
    required this.name,
    required this.features,
    required this.management,
    required this.tagline,
  });

  final String id;
  final String name;
  final String tagline;

  /// Feature ids that anchor this differential. Match-count is the
  /// score for ranking.
  final List<String> features;

  /// Paste-ready management plan.
  final String management;
}

const List<MovementFeature> kMovementFeatures = <MovementFeature>[
  // Parkinsonism
  MovementFeature(
    id: 'mvt_pkn_tremor',
    label: 'Resting tremor (pill-rolling)',
    subtitle: 'Disappears or attenuates on action.',
  ),
  MovementFeature(
    id: 'mvt_pkn_rigidity',
    label: 'Cogwheel rigidity',
    subtitle: 'Felt at the wrist on passive movement.',
  ),
  MovementFeature(
    id: 'mvt_pkn_bradykinesia',
    label: 'Bradykinesia · masked facies · stooped gait',
    subtitle: 'Slowness + reduced facial expression.',
  ),
  MovementFeature(
    id: 'mvt_pkn_onset_weeks',
    label: 'Onset 1–4 weeks after starting / dose increase',
    subtitle: 'Most drug-induced parkinsonism settles into this '
        'window.',
  ),
  // Acute dystonia
  MovementFeature(
    id: 'mvt_dys_acute',
    label: 'Acute sustained muscle contraction',
    subtitle: 'Typically torticollis, retrocollis, oculogyric crisis, '
        'laryngeal spasm.',
  ),
  MovementFeature(
    id: 'mvt_dys_onset_hours',
    label: 'Onset within hours–4 days of dose / increase',
    subtitle: 'Younger males, high-potency D2 antagonists at '
        'highest risk.',
  ),
  MovementFeature(
    id: 'mvt_dys_distressing',
    label: 'Patient very distressed · scared',
    subtitle: 'Acute dystonia is typically painful and frightening.',
  ),
  // Akathisia
  MovementFeature(
    id: 'mvt_aka_subjective',
    label: 'Subjective restlessness / "ants in pants"',
    subtitle: 'Inner sense of needing to move, distinct from anxiety.',
  ),
  MovementFeature(
    id: 'mvt_aka_movement',
    label: 'Pacing, leg-bouncing, shifting in seat',
    subtitle: 'Observable inability to sit still.',
  ),
  MovementFeature(
    id: 'mvt_aka_recent_change',
    label: 'Recent dose increase or start of antipsychotic',
    subtitle: 'Typical onset days–weeks after change.',
  ),
  // Tardive dyskinesia
  MovementFeature(
    id: 'mvt_td_chronic',
    label: 'Onset after months–years of antipsychotic use',
    subtitle: 'Especially with first-generation antipsychotics.',
  ),
  MovementFeature(
    id: 'mvt_td_orobuccal',
    label: 'Orobuccolingual choreoathetoid movements',
    subtitle: 'Tongue-protruding, lip-smacking, grimacing.',
  ),
  MovementFeature(
    id: 'mvt_td_worse_on_stress',
    label: 'Worse with stress, improves on activation',
    subtitle: 'Opposite pattern to parkinsonian tremor.',
  ),
  // Tremor (drug-induced, non-Parkinsonian)
  MovementFeature(
    id: 'mvt_trm_postural',
    label: 'Fine postural / action tremor',
    subtitle: 'Worse with outstretched arms; bilateral and '
        'symmetrical.',
  ),
  MovementFeature(
    id: 'mvt_trm_lithium_valproate',
    label: 'On lithium / valproate / SSRI / SNRI',
    subtitle: 'Classic offenders for postural tremor.',
  ),
];

const List<MovementDifferential> kMovementDifferentials =
    <MovementDifferential>[
  MovementDifferential(
    id: 'parkinsonism',
    name: 'Drug-induced parkinsonism',
    tagline: 'Tremor + rigidity + bradykinesia · weeks',
    features: <String>[
      'mvt_pkn_tremor',
      'mvt_pkn_rigidity',
      'mvt_pkn_bradykinesia',
      'mvt_pkn_onset_weeks',
    ],
    management:
        'Reduce the antipsychotic dose first. If unavoidable, switch '
        'to a lower-EPS agent (quetiapine, olanzapine, aripiprazole). '
        'Anticholinergic adjuncts (procyclidine, trihexyphenidyl) are '
        'a short-term option in adults but accumulate cognitive cost — '
        'avoid in elderly.',
  ),
  MovementDifferential(
    id: 'dystonia',
    name: 'Acute dystonic reaction',
    tagline: 'Sustained muscle spasm · hours of dose change',
    features: <String>[
      'mvt_dys_acute',
      'mvt_dys_onset_hours',
      'mvt_dys_distressing',
    ],
    management:
        'Emergency: IM procyclidine 5–10 mg or IM benztropine 1–2 mg, '
        'expect resolution within 20 min. IV diazepam 5–10 mg if '
        'laryngeal involvement. Reassure patient — extremely '
        'distressing but rapidly reversible. Continue oral '
        'anticholinergic prophylaxis for 1–2 weeks; reduce dose or '
        'switch to a lower-EPS agent.',
  ),
  MovementDifferential(
    id: 'akathisia',
    name: 'Akathisia',
    tagline: 'Inner restlessness · days–weeks',
    features: <String>[
      'mvt_aka_subjective',
      'mvt_aka_movement',
      'mvt_aka_recent_change',
    ],
    management:
        'Reduce antipsychotic dose first. Propranolol 10–40 mg TDS is '
        'first-line. Mirtazapine 15 mg ON or low-dose benzodiazepine '
        '(short courses only) are reasonable second-line. '
        'Anticholinergics generally do NOT help akathisia.',
  ),
  MovementDifferential(
    id: 'td',
    name: 'Tardive dyskinesia',
    tagline: 'Orobuccal choreoathetosis · months–years',
    features: <String>[
      'mvt_td_chronic',
      'mvt_td_orobuccal',
      'mvt_td_worse_on_stress',
    ],
    management:
        'STOP the offending antipsychotic where possible. Switching '
        'to clozapine has the strongest evidence for resolution. '
        'VMAT-2 inhibitors (valbenazine, deutetrabenazine) are '
        'first-line where available. AVOID adding anticholinergics — '
        'they worsen TD.',
  ),
  MovementDifferential(
    id: 'tremor',
    name: 'Drug-induced tremor',
    tagline: 'Postural / action tremor · lithium · valproate',
    features: <String>[
      'mvt_trm_postural',
      'mvt_trm_lithium_valproate',
    ],
    management:
        'Confirm the offending drug. Lithium: check level, reduce '
        'dose, ensure adequate hydration, avoid caffeine. Valproate: '
        'check level + reduce; consider divided dosing. Propranolol '
        '10–40 mg TDS often effective.',
  ),
];

class MovementRanking {
  const MovementRanking({
    required this.differential,
    required this.matches,
    required this.featureCount,
  });

  final MovementDifferential differential;
  final int matches;
  final int featureCount;

  /// Confidence — percentage of the differential's anchor features
  /// that are present.
  double get confidence =>
      featureCount == 0 ? 0 : matches / featureCount;
}

class MovementResult {
  const MovementResult({
    required this.rankings,
    required this.topId,
    required this.totalChecked,
  });

  /// Sorted descending by matches.
  final List<MovementRanking> rankings;
  final String? topId;
  final int totalChecked;

  MovementDifferential? get top {
    if (topId == null) return null;
    return kMovementDifferentials.firstWhere(
      (d) => d.id == topId,
      orElse: () => kMovementDifferentials.first,
    );
  }

  String clipboardSummary() {
    if (top == null) return 'Movement-disorder picker — no features ticked.';
    return 'Likely diagnosis: ${top!.name}. ${top!.management}';
  }
}

MovementResult rankMovementDisorder(Set<String> ticked) {
  final rankings = kMovementDifferentials.map((d) {
    final matches = d.features.where(ticked.contains).length;
    return MovementRanking(
      differential: d,
      matches: matches,
      featureCount: d.features.length,
    );
  }).toList()
    ..sort((a, b) => b.matches.compareTo(a.matches));

  String? topId;
  if (ticked.isNotEmpty && rankings.isNotEmpty && rankings.first.matches > 0) {
    topId = rankings.first.differential.id;
  }

  return MovementResult(
    rankings: rankings,
    topId: topId,
    totalChecked: ticked.length,
  );
}
