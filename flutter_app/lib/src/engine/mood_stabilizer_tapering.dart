// Mood-stabilizer tapering engine module.
//
// Loads structured tapering content (currently lithium-only; other mood
// stabilizers share the same hyperbolic principle but have less specific
// regimen data). All clinical content lives in /content/mood-stabilizers/
// JSON files.
//
// Per Maudsley 15th edition (Bipolar disorder, pp.331–333). Rapid
// discontinuation of lithium increases relapse risk sevenfold over the
// untreated rate — slow hyperbolic tapering is essential.
//
// Dart port of engine/moodStabilizerTapering.ts. Caller passes in the
// loaded JSON via [TaperingProtocol.fromJson]; runtime loader follows
// in Phase 4.

class TaperStep {
  const TaperStep({
    required this.phase,
    required this.stepDoseMg,
    required this.interval,
    required this.untilDoseMg,
    required this.notes,
  });

  factory TaperStep.fromJson(Map<String, dynamic> j) {
    return TaperStep(
      phase: j['phase'] as String,
      stepDoseMg: (j['stepDoseMg'] as num).toDouble(),
      interval: j['interval'] as String,
      untilDoseMg: (j['untilDoseMg'] as num).toDouble(),
      notes: j['notes'] as String,
    );
  }

  final String phase;
  final num stepDoseMg;
  final String interval;
  final num untilDoseMg;
  final String notes;
}

class TaperingRegimen {
  const TaperingRegimen({
    required this.title,
    required this.steps,
    required this.totalDurationMonths,
    required this.totalDurationNote,
  });

  factory TaperingRegimen.fromJson(Map<String, dynamic> j) {
    return TaperingRegimen(
      title: j['title'] as String,
      steps: (j['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(TaperStep.fromJson)
          .toList(),
      totalDurationMonths: (j['totalDurationMonths'] as num).toInt(),
      totalDurationNote: j['totalDurationNote'] as String,
    );
  }

  final String title;
  final List<TaperStep> steps;
  final int totalDurationMonths;
  final String totalDurationNote;
}

class WithdrawalEffects {
  const WithdrawalEffects({
    required this.rationale,
    required this.physical,
    required this.psychological,
  });

  factory WithdrawalEffects.fromJson(Map<String, dynamic> j) {
    return WithdrawalEffects(
      rationale: j['rationale'] as String,
      physical: (j['physical'] as List<dynamic>).cast<String>(),
      psychological: (j['psychological'] as List<dynamic>).cast<String>(),
    );
  }

  final String rationale;
  final List<String> physical;
  final List<String> psychological;
}

class TaperingPlan {
  const TaperingPlan({
    required this.principle,
    required this.rapidVsGradual,
    required this.initialReduction,
    required this.minimumDoseBeforeStop,
    required this.maudsleyRegimen,
  });

  factory TaperingPlan.fromJson(Map<String, dynamic> j) {
    return TaperingPlan(
      principle: j['principle'] as String,
      rapidVsGradual: j['rapidVsGradual'] as String,
      initialReduction: j['initialReduction'] as String,
      minimumDoseBeforeStop: j['minimumDoseBeforeStop'] as String,
      maudsleyRegimen: TaperingRegimen.fromJson(
        j['maudsleyRegimen'] as Map<String, dynamic>,
      ),
    );
  }

  final String principle;
  final String rapidVsGradual;
  final String initialReduction;
  final String minimumDoseBeforeStop;
  final TaperingRegimen maudsleyRegimen;
}

class TaperingProtocol {
  const TaperingProtocol({
    required this.id,
    required this.title,
    required this.rationale,
    required this.whenToConsiderStopping,
    required this.withdrawalEffects,
    required this.tapering,
    required this.monitoringDuringTaper,
    required this.ifSymptomsEmerge,
    required this.neverDoThis,
    required this.otherMoodStabilizers,
    required this.citations,
    required this.lastReviewedISO,
    required this.reviewedBy,
  });

  factory TaperingProtocol.fromJson(Map<String, dynamic> j) {
    return TaperingProtocol(
      id: j['id'] as String,
      title: j['title'] as String,
      rationale: j['rationale'] as String,
      whenToConsiderStopping:
          (j['whenToConsiderStopping'] as List<dynamic>).cast<String>(),
      withdrawalEffects: WithdrawalEffects.fromJson(
        j['withdrawalEffects'] as Map<String, dynamic>,
      ),
      tapering: TaperingPlan.fromJson(j['tapering'] as Map<String, dynamic>),
      monitoringDuringTaper:
          (j['monitoringDuringTaper'] as List<dynamic>).cast<String>(),
      ifSymptomsEmerge:
          (j['ifSymptomsEmerge'] as List<dynamic>).cast<String>(),
      neverDoThis: (j['neverDoThis'] as List<dynamic>).cast<String>(),
      otherMoodStabilizers: j['otherMoodStabilizers'] as String,
      citations: (j['citations'] as List<dynamic>).cast<String>(),
      lastReviewedISO: j['lastReviewedISO'] as String,
      reviewedBy: j['reviewedBy'] as String,
    );
  }

  final String id;
  final String title;
  final String rationale;
  final List<String> whenToConsiderStopping;
  final WithdrawalEffects withdrawalEffects;
  final TaperingPlan tapering;
  final List<String> monitoringDuringTaper;
  final List<String> ifSymptomsEmerge;
  final List<String> neverDoThis;
  final String otherMoodStabilizers;
  final List<String> citations;
  final String lastReviewedISO;
  final String reviewedBy;
}
