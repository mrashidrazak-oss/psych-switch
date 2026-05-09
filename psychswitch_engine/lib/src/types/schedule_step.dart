// One day in a switching schedule. From-drug dose ↘, to-drug dose ↗.
// Mirrors engine/types.ts ScheduleStep.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_step.freezed.dart';
part 'schedule_step.g.dart';

@freezed
class ScheduleStep with _$ScheduleStep {
  const factory ScheduleStep({
    required int day,
    required double fromDoseMg,
    required double toDoseMg,
    String? notes,
    List<String>? citations,
  }) = _ScheduleStep;

  factory ScheduleStep.fromJson(Map<String, dynamic> json) =>
      _$ScheduleStepFromJson(json);
}
