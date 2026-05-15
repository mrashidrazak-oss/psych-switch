// Tests for the perinatal safety atlas.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/pregnancy_lactation.dart';

void main() {
  test('sertraline preferred in both axes', () {
    final p = perinatalProfileFor('sertraline')!;
    expect(p.pregnancyTier, PerinatalTier.preferred);
    expect(p.lactationTier, PerinatalTier.preferred);
  });

  test('valproate avoid in pregnancy', () {
    final p = perinatalProfileFor('valproate')!;
    expect(p.pregnancyTier, PerinatalTier.avoid);
    expect(p.pregnancyNote, contains('Neural-tube defects'));
  });

  test('aripiprazole avoid in lactation (prolactin suppression)', () {
    final p = perinatalProfileFor('aripiprazole')!;
    expect(p.lactationTier, PerinatalTier.avoid);
  });

  test('paroxetine avoid in pregnancy, preferred in lactation', () {
    final p = perinatalProfileFor('paroxetine')!;
    expect(p.pregnancyTier, PerinatalTier.avoid);
    expect(p.lactationTier, PerinatalTier.preferred);
  });

  test('unknown drug returns null', () {
    expect(perinatalProfileFor('imaginary'), isNull);
  });

  test('every profile has both axis tiers + a note', () {
    for (final p in kPerinatalAtlas) {
      expect(p.pregnancyNote, isNotEmpty);
      expect(p.lactationNote, isNotEmpty);
      expect(p.sources, isNotEmpty);
    }
  });

  test('tierLabel returns human strings', () {
    expect(tierLabel(PerinatalTier.preferred), 'Preferred');
    expect(tierLabel(PerinatalTier.cautious), 'Use with caution');
    expect(tierLabel(PerinatalTier.avoid), 'Avoid');
  });
}
