import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/opioid_overdose.dart';

void main() {
  test('community default → bystander kit plan', () {
    final p = buildOpioidOverdosePlan();
    expect(p.setting, OverdoseSetting.community);
    expect(p.steps.first, contains('emergency services'));
  });

  test('re-narcotisation caution always present', () {
    final p = buildOpioidOverdosePlan();
    expect(p.cautions.join(' '), contains('RE-NARCOTISATION'));
  });

  test('long-acting opioid surfaces the outlasts-naloxone caution',
      () {
    final p = buildOpioidOverdosePlan(longActingOrMethadone: true);
    expect(p.longActing, isTrue);
    expect(p.cautions.first, contains('outlasts naloxone'));
  });

  test('clinical setting → titrated naloxone + airway', () {
    final p = buildOpioidOverdosePlan(
      setting: OverdoseSetting.clinical,
    );
    expect(p.steps.first, contains('airway'));
    expect(p.steps.join(' '), contains('Titrate IV naloxone'));
  });

  test('clinical + long-acting → infusion + admit', () {
    final p = buildOpioidOverdosePlan(
      setting: OverdoseSetting.clinical,
      longActingOrMethadone: true,
    );
    expect(p.steps.join(' '), contains('infusion'));
  });

  test('clipboard summary reports setting + steps', () {
    final s = buildOpioidOverdosePlan().clipboardSummary();
    expect(s, contains('Opioid overdose'));
    expect(s, contains('Steps:'));
  });
}
