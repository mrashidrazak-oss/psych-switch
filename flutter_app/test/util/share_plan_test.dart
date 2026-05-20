// Pure-Dart tests for the share-plan formatter. The formatter has no
// Flutter imports — these run as plain VM tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/util/share_plan.dart';
import 'package:psychswitch_engine/switching_engine.dart';

import '../_helpers/content_loader.dart';

void main() {
  test('formatPlanForShare produces a plan transcript with required '
      'sections', () {
    final engine = loadSwitchingEngine();
    final from = engine.getDrug('sertraline')!;
    final to = engine.getDrug('escitalopram')!;
    final plan = engine.generateSwitchPlan(SwitchInput(
      fromDrugId: from.id,
      fromDoseMg: 100,
      toDrugId: to.id,
      toDoseMg: 10,
    )) as SwitchPlanOk;

    final out = formatPlanForShare(fromDrug: from, toDrug: to, plan: plan);

    // Header.
    expect(out, contains('PsychSwitch'));
    expect(out, contains('Sertraline → Escitalopram'));

    // Dose mapping section.
    expect(out, contains('DOSE MAPPING'));

    // Schedule section.
    expect(out, contains('SCHEDULE'));
    expect(out, contains('Day '));

    // References.
    expect(out, contains('REFERENCES'));
    expect(out, contains('Reviewed by:'));
    expect(out, contains('Last reviewed:'));

    // Footer disclaimer.
    expect(out, contains('Decision support only'));
  });

  test('formatPlanForShare warns when input doses differ from reference',
      () {
    final engine = loadSwitchingEngine();
    final from = engine.getDrug('sertraline')!;
    final to = engine.getDrug('escitalopram')!;
    // Off-reference doses.
    final plan = engine.generateSwitchPlan(SwitchInput(
      fromDrugId: from.id,
      fromDoseMg: 200,
      toDrugId: to.id,
      toDoseMg: 30,
    )) as SwitchPlanOk;

    final out = formatPlanForShare(fromDrug: from, toDrug: to, plan: plan);
    expect(out, contains('You entered'));
    expect(out, contains('adapt doses proportionally'));
  });
}
