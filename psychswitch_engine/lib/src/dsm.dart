// DSM-5-TR Quick Criteria — bedside checkbox aid for the most-common
// psychiatric diagnoses.
//
// THIS IS NOT A DIAGNOSTIC INSTRUMENT. It mirrors the structure of the
// DSM-5-TR criterion sets (Criterion A, B, C…) so a clinician can run
// through the list at the bedside and confirm whether the threshold
// is met for each criterion. The final clinical judgement always rests
// with the assessor.
//
// Content is paraphrased from DSM-5-TR (APA, 2022) for fair-use
// educational summary. Exact criterion wording is owned by the APA;
// this engine surfaces the structure + counts, not verbatim text.
//
// Pattern mirrors `scales.dart`:
//   • `DsmDisorder` holds groups
//   • A `CriterionGroup` has a list of criteria and a rule for how
//     many must be met to satisfy the group (e.g. "at least 5 of 9")
//   • `evaluateDsm(disorder, answers)` returns a [DsmEvaluation] with
//     per-group satisfaction + overall meets/not-met verdict.

/// One yes/no criterion line item.
class DsmCriterion {
  const DsmCriterion({
    required this.id,
    required this.text,
    this.note,
  });

  /// Stable id for the criterion (used as map key for answers).
  final String id;

  /// Paraphrased criterion text.
  final String text;

  /// Optional clarifier rendered as a sub-line.
  final String? note;
}

/// One group of criteria + the threshold rule that decides whether
/// the group is met.
class DsmCriterionGroup {
  const DsmCriterionGroup({
    required this.label,
    required this.requirement,
    required this.criteria,
    this.minimumRequired,
    this.headerNote,
    this.coreItemIds,
    this.coreMinimum,
  });

  /// Eyebrow label (e.g. "Criterion A", "Criterion B", "Duration").
  final String label;

  /// Short human description of the rule
  /// (e.g. "≥ 5 of 9 symptoms for ≥ 2 weeks").
  final String requirement;

  /// Optional narrative shown under the eyebrow before the items.
  final String? headerNote;

  /// The criteria the user ticks off.
  final List<DsmCriterion> criteria;

  /// How many of [criteria] must be ticked. When null, every item is
  /// required (treated as "all of"). When equal to criteria.length,
  /// behaviour is identical to null.
  final int? minimumRequired;

  /// Optional ids that must be present among the ticked items
  /// regardless of total count (e.g. MDD requires one of depressed
  /// mood OR anhedonia). Null when there is no anchor requirement.
  final List<String>? coreItemIds;

  /// How many of [coreItemIds] must be ticked. Defaults to 1 when
  /// [coreItemIds] is non-null.
  final int? coreMinimum;

  /// Resolve the threshold to count of items needed.
  int get _threshold => minimumRequired ?? criteria.length;
  int get _coreThreshold => coreMinimum ?? (coreItemIds == null ? 0 : 1);

  /// Evaluate the group against a set of ticked ids.
  GroupEvaluation evaluate(Set<String> ticked) {
    final hits = criteria.where((c) => ticked.contains(c.id)).length;
    final coreHits = coreItemIds == null
        ? 0
        : coreItemIds!.where(ticked.contains).length;
    final coreOk = coreItemIds == null || coreHits >= _coreThreshold;
    final met = coreOk && hits >= _threshold;
    return GroupEvaluation(
      group: this,
      hits: hits,
      coreHits: coreHits,
      met: met,
    );
  }
}

class GroupEvaluation {
  const GroupEvaluation({
    required this.group,
    required this.hits,
    required this.coreHits,
    required this.met,
  });

  final DsmCriterionGroup group;
  final int hits;
  final int coreHits;
  final bool met;
}

class DsmDisorder {
  const DsmDisorder({
    required this.id,
    required this.code,
    required this.name,
    required this.tagline,
    required this.groups,
    required this.citation,
    this.exclusionNote,
  });

  /// Stable id (e.g. 'mdd', 'gad', 'schizophrenia').
  final String id;

  /// DSM code (e.g. "296.x", or "F33" ICD-equivalent label).
  final String code;

  /// Display name (e.g. "Major Depressive Episode").
  final String name;

  /// One-line tagline shown on the index card.
  final String tagline;

  /// Citation / source notice.
  final String citation;

  /// Ordered criterion groups (A, B, C…). All groups must be met for
  /// the overall verdict to be "met".
  final List<DsmCriterionGroup> groups;

  /// Standard "rule-out" reminder shown at the bottom of the runner.
  final String? exclusionNote;
}

class DsmEvaluation {
  const DsmEvaluation({
    required this.disorder,
    required this.groups,
    required this.metAll,
    required this.totalTicked,
  });

  final DsmDisorder disorder;
  final List<GroupEvaluation> groups;
  final bool metAll;
  final int totalTicked;

  /// Short clipboard-ready summary line.
  /// "Major Depressive Episode: criteria met (5/9 SX, duration ≥ 2 wk)."
  String summary() {
    if (metAll) {
      return '${disorder.name}: criteria appear met. '
          'Confirm clinical judgement, rule-outs, and impairment.';
    }
    final missing = groups.where((g) => !g.met).length;
    return '${disorder.name}: not all criteria met '
        '($missing of ${groups.length} group${groups.length == 1 ? '' : 's'} unmet).';
  }
}

/// Evaluate a disorder against the user's tick-set.
DsmEvaluation evaluateDsm(DsmDisorder disorder, Set<String> ticked) {
  final groups = disorder.groups.map((g) => g.evaluate(ticked)).toList();
  return DsmEvaluation(
    disorder: disorder,
    groups: groups,
    metAll: groups.every((g) => g.met),
    totalTicked: ticked.length,
  );
}

// ── Content ─────────────────────────────────────────────────────────

const _mdd = DsmDisorder(
  id: 'mdd',
  code: 'F32–F33',
  name: 'Major Depressive Episode',
  tagline: '≥ 5 of 9 symptoms · ≥ 2 weeks · functional impairment',
  citation: 'DSM-5-TR (APA 2022), Major Depressive Disorder.',
  exclusionNote: 'Rule out: bereavement-only presentations, bipolar '
      'episode, substance / medical-condition aetiology, psychotic '
      'disorders that better explain the picture.',
  groups: <DsmCriterionGroup>[
    DsmCriterionGroup(
      label: 'Criterion A',
      requirement: '≥ 5 of 9 symptoms — must include depressed mood '
          'OR anhedonia',
      minimumRequired: 5,
      coreItemIds: <String>['mdd_a_mood', 'mdd_a_anhedonia'],
      coreMinimum: 1,
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'mdd_a_mood',
          text: 'Depressed mood most of the day, nearly every day '
              '(self-reported or observed).',
        ),
        DsmCriterion(
          id: 'mdd_a_anhedonia',
          text: 'Markedly diminished interest or pleasure in nearly '
              'all activities.',
        ),
        DsmCriterion(
          id: 'mdd_a_weight',
          text: 'Significant weight change (> 5% in a month) or '
              'persistent appetite change.',
        ),
        DsmCriterion(
          id: 'mdd_a_sleep',
          text: 'Insomnia or hypersomnia nearly every day.',
        ),
        DsmCriterion(
          id: 'mdd_a_psychomotor',
          text: 'Observable psychomotor agitation or retardation.',
        ),
        DsmCriterion(
          id: 'mdd_a_fatigue',
          text: 'Fatigue or loss of energy nearly every day.',
        ),
        DsmCriterion(
          id: 'mdd_a_guilt',
          text: 'Feelings of worthlessness or excessive / inappropriate '
              'guilt.',
        ),
        DsmCriterion(
          id: 'mdd_a_concentration',
          text: 'Diminished ability to think, concentrate, or decide.',
        ),
        DsmCriterion(
          id: 'mdd_a_suicidality',
          text: 'Recurrent thoughts of death, suicidal ideation, or '
              'a suicide attempt / plan.',
          note: 'Trigger same-day safety planning if present.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion B',
      requirement: 'Symptoms cause distress or functional impairment',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'mdd_b_impairment',
          text: 'Clinically significant distress OR impairment in '
              'social / occupational / other key functioning.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion C',
      requirement: 'Not attributable to substance or medical condition',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'mdd_c_substance',
          text: 'Episode is not directly caused by a substance or '
              'general medical condition.',
        ),
      ],
    ),
  ],
);

const _maniaCriterion = DsmDisorder(
  id: 'mania',
  code: 'F31.1',
  name: 'Manic Episode',
  tagline: '≥ 1 week (or any duration if hospitalised) · ≥ 3 of 7 (4 if irritable only)',
  citation: 'DSM-5-TR (APA 2022), Bipolar I Disorder.',
  exclusionNote: 'Rule out substance / medical-condition aetiology, '
      'antidepressant-induced episodes that resolve on discontinuation, '
      'and schizoaffective patterns.',
  groups: <DsmCriterionGroup>[
    DsmCriterionGroup(
      label: 'Criterion A',
      requirement: 'Distinct period of abnormally elevated, expansive, '
          'or irritable mood + ↑ goal-directed activity, ≥ 1 week '
          '(or any duration if hospitalised)',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'mania_a_mood',
          text: 'Distinct period of elevated, expansive, or irritable '
              'mood, present most of the day, nearly every day.',
        ),
        DsmCriterion(
          id: 'mania_a_activity',
          text: 'Persistent increase in goal-directed activity or '
              'energy concurrent with the mood change.',
        ),
        DsmCriterion(
          id: 'mania_a_duration',
          text: 'Duration ≥ 1 week, present most of the day, nearly '
              'every day — or any duration if hospitalisation is '
              'required.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion B',
      requirement: '≥ 3 of 7 symptoms (4 if mood is irritable only) '
          'during the mood period',
      minimumRequired: 3,
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'mania_b_grandiosity',
          text: 'Inflated self-esteem or grandiosity.',
        ),
        DsmCriterion(
          id: 'mania_b_sleep',
          text: 'Decreased need for sleep (e.g. feels rested after 3 hours).',
        ),
        DsmCriterion(
          id: 'mania_b_talkative',
          text: 'More talkative than usual or pressure to keep talking.',
        ),
        DsmCriterion(
          id: 'mania_b_flight',
          text: 'Flight of ideas or subjective experience of racing thoughts.',
        ),
        DsmCriterion(
          id: 'mania_b_distractibility',
          text: 'Distractibility (attention drawn to unimportant stimuli).',
        ),
        DsmCriterion(
          id: 'mania_b_activity',
          text: 'Increased goal-directed activity (social, occupational, '
              'sexual) or psychomotor agitation.',
        ),
        DsmCriterion(
          id: 'mania_b_risk',
          text: 'Excessive involvement in activities with high potential '
              'for painful consequences (spending sprees, sexual '
              'indiscretions, foolish business investments).',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion C',
      requirement: 'Marked impairment / hospitalisation / psychotic features',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'mania_c_impairment',
          text: 'Mood disturbance is severe enough to cause marked '
              'social or occupational impairment, hospitalisation, OR '
              'has psychotic features.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion D',
      requirement: 'Not better explained by substance/medical cause',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'mania_d_substance',
          text: 'Episode is not attributable to substance use or a '
              'medical condition.',
          note: 'A full manic episode that emerges during '
              'antidepressant treatment and persists beyond the '
              'physiological effect is sufficient for Bipolar I.',
        ),
      ],
    ),
  ],
);

const _gad = DsmDisorder(
  id: 'gad',
  code: 'F41.1',
  name: 'Generalized Anxiety Disorder',
  tagline: 'Excessive worry · ≥ 3 of 6 symptoms · ≥ 6 months',
  citation: 'DSM-5-TR (APA 2022), Generalized Anxiety Disorder.',
  exclusionNote: 'Rule out: panic disorder, social anxiety, OCD, PTSD, '
      'separation anxiety, illness anxiety, anorexia, somatic-symptom '
      'disorder, and substance/medical aetiology.',
  groups: <DsmCriterionGroup>[
    DsmCriterionGroup(
      label: 'Criterion A',
      requirement: 'Excessive anxiety / worry, more days than not, '
          'for ≥ 6 months',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'gad_a_worry',
          text: 'Excessive anxiety and worry, occurring more days than '
              'not for at least 6 months, about a number of events / '
              'activities (e.g. work, school).',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion B',
      requirement: 'Difficulty controlling the worry',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'gad_b_control',
          text: 'The individual finds it difficult to control the worry.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion C',
      requirement: '≥ 3 of 6 associated symptoms (≥ 1 in children)',
      minimumRequired: 3,
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'gad_c_restless',
          text: 'Restlessness or feeling keyed up / on edge.',
        ),
        DsmCriterion(
          id: 'gad_c_fatigue',
          text: 'Being easily fatigued.',
        ),
        DsmCriterion(
          id: 'gad_c_concentration',
          text: 'Difficulty concentrating or mind going blank.',
        ),
        DsmCriterion(
          id: 'gad_c_irritability',
          text: 'Irritability.',
        ),
        DsmCriterion(
          id: 'gad_c_muscle',
          text: 'Muscle tension.',
        ),
        DsmCriterion(
          id: 'gad_c_sleep',
          text: 'Sleep disturbance (difficulty falling/staying asleep, '
              'restless / unsatisfying sleep).',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion D',
      requirement: 'Distress / functional impairment',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'gad_d_impairment',
          text: 'Clinically significant distress or impairment in '
              'social / occupational / other functioning.',
        ),
      ],
    ),
  ],
);

const _ptsd = DsmDisorder(
  id: 'ptsd',
  code: 'F43.10',
  name: 'Posttraumatic Stress Disorder',
  tagline: 'Trauma exposure · intrusion · avoidance · cognitions · '
      'arousal · ≥ 1 month',
  citation: 'DSM-5-TR (APA 2022), Posttraumatic Stress Disorder.',
  exclusionNote: 'Rule out acute stress disorder (< 1 month), '
      'adjustment disorder, substance/medical aetiology.',
  groups: <DsmCriterionGroup>[
    DsmCriterionGroup(
      label: 'Criterion A',
      requirement: 'Exposure to actual or threatened death, serious '
          'injury, or sexual violence',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'ptsd_a_exposure',
          text: 'Direct experience, witnessing in person, learning of '
              'a close family member / friend, OR repeated extreme '
              'exposure to aversive details (e.g. first responders).',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion B — Intrusion',
      requirement: '≥ 1 of 5 intrusion symptoms',
      minimumRequired: 1,
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'ptsd_b_memories',
          text: 'Recurrent, involuntary, intrusive distressing memories.',
        ),
        DsmCriterion(
          id: 'ptsd_b_dreams',
          text: 'Recurrent distressing dreams related to the event.',
        ),
        DsmCriterion(
          id: 'ptsd_b_flashbacks',
          text: 'Dissociative reactions (flashbacks).',
        ),
        DsmCriterion(
          id: 'ptsd_b_distress',
          text: 'Intense / prolonged psychological distress on exposure '
              'to cues that resemble the event.',
        ),
        DsmCriterion(
          id: 'ptsd_b_physiological',
          text: 'Marked physiological reactions to internal or external '
              'cues that symbolise the event.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion C — Avoidance',
      requirement: '≥ 1 of 2 avoidance symptoms',
      minimumRequired: 1,
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'ptsd_c_internal',
          text: 'Avoidance of distressing memories, thoughts, or '
              'feelings about the event.',
        ),
        DsmCriterion(
          id: 'ptsd_c_external',
          text: 'Avoidance of external reminders (people, places, '
              'activities, situations).',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion D — Cognitions & mood',
      requirement: '≥ 2 of 7 negative alterations in cognition / mood',
      minimumRequired: 2,
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'ptsd_d_amnesia',
          text: 'Inability to remember an important aspect of the event.',
        ),
        DsmCriterion(
          id: 'ptsd_d_beliefs',
          text: 'Persistent exaggerated negative beliefs about self, '
              'others, or the world.',
        ),
        DsmCriterion(
          id: 'ptsd_d_blame',
          text: 'Persistent distorted cognitions about cause / '
              'consequences leading to self-blame or other-blame.',
        ),
        DsmCriterion(
          id: 'ptsd_d_emotion',
          text: 'Persistent negative emotional state (fear, horror, '
              'anger, guilt, shame).',
        ),
        DsmCriterion(
          id: 'ptsd_d_interest',
          text: 'Markedly diminished interest / participation in '
              'significant activities.',
        ),
        DsmCriterion(
          id: 'ptsd_d_detachment',
          text: 'Feelings of detachment / estrangement from others.',
        ),
        DsmCriterion(
          id: 'ptsd_d_anhedonia',
          text: 'Persistent inability to experience positive emotions.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion E — Arousal & reactivity',
      requirement: '≥ 2 of 6 alterations in arousal / reactivity',
      minimumRequired: 2,
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'ptsd_e_irritability',
          text: 'Irritable behaviour / angry outbursts.',
        ),
        DsmCriterion(
          id: 'ptsd_e_reckless',
          text: 'Reckless or self-destructive behaviour.',
        ),
        DsmCriterion(
          id: 'ptsd_e_hypervigilance',
          text: 'Hypervigilance.',
        ),
        DsmCriterion(
          id: 'ptsd_e_startle',
          text: 'Exaggerated startle response.',
        ),
        DsmCriterion(
          id: 'ptsd_e_concentration',
          text: 'Problems with concentration.',
        ),
        DsmCriterion(
          id: 'ptsd_e_sleep',
          text: 'Sleep disturbance.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion F & G',
      requirement: 'Duration > 1 month + impairment',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'ptsd_fg_duration',
          text: 'Duration of disturbance > 1 month.',
        ),
        DsmCriterion(
          id: 'ptsd_fg_impairment',
          text: 'Clinically significant distress or functional impairment.',
        ),
      ],
    ),
  ],
);

const _schizophrenia = DsmDisorder(
  id: 'schizophrenia',
  code: 'F20',
  name: 'Schizophrenia',
  tagline: '≥ 2 of 5 active symptoms · ≥ 1 month active · ≥ 6 months total',
  citation: 'DSM-5-TR (APA 2022), Schizophrenia.',
  exclusionNote: 'Rule out schizoaffective / mood disorder with '
      'psychotic features, substance / medical aetiology, autism '
      'spectrum disorder.',
  groups: <DsmCriterionGroup>[
    DsmCriterionGroup(
      label: 'Criterion A',
      requirement: '≥ 2 of 5 — at least one must be #1, #2, or #3',
      minimumRequired: 2,
      coreItemIds: <String>[
        'sch_a_delusions',
        'sch_a_hallucinations',
        'sch_a_speech',
      ],
      coreMinimum: 1,
      criteria: <DsmCriterion>[
        DsmCriterion(id: 'sch_a_delusions', text: 'Delusions.'),
        DsmCriterion(id: 'sch_a_hallucinations', text: 'Hallucinations.'),
        DsmCriterion(
          id: 'sch_a_speech',
          text: 'Disorganised speech (e.g. frequent derailment or '
              'incoherence).',
        ),
        DsmCriterion(
          id: 'sch_a_behaviour',
          text: 'Grossly disorganised or catatonic behaviour.',
        ),
        DsmCriterion(
          id: 'sch_a_negative',
          text: 'Negative symptoms (e.g. diminished emotional '
              'expression, avolition).',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion B',
      requirement: 'Functional decline in major area(s)',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'sch_b_function',
          text: 'For a significant time since onset, level of '
              'functioning in work / interpersonal relations / self-'
              'care is markedly below the level achieved prior.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion C',
      requirement: 'Continuous signs ≥ 6 months (≥ 1 month active)',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'sch_c_duration',
          text: 'Continuous signs of disturbance persist for at least '
              '6 months — including at least 1 month of Criterion-A '
              'symptoms (active phase).',
        ),
      ],
    ),
  ],
);

const _ocd = DsmDisorder(
  id: 'ocd',
  code: 'F42',
  name: 'Obsessive–Compulsive Disorder',
  tagline: 'Obsessions and/or compulsions · time-consuming or impairing',
  citation: 'DSM-5-TR (APA 2022), Obsessive–Compulsive Disorder.',
  exclusionNote: 'Rule out: hoarding disorder, body dysmorphic '
      'disorder, autism-spectrum repetitive behaviours, tic disorder, '
      'GAD, substance/medical aetiology.',
  groups: <DsmCriterionGroup>[
    DsmCriterionGroup(
      label: 'Criterion A',
      requirement: 'Presence of obsessions, compulsions, or both',
      minimumRequired: 1,
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'ocd_a_obsessions',
          text: 'Obsessions — recurrent intrusive thoughts / urges / '
              'images that cause anxiety; individual attempts to '
              'suppress or neutralise them.',
        ),
        DsmCriterion(
          id: 'ocd_a_compulsions',
          text: 'Compulsions — repetitive behaviours or mental acts '
              'the person feels driven to perform in response to an '
              'obsession or according to rigid rules.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion B',
      requirement: 'Time-consuming (> 1 hr/day) OR impairment',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'ocd_b_burden',
          text: 'Obsessions / compulsions are time-consuming (e.g. take '
              'more than 1 hour per day) OR cause clinically significant '
              'distress / impairment.',
        ),
      ],
    ),
  ],
);

const _adhd = DsmDisorder(
  id: 'adhd',
  code: 'F90',
  name: 'Attention-Deficit/Hyperactivity Disorder (adult)',
  tagline: '≥ 5 of 9 inattentive AND/OR ≥ 5 of 9 hyperactive-impulsive · '
      '≥ 6 months · onset < 12 y',
  citation: 'DSM-5-TR (APA 2022), Attention-Deficit/Hyperactivity Disorder.',
  exclusionNote: 'Rule out: mood / anxiety / psychotic disorders, '
      'substance use, sleep disorder, intellectual disability.',
  groups: <DsmCriterionGroup>[
    DsmCriterionGroup(
      label: 'Criterion A1 — Inattention',
      requirement: 'Adults: ≥ 5 of 9 for ≥ 6 months (≥ 6 of 9 in '
          'children ≤ 16)',
      minimumRequired: 5,
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'adhd_a1_details',
          text: 'Fails to give close attention to details / makes '
              'careless mistakes.',
        ),
        DsmCriterion(
          id: 'adhd_a1_sustained',
          text: 'Difficulty sustaining attention in tasks or play.',
        ),
        DsmCriterion(
          id: 'adhd_a1_listening',
          text: 'Often does not seem to listen when spoken to directly.',
        ),
        DsmCriterion(
          id: 'adhd_a1_followthrough',
          text: 'Fails to follow through on instructions / finish '
              'school / work / chores.',
        ),
        DsmCriterion(
          id: 'adhd_a1_organising',
          text: 'Difficulty organising tasks and activities.',
        ),
        DsmCriterion(
          id: 'adhd_a1_avoidance',
          text: 'Avoids / dislikes tasks requiring sustained mental '
              'effort.',
        ),
        DsmCriterion(
          id: 'adhd_a1_losing',
          text: 'Loses things necessary for tasks (keys, wallet, '
              'phone, glasses).',
        ),
        DsmCriterion(
          id: 'adhd_a1_distractible',
          text: 'Easily distracted by extraneous stimuli.',
        ),
        DsmCriterion(
          id: 'adhd_a1_forgetful',
          text: 'Forgetful in daily activities.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion A2 — Hyperactivity / impulsivity',
      requirement: 'Adults: ≥ 5 of 9 for ≥ 6 months',
      minimumRequired: 5,
      criteria: <DsmCriterion>[
        DsmCriterion(id: 'adhd_a2_fidget', text: 'Fidgets or squirms.'),
        DsmCriterion(
          id: 'adhd_a2_leaves',
          text: 'Leaves seat in situations where remaining seated is '
              'expected.',
        ),
        DsmCriterion(
          id: 'adhd_a2_runs',
          text: 'Runs / climbs in inappropriate situations (adults: '
              'feels restless).',
        ),
        DsmCriterion(
          id: 'adhd_a2_quietly',
          text: 'Unable to engage in leisure activities quietly.',
        ),
        DsmCriterion(
          id: 'adhd_a2_on',
          text: 'Often "on the go" or acting as if "driven by a motor".',
        ),
        DsmCriterion(
          id: 'adhd_a2_talks',
          text: 'Talks excessively.',
        ),
        DsmCriterion(
          id: 'adhd_a2_blurts',
          text: 'Blurts out answers before a question is completed.',
        ),
        DsmCriterion(
          id: 'adhd_a2_waiting',
          text: 'Difficulty waiting their turn.',
        ),
        DsmCriterion(
          id: 'adhd_a2_interrupts',
          text: 'Interrupts or intrudes on others.',
        ),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criteria B–E',
      requirement: 'Onset < 12 y · ≥ 2 settings · functional '
          'impairment · not explained by another disorder',
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'adhd_b_onset',
          text: 'Several symptoms present before age 12.',
        ),
        DsmCriterion(
          id: 'adhd_c_settings',
          text: 'Several symptoms present in ≥ 2 settings (home, '
              'work, school, social).',
        ),
        DsmCriterion(
          id: 'adhd_d_impairment',
          text: 'Clear evidence symptoms interfere with social, '
              'academic, or occupational functioning.',
        ),
        DsmCriterion(
          id: 'adhd_e_exclusion',
          text: 'Symptoms not exclusively during another mental '
              'disorder and not better explained by it.',
        ),
      ],
    ),
  ],
);

const _panic = DsmDisorder(
  id: 'panic',
  code: 'F41.0',
  name: 'Panic Disorder',
  tagline: 'Recurrent unexpected panic attacks · ≥ 1 month of worry / '
      'avoidance',
  citation: 'DSM-5-TR (APA 2022), Panic Disorder.',
  exclusionNote: 'Rule out: panic attacks attributable to other mental '
      'disorders (social anxiety, OCD, PTSD), substance / medical '
      'condition.',
  groups: <DsmCriterionGroup>[
    DsmCriterionGroup(
      label: 'Criterion A',
      requirement: 'Recurrent unexpected panic attacks (≥ 4 of 13 '
          'symptoms peak within minutes)',
      minimumRequired: 4,
      headerNote: 'Tick the symptoms typically present during the '
          'patient\'s attacks.',
      criteria: <DsmCriterion>[
        DsmCriterion(id: 'panic_a_palpitations', text: 'Palpitations / pounding heart / accelerated heart rate.'),
        DsmCriterion(id: 'panic_a_sweating', text: 'Sweating.'),
        DsmCriterion(id: 'panic_a_trembling', text: 'Trembling or shaking.'),
        DsmCriterion(id: 'panic_a_breath', text: 'Sensation of shortness of breath or smothering.'),
        DsmCriterion(id: 'panic_a_choking', text: 'Feelings of choking.'),
        DsmCriterion(id: 'panic_a_chest', text: 'Chest pain or discomfort.'),
        DsmCriterion(id: 'panic_a_nausea', text: 'Nausea or abdominal distress.'),
        DsmCriterion(id: 'panic_a_dizzy', text: 'Feeling dizzy, unsteady, light-headed, or faint.'),
        DsmCriterion(id: 'panic_a_chills', text: 'Chills or heat sensations.'),
        DsmCriterion(id: 'panic_a_paresthesia', text: 'Paraesthesias (numbness / tingling).'),
        DsmCriterion(id: 'panic_a_derealisation', text: 'Derealisation or depersonalisation.'),
        DsmCriterion(id: 'panic_a_control', text: 'Fear of losing control or "going crazy".'),
        DsmCriterion(id: 'panic_a_death', text: 'Fear of dying.'),
      ],
    ),
    DsmCriterionGroup(
      label: 'Criterion B',
      requirement: '≥ 1 month of worry or behavioural change after '
          '≥ 1 attack',
      minimumRequired: 1,
      criteria: <DsmCriterion>[
        DsmCriterion(
          id: 'panic_b_worry',
          text: 'Persistent concern / worry about additional attacks '
              'or their consequences (≥ 1 month).',
        ),
        DsmCriterion(
          id: 'panic_b_avoidance',
          text: 'Significant maladaptive change in behaviour related '
              'to the attacks (e.g. avoidance of exercise / unfamiliar '
              'situations).',
        ),
      ],
    ),
  ],
);

const _aud = DsmDisorder(
  id: 'aud',
  code: 'F10.1–.2',
  name: 'Alcohol Use Disorder',
  tagline: '≥ 2 of 11 criteria · within a 12-month period',
  citation: 'DSM-5-TR (APA 2022), Alcohol Use Disorder.',
  exclusionNote: 'Severity: 2-3 = mild, 4-5 = moderate, ≥ 6 = severe.',
  groups: <DsmCriterionGroup>[
    DsmCriterionGroup(
      label: 'Criterion A',
      requirement: '≥ 2 of 11 within a 12-month period',
      minimumRequired: 2,
      criteria: <DsmCriterion>[
        DsmCriterion(id: 'aud_larger', text: 'Alcohol taken in larger amounts / over longer periods than intended.'),
        DsmCriterion(id: 'aud_cutdown', text: 'Persistent desire / unsuccessful efforts to cut down.'),
        DsmCriterion(id: 'aud_time', text: 'Great deal of time spent obtaining, using, or recovering.'),
        DsmCriterion(id: 'aud_craving', text: 'Craving / strong desire to drink.'),
        DsmCriterion(id: 'aud_obligations', text: 'Use interferes with major role obligations (work, school, home).'),
        DsmCriterion(id: 'aud_social', text: 'Continued use despite recurrent social / interpersonal problems.'),
        DsmCriterion(id: 'aud_giveup', text: 'Giving up / reducing important activities because of use.'),
        DsmCriterion(id: 'aud_hazardous', text: 'Recurrent use in hazardous situations (e.g. driving).'),
        DsmCriterion(id: 'aud_physical', text: 'Continued use despite physical / psychological problems caused / exacerbated by alcohol.'),
        DsmCriterion(id: 'aud_tolerance', text: 'Tolerance (need for ↑ amounts or diminished effect).'),
        DsmCriterion(id: 'aud_withdrawal', text: 'Withdrawal syndrome OR use to relieve / avoid withdrawal.'),
      ],
    ),
  ],
);

/// All built-in disorders in display order.
const List<DsmDisorder> kDsmDisorders = <DsmDisorder>[
  _mdd,
  _maniaCriterion,
  _gad,
  _panic,
  _ocd,
  _ptsd,
  _schizophrenia,
  _adhd,
  _aud,
];

/// Look up a disorder by id.
DsmDisorder? dsmById(String id) {
  for (final d in kDsmDisorders) {
    if (d.id == id) return d;
  }
  return null;
}
