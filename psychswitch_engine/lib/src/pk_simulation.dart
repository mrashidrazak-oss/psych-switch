// Pharmacokinetic simulation for visualization purposes.
//
// We use a one-compartment exponential model: when the prescribed dose
// changes, the patient's effective level moves toward the new prescribed
// dose with a time constant set by the drug's effective half-life.
//
// This is DELIBERATELY SIMPLE. We ignore: two-compartment kinetics,
// non-linear dose-response (paroxetine!), CYP-mediated drug-drug
// interactions in the regimen, food effects, and inter-individual
// variability. The output is for clinical INTUITION (showing the long
// fluoxetine tail, the slow venlafaxine washout) — not for exposure
// prediction. Do NOT use these numbers to dose patients.
//
// Dart port of engine/pkSimulation.ts.

import 'dart:math' as math;

import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/schedule_step.dart';

/// Effective half-life used for visualization. For drugs with a clinically
/// significant active metabolite (fluoxetine, venlafaxine), the metabolite
/// dominates the post-cessation tail and ignoring it would mislead.
///
/// Heuristic: if a clinically-significant metabolite exists, take the
/// larger of (parent half-life) and (metabolite half-life × 0.7). The 0.7
/// factor is a deliberately conservative weight reflecting that metabolites
/// are typically less potent on a per-mg basis than the parent.
double effectiveHalfLifeHours(Drug drug) {
  final parent = drug.halfLife.meanHours;
  final meta = drug.activeMetabolite;
  final metaT = meta.halfLifeHours;
  if (meta.clinicallySignificant && metaT != null) {
    return math.max(parent, metaT * 0.7);
  }
  return parent;
}

/// One day's prescribed-vs-effective level pair.
class DailyPoint {
  const DailyPoint({
    required this.day,
    required this.prescribedDoseMg,
    required this.effectiveLevelMg,
  });

  final int day;
  final num prescribedDoseMg;
  final num effectiveLevelMg;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'day': day,
        'prescribedDoseMg': prescribedDoseMg,
        'effectiveLevelMg': effectiveLevelMg,
      };
}

/// Generic (drug-agnostic) schedule point used by [simulateDailyLevels].
class SchedulePoint {
  const SchedulePoint({required this.day, required this.doseMg});

  final int day;
  final num doseMg;
}

/// Look up the prescribed dose at the given day by stepping through the
/// schedule. Days before the first step inherit the first step's dose.
/// Days after the final step inherit the final step's dose.
num _prescribedAt(List<SchedulePoint> points, int day) {
  var dose = points.isNotEmpty ? points[0].doseMg : 0;
  for (final p in points) {
    if (p.day <= day) {
      dose = p.doseMg;
    } else {
      break;
    }
  }
  return dose;
}

/// Simulate daily prescribed dose and effective level for one drug across
/// [totalDays] days. Initial effective level on day 1 is the day-1
/// prescribed dose (assumes the patient is at steady state when the
/// cross-taper begins).
List<DailyPoint> simulateDailyLevels(
  List<SchedulePoint> points,
  num halfLifeHours,
  int totalDays,
) {
  if (points.isEmpty) return <DailyPoint>[];

  // Fraction of the previous day's residual that survives 24 hours.
  // For half-life H hours, after 24h the residual is 0.5^(24/H).
  final survivePerDay = math.pow(0.5, 24 / halfLifeHours);

  final result = <DailyPoint>[];
  var effective = points[0].doseMg; // day-1 steady-state assumption

  for (var day = 1; day <= totalDays; day++) {
    final prescribed = _prescribedAt(points, day);
    if (day > 1) {
      effective =
          effective * survivePerDay + prescribed * (1 - survivePerDay);
    }
    result.add(
      DailyPoint(
        day: day,
        prescribedDoseMg: prescribed,
        effectiveLevelMg: effective,
      ),
    );
  }
  return result;
}

/// Result of [simulateSwitch] — paired daily series + total day count.
class SwitchSimulation {
  const SwitchSimulation({
    required this.from,
    required this.to,
    required this.totalDays,
  });

  final List<DailyPoint> from;
  final List<DailyPoint> to;
  final int totalDays;
}

/// Convenience: run the simulation for both drugs in a switching schedule
/// and return paired daily points. Includes a configurable trailing
/// window so the post-schedule washout is visible (most useful for
/// fluoxetine, where the tail is longer than the cross-taper itself).
SwitchSimulation simulateSwitch(
  List<ScheduleStep> schedule,
  Drug fromDrug,
  Drug toDrug, {
  int trailingDays = 14,
}) {
  final lastScheduleDay = schedule.isNotEmpty ? schedule.last.day : 1;
  final totalDays = lastScheduleDay + trailingDays;

  final fromPoints = schedule
      .map((s) => SchedulePoint(day: s.day, doseMg: s.fromDoseMg))
      .toList();
  final toPoints = schedule
      .map((s) => SchedulePoint(day: s.day, doseMg: s.toDoseMg))
      .toList();

  return SwitchSimulation(
    from: simulateDailyLevels(
      fromPoints,
      effectiveHalfLifeHours(fromDrug),
      totalDays,
    ),
    to: simulateDailyLevels(
      toPoints,
      effectiveHalfLifeHours(toDrug),
      totalDays,
    ),
    totalDays: totalDays,
  );
}
