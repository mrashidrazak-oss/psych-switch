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

import 'package:psychswitch/src/engine/patient_context_pure.dart' show Sex;

// ── Titration ─────────────────────────────────────────────────────────

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

  /// Resolve the appropriate titration protocol for [variant].
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
