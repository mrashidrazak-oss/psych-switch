// Tests for the Dart dose_equivalents port.
// Mirrors engine/__tests__/doseEquivalents.test.ts.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/dose_equivalents.dart';

void main() {
  group('dose equivalents', () {
    test('CPZ family: 100 mg chlorpromazine = 1 CPZ-eq', () {
      final r = doseInReferenceUnits(
        EquivalencyFamily.cpz,
        'chlorpromazine',
        100,
      );
      expect(r, isNotNull);
      expect(r!.refUnits, closeTo(1, 1e-5));
      expect(r.referenceDoseMg, closeTo(100, 1e-5));
    });

    test('CPZ family: 5 mg olanzapine ≈ 100 mg CPZ', () {
      final r = doseInReferenceUnits(EquivalencyFamily.cpz, 'olanzapine', 5);
      expect(r!.referenceDoseMg, closeTo(100, 1e-5));
    });

    test('FLX family: 20 mg fluoxetine = 0.5 FLX-eq', () {
      final r = doseInReferenceUnits(
        EquivalencyFamily.fluoxetine,
        'fluoxetine',
        20,
      );
      expect(r!.refUnits, closeTo(0.5, 1e-5));
    });

    test('DZP family: 10 mg diazepam = 1 DZP-eq', () {
      final r = doseInReferenceUnits(
        EquivalencyFamily.diazepam,
        'diazepam',
        10,
      );
      expect(r!.refUnits, closeTo(1, 1e-5));
    });

    test('convertWithinFamily: 200 mg sertraline → fluoxetine', () {
      // sertraline 100 = 40 fluoxetine; 200 → 80
      final r = convertWithinFamily(
        EquivalencyFamily.fluoxetine,
        'sertraline',
        200,
        'fluoxetine',
      );
      expect(r!.toDoseMg, closeTo(80, 1e-5));
      expect(r.refUnits, closeTo(2, 1e-5));
    });

    test('convertWithinFamily returns null for unknown drugs', () {
      expect(
        convertWithinFamily(
          EquivalencyFamily.cpz,
          'imaginary',
          10,
          'olanzapine',
        ),
        isNull,
      );
      expect(
        convertWithinFamily(
          EquivalencyFamily.cpz,
          'olanzapine',
          10,
          'imaginary',
        ),
        isNull,
      );
    });

    test('convertWithinFamily returns null for non-positive dose', () {
      expect(
        convertWithinFamily(
          EquivalencyFamily.cpz,
          'olanzapine',
          0,
          'risperidone',
        ),
        isNull,
      );
    });

    test('roundToClinicalDose: 0–5 mg → 0.5', () {
      expect(roundToClinicalDose(0), equals(0));
      expect(roundToClinicalDose(2.3), equals(2.5));
      expect(roundToClinicalDose(4.6), equals(4.5));
      // 5–50 mg → 1 mg
      expect(roundToClinicalDose(7.4), equals(7));
      expect(roundToClinicalDose(48.7), equals(49));
      // 50–200 mg → 5 mg
      expect(roundToClinicalDose(73), equals(75));
      expect(roundToClinicalDose(127), equals(125));
      // ≥200 mg → 25 mg
      expect(roundToClinicalDose(213), equals(225));
      expect(roundToClinicalDose(490), equals(500));
    });

    test('all families have a reference entry that maps to itself', () {
      for (final meta in equivalencyFamilies.values) {
        final ref = meta.entries.where(
          (e) => e.equivalentMg == meta.reference.mg,
        );
        expect(ref, isNotEmpty, reason: 'family=${meta.family}');
      }
    });
  });

  group('EquivalencyFamily jsonValue round-trips', () {
    test('every family parses back', () {
      for (final f in EquivalencyFamily.values) {
        expect(EquivalencyFamily.fromJson(f.jsonValue), equals(f));
      }
    });
  });
}
