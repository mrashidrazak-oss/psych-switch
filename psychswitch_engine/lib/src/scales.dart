// Clinical rating-scales engine.
//
// Authoritative, public-domain rating scales used in everyday psych
// practice — modelled as pure data so the UI can render them with no
// hard-coded item lists and the scoring logic stays testable.
//
// Scales included:
//   • PHQ-9 — Patient Health Questionnaire-9 (Kroenke 2001)
//     Pfizer-released, freely usable. 9 items, 0–3 each, total 0–27.
//   • GAD-7 — Generalized Anxiety Disorder-7 (Spitzer 2006)
//     Pfizer-released, freely usable. 7 items, 0–3 each, total 0–21.
//   • HAM-D-17 — Hamilton Depression Rating Scale, 17-item
//     (Hamilton 1960). Public domain.
//   • AIMS — Abnormal Involuntary Movement Scale (NIMH/Guy 1976).
//     Public domain. 12 items; items 1–7 dyskinesia (0–4), items 8–10
//     global (0–4), items 11–12 yes/no — only items 1–7 contribute to
//     the total dyskinesia score.
//
// Each scale is a [ClinicalScale] with ordered [ScaleItem]s and a list
// of [SeverityBand]s. [scoreScale] sums the relevant items and looks
// up the band for the resulting total.

/// One item on a rating scale.
class ScaleItem {
  const ScaleItem({
    required this.id,
    required this.prompt,
    required this.anchors,
    this.contributesToTotal = true,
    this.subtitle,
  });

  /// Stable id for the item (used as map key for answers).
  final String id;

  /// What the clinician/patient is reading.
  final String prompt;

  /// Ordered list of anchor labels — index 0 is score 0, index 1 is
  /// score 1, etc. Length 4 → 0–3 anchors, length 5 → 0–4.
  final List<String> anchors;

  /// Items 11–12 of the AIMS (dental problems / awareness) are
  /// recorded but don't contribute to the dyskinesia total. Default
  /// true.
  final bool contributesToTotal;

  /// Optional clarifier rendered under the prompt.
  final String? subtitle;

  /// Highest possible score on this item.
  int get maxScore => anchors.length - 1;
}

/// One severity band on a scale's total-score axis.
class SeverityBand {
  const SeverityBand({
    required this.min,
    required this.max,
    required this.label,
    required this.interpretation,
    required this.severity,
  });

  final int min;
  final int max;

  /// Short label shown on the score chip (e.g. "Moderate").
  final String label;

  /// One-sentence clinical interpretation (e.g. "Consider treatment
  /// plan, may need active intervention").
  final String interpretation;

  /// Semantic severity ordinal — used by the UI to pick a tone.
  ///   0 = none / minimal
  ///   1 = mild
  ///   2 = moderate
  ///   3 = moderately severe
  ///   4 = severe / very severe
  final int severity;

  bool contains(int score) => score >= min && score <= max;
}

/// One scale.
class ClinicalScale {
  const ClinicalScale({
    required this.id,
    required this.name,
    required this.fullName,
    required this.tagline,
    required this.citation,
    required this.items,
    required this.bands,
    this.headingPrompt,
  });

  /// Stable id (e.g. 'phq9', 'gad7', 'hamd17', 'aims').
  final String id;

  /// Short display name (e.g. 'PHQ-9').
  final String name;

  /// Full title (e.g. 'Patient Health Questionnaire-9').
  final String fullName;

  /// One-line tagline shown on the index card.
  final String tagline;

  /// Single-line citation / source.
  final String citation;

  /// Common preamble shown above the items (e.g. "Over the last two
  /// weeks, how often have you been bothered by any of the following
  /// problems?"). Optional.
  final String? headingPrompt;

  /// Ordered items.
  final List<ScaleItem> items;

  /// Severity bands.
  final List<SeverityBand> bands;

  /// Maximum total achievable.
  int get maxScore => items
      .where((i) => i.contributesToTotal)
      .fold<int>(0, (acc, i) => acc + i.maxScore);
}

/// Result of [scoreScale].
class ScaleResult {
  const ScaleResult({
    required this.scale,
    required this.total,
    required this.band,
    required this.answers,
  });

  final ClinicalScale scale;
  final int total;
  final SeverityBand band;

  /// The map the caller passed in — convenient for export / save.
  final Map<String, int> answers;
}

/// Sum the items, look up the band. Items not answered are treated as
/// 0. Items that don't contribute to the total (e.g. AIMS items 11–12)
/// are excluded from the sum.
ScaleResult scoreScale(ClinicalScale scale, Map<String, int> answers) {
  var total = 0;
  for (final item in scale.items) {
    if (!item.contributesToTotal) continue;
    final v = answers[item.id] ?? 0;
    total += v.clamp(0, item.maxScore);
  }
  final band = scale.bands.firstWhere(
    (b) => b.contains(total),
    orElse: () => scale.bands.last,
  );
  return ScaleResult(
    scale: scale,
    total: total,
    band: band,
    answers: Map<String, int>.unmodifiable(answers),
  );
}

// ── PHQ-9 ────────────────────────────────────────────────────────────

const _phq9Anchors = <String>[
  'Not at all',
  'Several days',
  'More than half the days',
  'Nearly every day',
];

const _phq9 = ClinicalScale(
  id: 'phq9',
  name: 'PHQ-9',
  fullName: 'Patient Health Questionnaire-9',
  tagline: 'Depression screening · 9 items · 0–27',
  citation: 'Kroenke K, Spitzer RL, Williams JBW. JGIM 2001;16:606-13.',
  headingPrompt: 'Over the last two weeks, how often have you been '
      'bothered by any of the following problems?',
  items: <ScaleItem>[
    ScaleItem(
      id: 'phq9_1',
      prompt: 'Little interest or pleasure in doing things',
      anchors: _phq9Anchors,
    ),
    ScaleItem(
      id: 'phq9_2',
      prompt: 'Feeling down, depressed, or hopeless',
      anchors: _phq9Anchors,
    ),
    ScaleItem(
      id: 'phq9_3',
      prompt: 'Trouble falling or staying asleep, or sleeping too much',
      anchors: _phq9Anchors,
    ),
    ScaleItem(
      id: 'phq9_4',
      prompt: 'Feeling tired or having little energy',
      anchors: _phq9Anchors,
    ),
    ScaleItem(
      id: 'phq9_5',
      prompt: 'Poor appetite or overeating',
      anchors: _phq9Anchors,
    ),
    ScaleItem(
      id: 'phq9_6',
      prompt: 'Feeling bad about yourself — or that you are a failure '
          'or have let yourself or your family down',
      anchors: _phq9Anchors,
    ),
    ScaleItem(
      id: 'phq9_7',
      prompt: 'Trouble concentrating on things, such as reading the '
          'newspaper or watching television',
      anchors: _phq9Anchors,
    ),
    ScaleItem(
      id: 'phq9_8',
      prompt: 'Moving or speaking so slowly that other people could '
          'have noticed — or the opposite, being so fidgety or '
          'restless that you have been moving around a lot more than usual',
      anchors: _phq9Anchors,
    ),
    ScaleItem(
      id: 'phq9_9',
      prompt: 'Thoughts that you would be better off dead, or of '
          'hurting yourself in some way',
      subtitle: 'Any positive answer warrants a same-day safety review.',
      anchors: _phq9Anchors,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 4,
      label: 'None / minimal',
      interpretation: 'No clinically significant depressive symptoms.',
      severity: 0,
    ),
    SeverityBand(
      min: 5,
      max: 9,
      label: 'Mild',
      interpretation: 'Watchful waiting; repeat PHQ-9 at follow-up.',
      severity: 1,
    ),
    SeverityBand(
      min: 10,
      max: 14,
      label: 'Moderate',
      interpretation: 'Treatment plan: counselling, follow-up, '
          'and/or pharmacotherapy.',
      severity: 2,
    ),
    SeverityBand(
      min: 15,
      max: 19,
      label: 'Moderately severe',
      interpretation: 'Active treatment with pharmacotherapy '
          'and/or psychotherapy.',
      severity: 3,
    ),
    SeverityBand(
      min: 20,
      max: 27,
      label: 'Severe',
      interpretation: 'Immediate initiation of pharmacotherapy; '
          'expedited specialist referral.',
      severity: 4,
    ),
  ],
);

// ── GAD-7 ────────────────────────────────────────────────────────────

const _gad7Anchors = _phq9Anchors;

const _gad7 = ClinicalScale(
  id: 'gad7',
  name: 'GAD-7',
  fullName: 'Generalized Anxiety Disorder-7',
  tagline: 'Anxiety screening · 7 items · 0–21',
  citation:
      'Spitzer RL, Kroenke K, Williams JB, Löwe B. Arch Intern Med '
      '2006;166:1092-7.',
  headingPrompt: 'Over the last two weeks, how often have you been '
      'bothered by the following problems?',
  items: <ScaleItem>[
    ScaleItem(
      id: 'gad7_1',
      prompt: 'Feeling nervous, anxious, or on edge',
      anchors: _gad7Anchors,
    ),
    ScaleItem(
      id: 'gad7_2',
      prompt: 'Not being able to stop or control worrying',
      anchors: _gad7Anchors,
    ),
    ScaleItem(
      id: 'gad7_3',
      prompt: 'Worrying too much about different things',
      anchors: _gad7Anchors,
    ),
    ScaleItem(
      id: 'gad7_4',
      prompt: 'Trouble relaxing',
      anchors: _gad7Anchors,
    ),
    ScaleItem(
      id: 'gad7_5',
      prompt: 'Being so restless that it is hard to sit still',
      anchors: _gad7Anchors,
    ),
    ScaleItem(
      id: 'gad7_6',
      prompt: 'Becoming easily annoyed or irritable',
      anchors: _gad7Anchors,
    ),
    ScaleItem(
      id: 'gad7_7',
      prompt: 'Feeling afraid as if something awful might happen',
      anchors: _gad7Anchors,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 4,
      label: 'Minimal',
      interpretation: 'No clinically significant anxiety symptoms.',
      severity: 0,
    ),
    SeverityBand(
      min: 5,
      max: 9,
      label: 'Mild',
      interpretation: 'Watchful waiting; repeat GAD-7 at follow-up.',
      severity: 1,
    ),
    SeverityBand(
      min: 10,
      max: 14,
      label: 'Moderate',
      interpretation: 'Treatment plan: psychoeducation, CBT, '
          'and/or pharmacotherapy.',
      severity: 2,
    ),
    SeverityBand(
      min: 15,
      max: 21,
      label: 'Severe',
      interpretation: 'Active treatment indicated; consider '
          'specialist referral.',
      severity: 4,
    ),
  ],
);

// ── HAM-D-17 ─────────────────────────────────────────────────────────
//
// Items 1, 2, 3, 7, 8, 9, 10, 11, 15 are 0–4 (5 anchors).
// Items 4, 5, 6, 12, 13, 14, 16, 17 are 0–2 (3 anchors).
// Max total = 9 × 4 + 8 × 2 = 36 + 16 = 52.

const _ham5 = <String>[
  'Absent',
  'Mild / doubtful',
  'Mild–moderate',
  'Moderate–severe',
  'Severe / incapacitating',
];

const _ham3 = <String>[
  'Absent',
  'Trivial / doubtful',
  'Clear / severe',
];

const _hamd17 = ClinicalScale(
  id: 'hamd17',
  name: 'HAM-D-17',
  fullName: 'Hamilton Depression Rating Scale (17-item)',
  tagline: 'Clinician-rated depression · 17 items · 0–52',
  citation: 'Hamilton M. J Neurol Neurosurg Psychiatry 1960;23:56-62.',
  headingPrompt: "Rate the patient over the past week. Pick the anchor "
      "that best matches today's clinical picture.",
  items: <ScaleItem>[
    ScaleItem(
      id: 'hamd_1',
      prompt: 'Depressed mood',
      subtitle: 'Sadness, hopelessness, helplessness, worthlessness.',
      anchors: _ham5,
    ),
    ScaleItem(
      id: 'hamd_2',
      prompt: 'Feelings of guilt',
      anchors: _ham5,
    ),
    ScaleItem(
      id: 'hamd_3',
      prompt: 'Suicide',
      subtitle: 'Score >0 warrants explicit safety planning.',
      anchors: _ham5,
    ),
    ScaleItem(
      id: 'hamd_4',
      prompt: 'Insomnia, early',
      subtitle: 'Difficulty falling asleep.',
      anchors: _ham3,
    ),
    ScaleItem(
      id: 'hamd_5',
      prompt: 'Insomnia, middle',
      subtitle: 'Restless / disturbed during the night.',
      anchors: _ham3,
    ),
    ScaleItem(
      id: 'hamd_6',
      prompt: 'Insomnia, late',
      subtitle: 'Waking in early hours and unable to fall asleep again.',
      anchors: _ham3,
    ),
    ScaleItem(
      id: 'hamd_7',
      prompt: 'Work and activities',
      anchors: _ham5,
    ),
    ScaleItem(
      id: 'hamd_8',
      prompt: 'Retardation',
      subtitle: 'Slowness of thought / speech / motor activity.',
      anchors: _ham5,
    ),
    ScaleItem(
      id: 'hamd_9',
      prompt: 'Agitation',
      anchors: _ham5,
    ),
    ScaleItem(
      id: 'hamd_10',
      prompt: 'Anxiety (psychic)',
      anchors: _ham5,
    ),
    ScaleItem(
      id: 'hamd_11',
      prompt: 'Anxiety (somatic)',
      subtitle: 'GI, cardiovascular, respiratory, autonomic, urinary.',
      anchors: _ham5,
    ),
    ScaleItem(
      id: 'hamd_12',
      prompt: 'Somatic symptoms (gastrointestinal)',
      anchors: _ham3,
    ),
    ScaleItem(
      id: 'hamd_13',
      prompt: 'Somatic symptoms (general)',
      subtitle: 'Fatigue, heaviness, backache, loss of energy.',
      anchors: _ham3,
    ),
    ScaleItem(
      id: 'hamd_14',
      prompt: 'Genital symptoms',
      subtitle: 'Loss of libido, menstrual disturbance.',
      anchors: _ham3,
    ),
    ScaleItem(
      id: 'hamd_15',
      prompt: 'Hypochondriasis',
      anchors: _ham5,
    ),
    ScaleItem(
      id: 'hamd_16',
      prompt: 'Loss of weight',
      anchors: _ham3,
    ),
    ScaleItem(
      id: 'hamd_17',
      prompt: 'Insight',
      anchors: _ham3,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 7,
      label: 'No depression',
      interpretation: 'Within the non-depressed range.',
      severity: 0,
    ),
    SeverityBand(
      min: 8,
      max: 13,
      label: 'Mild',
      interpretation: 'Mild depression; consider monitoring + '
          'psychotherapy.',
      severity: 1,
    ),
    SeverityBand(
      min: 14,
      max: 18,
      label: 'Moderate',
      interpretation: 'Moderate depression; antidepressant '
          'pharmacotherapy is usually indicated.',
      severity: 2,
    ),
    SeverityBand(
      min: 19,
      max: 22,
      label: 'Severe',
      interpretation: 'Severe depression; full-dose pharmacotherapy + '
          'close follow-up.',
      severity: 3,
    ),
    SeverityBand(
      min: 23,
      max: 52,
      label: 'Very severe',
      interpretation: 'Very severe depression; consider hospital '
          'admission, ECT, or augmentation.',
      severity: 4,
    ),
  ],
);

// ── AIMS ─────────────────────────────────────────────────────────────
//
// Items 1–7 (facial/oral, extremity, trunk movements + severity/
// incapacitation/awareness) score 0–4 and sum to the dyskinesia total
// (max 28).
// Items 8–10 (global judgments) also score 0–4 but are reported
// separately, not added to the dyskinesia total.
// Items 11–12 are yes/no (dental issues / dentures) — recorded as
// context but not scored.

const _aimsAnchors = <String>[
  'None',
  'Minimal — may be extreme normal',
  'Mild',
  'Moderate',
  'Severe',
];

const _aimsGlobalAnchors = <String>[
  'None / normal',
  'Minimal',
  'Mild',
  'Moderate',
  'Severe',
];

const _aimsYesNo = <String>['No', 'Yes'];

const _aims = ClinicalScale(
  id: 'aims',
  name: 'AIMS',
  fullName: 'Abnormal Involuntary Movement Scale',
  tagline: 'Tardive-dyskinesia screen · 12 items',
  citation: 'Guy W. ECDEU Assessment Manual. NIMH 1976.',
  headingPrompt: 'Observe the patient unobtrusively at rest, then '
      'use the AIMS examination procedure. Rate the HIGHEST severity '
      'observed.',
  items: <ScaleItem>[
    ScaleItem(
      id: 'aims_1',
      prompt: 'Muscles of facial expression',
      subtitle: 'Forehead, eyebrows, periorbital, cheeks; frowning, '
          'blinking, grimacing.',
      anchors: _aimsAnchors,
    ),
    ScaleItem(
      id: 'aims_2',
      prompt: 'Lips and perioral area',
      subtitle: 'Puckering, pouting, smacking.',
      anchors: _aimsAnchors,
    ),
    ScaleItem(
      id: 'aims_3',
      prompt: 'Jaw',
      subtitle: 'Biting, clenching, chewing, mouth opening, lateral '
          'movement.',
      anchors: _aimsAnchors,
    ),
    ScaleItem(
      id: 'aims_4',
      prompt: 'Tongue',
      subtitle: 'Rate only increase in movement (not inability to '
          'sustain protrusion).',
      anchors: _aimsAnchors,
    ),
    ScaleItem(
      id: 'aims_5',
      prompt: 'Upper extremity (arms, wrists, hands, fingers)',
      subtitle: 'Choreic, athetoid, rhythmic movements.',
      anchors: _aimsAnchors,
    ),
    ScaleItem(
      id: 'aims_6',
      prompt: 'Lower extremity (legs, knees, ankles, toes)',
      subtitle: 'Lateral knee movement, foot tapping, heel dropping, '
          'inversion / eversion.',
      anchors: _aimsAnchors,
    ),
    ScaleItem(
      id: 'aims_7',
      prompt: 'Neck, shoulders, hips',
      subtitle: 'Rocking, twisting, squirming, pelvic gyrations.',
      anchors: _aimsAnchors,
    ),
    ScaleItem(
      id: 'aims_8',
      prompt: 'Severity of abnormal movements (global)',
      contributesToTotal: false,
      anchors: _aimsGlobalAnchors,
    ),
    ScaleItem(
      id: 'aims_9',
      prompt: 'Incapacitation due to abnormal movements',
      contributesToTotal: false,
      anchors: _aimsGlobalAnchors,
    ),
    ScaleItem(
      id: 'aims_10',
      prompt: "Patient's awareness of abnormal movements",
      contributesToTotal: false,
      anchors: <String>[
        'No awareness',
        'Aware, no distress',
        'Aware, mild distress',
        'Aware, moderate distress',
        'Aware, severe distress',
      ],
    ),
    ScaleItem(
      id: 'aims_11',
      prompt: 'Current problems with teeth and/or dentures?',
      contributesToTotal: false,
      anchors: _aimsYesNo,
    ),
    ScaleItem(
      id: 'aims_12',
      prompt: 'Does patient usually wear dentures?',
      contributesToTotal: false,
      anchors: _aimsYesNo,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 1,
      label: 'No dyskinesia',
      interpretation: 'No clinically significant abnormal '
          'movements detected.',
      severity: 0,
    ),
    SeverityBand(
      min: 2,
      max: 4,
      label: 'Minimal',
      interpretation: 'Borderline findings; rescreen in 3 months.',
      severity: 1,
    ),
    SeverityBand(
      min: 5,
      max: 9,
      label: 'Mild',
      interpretation: 'Mild dyskinesia; consider antipsychotic dose '
          'review and risk-benefit discussion.',
      severity: 2,
    ),
    SeverityBand(
      min: 10,
      max: 17,
      label: 'Moderate',
      interpretation: 'Moderate dyskinesia; review antipsychotic '
          'choice; consider VMAT-2 inhibitor.',
      severity: 3,
    ),
    SeverityBand(
      min: 18,
      max: 28,
      label: 'Severe',
      interpretation: 'Severe dyskinesia; urgent antipsychotic '
          'reassessment + VMAT-2 inhibitor strongly indicated.',
      severity: 4,
    ),
  ],
);

// ── MADRS ────────────────────────────────────────────────────────────
//
// 10 items × 0–6, total 0–60. Clinician-rated; anchors picked at
// even-numbered scores (0/2/4/6) per the original Montgomery/Åsberg
// scoring guide — interpolate odd values per the convention.

const _madrsAnchors = <String>[
  'No abnormality',
  'Minor / fleeting',
  'Mild but clear',
  'Moderate',
  'Pervasive',
  'Severe',
  'Extreme / unbearable',
];

const _madrs = ClinicalScale(
  id: 'madrs',
  name: 'MADRS',
  fullName: 'Montgomery–Åsberg Depression Rating Scale',
  tagline: 'Clinician-rated depression · 10 items · 0–60',
  citation: 'Montgomery SA, Åsberg M. Br J Psychiatry 1979;134:382-9.',
  headingPrompt: 'Rate over the past week. Pick the severity anchor '
      'that best matches the picture.',
  items: <ScaleItem>[
    ScaleItem(
      id: 'madrs_1',
      prompt: 'Apparent sadness',
      subtitle: 'Despondency, gloom, despair beyond ordinary low mood.',
      anchors: _madrsAnchors,
    ),
    ScaleItem(
      id: 'madrs_2',
      prompt: 'Reported sadness',
      subtitle: 'Self-reported low mood.',
      anchors: _madrsAnchors,
    ),
    ScaleItem(
      id: 'madrs_3',
      prompt: 'Inner tension',
      subtitle: 'Indefinable discomfort, edginess, panic.',
      anchors: _madrsAnchors,
    ),
    ScaleItem(
      id: 'madrs_4',
      prompt: 'Reduced sleep',
      anchors: _madrsAnchors,
    ),
    ScaleItem(
      id: 'madrs_5',
      prompt: 'Reduced appetite',
      anchors: _madrsAnchors,
    ),
    ScaleItem(
      id: 'madrs_6',
      prompt: 'Concentration difficulties',
      anchors: _madrsAnchors,
    ),
    ScaleItem(
      id: 'madrs_7',
      prompt: 'Lassitude',
      subtitle: 'Difficulty getting started or sluggishness.',
      anchors: _madrsAnchors,
    ),
    ScaleItem(
      id: 'madrs_8',
      prompt: 'Inability to feel',
      subtitle: 'Reduced interest, emotional flattening.',
      anchors: _madrsAnchors,
    ),
    ScaleItem(
      id: 'madrs_9',
      prompt: 'Pessimistic thoughts',
      subtitle: 'Guilt, self-reproach, ruin.',
      anchors: _madrsAnchors,
    ),
    ScaleItem(
      id: 'madrs_10',
      prompt: 'Suicidal thoughts',
      subtitle: 'Score > 0 warrants explicit safety planning.',
      anchors: _madrsAnchors,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 6,
      label: 'No / minimal',
      interpretation: 'Within the non-depressed range.',
      severity: 0,
    ),
    SeverityBand(
      min: 7,
      max: 19,
      label: 'Mild',
      interpretation: 'Mild depression; consider monitoring + '
          'psychotherapy.',
      severity: 1,
    ),
    SeverityBand(
      min: 20,
      max: 34,
      label: 'Moderate',
      interpretation: 'Moderate depression; antidepressant '
          'pharmacotherapy usually indicated.',
      severity: 2,
    ),
    SeverityBand(
      min: 35,
      max: 60,
      label: 'Severe',
      interpretation: 'Severe depression; full-dose treatment + '
          'consider augmentation / ECT / admission.',
      severity: 4,
    ),
  ],
);

// ── EPDS ─────────────────────────────────────────────────────────────
//
// Edinburgh Postnatal Depression Scale (Cox 1987). Self-rated. 10
// items × 0–3 (items 3, 5, 6, 7, 8, 9, 10 are reverse-scored — but the
// engine receives the already-mapped 0-3 score per item).

const _epdsAnchors = <String>[
  'Not at all / never',
  'Hardly ever / occasionally',
  'Yes, quite often',
  'Yes, most of the time',
];

const _epds = ClinicalScale(
  id: 'epds',
  name: 'EPDS',
  fullName: 'Edinburgh Postnatal Depression Scale',
  tagline: 'Perinatal depression screen · 10 items · 0–30',
  citation: 'Cox JL, Holden JM, Sagovsky R. Br J Psychiatry 1987;150:782-6.',
  headingPrompt: 'Over the past 7 days, the mother has felt:',
  items: <ScaleItem>[
    ScaleItem(
      id: 'epds_1',
      prompt: 'Able to laugh and see the funny side of things '
          '(reverse-scored)',
      anchors: _epdsAnchors,
    ),
    ScaleItem(
      id: 'epds_2',
      prompt: 'Looked forward with enjoyment to things '
          '(reverse-scored)',
      anchors: _epdsAnchors,
    ),
    ScaleItem(
      id: 'epds_3',
      prompt: 'Blamed myself unnecessarily when things went wrong',
      anchors: _epdsAnchors,
    ),
    ScaleItem(
      id: 'epds_4',
      prompt: 'Been anxious or worried for no good reason',
      anchors: _epdsAnchors,
    ),
    ScaleItem(
      id: 'epds_5',
      prompt: 'Felt scared or panicky for no very good reason',
      anchors: _epdsAnchors,
    ),
    ScaleItem(
      id: 'epds_6',
      prompt: 'Things have been getting on top of me',
      anchors: _epdsAnchors,
    ),
    ScaleItem(
      id: 'epds_7',
      prompt: 'Been so unhappy that I have had difficulty sleeping',
      anchors: _epdsAnchors,
    ),
    ScaleItem(
      id: 'epds_8',
      prompt: 'Felt sad or miserable',
      anchors: _epdsAnchors,
    ),
    ScaleItem(
      id: 'epds_9',
      prompt: 'Been so unhappy I have been crying',
      anchors: _epdsAnchors,
    ),
    ScaleItem(
      id: 'epds_10',
      prompt: 'Thought of harming myself has occurred to me',
      subtitle: 'Any positive answer warrants same-day safety review.',
      anchors: _epdsAnchors,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 8,
      label: 'Low likelihood',
      interpretation: 'Low likelihood of perinatal depression.',
      severity: 0,
    ),
    SeverityBand(
      min: 9,
      max: 12,
      label: 'Possible',
      interpretation: 'Possible depression; rescreen at 2-4 weeks + '
          'enhanced support.',
      severity: 1,
    ),
    SeverityBand(
      min: 13,
      max: 30,
      label: 'Probable',
      interpretation: 'Probable depression; assess clinically, '
          'consider treatment (psychotherapy / antidepressant).',
      severity: 3,
    ),
  ],
);

// ── AUDIT ────────────────────────────────────────────────────────────
//
// Alcohol Use Disorders Identification Test (Saunders 1993, WHO).
// 10 items: items 1-8 score 0-4, items 9-10 score 0/2/4. Total 0-40.

const _auditFrequency = <String>[
  'Never',
  'Monthly or less',
  '2–4 times a month',
  '2–3 times a week',
  '4+ times a week',
];

const _auditDrinks = <String>[
  '1 or 2',
  '3 or 4',
  '5 or 6',
  '7 to 9',
  '10 or more',
];

const _auditOccurrence = <String>[
  'Never',
  'Less than monthly',
  'Monthly',
  'Weekly',
  'Daily or almost daily',
];

const _auditYesNoLifetime = <String>[
  'No',
  '',
  'Yes, but not in the last year',
  '',
  'Yes, during the last year',
];

const _audit = ClinicalScale(
  id: 'audit',
  name: 'AUDIT',
  fullName: 'Alcohol Use Disorders Identification Test',
  tagline: 'Alcohol-use screening · 10 items · 0–40',
  citation: 'Saunders JB, Aasland OG, Babor TF, et al. Addiction '
      '1993;88:791-804.',
  items: <ScaleItem>[
    ScaleItem(
      id: 'audit_1',
      prompt: 'How often do you have a drink containing alcohol?',
      anchors: _auditFrequency,
    ),
    ScaleItem(
      id: 'audit_2',
      prompt: 'How many drinks containing alcohol do you have on a '
          'typical day when drinking?',
      anchors: _auditDrinks,
    ),
    ScaleItem(
      id: 'audit_3',
      prompt: 'How often do you have six or more drinks on one occasion?',
      anchors: _auditOccurrence,
    ),
    ScaleItem(
      id: 'audit_4',
      prompt: 'How often during the last year have you found that you '
          'were not able to stop drinking once you had started?',
      anchors: _auditOccurrence,
    ),
    ScaleItem(
      id: 'audit_5',
      prompt: 'How often during the last year have you failed to do '
          'what was normally expected of you because of drinking?',
      anchors: _auditOccurrence,
    ),
    ScaleItem(
      id: 'audit_6',
      prompt: 'How often during the last year have you needed a first '
          'drink in the morning to get going after a heavy session?',
      anchors: _auditOccurrence,
    ),
    ScaleItem(
      id: 'audit_7',
      prompt: 'How often during the last year have you had a feeling '
          'of guilt or remorse after drinking?',
      anchors: _auditOccurrence,
    ),
    ScaleItem(
      id: 'audit_8',
      prompt: 'How often during the last year have you been unable to '
          'remember what happened the night before because you had '
          'been drinking?',
      anchors: _auditOccurrence,
    ),
    ScaleItem(
      id: 'audit_9',
      prompt: 'Have you or someone else been injured because of your '
          'drinking?',
      anchors: _auditYesNoLifetime,
    ),
    ScaleItem(
      id: 'audit_10',
      prompt: 'Has a relative, friend, doctor, or other health worker '
          'been concerned about your drinking or suggested you cut down?',
      anchors: _auditYesNoLifetime,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 7,
      label: 'Low risk',
      interpretation: 'Low-risk drinking. Brief education sufficient.',
      severity: 0,
    ),
    SeverityBand(
      min: 8,
      max: 15,
      label: 'Hazardous',
      interpretation: 'Hazardous drinking. Brief intervention indicated.',
      severity: 2,
    ),
    SeverityBand(
      min: 16,
      max: 19,
      label: 'Harmful',
      interpretation: 'Harmful drinking. Brief counselling + monitoring.',
      severity: 3,
    ),
    SeverityBand(
      min: 20,
      max: 40,
      label: 'Possible dependence',
      interpretation: 'Likely alcohol-use disorder; specialist '
          'assessment + management.',
      severity: 4,
    ),
  ],
);

// ── DAST-10 ──────────────────────────────────────────────────────────
//
// Drug Abuse Screening Test (Skinner 1982), 10 yes/no items. Item 3
// is reverse-scored ("Can you stop drugs when you want to?") — engine
// receives the already-mapped 0/1.

const _yesNoAnchors = <String>['No', 'Yes'];

const _dast10 = ClinicalScale(
  id: 'dast10',
  name: 'DAST-10',
  fullName: 'Drug Abuse Screening Test (10-item)',
  tagline: 'Drug-use screening · 10 items · 0–10',
  citation: 'Skinner HA. Addict Behav 1982;7:363-71.',
  headingPrompt: 'In the past 12 months — covers any non-medical use '
      'of prescription drugs and any use of illicit drugs.',
  items: <ScaleItem>[
    ScaleItem(
      id: 'dast_1',
      prompt: 'Have you used drugs other than those required for '
          'medical reasons?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'dast_2',
      prompt: 'Do you abuse more than one drug at a time?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'dast_3',
      prompt: 'Are you unable to stop drugs when you want to? '
          '(reverse-scored)',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'dast_4',
      prompt: 'Have you had blackouts or flashbacks as a result of '
          'drug use?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'dast_5',
      prompt: 'Do you ever feel bad or guilty about your drug use?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'dast_6',
      prompt: 'Does your spouse / parents ever complain about your '
          'involvement with drugs?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'dast_7',
      prompt: 'Have you neglected your family because of your drug use?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'dast_8',
      prompt: 'Have you engaged in illegal activities to obtain drugs?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'dast_9',
      prompt: 'Have you experienced withdrawal symptoms (felt sick) '
          'when you stopped taking drugs?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'dast_10',
      prompt: 'Have you had medical problems as a result of your drug '
          'use (e.g. memory loss, hepatitis, convulsions, bleeding)?',
      anchors: _yesNoAnchors,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 0,
      label: 'No problems',
      interpretation: 'No problems reported.',
      severity: 0,
    ),
    SeverityBand(
      min: 1,
      max: 2,
      label: 'Low level',
      interpretation: 'Low-level problems; monitor + brief advice.',
      severity: 1,
    ),
    SeverityBand(
      min: 3,
      max: 5,
      label: 'Moderate',
      interpretation: 'Moderate level; further investigation + brief '
          'counselling.',
      severity: 2,
    ),
    SeverityBand(
      min: 6,
      max: 8,
      label: 'Substantial',
      interpretation: 'Substantial level; assessment + intensive '
          'intervention.',
      severity: 3,
    ),
    SeverityBand(
      min: 9,
      max: 10,
      label: 'Severe',
      interpretation: 'Severe level; specialist substance-use '
          'treatment.',
      severity: 4,
    ),
  ],
);

// ── HAM-A ────────────────────────────────────────────────────────────
//
// Hamilton Anxiety Rating Scale (Hamilton 1959). 14 items × 0-4,
// total 0-56. Public domain.

const _hamAnchors = <String>[
  'Not present',
  'Mild',
  'Moderate',
  'Severe',
  'Very severe / incapacitating',
];

const _hama = ClinicalScale(
  id: 'hama',
  name: 'HAM-A',
  fullName: 'Hamilton Anxiety Rating Scale',
  tagline: 'Clinician-rated anxiety · 14 items · 0–56',
  citation: 'Hamilton M. Br J Med Psychol 1959;32:50-5.',
  headingPrompt: "Rate the patient's anxiety symptoms over the past week.",
  items: <ScaleItem>[
    ScaleItem(
      id: 'hama_1',
      prompt: 'Anxious mood',
      subtitle: 'Worries, anticipation of the worst, irritability.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_2',
      prompt: 'Tension',
      subtitle: 'Inability to relax, fatigability, startle, restlessness.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_3',
      prompt: 'Fears',
      subtitle: 'Of the dark, of strangers, of being alone, of crowds.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_4',
      prompt: 'Insomnia',
      subtitle: 'Difficulty falling asleep, broken sleep, fatigue on '
          'waking.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_5',
      prompt: 'Intellectual / cognitive',
      subtitle: 'Difficulty concentrating, poor memory.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_6',
      prompt: 'Depressed mood',
      subtitle: 'Loss of interest, anhedonia, depression, diurnal swing.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_7',
      prompt: 'Somatic — muscular',
      subtitle: 'Pains, twitching, stiffness, bruxism, voice.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_8',
      prompt: 'Somatic — sensory',
      subtitle: 'Tinnitus, blurring, hot/cold flushes, prickling.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_9',
      prompt: 'Cardiovascular',
      subtitle: 'Tachycardia, palpitations, chest pain, fainting.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_10',
      prompt: 'Respiratory',
      subtitle: 'Pressure / constriction in chest, choking, '
          'sighing, dyspnoea.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_11',
      prompt: 'Gastrointestinal',
      subtitle: 'Dysphagia, wind, pain, fullness, weight loss.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_12',
      prompt: 'Genitourinary',
      subtitle: 'Urinary frequency, amenorrhoea, impotence, '
          'premature ejaculation.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_13',
      prompt: 'Autonomic',
      subtitle: 'Dry mouth, flushing, pallor, sweating, dizziness.',
      anchors: _hamAnchors,
    ),
    ScaleItem(
      id: 'hama_14',
      prompt: 'Behaviour at interview',
      subtitle: 'Fidgeting, tremor, pacing, swallowing, sweating.',
      anchors: _hamAnchors,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 17,
      label: 'Mild',
      interpretation: 'Mild anxiety; consider monitoring + '
          'psychoeducation.',
      severity: 1,
    ),
    SeverityBand(
      min: 18,
      max: 24,
      label: 'Mild–moderate',
      interpretation: 'Mild to moderate; CBT and/or pharmacotherapy.',
      severity: 2,
    ),
    SeverityBand(
      min: 25,
      max: 30,
      label: 'Moderate–severe',
      interpretation: 'Moderate to severe; active treatment indicated.',
      severity: 3,
    ),
    SeverityBand(
      min: 31,
      max: 56,
      label: 'Severe',
      interpretation: 'Severe anxiety; specialist input + '
          'pharmacotherapy.',
      severity: 4,
    ),
  ],
);

// ── GDS-15 ───────────────────────────────────────────────────────────
//
// Geriatric Depression Scale, 15-item (Yesavage 1986). 15 yes/no
// items. Some are reverse-scored — engine receives the already-mapped
// 0 / 1 score per item.

const _gds15 = ClinicalScale(
  id: 'gds15',
  name: 'GDS-15',
  fullName: 'Geriatric Depression Scale (15-item)',
  tagline: 'Depression screening in older adults · 15 items · 0–15',
  citation: 'Sheikh JI, Yesavage JA. Clin Gerontol 1986;5:165-73.',
  headingPrompt: 'Choose the best answer for how you have felt over '
      'the past week.',
  items: <ScaleItem>[
    ScaleItem(
      id: 'gds_1',
      prompt: 'Are you basically satisfied with your life? '
          '(reverse-scored)',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_2',
      prompt: 'Have you dropped many of your activities and interests?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_3',
      prompt: 'Do you feel that your life is empty?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_4',
      prompt: 'Do you often get bored?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_5',
      prompt: 'Are you in good spirits most of the time? '
          '(reverse-scored)',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_6',
      prompt: 'Are you afraid that something bad is going to '
          'happen to you?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_7',
      prompt: 'Do you feel happy most of the time? (reverse-scored)',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_8',
      prompt: 'Do you often feel helpless?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_9',
      prompt: 'Do you prefer to stay at home, rather than going '
          'out and doing new things?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_10',
      prompt: 'Do you feel you have more problems with memory '
          'than most?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_11',
      prompt: 'Do you think it is wonderful to be alive now? '
          '(reverse-scored)',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_12',
      prompt: 'Do you feel pretty worthless the way you are now?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_13',
      prompt: 'Do you feel full of energy? (reverse-scored)',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_14',
      prompt: 'Do you feel that your situation is hopeless?',
      anchors: _yesNoAnchors,
    ),
    ScaleItem(
      id: 'gds_15',
      prompt: 'Do you think that most people are better off than '
          'you are?',
      anchors: _yesNoAnchors,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 4,
      label: 'Normal',
      interpretation: 'Within normal range.',
      severity: 0,
    ),
    SeverityBand(
      min: 5,
      max: 8,
      label: 'Mild',
      interpretation: 'Mild depression suggested; clinical assessment.',
      severity: 1,
    ),
    SeverityBand(
      min: 9,
      max: 11,
      label: 'Moderate',
      interpretation: 'Moderate depression; intervention indicated.',
      severity: 2,
    ),
    SeverityBand(
      min: 12,
      max: 15,
      label: 'Severe',
      interpretation: 'Severe depression; pharmacotherapy + close '
          'follow-up.',
      severity: 4,
    ),
  ],
);

// ── CIWA-Ar ──────────────────────────────────────────────────────────
//
// Clinical Institute Withdrawal Assessment for Alcohol — revised
// (Sullivan 1989). 10 items: items 1-7 + 9-10 score 0-7 (8 anchors),
// item 8 (orientation) scores 0-4. Total 0-67.

const _ciwa7Anchors = <String>[
  '0 — none',
  '1 — very mild',
  '2 — mild',
  '3',
  '4 — moderate',
  '5',
  '6',
  '7 — severe',
];

const _ciwaOrientationAnchors = <String>[
  '0 — oriented and can do serial additions',
  '1 — cannot do serial additions or uncertain about date',
  '2 — disoriented for date by no more than 2 days',
  '3 — disoriented for date by more than 2 days',
  '4 — disoriented for place and / or person',
];

const _ciwaAr = ClinicalScale(
  id: 'ciwaar',
  name: 'CIWA-Ar',
  fullName: 'Clinical Institute Withdrawal Assessment for Alcohol – Revised',
  tagline: 'Alcohol withdrawal severity · 10 items · 0–67',
  citation: 'Sullivan JT, Sykora K, Schneiderman J, et al. Br J Addict '
      '1989;84:1353-7.',
  headingPrompt: 'Rate observed severity. Re-administer hourly until '
      'CIWA-Ar < 8 for 8 consecutive hours.',
  items: <ScaleItem>[
    ScaleItem(
      id: 'ciwa_1',
      prompt: 'Nausea / vomiting',
      subtitle: '"Do you feel sick to your stomach? Have you vomited?"',
      anchors: _ciwa7Anchors,
    ),
    ScaleItem(
      id: 'ciwa_2',
      prompt: 'Tremor',
      subtitle: 'Arms extended, fingers spread apart.',
      anchors: _ciwa7Anchors,
    ),
    ScaleItem(
      id: 'ciwa_3',
      prompt: 'Paroxysmal sweats',
      anchors: _ciwa7Anchors,
    ),
    ScaleItem(
      id: 'ciwa_4',
      prompt: 'Anxiety',
      subtitle: '"Do you feel nervous?"',
      anchors: _ciwa7Anchors,
    ),
    ScaleItem(
      id: 'ciwa_5',
      prompt: 'Agitation',
      anchors: _ciwa7Anchors,
    ),
    ScaleItem(
      id: 'ciwa_6',
      prompt: 'Tactile disturbances',
      subtitle: '"Itching, pins and needles, burning, numbness?"',
      anchors: _ciwa7Anchors,
    ),
    ScaleItem(
      id: 'ciwa_7',
      prompt: 'Auditory disturbances',
      subtitle: '"Sounds harsh, frightening; hearing things?"',
      anchors: _ciwa7Anchors,
    ),
    ScaleItem(
      id: 'ciwa_8',
      prompt: 'Orientation and clouding of sensorium',
      subtitle: '"What day is this? Where are you? Who am I?"',
      anchors: _ciwaOrientationAnchors,
    ),
    ScaleItem(
      id: 'ciwa_9',
      prompt: 'Visual disturbances',
      subtitle: '"Light too bright? Seeing things you know are not there?"',
      anchors: _ciwa7Anchors,
    ),
    ScaleItem(
      id: 'ciwa_10',
      prompt: 'Headache, fullness in head',
      anchors: _ciwa7Anchors,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 7,
      label: 'Minimal',
      interpretation: 'Minimal / no withdrawal — supportive care, '
          'reassess in 4 hours.',
      severity: 0,
    ),
    SeverityBand(
      min: 8,
      max: 15,
      label: 'Mild',
      interpretation: 'Mild withdrawal — symptom-triggered '
          'benzodiazepine (e.g. diazepam 10 mg PO); reassess hourly.',
      severity: 2,
    ),
    SeverityBand(
      min: 16,
      max: 19,
      label: 'Moderate',
      interpretation: 'Moderate withdrawal — benzodiazepine and '
          'consider thiamine 100 mg IV; reassess hourly.',
      severity: 3,
    ),
    SeverityBand(
      min: 20,
      max: 67,
      label: 'Severe',
      interpretation: 'Severe withdrawal — high risk of delirium '
          'tremens / seizure. IV benzodiazepine loading, monitored '
          'setting, urgent senior review.',
      severity: 4,
    ),
  ],
);

// ── COWS ─────────────────────────────────────────────────────────────
//
// Clinical Opiate Withdrawal Scale (Wesson & Ling 2003). 11 items
// with varying anchors; total 0–48. Cuts: 5–12 mild, 13–24 moderate,
// 25–36 moderately severe, ≥ 36 severe.

const _cowsPulse = <String>[
  '≤ 80 bpm',
  '81–100 bpm',
  '101–120 bpm',
  '> 120 bpm',
];
const _cows0to4 = <String>[
  '0 — none',
  '1 — mild',
  '2 — moderate',
  '3',
  '4 — severe',
];
const _cows0to5 = <String>[
  '0 — none',
  '1',
  '2',
  '3',
  '4',
  '5 — severe',
];
const _cowsGoose = <String>[
  '0 — smooth',
  '1 — piloerection',
  '2 — prominent',
  '3 — severe',
  '4 — extreme',
  '5 — very marked',
];
const _cowsRest = <String>[
  'Sits still',
  'Reports difficulty sitting still, able to do so',
  'Occasional shifting / extraneous movements',
  'Frequent shifting',
  'Extreme restlessness',
  'Unable to sit still for more than a few seconds',
];

const _cows = ClinicalScale(
  id: 'cows',
  name: 'COWS',
  fullName: 'Clinical Opiate Withdrawal Scale',
  tagline: 'Opioid withdrawal severity · 11 items · 0–48',
  citation: 'Wesson DR, Ling W. J Psychoactive Drugs 2003;35:253-9.',
  headingPrompt: 'Score each at the same time-point; total guides '
      'buprenorphine induction (typically ≥ 12 before first dose).',
  items: <ScaleItem>[
    ScaleItem(
      id: 'cows_1',
      prompt: 'Resting pulse rate (bpm)',
      anchors: _cowsPulse,
    ),
    ScaleItem(
      id: 'cows_2',
      prompt: 'Sweating',
      anchors: _cows0to4,
    ),
    ScaleItem(
      id: 'cows_3',
      prompt: 'Restlessness',
      anchors: _cowsRest,
    ),
    ScaleItem(
      id: 'cows_4',
      prompt: 'Pupil size',
      anchors: <String>[
        '0 — pinned / normal',
        '1 — slightly enlarged',
        '2 — moderately enlarged',
        '3',
        '4',
        '5 — so dilated only the rim of iris is visible',
      ],
    ),
    ScaleItem(
      id: 'cows_5',
      prompt: 'Bone or joint aches',
      anchors: _cows0to4,
    ),
    ScaleItem(
      id: 'cows_6',
      prompt: 'Runny nose or tearing',
      anchors: _cows0to4,
    ),
    ScaleItem(
      id: 'cows_7',
      prompt: 'GI upset',
      anchors: _cows0to5,
    ),
    ScaleItem(
      id: 'cows_8',
      prompt: 'Tremor',
      anchors: _cows0to4,
    ),
    ScaleItem(
      id: 'cows_9',
      prompt: 'Yawning',
      anchors: _cows0to4,
    ),
    ScaleItem(
      id: 'cows_10',
      prompt: 'Anxiety or irritability',
      anchors: _cows0to4,
    ),
    ScaleItem(
      id: 'cows_11',
      prompt: 'Gooseflesh skin',
      anchors: _cowsGoose,
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 4,
      label: 'None',
      interpretation: 'No clinically significant withdrawal.',
      severity: 0,
    ),
    SeverityBand(
      min: 5,
      max: 12,
      label: 'Mild',
      interpretation: 'Mild withdrawal — symptomatic management; '
          'monitor.',
      severity: 1,
    ),
    SeverityBand(
      min: 13,
      max: 24,
      label: 'Moderate',
      interpretation: 'Moderate withdrawal — appropriate for '
          'buprenorphine induction (typical first dose 4 mg SL).',
      severity: 2,
    ),
    SeverityBand(
      min: 25,
      max: 36,
      label: 'Moderately severe',
      interpretation: 'Moderately severe withdrawal — buprenorphine '
          'induction; reassess after 1-2 hours.',
      severity: 3,
    ),
    SeverityBand(
      min: 37,
      max: 48,
      label: 'Severe',
      interpretation: 'Severe withdrawal — escalate dosing per '
          'protocol; supportive care.',
      severity: 4,
    ),
  ],
);

// ── CGI ──────────────────────────────────────────────────────────────
//
// Clinical Global Impression — Severity (Guy 1976). Single-item scale,
// 1-7. We represent as a one-item scale with a 7-anchor list; the
// engine handles single-item totals correctly.
//
// Note: native scoring is 1-7 (not 0-6); we shift to 0-6 to match the
// engine's index-based scoring. The interpretation labels match the
// standard 1-7 wording offset by one.

const _cgis = ClinicalScale(
  id: 'cgis',
  name: 'CGI-S',
  fullName: 'Clinical Global Impression — Severity',
  tagline: 'Single-item global severity · 0–6 (CGI 1–7)',
  citation: 'Guy W. ECDEU Assessment Manual. NIMH 1976.',
  items: <ScaleItem>[
    ScaleItem(
      id: 'cgis_1',
      prompt: 'How mentally ill is the patient at this time?',
      subtitle: 'Consider total clinical experience with the disorder.',
      anchors: <String>[
        'Normal · not at all ill',
        'Borderline mentally ill',
        'Mildly ill',
        'Moderately ill',
        'Markedly ill',
        'Severely ill',
        'Among the most extremely ill patients',
      ],
    ),
  ],
  bands: <SeverityBand>[
    SeverityBand(
      min: 0,
      max: 1,
      label: 'Normal–borderline',
      interpretation: 'Within or near normal range.',
      severity: 0,
    ),
    SeverityBand(
      min: 2,
      max: 2,
      label: 'Mild',
      interpretation: 'Mild illness.',
      severity: 1,
    ),
    SeverityBand(
      min: 3,
      max: 3,
      label: 'Moderate',
      interpretation: 'Moderate illness.',
      severity: 2,
    ),
    SeverityBand(
      min: 4,
      max: 4,
      label: 'Marked',
      interpretation: 'Marked illness.',
      severity: 3,
    ),
    SeverityBand(
      min: 5,
      max: 6,
      label: 'Severe',
      interpretation: 'Severe to extremely severe illness.',
      severity: 4,
    ),
  ],
);

// ── Registry ─────────────────────────────────────────────────────────

/// All built-in scales in display order.
const List<ClinicalScale> kClinicalScales = <ClinicalScale>[
  _phq9,
  _gad7,
  _madrs,
  _hamd17,
  _hama,
  _epds,
  _gds15,
  _audit,
  _dast10,
  _ciwaAr,
  _cows,
  _cgis,
  _aims,
];

/// Look up a scale by id. Returns null if unknown.
ClinicalScale? scaleById(String id) {
  for (final s in kClinicalScales) {
    if (s.id == id) return s;
  }
  return null;
}
