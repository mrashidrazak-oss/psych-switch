// Overlap-intensity assessment + Conservative-mode schedule transform.
//
// "Cross-taper" in Maudsley 15th ed. ch.3 explicitly allows co-pres-
// cribing two drugs while reducing one and increasing the other.
// The clinical question is HOW MUCH overlap, for HOW LONG, and
// between which receptor profiles. This module quantifies that and
// gives the clinician a single tier (low / moderate / high / severe)
// with a tappable breakdown.
//
// The Conservative-mode transform is a UX escape hatch: if the
// clinician thinks the standard schedule's Day-1 overlap looks
// aggressive for their patient, one toggle reduces the from-drug's
// Day-1 dose by 25% (rounded to formulation, clamped so the taper
// stays monotonic).
//
// Everything here is pure — no Flutter, no I/O.
//
// Dart port of engine/overlapIntensity.ts.

import 'dart:math' as math;

import 'package:psychswitch_engine/dose_rounding.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/enums.dart';
import 'package:psychswitch_engine/types/schedule_step.dart';

/// Tier for the overlap-intensity score.
enum OverlapTier {
  low('low'),
  moderate('moderate'),
  high('high'),
  severe('severe');

  const OverlapTier(this.jsonValue);

  final String jsonValue;

  static OverlapTier fromJson(String value) {
    for (final t in OverlapTier.values) {
      if (t.jsonValue == value) return t;
    }
    throw ArgumentError.value(value, 'value', 'unknown OverlapTier');
  }
}

/// Component breakdown surfaced inside the modal.
class OverlapComponents {
  const OverlapComponents({
    required this.overlapDays,
    required this.day1FromFraction,
    required this.day1ToFraction,
    required this.mechanismMultiplier,
  });

  final int overlapDays;

  /// Fraction of from-drug typical-target on Day 1.
  final num day1FromFraction;

  /// Fraction of to-drug typical-target on Day 1.
  final num day1ToFraction;

  /// Multiplier applied for receptor-mechanism stacking.
  final num mechanismMultiplier;
}

/// Result of [assessOverlapIntensity].
class OverlapAssessment {
  const OverlapAssessment({
    required this.tier,
    required this.score,
    required this.label,
    required this.rationale,
    required this.flags,
    required this.components,
  });

  final OverlapTier tier;

  /// 0–100 numeric score (clamped).
  final int score;

  /// One-line user-facing label.
  final String label;

  /// Plain-English explanation of how the tier was derived.
  final String rationale;

  /// Mechanism-flag tags applied (serotonergic, qt_additive, etc.).
  final List<String> flags;

  final OverlapComponents components;
}

// ── Mechanism detection ────────────────────────────────────────────

const List<String> _serotonergicPatterns = <String>[
  'ssri',
  'snri',
  'nassa',
  'sms',
  'serotonin',
  'modulator',
];

bool _isSerotonergic(Drug drug) {
  final cls = drug.drugClass.toLowerCase();
  for (final p in _serotonergicPatterns) {
    if (cls.contains(p)) return true;
  }
  return drug.isMAOI ?? false;
}

bool _isFga(Drug drug) {
  final cls = drug.drugClass.toLowerCase();
  return cls.contains('fga') || cls.contains('typical');
}

int _risk(RiskLevel? level) {
  if (level == null) return 0;
  switch (level) {
    case RiskLevel.veryHigh:
      return 4;
    case RiskLevel.high:
      return 3;
    case RiskLevel.moderate:
    case RiskLevel.lowModerate:
      return 2;
    case RiskLevel.low:
      return 1;
  }
}

// ── Core assessment ───────────────────────────────────────────────

const OverlapAssessment _emptyAssessment = OverlapAssessment(
  tier: OverlapTier.low,
  score: 0,
  label: 'No overlap',
  rationale: 'The schedule has no co-prescribed days.',
  flags: <String>[],
  components: OverlapComponents(
    overlapDays: 0,
    day1FromFraction: 0,
    day1ToFraction: 0,
    mechanismMultiplier: 1,
  ),
);

/// Assess the overlap intensity for a switch schedule.
OverlapAssessment assessOverlapIntensity({
  required Drug fromDrug,
  required Drug toDrug,
  required List<ScheduleStep> schedule,
}) {
  if (schedule.isEmpty) return _emptyAssessment;

  // Use the typical target range top as the "100%" reference. Falls
  // back to maxDoseMg so we always have a denominator.
  final fromTarget = fromDrug.dosing.typicalTargetRangeMg;
  final toTarget = toDrug.dosing.typicalTargetRangeMg;
  final fromRef =
      fromTarget.length >= 2 ? fromTarget[1] : fromDrug.dosing.maxDoseMg;
  final toRef =
      toTarget.length >= 2 ? toTarget[1] : toDrug.dosing.maxDoseMg;

  // Overlap window — first day where BOTH > 0, last day where both > 0.
  final overlapSteps =
      schedule.where((s) => s.fromDoseMg > 0 && s.toDoseMg > 0).toList();
  if (overlapSteps.isEmpty) {
    return const OverlapAssessment(
      tier: OverlapTier.low,
      score: 0,
      label: 'No overlap',
      rationale:
          'The schedule never has both drugs at non-zero dose simultaneously.',
      flags: <String>[],
      components: OverlapComponents(
        overlapDays: 0,
        day1FromFraction: 0,
        day1ToFraction: 0,
        mechanismMultiplier: 1,
      ),
    );
  }

  final overlapDays = overlapSteps.last.day - overlapSteps.first.day + 1;

  final day1 = overlapSteps.first;
  final day1FromFraction = fromRef > 0 ? day1.fromDoseMg / fromRef : 0.0;
  final day1ToFraction = toRef > 0 ? day1.toDoseMg / toRef : 0.0;

  // ── Mechanism multiplier ──
  var multiplier = 1.0;
  final flags = <String>[];

  if (_isSerotonergic(fromDrug) && _isSerotonergic(toDrug)) {
    multiplier += 0.5;
    flags.add('serotonergic_stacking');
  }

  // QT additive — both qtcRisk >= moderate
  if (_risk(fromDrug.qtcRisk) >= 2 && _risk(toDrug.qtcRisk) >= 2) {
    multiplier += 0.3;
    flags.add('qt_additive');
  }

  // Sedation additive — both sedation >= moderate
  if (_risk(fromDrug.sedation) >= 2 && _risk(toDrug.sedation) >= 2) {
    multiplier += 0.2;
    flags.add('sedation_additive');
  }

  // EPS additive — two FGAs, or one FGA + high-EPS SGA
  if (_isFga(fromDrug) && _isFga(toDrug)) {
    multiplier += 0.3;
    flags.add('eps_additive');
  } else if ((_isFga(fromDrug) && _risk(toDrug.epsRisk) >= 3) ||
      (_isFga(toDrug) && _risk(fromDrug.epsRisk) >= 3)) {
    multiplier += 0.2;
    flags.add('eps_additive');
  }

  // Anticholinergic burden — proxy via known drug ids + tricyclic class.
  bool hasAnticholinergic(Drug d) =>
      d.id == 'chlorpromazine' ||
      d.id == 'paroxetine' ||
      d.drugClass.toLowerCase().contains('tricyclic');
  if (hasAnticholinergic(fromDrug) && hasAnticholinergic(toDrug)) {
    multiplier += 0.2;
    flags.add('anticholinergic_burden');
  }

  if (multiplier > 2.2) multiplier = 2.2;

  // ── Score ──
  final day1Score = (day1FromFraction + day1ToFraction) * 25;
  final durationScore = math.min(overlapDays / 14, 1.5) * 16;
  final baseScore = day1Score + durationScore;
  final scoreRaw = (baseScore * multiplier).clamp(0, 100);
  final score = scoreRaw.round();

  // ── Tier ──
  final OverlapTier tier;
  if (score < 25) {
    tier = OverlapTier.low;
  } else if (score < 50) {
    tier = OverlapTier.moderate;
  } else if (score < 75) {
    tier = OverlapTier.high;
  } else {
    tier = OverlapTier.severe;
  }

  final rationale = _buildRationale(
    overlapDays: overlapDays,
    day1FromFraction: day1FromFraction,
    day1ToFraction: day1ToFraction,
    multiplier: multiplier,
    flags: flags,
    fromName: fromDrug.genericName,
    toName: toDrug.genericName,
  );

  return OverlapAssessment(
    tier: tier,
    score: score,
    label: tierLabel(tier),
    rationale: rationale,
    flags: flags,
    components: OverlapComponents(
      overlapDays: overlapDays,
      day1FromFraction: day1FromFraction,
      day1ToFraction: day1ToFraction,
      mechanismMultiplier: multiplier,
    ),
  );
}

/// Display label for an [OverlapTier].
String tierLabel(OverlapTier t) {
  switch (t) {
    case OverlapTier.low:
      return 'Low overlap';
    case OverlapTier.moderate:
      return 'Moderate overlap';
    case OverlapTier.high:
      return 'High overlap';
    case OverlapTier.severe:
      return 'Severe overlap';
  }
}

/// Semantic colour-token triple for an [OverlapTier]. UI maps to AppColors.
({String bg, String border, String text}) tierTintTokens(OverlapTier t) {
  switch (t) {
    case OverlapTier.low:
      return (bg: 'to', border: 'to', text: 'to');
    case OverlapTier.moderate:
      return (bg: 'accent', border: 'accent', text: 'accent');
    case OverlapTier.high:
      return (bg: 'warning', border: 'warning', text: 'warning');
    case OverlapTier.severe:
      return (bg: 'danger', border: 'danger', text: 'danger');
  }
}

/// Hex colour for an [OverlapTier] (used in monochrome surfaces / share
/// pipeline where AppColors isn't reachable).
String tierTintHex(OverlapTier t) {
  switch (t) {
    case OverlapTier.low:
      return '#34d399';
    case OverlapTier.moderate:
      return '#3b82f6';
    case OverlapTier.high:
      return '#f59e0b';
    case OverlapTier.severe:
      return '#ef4444';
  }
}

/// Display label for a mechanism flag.
String flagLabel(String flag) {
  switch (flag) {
    case 'serotonergic_stacking':
      return 'Serotonergic stacking';
    case 'qt_additive':
      return 'QTc additive';
    case 'sedation_additive':
      return 'Sedation additive';
    case 'eps_additive':
      return 'EPS additive';
    case 'anticholinergic_burden':
      return 'Anticholinergic burden';
    default:
      return flag;
  }
}

String _buildRationale({
  required int overlapDays,
  required num day1FromFraction,
  required num day1ToFraction,
  required num multiplier,
  required List<String> flags,
  required String fromName,
  required String toName,
}) {
  final fromPct = _pctOfTarget(day1FromFraction);
  final toPct = _pctOfTarget(day1ToFraction);
  final parts = <String>[
    'Day 1: $fromName $fromPct of typical target, $toName $toPct of typical target.',
    'Co-prescribed for $overlapDays day${overlapDays == 1 ? '' : 's'}.',
  ];
  if (flags.isNotEmpty) {
    final mults = multiplier.toStringAsFixed(1);
    final list = flags.map(flagLabel).join(', ').toLowerCase();
    parts.add('Mechanism stacking ($mults×): $list.');
  } else {
    parts.add('No receptor-mechanism stacking detected.');
  }
  return parts.join(' ');
}

String _pctOfTarget(num fraction) =>
    '${(fraction * 100).round()}%';

// ── Conservative-mode schedule transform ─────────────────────────

/// Result of [applyConservativeOverlap].
class ConservativeResult {
  const ConservativeResult({
    required this.schedule,
    required this.modified,
    required this.deltaMg,
  });

  final List<ScheduleStep> schedule;
  final bool modified;
  final num deltaMg;
}

/// Apply Conservative mode: reduce Day 1's from-drug dose by 25%
/// (rounded to formulation, clamped so it can never drop below the next
/// step's dose — keeps the taper monotonic).
///
/// Returns the schedule unchanged if:
///  * Day 1 has fromDose == 0 (no overlap to soften).
///  * The 25% reduction rounds to the same value as the current Day 1.
///  * Day 2's dose is already ≥ Day 1 × 0.75.
ConservativeResult applyConservativeOverlap(
  List<ScheduleStep> schedule,
  Drug fromDrug,
) {
  if (schedule.length < 2) {
    return ConservativeResult(
      schedule: schedule,
      modified: false,
      deltaMg: 0,
    );
  }
  final day1 = schedule[0];
  if (day1.fromDoseMg <= 0) {
    return ConservativeResult(
      schedule: schedule,
      modified: false,
      deltaMg: 0,
    );
  }

  final day2 = schedule[1];
  final target = day1.fromDoseMg * 0.75;
  final incs = fromDrug.dosing.increments;
  var rounded = roundToIncrement(target, incs);

  // Don't drop below day 2's from-dose — that would invert the taper.
  if (day2.fromDoseMg > 0 && rounded < day2.fromDoseMg) {
    rounded = day2.fromDoseMg;
  }

  if (rounded == day1.fromDoseMg) {
    return ConservativeResult(
      schedule: schedule,
      modified: false,
      deltaMg: 0,
    );
  }

  final note = _appendConservativeNote(
    day1.notes,
    day1.fromDoseMg,
    rounded.toDouble(),
  );
  final newDay1 =
      day1.copyWith(fromDoseMg: rounded.toDouble(), notes: note);
  return ConservativeResult(
    schedule: <ScheduleStep>[newDay1, ...schedule.skip(1)],
    modified: true,
    deltaMg: day1.fromDoseMg - rounded,
  );
}

String _appendConservativeNote(
  String? existing,
  num before,
  num after,
) {
  final pct = (((before - after) / before) * 100).toStringAsFixed(0);
  final tag = '(Conservative mode: $before → $after mg, –$pct%)';
  if (existing == null || existing.isEmpty) return tag;
  return '$existing $tag';
}
