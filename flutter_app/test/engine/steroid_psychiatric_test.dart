import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/steroid_psychiatric.dart';

void main() {
  test('default → pre-treatment, high dose', () {
    final r = evaluateSteroidPsychiatric();
    expect(r.scenario, SteroidScenario.preTreatment);
    expect(r.highDose, isTrue);
  });

  test('pre-treatment does not recommend routine prophylaxis', () {
    final r = evaluateSteroidPsychiatric();
    expect(r.steps.join(' '), contains('not give prophylactic'));
  });

  test('low-dose pre-treatment changes the headline', () {
    final r = evaluateSteroidPsychiatric(highDose: false);
    expect(r.headline, contains('Lower-dose'));
  });

  test('mania/psychosis → reduce steroid + antipsychotic', () {
    final r = evaluateSteroidPsychiatric(
      scenario: SteroidScenario.maniaPsychosis,
    );
    expect(r.steps.join(' '), contains('antipsychotic'));
    expect(r.headline, contains('commonest early'));
  });

  test('depression scenario flags withdrawal emergence', () {
    final r = evaluateSteroidPsychiatric(
      scenario: SteroidScenario.depression,
    );
    expect(r.steps.join(' '), contains('dose reduction'));
  });

  test('delirium scenario demands a full work-up', () {
    final r = evaluateSteroidPsychiatric(
      scenario: SteroidScenario.delirium,
    );
    expect(r.steps.first, contains('delirium work-up'));
  });

  test('no-abrupt-stop caution always present', () {
    final r = evaluateSteroidPsychiatric();
    expect(r.cautions.join(' '),
        contains('Do not stop systemic steroids abruptly'));
  });

  test('clipboard summary reports scenario', () {
    final s = evaluateSteroidPsychiatric(
      scenario: SteroidScenario.maniaPsychosis,
    ).clipboardSummary();
    expect(s, contains('Established mania / psychosis'));
    expect(s, contains('Cautions:'));
  });
}
