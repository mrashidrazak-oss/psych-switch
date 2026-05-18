import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/nms_rechallenge.dart';

void main() {
  test('not recovered → not ready', () {
    final r = evaluateNmsRechallenge();
    expect(r.verdict, NmsRechallengeVerdict.notReady);
  });

  test('recovered but < 2 weeks → not ready', () {
    final r = evaluateNmsRechallenge(fullyRecovered: true);
    expect(r.verdict, NmsRechallengeVerdict.notReady);
  });

  test('recovered + delayed + not essential → avoid', () {
    final r = evaluateNmsRechallenge(
      fullyRecovered: true,
      atLeastTwoWeeksSinceRecovery: true,
      antipsychoticEssential: false,
    );
    expect(r.verdict, NmsRechallengeVerdict.avoid);
  });

  test('recovered + delayed + essential → cautious rechallenge', () {
    final r = evaluateNmsRechallenge(
      fullyRecovered: true,
      atLeastTwoWeeksSinceRecovery: true,
    );
    expect(r.verdict, NmsRechallengeVerdict.proceedCautious);
    expect(r.steps.join(' '), contains('DIFFERENT'));
  });

  test('severe prior episode adds inpatient-level step', () {
    final r = evaluateNmsRechallenge(
      fullyRecovered: true,
      atLeastTwoWeeksSinceRecovery: true,
      priorEpisodeSevereOrComplicated: true,
    );
    expect(r.steps.first, contains('inpatient-level'));
  });

  test('recurrence + avoid-high-risk cautions always present', () {
    final r = evaluateNmsRechallenge();
    final c = r.cautions.join(' ');
    expect(c, contains('can recur on rechallenge'));
    expect(c, contains('high-potency typicals'));
  });

  test('clipboard summary reports verdict', () {
    final s = evaluateNmsRechallenge(
      fullyRecovered: true,
      atLeastTwoWeeksSinceRecovery: true,
    ).clipboardSummary();
    expect(s, contains('cautious protocol'));
    expect(s, contains('Steps:'));
  });
}
