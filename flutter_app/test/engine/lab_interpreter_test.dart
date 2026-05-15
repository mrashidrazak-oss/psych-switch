// Tests for the lab interpreter.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/lab_interpreter.dart';

void main() {
  test('labTestById returns expected labs', () {
    expect(labTestById('tsh')?.name, 'TSH');
    expect(labTestById('anc')?.name, 'ANC');
    expect(labTestById('imaginary'), isNull);
  });

  group('TSH interpretation', () {
    final tsh = labTestById('tsh')!;
    test('0.05 → critical low', () {
      expect(interpretLab(tsh, 0.05).tier, LabTier.criticalLow);
    });
    test('2.5 → normal', () {
      expect(interpretLab(tsh, 2.5).tier, LabTier.normal);
    });
    test('7 → high (subclinical)', () {
      expect(interpretLab(tsh, 7).tier, LabTier.high);
    });
    test('15 → critical high (overt)', () {
      expect(interpretLab(tsh, 15).tier, LabTier.criticalHigh);
    });
  });

  group('ANC interpretation (clozapine)', () {
    final anc = labTestById('anc')!;
    test('0.4 → agranulocytosis', () {
      final r = interpretLab(anc, 0.4);
      expect(r.tier, LabTier.criticalLow);
      expect(r.action, contains('AGRANULOCYTOSIS'));
    });
    test('1.2 → mild neutropenia', () {
      expect(interpretLab(anc, 1.2).tier, LabTier.low);
    });
    test('5 → normal', () {
      expect(interpretLab(anc, 5).tier, LabTier.normal);
    });
  });

  group('Sodium interpretation', () {
    final na = labTestById('sodium')!;
    test('123 → critical low (admit)', () {
      expect(interpretLab(na, 123).tier, LabTier.criticalLow);
    });
    test('140 → normal', () {
      expect(interpretLab(na, 140).tier, LabTier.normal);
    });
    test('150 → high', () {
      expect(interpretLab(na, 150).tier, LabTier.high);
    });
  });

  test('clipboard summary contains value + tier label', () {
    final r = interpretLab(labTestById('tsh')!, 7);
    final s = r.clipboardSummary();
    expect(s, contains('7'));
    expect(s, contains('High'));
  });

  test('every lab has a non-empty context + bands', () {
    for (final t in kLabTests) {
      expect(t.context, isNotEmpty);
      expect(t.bands, isNotEmpty);
    }
  });
}
