// One reviewed switching rule. Pairs from-drug → to-drug with a
// dated, sourced cross-titration schedule. Mirrors engine/types.ts
// SwitchingRule.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:psychswitch/src/engine/types/enums.dart';
import 'package:psychswitch/src/engine/types/schedule_step.dart';

part 'switching_rule.freezed.dart';
part 'switching_rule.g.dart';

@freezed
class DoseRatios with _$DoseRatios {
  const factory DoseRatios({
    required double fromCurrentDoseMg,
    required double toTargetDoseMg,
    required String equivalencyNote,
  }) = _DoseRatios;

  factory DoseRatios.fromJson(Map<String, dynamic> json) =>
      _$DoseRatiosFromJson(json);
}

@freezed
class SwitchingRule with _$SwitchingRule {
  const factory SwitchingRule({
    required String id,
    required String fromDrugId,
    required String toDrugId,
    @JsonKey(fromJson: _strategyFromJson, toJson: _strategyToJson)
    required Strategy strategy,
    required String rationale,
    required int durationDays,
    required List<ScheduleStep> schedule,
    required DoseRatios doseRatios,
    required List<String> safetyFlags,
    required List<String> citations,
    required List<String> contraindications,
    required String lastReviewedISO,
    required String reviewedBy,
  }) = _SwitchingRule;

  factory SwitchingRule.fromJson(Map<String, dynamic> json) =>
      _$SwitchingRuleFromJson(json);
}

Strategy _strategyFromJson(String s) => Strategy.fromJson(s);
String _strategyToJson(Strategy s) => s.jsonValue;
