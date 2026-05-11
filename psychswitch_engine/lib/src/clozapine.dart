// Clozapine module — initiation, monitoring and safety logic.
//
// Clozapine is the highest-stakes oral antipsychotic in the registry. It
// gets its own engine module rather than living under switching-rules
// because it is fundamentally not a switch — it is an INITIATION protocol
// with mandatory lifelong haematological monitoring and a discrete set of
// safety considerations (agranulocytosis, myocarditis, ileus, smoking-
// cessation CYP1A2 effect).
//
// Per Maudsley 15th edition (Schizophrenia chapter, p.214–218): titration
// targets and schedules are split by sex × smoking status, not by inpatient
// vs community setting. Four variants:
//   - Female non-smoker: target 225 mg/day
//   - Female smoker:     target 300 mg/day
//   - Male non-smoker:   target 250 mg/day
//   - Male smoker:       target 375 mg/day
//
// Dart port of engine/clozapine.ts. Caller supplies the four titration
// protocols + monitoring/safety/rechallenge/community payloads (loaded
// from `/content/clozapine/` in production).

import 'package:psychswitch_engine/patient_context_pure.dart' show Sex;

// ── Titration ─────────────────────────────────────────────────────────

/// Which published titration schedule to render.
///
/// The four built-in `Maudsley15` protocols (sex × smoker) are the
/// current default — slower, CYP1A2-aware (Spina & de Leon 2018,
/// Kennedy 2019). Older clinicians often want the 14th-edition
/// schedule for comparison or for sites still using it, and many
/// services run a slower COMMUNITY titration when an admission isn't
/// feasible. This enum gates the picker.
///
/// Wire format mirrors the engine pattern (kebab/snake-case strings).
enum TitrationRegimen {
  maudsley15('maudsley15'),
  maudsley14('maudsley14'),
  community('community');

  const TitrationRegimen(this.jsonValue);

  final String jsonValue;

  static TitrationRegimen fromJson(String value) {
    for (final r in TitrationRegimen.values) {
      if (r.jsonValue == value) return r;
    }
    throw ArgumentError.value(value, 'value', 'unknown TitrationRegimen');
  }
}

/// Plain-English summary of each regimen — surfaced in the picker's
/// reasoning card so the clinician can choose deliberately rather
/// than copying the default.
class RegimenSummary {
  const RegimenSummary({
    required this.label,
    required this.subtitle,
    required this.reasoning,
    required this.citations,
  });

  final String label;
  final String subtitle;
  final String reasoning;
  final List<String> citations;
}

const Map<TitrationRegimen, RegimenSummary> regimenSummaries =
    <TitrationRegimen, RegimenSummary>{
  TitrationRegimen.maudsley15: RegimenSummary(
    label: 'Maudsley 15',
    subtitle: 'CYP1A2-aware · sex × smoker targets',
    reasoning:
        'Maudsley Prescribing Guidelines 15th edition, Schizophrenia '
        'chapter (p. 214–218). Slower start (6.25 mg test dose), '
        'maintenance target personalised to CYP1A2 activity: '
        '225 mg (female non-smoker) → 375 mg (male smoker). Default '
        'in NHS / CPMS-aligned services because four-variant targeting '
        'reduces both under-dosing in fast metabolisers and toxicity in '
        'slow metabolisers. The "test-dose" Day-1 (6.25 mg) is intended '
        'to catch hypersensitivity reactions early.',
    citations: <String>[
      'maudsley15_schizophrenia_p214_clozapine_dosing',
      'maudsley15_schizophrenia_p217_clozapine_titration',
      'spina_deleon_2018_clozapine_cyp1a2',
    ],
  ),
  TitrationRegimen.maudsley14: RegimenSummary(
    label: 'Maudsley 14',
    subtitle: 'Historical · uniform target 450 mg',
    reasoning:
        'Maudsley Prescribing Guidelines 14th edition (2018), Schizophrenia '
        'chapter. Faster escalation (12.5 mg Day 1, BD from Day 2), '
        'uniform maintenance target ~450 mg/day before plasma-level '
        'optimisation, no CYP1A2 personalisation. Reaches 300 mg by '
        'Day 14, 450 mg by Day 18. Some services and older trial '
        'protocols still reference this schedule. Useful when '
        'comparing against historical inpatient pathways or when '
        'plasma-level guidance will lead the final dose anyway. '
        'Smokers: levels still drop ~50 % vs non-smokers — confirm '
        'with plasma sample at 6 weeks before settling on a dose. '
        'PENDING_CLINICAL_REVIEW.',
    citations: <String>[
      'maudsley14_schizophrenia_clozapine_titration',
      'bap2020_schizophrenia_clozapine',
    ],
  ),
  TitrationRegimen.community: RegimenSummary(
    label: 'Community',
    subtitle: 'Slower · outpatient-safe over 28 days',
    reasoning:
        'Outpatient / community initiation pathway. Adapted from BAP '
        '2020 Schizophrenia guideline and the TREC (UK) community '
        'clozapine protocol. Half-rate escalation vs Maudsley 15 — '
        'reaches ~250 mg over ~28 days rather than ~20. The slower '
        'curve allows monitoring at thrice-weekly clinic visits (BP '
        'lying/standing, pulse, temperature) rather than continuous '
        'inpatient observation. Use when the patient meets community '
        'initiation criteria: stable accommodation, an informed carer, '
        '< 30-min travel to the clinic, no syncopal history, baseline '
        'ECG within normal limits, and FBC monitoring access. '
        'PENDING_CLINICAL_REVIEW.',
    citations: <String>[
      'bap2020_schizophrenia_community_clozapine',
      'trec_community_clozapine_protocol',
      'nice_cg178_schizophrenia',
    ],
  ),
};

/// Sex variant for a clozapine titration protocol. Mirrors the TS
/// `'female' | 'male'` literal — we reuse the existing [Sex] enum's
/// `male` / `female` members.
typedef TitrationSex = Sex;

/// Combination of sex + smoking status that selects a titration protocol.
/// Modeled as a Dart record so equality is value-based out of the box.
typedef TitrationVariant = ({TitrationSex sex, bool smoker});

/// One day in a clozapine titration schedule.
class TitrationStep {
  const TitrationStep({
    required this.day,
    required this.morningMg,
    required this.eveningMg,
    required this.totalMg,
    this.notes,
  });

  factory TitrationStep.fromJson(Map<String, dynamic> j) {
    return TitrationStep(
      day: j['day'] as int,
      morningMg: (j['morningMg'] as num).toDouble(),
      eveningMg: (j['eveningMg'] as num).toDouble(),
      totalMg: (j['totalMg'] as num).toDouble(),
      notes: j['notes'] as String?,
    );
  }

  final int day;
  final num morningMg;
  final num eveningMg;
  final num totalMg;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'day': day,
        'morningMg': morningMg,
        'eveningMg': eveningMg,
        'totalMg': totalMg,
        if (notes != null) 'notes': notes,
      };
}

/// Full titration protocol for one [TitrationVariant].
class TitrationProtocol {
  const TitrationProtocol({
    required this.id,
    required this.variant,
    required this.targetDoseMg,
    required this.rationale,
    required this.totalDays,
    required this.steps,
    required this.postTitrationGuidance,
    required this.missedDoseRule,
    required this.citations,
    required this.lastReviewedISO,
    required this.reviewedBy,
  });

  factory TitrationProtocol.fromJson(Map<String, dynamic> j) {
    final variantJson = j['variant'] as Map<String, dynamic>;
    return TitrationProtocol(
      id: j['id'] as String,
      variant: (
        sex: variantJson['sex'] == 'male' ? Sex.male : Sex.female,
        smoker: variantJson['smoker'] as bool,
      ),
      targetDoseMg: (j['targetDoseMg'] as num).toDouble(),
      rationale: j['rationale'] as String,
      totalDays: j['totalDays'] as int,
      steps: (j['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(TitrationStep.fromJson)
          .toList(),
      postTitrationGuidance: j['postTitrationGuidance'] as String,
      missedDoseRule: j['missedDoseRule'] as String,
      citations: (j['citations'] as List<dynamic>).cast<String>(),
      lastReviewedISO: j['lastReviewedISO'] as String,
      reviewedBy: j['reviewedBy'] as String,
    );
  }

  final String id;
  final TitrationVariant variant;

  /// Maintenance dose target reached at end of titration (mg/day).
  final num targetDoseMg;

  final String rationale;
  final int totalDays;
  final List<TitrationStep> steps;
  final String postTitrationGuidance;
  final String missedDoseRule;
  final List<String> citations;
  final String lastReviewedISO;
  final String reviewedBy;
}

// ── Monitoring schedule ────────────────────────────────────────────────

class MonitoringPhase {
  const MonitoringPhase({
    required this.phase,
    required this.weekStart,
    required this.weekEnd,
    required this.frequency,
    required this.test,
    required this.notes,
  });

  factory MonitoringPhase.fromJson(Map<String, dynamic> j) {
    return MonitoringPhase(
      phase: j['phase'] as String,
      weekStart: j['weekStart'] as int,
      weekEnd: j['weekEnd'] as int?,
      frequency: j['frequency'] as String,
      test: j['test'] as String,
      notes: j['notes'] as String,
    );
  }

  final String phase;
  final int weekStart;
  final int? weekEnd;
  final String frequency;
  final String test;
  final String notes;
}

class MonitoringMilestone {
  const MonitoringMilestone({
    required this.id,
    required this.timepoint,
    required this.weekFromStart,
    required this.tests,
    required this.criticalNotes,
  });

  factory MonitoringMilestone.fromJson(Map<String, dynamic> j) {
    return MonitoringMilestone(
      id: j['id'] as String,
      timepoint: j['timepoint'] as String,
      weekFromStart: j['weekFromStart'] as int?,
      tests: (j['tests'] as List<dynamic>).cast<String>(),
      criticalNotes: j['criticalNotes'] as String,
    );
  }

  final String id;
  final String timepoint;
  final int? weekFromStart;
  final List<String> tests;
  final String criticalNotes;
}

class FbcAmberRange {
  const FbcAmberRange({required this.low, required this.high});

  final num low;
  final num high;
}

class FbcBenAdjustment {
  const FbcBenAdjustment({
    required this.ancGreenAtOrAbove,
    required this.ancAmberRange,
    required this.ancRedBelow,
    required this.wbcGreenAtOrAbove,
    required this.wbcAmberRange,
    required this.wbcRedBelow,
    required this.notes,
  });

  factory FbcBenAdjustment.fromJson(Map<String, dynamic> j) {
    final ancRange = (j['ancAmberRange'] as List<dynamic>).cast<num>();
    final wbcRange = (j['wbcAmberRange'] as List<dynamic>).cast<num>();
    return FbcBenAdjustment(
      ancGreenAtOrAbove: j['ancGreenAtOrAbove'] as num,
      ancAmberRange: FbcAmberRange(low: ancRange[0], high: ancRange[1]),
      ancRedBelow: j['ancRedBelow'] as num,
      wbcGreenAtOrAbove: j['wbcGreenAtOrAbove'] as num,
      wbcAmberRange: FbcAmberRange(low: wbcRange[0], high: wbcRange[1]),
      wbcRedBelow: j['wbcRedBelow'] as num,
      notes: j['notes'] as String,
    );
  }

  final num ancGreenAtOrAbove;
  final FbcAmberRange ancAmberRange;
  final num ancRedBelow;
  final num wbcGreenAtOrAbove;
  final FbcAmberRange wbcAmberRange;
  final num wbcRedBelow;
  final String notes;
}

class FbcThresholds {
  const FbcThresholds({
    required this.ancGreenAtOrAbove,
    required this.ancAmberRange,
    required this.ancRedBelow,
    required this.wbcGreenAtOrAbove,
    required this.wbcAmberRange,
    required this.wbcRedBelow,
    required this.unit,
    required this.actions,
    required this.benAdjustment,
  });

  factory FbcThresholds.fromJson(Map<String, dynamic> j) {
    final ancRange = (j['ancAmberRange'] as List<dynamic>).cast<num>();
    final wbcRange = (j['wbcAmberRange'] as List<dynamic>).cast<num>();
    final actions = j['actions'] as Map<String, dynamic>;
    return FbcThresholds(
      ancGreenAtOrAbove: j['ancGreenAtOrAbove'] as num,
      ancAmberRange: FbcAmberRange(low: ancRange[0], high: ancRange[1]),
      ancRedBelow: j['ancRedBelow'] as num,
      wbcGreenAtOrAbove: j['wbcGreenAtOrAbove'] as num,
      wbcAmberRange: FbcAmberRange(low: wbcRange[0], high: wbcRange[1]),
      wbcRedBelow: j['wbcRedBelow'] as num,
      unit: j['unit'] as String,
      actions: FbcActions(
        green: actions['green'] as String,
        amber: actions['amber'] as String,
        red: actions['red'] as String,
      ),
      benAdjustment: FbcBenAdjustment.fromJson(
        j['benAdjustment'] as Map<String, dynamic>,
      ),
    );
  }

  final num ancGreenAtOrAbove;
  final FbcAmberRange ancAmberRange;
  final num ancRedBelow;
  final num wbcGreenAtOrAbove;
  final FbcAmberRange wbcAmberRange;
  final num wbcRedBelow;
  final String unit;
  final FbcActions actions;
  final FbcBenAdjustment benAdjustment;
}

class FbcActions {
  const FbcActions({
    required this.green,
    required this.amber,
    required this.red,
  });

  final String green;
  final String amber;
  final String red;
}

class MonitoringScheduleData {
  const MonitoringScheduleData({
    required this.id,
    required this.rationale,
    required this.phases,
    required this.milestones,
    required this.fbcThresholds,
    required this.citations,
    required this.lastReviewedISO,
    required this.reviewedBy,
  });

  factory MonitoringScheduleData.fromJson(Map<String, dynamic> j) {
    return MonitoringScheduleData(
      id: j['id'] as String,
      rationale: j['rationale'] as String,
      phases: (j['phases'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(MonitoringPhase.fromJson)
          .toList(),
      milestones: (j['milestones'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(MonitoringMilestone.fromJson)
          .toList(),
      fbcThresholds: FbcThresholds.fromJson(
        j['fbcThresholds'] as Map<String, dynamic>,
      ),
      citations: (j['citations'] as List<dynamic>).cast<String>(),
      lastReviewedISO: j['lastReviewedISO'] as String,
      reviewedBy: j['reviewedBy'] as String,
    );
  }

  final String id;
  final String rationale;
  final List<MonitoringPhase> phases;
  final List<MonitoringMilestone> milestones;
  final FbcThresholds fbcThresholds;
  final List<String> citations;
  final String lastReviewedISO;
  final String reviewedBy;
}

// ── Safety considerations ──────────────────────────────────────────────

enum SafetySeverityLevel {
  info('info'),
  warning('warning'),
  danger('danger');

  const SafetySeverityLevel(this.jsonValue);

  final String jsonValue;

  static SafetySeverityLevel fromJson(String value) {
    for (final s in SafetySeverityLevel.values) {
      if (s.jsonValue == value) return s;
    }
    throw ArgumentError.value(
      value,
      'value',
      'unknown SafetySeverityLevel',
    );
  }
}

class SafetyConsideration {
  const SafetyConsideration({
    required this.id,
    required this.severity,
    required this.title,
    required this.body,
    required this.monitoring,
  });

  factory SafetyConsideration.fromJson(Map<String, dynamic> j) {
    return SafetyConsideration(
      id: j['id'] as String,
      severity: SafetySeverityLevel.fromJson(j['severity'] as String),
      title: j['title'] as String,
      body: j['body'] as String,
      monitoring: j['monitoring'] as String,
    );
  }

  final String id;
  final SafetySeverityLevel severity;
  final String title;
  final String body;
  final String monitoring;
}

class SafetyConsiderationsData {
  const SafetyConsiderationsData({
    required this.id,
    required this.considerations,
    required this.citations,
    required this.lastReviewedISO,
    required this.reviewedBy,
  });

  factory SafetyConsiderationsData.fromJson(Map<String, dynamic> j) {
    return SafetyConsiderationsData(
      id: j['id'] as String,
      considerations: (j['considerations'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(SafetyConsideration.fromJson)
          .toList(),
      citations: (j['citations'] as List<dynamic>).cast<String>(),
      lastReviewedISO: j['lastReviewedISO'] as String,
      reviewedBy: j['reviewedBy'] as String,
    );
  }

  final String id;
  final List<SafetyConsideration> considerations;
  final List<String> citations;
  final String lastReviewedISO;
  final String reviewedBy;
}

// ── Rechallenge ────────────────────────────────────────────────────────

typedef RechallengeSeverity = SafetySeverityLevel;

class RechallengeTier {
  const RechallengeTier({
    required this.id,
    required this.label,
    required this.maxHours,
    required this.severity,
    required this.heading,
    required this.guidance,
    required this.restartInstruction,
    required this.retitrationRequired,
    required this.monitoringNote,
    required this.warningSignsToWatch,
  });

  factory RechallengeTier.fromJson(Map<String, dynamic> j) {
    return RechallengeTier(
      id: j['id'] as String,
      label: j['label'] as String,
      maxHours: j['maxHours'] as num?,
      severity: SafetySeverityLevel.fromJson(j['severity'] as String),
      heading: j['heading'] as String,
      guidance: j['guidance'] as String,
      restartInstruction: j['restartInstruction'] as String,
      retitrationRequired: j['retitrationRequired'] as bool,
      monitoringNote: j['monitoringNote'] as String,
      warningSignsToWatch:
          (j['warningSignsToWatch'] as List<dynamic>).cast<String>(),
    );
  }

  final String id;
  final String label;
  final num? maxHours;
  final RechallengeSeverity severity;
  final String heading;
  final String guidance;
  final String restartInstruction;
  final bool retitrationRequired;
  final String monitoringNote;
  final List<String> warningSignsToWatch;
}

class RechallengeRulesData {
  const RechallengeRulesData({
    required this.id,
    required this.rationale,
    required this.tiers,
    required this.absoluteContraindications,
    required this.citations,
    required this.lastReviewedISO,
    required this.reviewedBy,
  });

  factory RechallengeRulesData.fromJson(Map<String, dynamic> j) {
    return RechallengeRulesData(
      id: j['id'] as String,
      rationale: j['rationale'] as String,
      tiers: (j['tiers'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(RechallengeTier.fromJson)
          .toList(),
      absoluteContraindications:
          (j['absoluteContraindications'] as List<dynamic>).cast<String>(),
      citations: (j['citations'] as List<dynamic>).cast<String>(),
      lastReviewedISO: j['lastReviewedISO'] as String,
      reviewedBy: j['reviewedBy'] as String,
    );
  }

  final String id;
  final String rationale;
  final List<RechallengeTier> tiers;
  final List<String> absoluteContraindications;
  final List<String> citations;
  final String lastReviewedISO;
  final String reviewedBy;
}

// ── Community initiation ──────────────────────────────────────────────

class CommunityInitiationCriterion {
  const CommunityInitiationCriterion({
    required this.id,
    required this.title,
    required this.detail,
  });

  factory CommunityInitiationCriterion.fromJson(Map<String, dynamic> j) {
    return CommunityInitiationCriterion(
      id: j['id'] as String,
      title: j['title'] as String,
      detail: j['detail'] as String,
    );
  }

  final String id;
  final String title;
  final String detail;
}

class CommunityMonitoringIntensity {
  const CommunityMonitoringIntensity({
    required this.first4Weeks,
    required this.weeks5To18,
    required this.weeks19To52,
    required this.year2Onwards,
  });

  factory CommunityMonitoringIntensity.fromJson(Map<String, dynamic> j) {
    return CommunityMonitoringIntensity(
      first4Weeks: j['first_4_weeks'] as String,
      weeks5To18: j['weeks_5_to_18'] as String,
      weeks19To52: j['weeks_19_to_52'] as String,
      year2Onwards: j['year_2_onwards'] as String,
    );
  }

  final String first4Weeks;
  final String weeks5To18;
  final String weeks19To52;
  final String year2Onwards;
}

class CommunityInitiationData {
  const CommunityInitiationData({
    required this.id,
    required this.rationale,
    required this.relativeContraindications,
    required this.essentialCriteria,
    required this.initialWorkup,
    required this.monitoringIntensity,
    required this.citations,
    required this.lastReviewedISO,
    required this.reviewedBy,
  });

  factory CommunityInitiationData.fromJson(Map<String, dynamic> j) {
    List<CommunityInitiationCriterion> mapList(String key) =>
        (j[key] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(CommunityInitiationCriterion.fromJson)
            .toList();
    return CommunityInitiationData(
      id: j['id'] as String,
      rationale: j['rationale'] as String,
      relativeContraindications: mapList('relativeContraindications'),
      essentialCriteria: mapList('essentialCriteria'),
      initialWorkup: mapList('initialWorkup'),
      monitoringIntensity: CommunityMonitoringIntensity.fromJson(
        j['monitoringIntensity'] as Map<String, dynamic>,
      ),
      citations: (j['citations'] as List<dynamic>).cast<String>(),
      lastReviewedISO: j['lastReviewedISO'] as String,
      reviewedBy: j['reviewedBy'] as String,
    );
  }

  final String id;
  final String rationale;
  final List<CommunityInitiationCriterion> relativeContraindications;
  final List<CommunityInitiationCriterion> essentialCriteria;
  final List<CommunityInitiationCriterion> initialWorkup;
  final CommunityMonitoringIntensity monitoringIntensity;
  final List<String> citations;
  final String lastReviewedISO;
  final String reviewedBy;
}

// ── Module ─────────────────────────────────────────────────────────────

/// Composite payload bundling all the clozapine content the engine needs.
/// The Phase 4 runtime loader builds one of these from the four
/// `/content/clozapine/` JSON files and passes it to [ClozapineModule].
class ClozapineContent {
  const ClozapineContent({
    required this.femaleNonSmoker,
    required this.femaleSmoker,
    required this.maleNonSmoker,
    required this.maleSmoker,
    required this.monitoringSchedule,
    required this.safetyConsiderations,
    required this.rechallengeRules,
    required this.communityInitiation,
  });

  final TitrationProtocol femaleNonSmoker;
  final TitrationProtocol femaleSmoker;
  final TitrationProtocol maleNonSmoker;
  final TitrationProtocol maleSmoker;
  final MonitoringScheduleData monitoringSchedule;
  final SafetyConsiderationsData safetyConsiderations;
  final RechallengeRulesData rechallengeRules;
  final CommunityInitiationData communityInitiation;
}

/// Wraps clozapine content + algorithms.
class ClozapineModule {
  const ClozapineModule(this.content);

  final ClozapineContent content;

  /// Resolve the appropriate titration protocol for [variant]
  /// (defaults to Maudsley 15th edition — the four-variant default).
  TitrationProtocol getTitration(TitrationVariant variant) {
    if (variant.sex == Sex.female && !variant.smoker) {
      return content.femaleNonSmoker;
    }
    if (variant.sex == Sex.female && variant.smoker) {
      return content.femaleSmoker;
    }
    if (variant.sex == Sex.male && !variant.smoker) {
      return content.maleNonSmoker;
    }
    return content.maleSmoker;
  }

  /// Resolve a titration protocol for [regimen] + [variant].
  ///
  /// • `maudsley15` → loaded JSON four-variant protocols (sex × smoker).
  /// • `maudsley14` → inline four-variant protocols; the 14th edition
  ///   used a uniform 450 mg headline target, but real-world plasma-
  ///   level data show the same CYP1A2 personalisation applies
  ///   (Spina 2018) — schedules truncate at sex × smoker-appropriate
  ///   maintenance targets following the historical fast curve.
  /// • `community` → slower outpatient pathway, single uniform
  ///   protocol. Variant is ignored.
  TitrationProtocol getTitrationFor({
    required TitrationRegimen regimen,
    required TitrationVariant variant,
  }) {
    switch (regimen) {
      case TitrationRegimen.maudsley15:
        return getTitration(variant);
      case TitrationRegimen.maudsley14:
        return _maudsley14ForVariant(variant);
      case TitrationRegimen.community:
        return _communityProtocol;
    }
  }

  /// All four titration variants (used by the picker UI).
  List<TitrationProtocol> getAllTitrations() => <TitrationProtocol>[
        content.femaleNonSmoker,
        content.femaleSmoker,
        content.maleNonSmoker,
        content.maleSmoker,
      ];

  MonitoringScheduleData getMonitoringSchedule() => content.monitoringSchedule;

  SafetyConsiderationsData getSafetyConsiderations() =>
      content.safetyConsiderations;

  RechallengeRulesData getRechallengeRules() => content.rechallengeRules;

  CommunityInitiationData getCommunityInitiation() =>
      content.communityInitiation;

  /// Look up the appropriate restart tier for an interruption duration.
  ///
  /// Pass either [hours] OR [days] (they are summed:
  /// `totalHours = hours + days * 24`). Returns the most conservative
  /// tier whose `maxHours >= totalHours`, or the > 5-day danger tier if
  /// the gap exceeds all finite boundaries.
  RechallengeTier classifyInterruption({int days = 0, int hours = 0}) {
    final totalHours = days * 24 + hours;
    final tiers = content.rechallengeRules.tiers;
    for (final t in tiers) {
      final maxH = t.maxHours;
      if (maxH != null && totalHours <= maxH) return t;
    }
    return tiers.last;
  }
}

/// FBC zone result.
enum FbcZone {
  green('green'),
  amber('amber'),
  red('red');

  const FbcZone(this.jsonValue);

  final String jsonValue;
}

/// Result of [classifyFbc].
class FbcClassification {
  const FbcClassification({required this.zone, required this.reason});

  final FbcZone zone;
  final String reason;
}

/// Classify an FBC reading against the CPMS-derived thresholds.
///
/// Pass `applyBen: true` for patients with documented benign ethnic
/// neutropenia — this swaps in the FULL BEN threshold set.
///
/// Either ANC or WBC dropping into a worse zone determines the result
/// (red > amber > green).
FbcClassification classifyFbc({
  required num ancE9PerL,
  required num wbcE9PerL,
  required FbcThresholds thresholds,
  bool applyBen = false,
}) {
  final ancGreen = applyBen
      ? thresholds.benAdjustment.ancGreenAtOrAbove
      : thresholds.ancGreenAtOrAbove;
  final ancRed = applyBen
      ? thresholds.benAdjustment.ancRedBelow
      : thresholds.ancRedBelow;
  final wbcGreen = applyBen
      ? thresholds.benAdjustment.wbcGreenAtOrAbove
      : thresholds.wbcGreenAtOrAbove;
  final wbcRed = applyBen
      ? thresholds.benAdjustment.wbcRedBelow
      : thresholds.wbcRedBelow;

  // Red trumps amber trumps green.
  if (ancE9PerL < ancRed || wbcE9PerL < wbcRed) {
    final benTag = applyBen ? ' (BEN-adjusted)' : '';
    final reason = ancE9PerL < ancRed
        ? 'ANC $ancE9PerL below red threshold $ancRed$benTag'
        : 'WBC $wbcE9PerL below red threshold $wbcRed$benTag';
    return FbcClassification(zone: FbcZone.red, reason: reason);
  }

  final ancAmber = ancE9PerL < ancGreen;
  final wbcAmber = wbcE9PerL < wbcGreen;
  if (ancAmber || wbcAmber) {
    final benTag = applyBen ? ' (BEN-adjusted)' : '';
    final reason = ancAmber
        ? 'ANC $ancE9PerL below green threshold $ancGreen$benTag'
        : 'WBC $wbcE9PerL below green threshold $wbcGreen$benTag';
    return FbcClassification(zone: FbcZone.amber, reason: reason);
  }

  return const FbcClassification(
    zone: FbcZone.green,
    reason: 'Both ANC and WBC in green range.',
  );
}

// ── Hardcoded alternative regimens ─────────────────────────────────────
//
// The Maudsley-15 four-variant protocols are loaded from JSON in
// `/content/clozapine/` (sex × smoking specific). The two alternative
// regimens below — Maudsley 14 (historical, uniform 450 mg target)
// and Community (outpatient slower-curve) — are encoded inline as
// constants for now. They don't carry the sex/smoking split and are
// small enough that inline storage is appropriate; if either becomes
// site-tunable they can be promoted to JSON later without breaking
// the public API.
//
// PENDING_CLINICAL_REVIEW on both. The step list, target dose and
// monitoring touchpoints have been drawn from the cited published
// schedules but should be cross-checked against the original tables
// before clinical release.

/// Pick the appropriate Maudsley-14 protocol for a sex × smoker
/// variant. The escalation curve is shared (faster than M15, BD from
/// Day 2); only the maintenance target and the truncation point on
/// the curve differ — following CYP1A2 induction patterns
/// (Spina & de Leon 2018, Kennedy 2019).
TitrationProtocol _maudsley14ForVariant(TitrationVariant variant) {
  if (variant.sex == Sex.female && !variant.smoker) {
    return _maudsley14FemaleNonSmoker;
  }
  if (variant.sex == Sex.female && variant.smoker) {
    return _maudsley14FemaleSmoker;
  }
  if (variant.sex == Sex.male && !variant.smoker) {
    return _maudsley14MaleNonSmoker;
  }
  return _maudsley14MaleSmoker;
}

/// Maudsley 14th-edition canonical fast curve. Reaches:
///   • 300 mg by Day 13 (female non-smoker target)
///   • 400 mg by Day 16 (female smoker / male non-smoker target)
///   • 450 mg by Day 18 (male smoker — the historical default)
/// Each variant truncates this curve at its target. All Day-by-day
/// steps below the truncation are identical across variants; the
/// notes adjust at the final step.
const List<TitrationStep> _maudsley14SharedCurve = <TitrationStep>[
    TitrationStep(
      day: 1,
      morningMg: 0,
      eveningMg: 12.5,
      totalMg: 12.5,
      notes: 'Test dose 12.5 mg evening. Lying + standing BP at 1, '
          '2, 4 h post-dose. Pulse and temperature 4-hourly.',
    ),
    TitrationStep(
      day: 2,
      morningMg: 12.5,
      eveningMg: 12.5,
      totalMg: 25,
      notes: 'Begin BD. Continue BP / pulse / temp.',
    ),
    TitrationStep(
      day: 3,
      morningMg: 25,
      eveningMg: 25,
      totalMg: 50,
      notes: 'Counsel on hypersalivation, constipation. Start '
          'prophylactic laxative.',
    ),
    TitrationStep(
      day: 4,
      morningMg: 25,
      eveningMg: 50,
      totalMg: 75,
      notes: 'Watch postural drop.',
    ),
    TitrationStep(
      day: 5,
      morningMg: 50,
      eveningMg: 50,
      totalMg: 100,
      notes: 'Hypersalivation typically emerges.',
    ),
    TitrationStep(
      day: 6,
      morningMg: 50,
      eveningMg: 75,
      totalMg: 125,
      notes: 'Daily BP, pulse, temperature.',
    ),
    TitrationStep(
      day: 7,
      morningMg: 75,
      eveningMg: 75,
      totalMg: 150,
      notes: 'Reassess tolerability. Document bowel function.',
    ),
    TitrationStep(
      day: 8,
      morningMg: 75,
      eveningMg: 100,
      totalMg: 175,
      notes: 'Continue.',
    ),
    TitrationStep(
      day: 9,
      morningMg: 100,
      eveningMg: 100,
      totalMg: 200,
      notes: 'Tachycardia commonly persists.',
    ),
    TitrationStep(
      day: 10,
      morningMg: 100,
      eveningMg: 125,
      totalMg: 225,
      notes: 'Continue.',
    ),
    TitrationStep(
      day: 11,
      morningMg: 125,
      eveningMg: 125,
      totalMg: 250,
      notes: 'Halfway through dose escalation.',
    ),
    TitrationStep(
      day: 12,
      morningMg: 125,
      eveningMg: 150,
      totalMg: 275,
      notes: 'Reassess myocarditis warning signs.',
    ),
    TitrationStep(
      day: 13,
      morningMg: 150,
      eveningMg: 150,
      totalMg: 300,
      notes: 'Approaching mid-target.',
    ),
    TitrationStep(
      day: 14,
      morningMg: 150,
      eveningMg: 150,
      totalMg: 300,
      notes: 'Hold at 300 mg. FBC due (week 2).',
    ),
    TitrationStep(
      day: 15,
      morningMg: 150,
      eveningMg: 175,
      totalMg: 325,
      notes: 'Continue escalation toward 450 if no concerns.',
    ),
    TitrationStep(
      day: 16,
      morningMg: 175,
      eveningMg: 200,
      totalMg: 375,
      notes: 'Continue.',
    ),
    TitrationStep(
      day: 17,
      morningMg: 200,
      eveningMg: 200,
      totalMg: 400,
      notes: 'One step from target.',
    ),
    TitrationStep(
      day: 18,
      morningMg: 200,
      eveningMg: 250,
      totalMg: 450,
      notes: 'Target reached. Take plasma level at 6 weeks '
          '(trough). Optimise to 350–600 ng/mL.',
    ),
  ];

const String _maudsley14MissedDose =
    'Doses missed for more than 48 hours mandate retitration. '
    'Use the Interruption Restart Wizard.';

const List<String> _maudsley14Citations = <String>[
  'maudsley14_schizophrenia_clozapine_titration',
  'bap2020_schizophrenia_clozapine',
  'spina_deleon_2018_clozapine_cyp1a2',
];

/// Build one Maudsley-14 variant by truncating the shared curve at a
/// given total-mg target (the variant's maintenance dose).
TitrationProtocol _buildMaudsley14Variant({
  required String id,
  required TitrationVariant variant,
  required num targetDoseMg,
  required String variantLabel,
  required String postTitrationGuidance,
}) {
  // Find the last step whose total reaches `targetDoseMg`. Variants
  // truncate the curve there.
  var endIdx = _maudsley14SharedCurve.length - 1;
  for (var i = 0; i < _maudsley14SharedCurve.length; i++) {
    if (_maudsley14SharedCurve[i].totalMg >= targetDoseMg) {
      endIdx = i;
      break;
    }
  }
  final steps = _maudsley14SharedCurve.sublist(0, endIdx + 1);
  // Replace the final step's notes with the variant-specific finish.
  final last = steps.last;
  final finalStep = TitrationStep(
    day: last.day,
    morningMg: last.morningMg,
    eveningMg: last.eveningMg,
    totalMg: last.totalMg,
    notes:
        'Maintenance target ${targetDoseMg.toInt()} mg/day reached '
        '($variantLabel). Plasma level at 6 weeks (trough), optimise '
        'to 350–600 ng/mL.',
  );
  final shapedSteps = <TitrationStep>[
    ...steps.take(steps.length - 1),
    finalStep,
  ];
  return TitrationProtocol(
    id: id,
    variant: variant,
    targetDoseMg: targetDoseMg,
    rationale:
        'Maudsley 14th edition canonical fast curve (12.5 mg test '
        'dose, BD from Day 2). Maintenance target individualised to '
        '$variantLabel by CYP1A2 activity (Spina & de Leon 2018) — '
        'the 14th edition itself headlined a uniform 450 mg pre-'
        'plasma-level target but real-world plasma data follow the '
        'same sex × smoking gradient as Maudsley 15. Plasma level '
        'at 6 weeks remains the final arbiter. PENDING_CLINICAL_REVIEW.',
    totalDays: shapedSteps.last.day,
    steps: shapedSteps,
    postTitrationGuidance: postTitrationGuidance,
    missedDoseRule: _maudsley14MissedDose,
    citations: _maudsley14Citations,
    lastReviewedISO: '2026-05-11',
    reviewedBy: 'PENDING - Rashid Razak (clinical author)',
  );
}

final TitrationProtocol _maudsley14FemaleNonSmoker = _buildMaudsley14Variant(
  id: 'clozapine-titration-maudsley14-female-non-smoker',
  variant: (sex: Sex.female, smoker: false),
  targetDoseMg: 300,
  variantLabel: 'female non-smoker',
  postTitrationGuidance:
      'Hold at 300 mg/day pending plasma-level optimisation '
      '(target 350–600 ng/mL trough). Lowest CYP1A2 activity of '
      'the four variants — watch for early plasma-level overshoot '
      'and lower the dose if levels exceed 600 ng/mL.',
);

final TitrationProtocol _maudsley14FemaleSmoker = _buildMaudsley14Variant(
  id: 'clozapine-titration-maudsley14-female-smoker',
  variant: (sex: Sex.female, smoker: true),
  targetDoseMg: 400,
  variantLabel: 'female smoker',
  postTitrationGuidance:
      'Hold at 400 mg/day pending plasma-level optimisation '
      '(target 350–600 ng/mL). CRITICAL — smoking cessation post-'
      'titration: plasma levels can rise by up to 2× within 4 weeks. '
      'Recheck and reduce dose accordingly.',
);

final TitrationProtocol _maudsley14MaleNonSmoker = _buildMaudsley14Variant(
  id: 'clozapine-titration-maudsley14-male-non-smoker',
  variant: (sex: Sex.male, smoker: false),
  targetDoseMg: 400,
  variantLabel: 'male non-smoker',
  postTitrationGuidance:
      'Hold at 400 mg/day pending plasma-level optimisation '
      '(target 350–600 ng/mL trough). Moderate CYP1A2 activity — '
      'plasma sample at 6 weeks before further dose changes.',
);

final TitrationProtocol _maudsley14MaleSmoker = _buildMaudsley14Variant(
  id: 'clozapine-titration-maudsley14-male-smoker',
  variant: (sex: Sex.male, smoker: true),
  targetDoseMg: 450,
  variantLabel: 'male smoker — historical 14th-edition default',
  postTitrationGuidance:
      'Hold at 450 mg/day pending plasma-level optimisation '
      '(target 350–600 ng/mL trough). Highest CYP1A2 activity; the '
      '14th-edition canonical case. CRITICAL — if smoking ceases '
      'later, plasma levels can rise by up to 2× within 4 weeks, '
      'recheck and reduce dose accordingly.',
);

/// Community (outpatient) titration — slower 28-day curve adapted from
/// BAP 2020 + TREC community clozapine protocol. Single uniform
/// schedule; sex/smoking-specific final dose is set later via plasma
/// level.
final TitrationProtocol _communityProtocol = TitrationProtocol(
  id: 'clozapine-titration-community',
  variant: (sex: Sex.male, smoker: false),
  targetDoseMg: 250,
  rationale:
      'Community / outpatient initiation pathway. Adapted from BAP '
      '2020 Schizophrenia guideline and the TREC community clozapine '
      'protocol. Half-rate escalation vs Maudsley 15 — reaches '
      '~250 mg/day over ~28 days. Designed so each dose step '
      'aligns with a thrice-weekly clinic visit (Mon/Wed/Fri or '
      'equivalent) where BP lying/standing, pulse, temperature and '
      'symptom check are performed. Final target individualised by '
      'plasma level after 6 weeks at maintenance. PENDING_CLINICAL_REVIEW.',
  totalDays: 28,
  steps: const <TitrationStep>[
    TitrationStep(
      day: 1,
      morningMg: 0,
      eveningMg: 12.5,
      totalMg: 12.5,
      notes:
          'Test dose 12.5 mg at clinic. Observe 4 h post-dose: BP '
          'lying + standing at 1, 2, 4 h; pulse; temperature. '
          'Discharge home with carer + emergency contact card.',
    ),
    TitrationStep(
      day: 2,
      morningMg: 0,
      eveningMg: 12.5,
      totalMg: 12.5,
      notes: 'Carer monitors BP at home (cuff supplied). Call clinic '
          'if symptomatic postural drop.',
    ),
    TitrationStep(
      day: 3,
      morningMg: 12.5,
      eveningMg: 12.5,
      totalMg: 25,
      notes: 'Clinic visit (Day 3). BP / pulse / temp / symptom '
          'check. Begin BD.',
    ),
    TitrationStep(
      day: 5,
      morningMg: 12.5,
      eveningMg: 25,
      totalMg: 37.5,
      notes: 'Clinic visit. Counsel on hypersalivation, constipation. '
          'Start prophylactic laxative.',
    ),
    TitrationStep(
      day: 7,
      morningMg: 25,
      eveningMg: 25,
      totalMg: 50,
      notes: 'Clinic visit. FBC due (week 1 baseline).',
    ),
    TitrationStep(
      day: 10,
      morningMg: 25,
      eveningMg: 50,
      totalMg: 75,
      notes: 'Clinic visit. Watch postural drop.',
    ),
    TitrationStep(
      day: 12,
      morningMg: 50,
      eveningMg: 50,
      totalMg: 100,
      notes: 'Clinic visit. Hypersalivation typically emerging.',
    ),
    TitrationStep(
      day: 14,
      morningMg: 50,
      eveningMg: 75,
      totalMg: 125,
      notes: 'Clinic visit. FBC due (week 2).',
    ),
    TitrationStep(
      day: 17,
      morningMg: 75,
      eveningMg: 75,
      totalMg: 150,
      notes: 'Clinic visit. Reassess myocarditis warning signs '
          '(fever, chest pain, dyspnoea, tachycardia).',
    ),
    TitrationStep(
      day: 19,
      morningMg: 75,
      eveningMg: 100,
      totalMg: 175,
      notes: 'Clinic visit.',
    ),
    TitrationStep(
      day: 21,
      morningMg: 100,
      eveningMg: 100,
      totalMg: 200,
      notes: 'Clinic visit. FBC due (week 3).',
    ),
    TitrationStep(
      day: 24,
      morningMg: 100,
      eveningMg: 125,
      totalMg: 225,
      notes: 'Clinic visit. Approaching target.',
    ),
    TitrationStep(
      day: 28,
      morningMg: 125,
      eveningMg: 125,
      totalMg: 250,
      notes: 'Maintenance target. Plasma level at week 6 — '
          'optimise to 350–600 ng/mL.',
    ),
  ],
  postTitrationGuidance:
      'Hold at 250 mg/day. Plasma level at 6 weeks (trough), '
      'optimise to 350–600 ng/mL. Maintain thrice-weekly clinic '
      'visits for the first 4 weeks then taper monitoring per the '
      'community schedule. Emphasise to patient + carer: any fever, '
      'chest pain, severe drowsiness or new infection symptom is '
      'a same-day call to the clinic.',
  missedDoseRule:
      'Doses missed for more than 48 hours mandate retitration. '
      'Community patients should call the clinic same-day before '
      'the next dose is due. Use the Interruption Restart Wizard.',
  citations: <String>[
    'bap2020_schizophrenia_community_clozapine',
    'trec_community_clozapine_protocol',
    'nice_cg178_schizophrenia',
  ],
  lastReviewedISO: '2026-05-11',
  reviewedBy: 'PENDING - Rashid Razak (clinical author)',
);
