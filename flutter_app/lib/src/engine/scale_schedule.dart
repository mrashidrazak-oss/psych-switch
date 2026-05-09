// Adaptive schedule scaler.
//
// Goal: when the clinician enters doses that differ from the rule's
// reviewed reference, produce a schedule that uses the user's doses —
// rounded to real formulations, capped at clinical maxima, with honest
// signaling about how much adaptation happened.
//
// Three modes (per-rule, with safe defaults):
//
//   • proportional — scale every step by the user/reference ratio for
//     each drug, round to the drug's `dosing.increments`, merge any
//     adjacent steps that round to identical dose pairs. Default mode
//     for cross-tapers and titrations.
//
//   • fixed-step — taper at the rule's reviewed mg-decrement-per-step,
//     adjusting the *number* of steps to match the user's starting
//     dose. Right for lithium tapers and other absolute-rate schedules.
//
//   • no-scale — return the reviewed schedule untouched. Right for LAI
//     loading regimens and any protocol where the doses are dictated
//     by the product PI rather than the patient's current dose.
//
// Strong opinions baked in:
//   1. Rounding is a deterministic function. Don't ask an LLM to do it.
//   2. Schedules with non-formulation doses (e.g. 22.5 mg olanzapine)
//      are worse than no schedule. Always round to drug increments.
//   3. Capping at max generates a warning, never silently truncates.
//   4. Adapted schedules drop evidence grade by 1 ("A → B (adapted)").
//      The strategy is still reviewed; only the doses were derived.
//
// Dart port of engine/scaleSchedule.ts.

import 'package:psychswitch/src/engine/dose_rounding.dart';
import 'package:psychswitch/src/engine/types/drug.dart';
import 'package:psychswitch/src/engine/types/enums.dart';
import 'package:psychswitch/src/engine/types/schedule_step.dart';
import 'package:psychswitch/src/engine/types/switching_rule.dart';

export 'package:psychswitch/src/engine/dose_rounding.dart' show roundToIncrement;

/// Three scaling modes, picked per-rule.
enum ScalingMode {
  proportional('proportional'),
  fixedStep('fixed-step'),
  noScale('no-scale');

  const ScalingMode(this.jsonValue);

  final String jsonValue;

  static ScalingMode fromJson(String value) {
    for (final m in ScalingMode.values) {
      if (m.jsonValue == value) return m;
    }
    throw ArgumentError.value(value, 'value', 'unknown ScalingMode');
  }
}

/// Categorised scaling-time warning.
enum ScaleWarningKind {
  cappedAtMax('capped_at_max'),
  roundedToZero('rounded_to_zero'),
  mergedDuplicate('merged_duplicate'),
  extremeFactor('extreme_factor'),
  extremeFactorFrom('extreme_factor_from'),
  extremeFactorTo('extreme_factor_to'),
  invalidInput('invalid_input'),
  noScale('no_scale');

  const ScaleWarningKind(this.jsonValue);

  final String jsonValue;
}

/// One scaling-time warning.
class ScaleWarning {
  const ScaleWarning({
    required this.kind,
    required this.message,
    this.day,
  });

  final ScaleWarningKind kind;
  final String message;
  final int? day;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind.jsonValue,
        'message': message,
        if (day != null) 'day': day,
      };
}

/// Numeric record of which factor was applied to each drug.
class ScaleApplied {
  const ScaleApplied({
    required this.mode,
    required this.fromFactor,
    required this.toFactor,
  });

  final ScalingMode mode;
  final num fromFactor;
  final num toFactor;
}

/// Output of [scaleSchedule].
class ScaleResult {
  const ScaleResult({
    required this.schedule,
    required this.applied,
    required this.adapted,
    required this.warnings,
    required this.evidencePenalty,
  });

  final List<ScheduleStep> schedule;
  final ScaleApplied applied;

  /// True when the schedule was actually changed from the reviewed reference.
  final bool adapted;

  final List<ScaleWarning> warnings;

  /// Evidence grade penalty: 0 if no change, 1 if adapted (drop one grade).
  final int evidencePenalty;
}

const num _factorLo = 0.5;
const num _factorHi = 2.0;

/// Pick the appropriate scaling mode for a rule. Heuristic:
///  * LAI rules (either side LAI) → noScale (PI-defined doses).
///  * `explicitMode` overrides if set (passed by caller from JSON).
///  * Otherwise → proportional.
ScalingMode pickScalingMode(
  SwitchingRule rule,
  Drug fromDrug,
  Drug toDrug, {
  ScalingMode? explicitMode,
}) {
  if (explicitMode != null) return explicitMode;
  if (fromDrug.formulation == Formulation.lai ||
      toDrug.formulation == Formulation.lai) {
    return ScalingMode.noScale;
  }
  return ScalingMode.proportional;
}

// ── Notes adaptation ─────────────────────────────────────────────────────

String _escapeRegex(String s) {
  // Escape every regex meta-character. Mirrors the JS character class.
  return s.replaceAllMapped(
    RegExp(r'[.*+?^${}()|[\]\\]'),
    (m) => '\\${m[0]}',
  );
}

String _formatDoseForNotes(num n) {
  if (n is int || n == n.toInt()) return n.toInt().toString();
  // Match TS: toFixed(2) then strip trailing zeros and trailing dot.
  var s = n.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

/// Substitute reference dose mentions in a step's notes with their
/// adapted equivalents. Pure function — no side effects, easy to test.
String? adaptStepNotes(
  String? notes,
  num refStepFrom,
  num refStepTo,
  num newStepFrom,
  num newStepTo,
) {
  if (notes == null) return null;

  // Build the replacement map. Skip identity replacements and 0-mg
  // (which means "stop" — usually written as a verb in notes anyway).
  final map = <num, num>{};
  if (refStepFrom > 0 && newStepFrom != refStepFrom) {
    map[refStepFrom] = newStepFrom;
  }
  if (refStepTo > 0 && newStepTo != refStepTo) {
    map[refStepTo] = newStepTo;
  }
  if (map.isEmpty) return notes;

  // Process largest first so that "5 mg" never accidentally substitutes
  // a leading digit of "50 mg".
  final sorted = map.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key));

  var result = notes;
  for (final entry in sorted) {
    final ref = entry.key;
    final adapted = entry.value;
    final escaped = _escapeRegex(_formatDoseForNotes(ref));
    final pattern =
        RegExp('\\b$escaped\\s*mg\\b', caseSensitive: false);
    result =
        result.replaceAll(pattern, '${_formatDoseForNotes(adapted)} mg');
  }
  return result;
}

/// Apply scaling. Defaults to proportional unless [explicitMode] is set.
ScaleResult scaleSchedule({
  required SwitchingRule rule,
  required Drug fromDrug,
  required Drug toDrug,
  required num userFromDose,
  required num userToDose,
  ScalingMode? explicitMode,
}) {
  final mode = pickScalingMode(
    rule,
    fromDrug,
    toDrug,
    explicitMode: explicitMode,
  );
  final refFrom = rule.doseRatios.fromCurrentDoseMg;
  final refTo = rule.doseRatios.toTargetDoseMg;

  // Input sanity checks.
  if (userFromDose <= 0 || userToDose < 0 || refFrom <= 0 || refTo < 0) {
    return ScaleResult(
      schedule: rule.schedule,
      applied: ScaleApplied(mode: mode, fromFactor: 1, toFactor: 1),
      adapted: false,
      warnings: const <ScaleWarning>[
        ScaleWarning(
          kind: ScaleWarningKind.invalidInput,
          message: 'Invalid dose input — using reviewed schedule.',
        ),
      ],
      evidencePenalty: 0,
    );
  }

  final matchedReference = (userFromDose - refFrom).abs() < 1e-6 &&
      (refTo == 0
          ? userToDose == 0
          : (userToDose - refTo).abs() < 1e-6);

  if (mode == ScalingMode.noScale || matchedReference) {
    return ScaleResult(
      schedule: rule.schedule,
      applied: ScaleApplied(mode: mode, fromFactor: 1, toFactor: 1),
      adapted: false,
      warnings: mode == ScalingMode.noScale && !matchedReference
          ? const <ScaleWarning>[
              ScaleWarning(
                kind: ScaleWarningKind.noScale,
                message:
                    'Fixed protocol — doses set by product / pharmacokinetics, not scaled to entered values.',
              ),
            ]
          : const <ScaleWarning>[],
      evidencePenalty: 0,
    );
  }

  if (mode == ScalingMode.fixedStep) {
    return _scaleFixedStep(
      rule: rule,
      fromDrug: fromDrug,
      toDrug: toDrug,
      userFromDose: userFromDose,
      userToDose: userToDose,
      refFrom: refFrom,
    );
  }

  // proportional
  return _scaleProportional(
    rule: rule,
    fromDrug: fromDrug,
    toDrug: toDrug,
    userFromDose: userFromDose,
    userToDose: userToDose,
    refFrom: refFrom,
    refTo: refTo,
  );
}

// ── Proportional ─────────────────────────────────────────────────────────

ScaleResult _scaleProportional({
  required SwitchingRule rule,
  required Drug fromDrug,
  required Drug toDrug,
  required num userFromDose,
  required num userToDose,
  required num refFrom,
  required num refTo,
}) {
  final fromFactor = userFromDose / refFrom;
  final toFactor = refTo > 0 ? userToDose / refTo : 1;

  final warnings = <ScaleWarning>[];

  if (fromFactor < _factorLo || fromFactor > _factorHi) {
    warnings.add(
      ScaleWarning(
        kind: ScaleWarningKind.extremeFactorFrom,
        message:
            'From-drug scale ${fromFactor.toStringAsFixed(2)}× — verify carefully against the drug profile.',
      ),
    );
  }
  if (refTo > 0 && (toFactor < _factorLo || toFactor > _factorHi)) {
    warnings.add(
      ScaleWarning(
        kind: ScaleWarningKind.extremeFactorTo,
        message:
            'To-drug scale ${toFactor.toStringAsFixed(2)}× — verify carefully against the drug profile.',
      ),
    );
  }

  final fromIncrements = fromDrug.dosing.increments;
  final toIncrements = toDrug.dosing.increments;
  final fromMax = fromDrug.dosing.maxDoseMg;
  final toMax = toDrug.dosing.maxDoseMg;

  // Step 1: scale + round + cap.
  final intermediate = <ScheduleStep>[];
  for (final step in rule.schedule) {
    var scaledFrom = step.fromDoseMg * fromFactor;
    var scaledTo = step.toDoseMg * toFactor;

    var cappedFrom = false;
    var cappedTo = false;
    if (scaledFrom > fromMax) {
      scaledFrom = fromMax;
      cappedFrom = true;
    }
    if (scaledTo > toMax) {
      scaledTo = toMax;
      cappedTo = true;
    }

    final fromDoseMg = step.fromDoseMg == 0
        ? 0.0
        : roundToIncrement(scaledFrom, fromIncrements).toDouble();
    final toDoseMg = step.toDoseMg == 0
        ? 0.0
        : roundToIncrement(scaledTo, toIncrements).toDouble();

    if (cappedFrom) {
      warnings.add(
        ScaleWarning(
          kind: ScaleWarningKind.cappedAtMax,
          day: step.day,
          message:
              'Day ${step.day}: ${fromDrug.genericName} capped at max $fromMax mg.',
        ),
      );
    }
    if (cappedTo) {
      warnings.add(
        ScaleWarning(
          kind: ScaleWarningKind.cappedAtMax,
          day: step.day,
          message:
              'Day ${step.day}: ${toDrug.genericName} capped at max $toMax mg.',
        ),
      );
    }

    final notes = adaptStepNotes(
      step.notes,
      step.fromDoseMg,
      step.toDoseMg,
      fromDoseMg,
      toDoseMg,
    );

    intermediate.add(
      ScheduleStep(
        day: step.day,
        fromDoseMg: fromDoseMg,
        toDoseMg: toDoseMg,
        notes: notes,
        citations: step.citations,
      ),
    );
  }

  // Step 2: merge adjacent steps that scaled to identical dose pairs.
  final merged = <ScheduleStep>[];
  for (final step in intermediate) {
    if (merged.isNotEmpty) {
      final last = merged.last;
      if (last.fromDoseMg == step.fromDoseMg &&
          last.toDoseMg == step.toDoseMg) {
        warnings.add(
          ScaleWarning(
            kind: ScaleWarningKind.mergedDuplicate,
            day: step.day,
            message:
                'Day ${step.day} rounded to the same doses as Day ${last.day} — step merged.',
          ),
        );
        continue;
      }
    }
    merged.add(step);
  }

  return ScaleResult(
    schedule: merged,
    applied: ScaleApplied(
      mode: ScalingMode.proportional,
      fromFactor: fromFactor,
      toFactor: toFactor,
    ),
    adapted: true,
    warnings: warnings,
    evidencePenalty: 1,
  );
}

// ── Fixed-step ──────────────────────────────────────────────────────────

ScaleResult _scaleFixedStep({
  required SwitchingRule rule,
  required Drug fromDrug,
  required Drug toDrug,
  required num userFromDose,
  required num userToDose,
  required num refFrom,
}) {
  final fromIncrements = fromDrug.dosing.increments;
  final toIncrements = toDrug.dosing.increments;
  final warnings = <ScaleWarning>[];

  if (rule.schedule.length < 2) {
    return _scaleProportional(
      rule: rule,
      fromDrug: fromDrug,
      toDrug: toDrug,
      userFromDose: userFromDose,
      userToDose: userToDose,
      refFrom: refFrom,
      refTo: rule.doseRatios.toTargetDoseMg,
    );
  }

  num stepDecrement = 0;
  var intervalDays = 0;
  for (var i = 1; i < rule.schedule.length; i++) {
    final dec = rule.schedule[i - 1].fromDoseMg - rule.schedule[i].fromDoseMg;
    final dDay = rule.schedule[i].day - rule.schedule[i - 1].day;
    if (dec > stepDecrement) {
      stepDecrement = dec;
      if (dDay > intervalDays) intervalDays = dDay;
    }
  }

  if (stepDecrement <= 0) {
    return _scaleProportional(
      rule: rule,
      fromDrug: fromDrug,
      toDrug: toDrug,
      userFromDose: userFromDose,
      userToDose: userToDose,
      refFrom: refFrom,
      refTo: rule.doseRatios.toTargetDoseMg,
    );
  }

  final startDay = rule.schedule.isNotEmpty ? rule.schedule[0].day : 0;
  final out = <ScheduleStep>[];
  var dose = userFromDose;
  var day = startDay;
  var i = 0;
  const maxSteps = 64;
  final intervalForLoop = intervalDays > 0 ? intervalDays : 14;

  while (dose > 0 && i < maxSteps) {
    final nextDose = (dose - stepDecrement).clamp(0, dose);
    final toForStep = userToDose == 0
        ? 0.0
        : roundToIncrement(userToDose, toIncrements).toDouble();
    out.add(
      ScheduleStep(
        day: day,
        fromDoseMg: roundToIncrement(dose, fromIncrements).toDouble(),
        toDoseMg: toForStep,
      ),
    );
    if (nextDose == 0) {
      out.add(
        ScheduleStep(
          day: day + intervalForLoop,
          fromDoseMg: 0,
          toDoseMg: toForStep,
          notes: 'Stop',
        ),
      );
    }
    dose = nextDose;
    day += intervalForLoop;
    i++;
  }

  if (i >= maxSteps) {
    warnings.add(
      const ScaleWarning(
        kind: ScaleWarningKind.extremeFactorFrom,
        message:
            'Starting dose generated an unusually long taper — verify against the drug profile.',
      ),
    );
  }

  return ScaleResult(
    schedule: out,
    applied: ScaleApplied(
      mode: ScalingMode.fixedStep,
      fromFactor: userFromDose / refFrom,
      toFactor: 1,
    ),
    adapted: true,
    warnings: warnings,
    evidencePenalty: 1,
  );
}
