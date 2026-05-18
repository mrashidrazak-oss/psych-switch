import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/refeeding.dart';

void main() {
  test('no criteria → not high risk', () {
    final r = evaluateRefeeding(<String>{});
    expect(r.tier, RefeedTier.notHighRisk);
  });

  test('one major → high risk', () {
    final r = evaluateRefeeding(<String>{'bmi16'});
    expect(r.tier, RefeedTier.highRisk);
    expect(r.majorCount, 1);
    expect(r.management, contains('10 kcal/kg'));
  });

  test('two minor → high risk', () {
    final r = evaluateRefeeding(<String>{'bmi185', 'loss10'});
    expect(r.tier, RefeedTier.highRisk);
    expect(r.minorCount, 2);
  });

  test('one minor only → not high risk', () {
    final r = evaluateRefeeding(<String>{'bmi185'});
    expect(r.tier, RefeedTier.notHighRisk);
  });

  test('extreme criterion → extreme risk + 5 kcal/kg start', () {
    final r = evaluateRefeeding(<String>{'bmi14'});
    expect(r.tier, RefeedTier.extremeRisk);
    expect(r.management, contains('5 kcal/kg'));
  });

  test('thiamine + electrolyte monitoring always in management', () {
    final r = evaluateRefeeding(<String>{'bmi16'});
    expect(r.management.toLowerCase(), contains('thiamine'));
    expect(r.management, contains('PO₄'));
  });

  test('clipboard summary reports major/minor counts + tier', () {
    final r = evaluateRefeeding(<String>{'bmi16', 'history'});
    final s = r.clipboardSummary();
    expect(s, contains('1 major'));
    expect(s, contains('HIGH RISK'));
  });
}
