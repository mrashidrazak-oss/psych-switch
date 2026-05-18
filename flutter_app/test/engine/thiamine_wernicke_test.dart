import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/thiamine_wernicke.dart';

void main() {
  test('low-risk prophylaxis → oral acceptable', () {
    final p = buildThiaminePlan(
        ThiamineScenario.prophylaxisLowRisk);
    expect(p.regimen.toLowerCase(), contains('oral thiamine'));
    expect(p.keyPoints.join(' '),
        contains('Give thiamine BEFORE any IV glucose'));
  });

  test('high-risk prophylaxis → parenteral, oral unreliable', () {
    final p = buildThiaminePlan(
        ThiamineScenario.prophylaxisHighRisk);
    expect(p.regimen, contains('Parenteral'));
    expect(p.keyPoints.join(' '),
        contains('absorption is unreliable'));
  });

  test('suspected Wernicke → treat empirically, two pairs TDS', () {
    final p =
        buildThiaminePlan(ThiamineScenario.suspectedWernicke);
    expect(p.headline, contains('treat on'));
    expect(p.regimen, contains('TWO pairs TDS'));
  });

  test('every scenario carries the glucose-before-thiamine rule', () {
    for (final s in ThiamineScenario.values) {
      final p = buildThiaminePlan(s);
      expect(
        p.keyPoints.join(' '),
        contains('thiamine BEFORE any IV glucose'),
        reason: '$s missing glucose rule',
      );
    }
  });

  test('clipboard summary includes regimen + key points', () {
    final s = buildThiaminePlan(ThiamineScenario.suspectedWernicke)
        .clipboardSummary();
    expect(s, contains('Regimen:'));
    expect(s, contains('Key points:'));
  });
}
