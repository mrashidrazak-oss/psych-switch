// Tests for the smoking-status CYP1A2 dose-adjustment calculator.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/smoking_adjustment.dart';

void main() {
  test('smokingDrugById returns clozapine + olanzapine only', () {
    expect(smokingDrugById('clozapine')?.name, 'Clozapine');
    expect(smokingDrugById('olanzapine')?.name, 'Olanzapine');
    expect(smokingDrugById('sertraline'), isNull);
  });

  group('stopping smoking → level rises, dose should fall', () {
    final clo = smokingDrugById('clozapine')!;

    test('clozapine projected factor = stopFactor (1.5)', () {
      final r = computeSmokingAdjustment(
        drug: clo,
        change: SmokingChange.stopping,
        currentDoseMg: 450,
      );
      expect(r.projectedLevelFactor, clo.stopFactor);
      expect(r.suggestedDoseMg < 450, isTrue);
      expect(r.headline, contains('de-induction'));
    });

    test('suggested dose ≈ current / stopFactor, rounded to 5', () {
      final r = computeSmokingAdjustment(
        drug: clo,
        change: SmokingChange.stopping,
        currentDoseMg: 450,
      );
      // 450 / 1.5 = 300 exactly.
      expect(r.suggestedDoseMg, 300);
    });
  });

  group('starting smoking → level falls, dose should rise', () {
    final olz = smokingDrugById('olanzapine')!;

    test('olanzapine projected factor = startFactor (<1)', () {
      final r = computeSmokingAdjustment(
        drug: olz,
        change: SmokingChange.starting,
        currentDoseMg: 10,
      );
      expect(r.projectedLevelFactor, olz.startFactor);
      expect(r.suggestedDoseMg > 10, isTrue);
      expect(r.headline, contains('induction'));
    });
  });

  test('clipboard summary contains drug, direction, suggested dose', () {
    final r = computeSmokingAdjustment(
      drug: smokingDrugById('clozapine')!,
      change: SmokingChange.stopping,
      currentDoseMg: 400,
    );
    final s = r.clipboardSummary();
    expect(s, contains('Clozapine'));
    expect(s, contains('+50%'));
    expect(s, contains('Suggested dose'));
  });
}
