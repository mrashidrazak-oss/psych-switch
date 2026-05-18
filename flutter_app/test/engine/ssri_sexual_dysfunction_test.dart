import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/ssri_sexual_dysfunction.dart';

void main() {
  test('not confirmed → assess step', () {
    final r = evaluateSexualDysfunction();
    expect(r.step, SexDysStep.assess);
    expect(r.options.join(' '), contains('Exclude'));
  });

  test('confirmed but not persistent → conservative', () {
    final r = evaluateSexualDysfunction(confirmedDrugRelated: true);
    expect(r.step, SexDysStep.conservative);
    expect(r.options.join(' '), contains('Watchful waiting'));
  });

  test('persistent + in remission → switch agent', () {
    final r = evaluateSexualDysfunction(
      confirmedDrugRelated: true,
      persistent4Weeks: true,
      inRemission: true,
    );
    expect(r.step, SexDysStep.switchAgent);
    expect(r.options.join(' '), contains('mirtazapine'));
  });

  test('persistent + NOT in remission → adjunct (mood first)', () {
    final r = evaluateSexualDysfunction(
      confirmedDrugRelated: true,
      persistent4Weeks: true,
    );
    expect(r.step, SexDysStep.adjunct);
    expect(r.options.join(' '), contains('bupropion'));
  });

  test('adherence + non-drug-cause cautions always present', () {
    final r = evaluateSexualDysfunction();
    final c = r.cautions.join(' ');
    expect(c, contains('non-adherence'));
    expect(c, contains('non-drug causes'));
  });

  test('clipboard summary reports step', () {
    final s = evaluateSexualDysfunction(
      confirmedDrugRelated: true,
      persistent4Weeks: true,
      inRemission: true,
    ).clipboardSummary();
    expect(s, contains('Switch to a lower-risk agent'));
    expect(s, contains('Options:'));
  });
}
