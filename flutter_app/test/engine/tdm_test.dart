// Tests for the TDM interpreter.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/tdm.dart';

void main() {
  test('tdmDrugById returns the four registered drugs', () {
    expect(tdmDrugById('lithium')?.unit, 'mmol/L');
    expect(tdmDrugById('clozapine')?.unit, 'ng/mL');
    expect(tdmDrugById('valproate')?.unit, 'μg/mL');
    expect(tdmDrugById('lamotrigine')?.unit, 'μg/mL');
    expect(tdmDrugById('imaginary'), isNull);
  });

  group('lithium interpretation', () {
    final li = tdmDrugById('lithium')!;
    test('0.3 → subtherapeutic', () {
      expect(interpretLevel(li, 0.3).tier, TdmTier.subtherapeutic);
    });
    test('0.7 → therapeutic', () {
      expect(interpretLevel(li, 0.7).tier, TdmTier.therapeutic);
    });
    test('1.0 → upper therapeutic', () {
      expect(interpretLevel(li, 1).tier, TdmTier.therapeuticHigh);
    });
    test('1.3 → supratherapeutic', () {
      expect(interpretLevel(li, 1.3).tier, TdmTier.supratherapeutic);
    });
    test('1.8 → toxic', () {
      expect(interpretLevel(li, 1.8).tier, TdmTier.toxic);
    });
    test('clipboard summary contains tier + level', () {
      final r = interpretLevel(li, 1.8);
      expect(r.clipboardSummary(), contains('Toxic'));
      expect(r.clipboardSummary(), contains('1.8 mmol/L'));
    });
  });

  group('clozapine interpretation', () {
    final clo = tdmDrugById('clozapine')!;
    test('200 → subtherapeutic', () {
      expect(interpretLevel(clo, 200).tier, TdmTier.subtherapeutic);
    });
    test('500 → therapeutic', () {
      expect(interpretLevel(clo, 500).tier, TdmTier.therapeutic);
    });
    test('1100 → toxic', () {
      expect(interpretLevel(clo, 1100).tier, TdmTier.toxic);
    });
  });

  test('every drug has a target + timing string', () {
    for (final d in kTdmDrugs) {
      expect(d.targetCopy, isNotEmpty);
      expect(d.timingCopy, isNotEmpty);
    }
  });
}
