import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/alcohol_withdrawal.dart';

AlcoholWithdrawalInput inp({
  WithdrawalSeverity severity = WithdrawalSeverity.moderate,
  bool hepatic = false,
  bool elderly = false,
  bool seizureDt = false,
  bool outpatient = false,
}) =>
    AlcoholWithdrawalInput(
      severity: severity,
      hepaticImpairment: hepatic,
      elderlyOrFrail: elderly,
      seizureOrDtHistory: seizureDt,
      outpatient: outpatient,
    );

void main() {
  test('default inpatient moderate → chlordiazepoxide, '
      'symptom-triggered', () {
    final p = buildAlcoholWithdrawalPlan(inp());
    expect(p.benzoChoice, contains('Chlordiazepoxide'));
    expect(p.regimen.join(' '), contains('SYMPTOM-TRIGGERED'));
  });

  test('hepatic impairment switches to lorazepam', () {
    final p = buildAlcoholWithdrawalPlan(inp(hepatic: true));
    expect(p.benzoChoice, contains('Lorazepam'));
  });

  test('elderly/frail also switches to lorazepam', () {
    final p = buildAlcoholWithdrawalPlan(inp(elderly: true));
    expect(p.benzoChoice, contains('Lorazepam'));
  });

  test('outpatient → fixed schedule + community-detox caution', () {
    final p = buildAlcoholWithdrawalPlan(inp(outpatient: true));
    expect(p.regimen.join(' '), contains('FIXED'));
    expect(p.cautions.join(' '),
        contains('Do NOT offer community detox'));
  });

  test('severe inpatient → parenteral thiamine before carbohydrate',
      () {
    final p = buildAlcoholWithdrawalPlan(
        inp(severity: WithdrawalSeverity.severe));
    expect(p.thiamine, contains('Parenteral'));
    expect(p.thiamine, contains('BEFORE any carbohydrate'));
  });

  test('seizure/DT history adds escalation + caution', () {
    final p = buildAlcoholWithdrawalPlan(inp(seizureDt: true));
    expect(p.escalation.toLowerCase(),
        anyOf(contains('delirium tremens'), contains('hdu')));
    expect(p.cautions.join(' '), contains('withdrawal seizures'));
  });

  test('magnesium replacement is always cautioned', () {
    final p = buildAlcoholWithdrawalPlan(inp());
    expect(p.cautions.join(' ').toLowerCase(), contains('magnesium'));
  });

  test('clipboard summary lists regimen + thiamine + cautions', () {
    final s = buildAlcoholWithdrawalPlan(inp()).clipboardSummary();
    expect(s, contains('Regimen:'));
    expect(s, contains('Thiamine:'));
    expect(s, contains('Cautions:'));
  });
}
