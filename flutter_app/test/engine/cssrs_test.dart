// Tests for the Columbia Suicide Severity Rating Scale engine.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/cssrs.dart';

void main() {
  test('no ideation, no behaviour → none tier', () {
    final r = evaluateCssrs(const CssrsInput(
      highestIdeationLevel: 0,
      ideationLastMonth: false,
      behaviourLifetime: false,
      behaviourLast3Months: false,
    ));
    expect(r.tier, CssrsTier.none);
    expect(r.tierLabel, 'No reported risk');
  });

  test('level 1 only → low tier', () {
    final r = evaluateCssrs(const CssrsInput(
      highestIdeationLevel: 1,
      ideationLastMonth: true,
      behaviourLifetime: false,
      behaviourLast3Months: false,
    ));
    expect(r.tier, CssrsTier.low);
  });

  test('level 2 in last month → moderate', () {
    final r = evaluateCssrs(const CssrsInput(
      highestIdeationLevel: 2,
      ideationLastMonth: true,
      behaviourLifetime: false,
      behaviourLast3Months: false,
    ));
    expect(r.tier, CssrsTier.moderate);
  });

  test('level 3 NOT in last month, lifetime behaviour → moderate', () {
    final r = evaluateCssrs(const CssrsInput(
      highestIdeationLevel: 3,
      ideationLastMonth: false,
      behaviourLifetime: true,
      behaviourLast3Months: false,
    ));
    expect(r.tier, CssrsTier.moderate);
  });

  test('level 4 → high regardless of behaviour', () {
    final r = evaluateCssrs(const CssrsInput(
      highestIdeationLevel: 4,
      ideationLastMonth: false,
      behaviourLifetime: false,
      behaviourLast3Months: false,
    ));
    expect(r.tier, CssrsTier.high);
  });

  test('any behaviour in last 3 months → high regardless of ideation', () {
    final r = evaluateCssrs(const CssrsInput(
      highestIdeationLevel: 1,
      ideationLastMonth: false,
      behaviourLifetime: true,
      behaviourLast3Months: true,
    ));
    expect(r.tier, CssrsTier.high);
  });

  test('clipboard summary contains tier label + level + behaviour', () {
    final r = evaluateCssrs(const CssrsInput(
      highestIdeationLevel: 4,
      ideationLastMonth: true,
      behaviourLifetime: true,
      behaviourLast3Months: true,
    ));
    final s = r.clipboardSummary();
    expect(s, contains('High'));
    expect(s, contains('ideation level 4'));
    expect(s, contains('behaviour within last 3 months'));
  });

  test('ladder has 5 items in level order', () {
    expect(kCssrsIdeationLadder.length, 5);
    for (var i = 0; i < kCssrsIdeationLadder.length; i++) {
      expect(kCssrsIdeationLadder[i].level, i + 1);
    }
  });
}
