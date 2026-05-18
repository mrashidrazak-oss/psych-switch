import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/lamotrigine_titration.dart';

void main() {
  test('alone → 25 mg OD start, no rash → continue', () {
    final p = buildLamotriginePlan();
    expect(p.comed, LamotrigineComed.alone);
    expect(p.rashAction, LamotrigineRashAction.none);
    expect(p.schedule.first, contains('25 mg once daily'));
  });

  test('with valproate → alternate-day start', () {
    final p = buildLamotriginePlan(
      comed: LamotrigineComed.withValproate,
    );
    expect(p.schedule.first, contains('every OTHER day'));
  });

  test('with inducer → faster / higher schedule', () {
    final p = buildLamotriginePlan(
      comed: LamotrigineComed.withInducer,
    );
    expect(p.schedule.first, contains('50 mg once daily'));
  });

  test('benign rash → withhold + review', () {
    final p = buildLamotriginePlan(
      rashFindings: <String>{'any_rash'},
    );
    expect(p.rashAction, LamotrigineRashAction.reviewStop);
  });

  test('mucosal involvement → emergency stop, no rechallenge', () {
    final p = buildLamotriginePlan(
      rashFindings: <String>{'mucosal'},
    );
    expect(p.rashAction, LamotrigineRashAction.emergency);
    expect(p.rashSteps.join(' '), contains('STOP lamotrigine now'));
  });

  test('red overrides co-existing amber', () {
    final p = buildLamotriginePlan(
      rashFindings: <String>{'any_rash', 'blistering'},
    );
    expect(p.rashAction, LamotrigineRashAction.emergency);
  });

  test('missed-dose re-titration caution always present', () {
    final p = buildLamotriginePlan();
    expect(p.cautions.join(' '), contains('RE-TITRATE from'));
  });

  test('clipboard summary reports comed + rash action', () {
    final s = buildLamotriginePlan(
      comed: LamotrigineComed.withValproate,
      rashFindings: <String>{'systemic'},
    ).clipboardSummary();
    expect(s, contains('With valproate'));
    expect(s, contains('STOP now'));
  });
}
