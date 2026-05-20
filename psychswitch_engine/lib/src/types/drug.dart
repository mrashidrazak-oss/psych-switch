// Drug — the central data type. Mirrors engine/types.ts `Drug` interface
// exactly. Field order, names, and optionality match the TS shape line
// by line so the same JSON files in /content/drugs/ parse on both
// stacks during the migration.
//
// Codegen: run `dart run build_runner build` to generate the .freezed
// + .g files. They're gitignored.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:psychswitch_engine/types/enums.dart';

part 'drug.freezed.dart';
part 'drug.g.dart';

@freezed
class HalfLife with _$HalfLife {
  const factory HalfLife({
    required double meanHours,
    required List<double> rangeHours,
    String? notes,
  }) = _HalfLife;

  factory HalfLife.fromJson(Map<String, dynamic> json) =>
      _$HalfLifeFromJson(json);
}

@freezed
class ActiveMetabolite with _$ActiveMetabolite {
  const factory ActiveMetabolite({
    required String? name,
    required double? halfLifeHours,
    required bool clinicallySignificant,
    String? notes,
  }) = _ActiveMetabolite;

  factory ActiveMetabolite.fromJson(Map<String, dynamic> json) =>
      _$ActiveMetaboliteFromJson(json);
}

@freezed
class CypInteractions with _$CypInteractions {
  const factory CypInteractions({
    required List<String> substrateOf,
    required List<String> inhibitorOf,
    required String switchingRelevance,
  }) = _CypInteractions;

  factory CypInteractions.fromJson(Map<String, dynamic> json) =>
      _$CypInteractionsFromJson(json);
}

@freezed
class MaoiWashout with _$MaoiWashout {
  const factory MaoiWashout({
    required int daysOffBeforeMAOI,
    required int daysOffAfterMAOI,
    required String notes,
  }) = _MaoiWashout;

  factory MaoiWashout.fromJson(Map<String, dynamic> json) =>
      _$MaoiWashoutFromJson(json);
}

@freezed
class DiscontinuationSyndromeRisk with _$DiscontinuationSyndromeRisk {
  const factory DiscontinuationSyndromeRisk({
    @JsonKey(fromJson: _riskFromJson, toJson: _riskToJson)
    required RiskLevel score,
    required String notes,
  }) = _DiscontinuationSyndromeRisk;

  factory DiscontinuationSyndromeRisk.fromJson(Map<String, dynamic> json) =>
      _$DiscontinuationSyndromeRiskFromJson(json);
}

@freezed
class MetabolicRisk with _$MetabolicRisk {
  const factory MetabolicRisk({
    @JsonKey(fromJson: _riskFromJson, toJson: _riskToJson)
    required RiskLevel score,
    required String notes,
  }) = _MetabolicRisk;

  factory MetabolicRisk.fromJson(Map<String, dynamic> json) =>
      _$MetabolicRiskFromJson(json);
}

@freezed
class ReboundPsychosisRisk with _$ReboundPsychosisRisk {
  const factory ReboundPsychosisRisk({
    @JsonKey(fromJson: _riskFromJson, toJson: _riskToJson)
    required RiskLevel score,
    required String notes,
  }) = _ReboundPsychosisRisk;

  factory ReboundPsychosisRisk.fromJson(Map<String, dynamic> json) =>
      _$ReboundPsychosisRiskFromJson(json);
}

@freezed
class LaiInfo with _$LaiInfo {
  const factory LaiInfo({
    required bool available,
    required String notes,
  }) = _LaiInfo;

  factory LaiInfo.fromJson(Map<String, dynamic> json) =>
      _$LaiInfoFromJson(json);
}

@freezed
class LaiDetails with _$LaiDetails {
  const factory LaiDetails({
    required int injectionIntervalDays,
    required String initiationProtocol,
    required bool needsOralOverlap,
    int? oralOverlapDurationDays,
  }) = _LaiDetails;

  factory LaiDetails.fromJson(Map<String, dynamic> json) =>
      _$LaiDetailsFromJson(json);
}

@freezed
class Dosing with _$Dosing {
  const factory Dosing({
    required double startingDoseMg,
    required List<double> typicalTargetRangeMg,
    required double maxDoseMg,
    required List<double> increments,
    required List<String> formulationsAvailableMy,
  }) = _Dosing;

  factory Dosing.fromJson(Map<String, dynamic> json) =>
      _$DosingFromJson(json);
}

@freezed
class Drug with _$Drug {
  const factory Drug({
    required String id,
    required String genericName,
    required String drugClass,
    @JsonKey(fromJson: _drugCategoryFromJson, toJson: _drugCategoryToJson)
    DrugCategory? category,
    bool? hidden,
    bool? isMAOI,
    int? maoiClearanceDays,
    required List<String> malaysianBrandNames,
    required HalfLife halfLife,
    required ActiveMetabolite activeMetabolite,
    required CypInteractions cypInteractions,
    MaoiWashout? maoiWashout,
    DiscontinuationSyndromeRisk? discontinuationSyndromeRisk,
    @JsonKey(fromJson: _riskFromJsonNullable, toJson: _riskToJsonNullable)
    RiskLevel? epsRisk,
    MetabolicRisk? metabolicRisk,
    @JsonKey(fromJson: _riskFromJsonNullable, toJson: _riskToJsonNullable)
    RiskLevel? prolactinRisk,
    @JsonKey(fromJson: _riskFromJsonNullable, toJson: _riskToJsonNullable)
    RiskLevel? qtcRisk,
    @JsonKey(fromJson: _riskFromJsonNullable, toJson: _riskToJsonNullable)
    RiskLevel? sedation,
    LaiInfo? lai,
    @JsonKey(fromJson: _formulationFromJson, toJson: _formulationToJson)
    Formulation? formulation,
    LaiDetails? laiDetails,
    ReboundPsychosisRisk? reboundPsychosisRisk,
    required Dosing dosing,
    required String formulationNotes,
    required List<String> citations,
    required String lastReviewedISO,
    required String reviewedBy,
  }) = _Drug;

  factory Drug.fromJson(Map<String, dynamic> json) => _$DrugFromJson(json);
}

// ── Custom converters for the kebab-case wire formats ────────────────

RiskLevel _riskFromJson(String s) => RiskLevel.fromJson(s);
String _riskToJson(RiskLevel r) => r.jsonValue;

RiskLevel? _riskFromJsonNullable(String? s) =>
    s == null ? null : RiskLevel.fromJson(s);
String? _riskToJsonNullable(RiskLevel? r) => r?.jsonValue;

DrugCategory? _drugCategoryFromJson(String? s) =>
    s == null ? null : DrugCategory.fromJson(s);
String? _drugCategoryToJson(DrugCategory? c) => c?.jsonValue;

Formulation? _formulationFromJson(String? s) =>
    s == null ? null : Formulation.fromJson(s);
String? _formulationToJson(Formulation? f) => f?.jsonValue;
