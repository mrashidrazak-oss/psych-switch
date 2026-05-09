// Tests for the Dart specialty port.
// Mirrors engine/__tests__/specialty.test.ts.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';
import 'package:psychswitch_engine/specialty.dart';

void main() {
  group('activeSpecialties', () {
    test('empty context → no specialties', () {
      expect(activeSpecialties(const PatientContext()), isEmpty);
    });

    test('pregnant → pregnancy', () {
      expect(
        activeSpecialties(const PatientContext(pregnant: true)),
        contains(Specialty.pregnancy),
      );
    });

    test('breastfeeding → breastfeeding', () {
      expect(
        activeSpecialties(const PatientContext(breastfeeding: true)),
        contains(Specialty.breastfeeding),
      );
    });

    test('age >=65 → geriatric', () {
      expect(
        activeSpecialties(const PatientContext(ageYears: 75)),
        contains(Specialty.geriatric),
      );
    });

    test('age <18 → pediatric', () {
      expect(
        activeSpecialties(const PatientContext(ageYears: 12)),
        contains(Specialty.pediatric),
      );
    });

    test('multiple flags → multiple specialties', () {
      final out = activeSpecialties(
        const PatientContext(
          ageYears: 30,
          pregnant: true,
          breastfeeding: true,
        ),
      );
      expect(out, contains(Specialty.pregnancy));
      expect(out, contains(Specialty.breastfeeding));
    });
  });

  group('pregnancy matrix', () {
    test('valproate is avoid', () {
      expect(pregnancyTierFor('valproate'), equals(SpecialtyTier.avoid));
    });

    test('lamotrigine is preferred for bipolar maintenance', () {
      expect(
        pregnancyTierFor('lamotrigine'),
        equals(SpecialtyTier.preferred),
      );
    });

    test('paroxetine is avoid in 1st trimester, caution in 2nd/3rd', () {
      expect(pregnancyTierFor('paroxetine', 1), equals(SpecialtyTier.avoid));
      expect(
        pregnancyTierFor('paroxetine', 2),
        equals(SpecialtyTier.caution),
      );
      expect(
        pregnancyTierFor('paroxetine', 3),
        equals(SpecialtyTier.caution),
      );
    });

    test('lithium is avoid 1st trimester only', () {
      expect(pregnancyTierFor('lithium', 1), equals(SpecialtyTier.avoid));
      expect(pregnancyTierFor('lithium', 2), equals(SpecialtyTier.caution));
    });

    test('sertraline is preferred for breastfeeding', () {
      expect(
        pregnancyEntryFor('sertraline')?.breastfeedingTier,
        equals(SpecialtyTier.preferred),
      );
    });

    test('clozapine breastfeeding = avoid', () {
      expect(
        pregnancyEntryFor('clozapine')?.breastfeedingTier,
        equals(SpecialtyTier.avoid),
      );
    });
  });

  group('geriatric matrix', () {
    test('paroxetine is avoid (Beers list)', () {
      expect(
        geriatricEntryFor('paroxetine')?.tier,
        equals(SpecialtyTier.avoid),
      );
    });

    test('aripiprazole is preferred (low metabolic + sedation)', () {
      expect(
        geriatricEntryFor('aripiprazole')?.tier,
        equals(SpecialtyTier.preferred),
      );
    });

    test('chlorpromazine is avoid (anticholinergic)', () {
      expect(
        geriatricEntryFor('chlorpromazine')?.tier,
        equals(SpecialtyTier.avoid),
      );
    });

    test('every drug has a doseFactor < 1 (start low)', () {
      const all = <String>[
        'sertraline',
        'olanzapine',
        'aripiprazole',
        'lithium',
        'lamotrigine',
      ];
      for (final id in all) {
        final e = geriatricEntryFor(id);
        expect(e, isNotNull);
        expect(e!.doseFactor, lessThan(1));
      }
    });
  });

  group('pediatric matrix', () {
    test('fluoxetine is preferred (NICE first-line for paeds depression)', () {
      expect(
        pediatricEntryFor('fluoxetine')?.tier,
        equals(SpecialtyTier.preferred),
      );
    });

    test('paroxetine is avoid (suicidality signal in trials)', () {
      expect(
        pediatricEntryFor('paroxetine')?.tier,
        equals(SpecialtyTier.avoid),
      );
    });

    test('valproate is avoid (PPP)', () {
      expect(
        pediatricEntryFor('valproate')?.tier,
        equals(SpecialtyTier.avoid),
      );
    });

    test(
        'age boost: paroxetine in 17yo stays avoid (licensedFrom is null)',
        () {
      expect(
        pediatricTierFor('paroxetine', 17),
        equals(SpecialtyTier.avoid),
      );
    });

    test(
        'age boost: risperidone licensed from 5 → on-label for 12yo stays preferred',
        () {
      expect(
        pediatricTierFor('risperidone', 12),
        equals(SpecialtyTier.preferred),
      );
    });
  });

  group('assessSpecialty', () {
    test('non-applicable context → empty applicable list', () {
      final a = assessSpecialty(
        fromDrugId: 'sertraline',
        toDrugId: 'mirtazapine',
        context: const PatientContext(ageYears: 30, sex: Sex.male),
      );
      expect(a.applicable, isEmpty);
      expect(a.recommendations, isEmpty);
    });

    test('pregnant context surfaces pregnancy recommendations', () {
      final a = assessSpecialty(
        fromDrugId: 'sertraline',
        toDrugId: 'mirtazapine',
        context: const PatientContext(pregnant: true, trimester: 1),
      );
      expect(a.applicable, contains(Specialty.pregnancy));
      expect(
        a.recommendations.any(
          (r) =>
              r.specialty == Specialty.pregnancy &&
              r.drugId == 'sertraline',
        ),
        isTrue,
      );
    });

    test('paroxetine + 1st trimester → avoid tier', () {
      final a = assessSpecialty(
        fromDrugId: 'sertraline',
        toDrugId: 'paroxetine',
        context: const PatientContext(pregnant: true, trimester: 1),
      );
      final paroxRec = a.recommendations.firstWhere(
        (r) => r.drugId == 'paroxetine' && r.specialty == Specialty.pregnancy,
      );
      expect(paroxRec.tier, equals(SpecialtyTier.avoid));
    });

    test('older adult → geriatric recommendations include doseFactor', () {
      final a = assessSpecialty(
        fromDrugId: 'sertraline',
        toDrugId: 'mirtazapine',
        context: const PatientContext(ageYears: 80),
      );
      expect(a.applicable, contains(Specialty.geriatric));
      final geriatricRec = a.recommendations.firstWhere(
        (r) => r.specialty == Specialty.geriatric,
      );
      expect(geriatricRec.doseFactor, isNotNull);
      expect(geriatricRec.doseFactor, lessThan(1));
    });

    test('headline reflects worst tier per specialty', () {
      final a = assessSpecialty(
        fromDrugId: 'sertraline',
        toDrugId: 'paroxetine',
        context: const PatientContext(pregnant: true, trimester: 1),
      );
      expect(a.headline.toLowerCase(), contains('avoid'));
    });

    test('label helpers return user-facing strings', () {
      expect(specialtyLabel(Specialty.pregnancy), equals('Pregnancy'));
      expect(specialtyTierLabel(SpecialtyTier.avoid), equals('Avoid'));
    });
  });

  group('jsonValue round-trips', () {
    test('every Specialty parses back', () {
      for (final s in Specialty.values) {
        expect(Specialty.fromJson(s.jsonValue), equals(s));
      }
    });

    test('every SpecialtyTier parses back', () {
      for (final t in SpecialtyTier.values) {
        expect(SpecialtyTier.fromJson(t.jsonValue), equals(t));
      }
    });

    test('every SubgroupRiskBand parses back', () {
      for (final r in SubgroupRiskBand.values) {
        expect(SubgroupRiskBand.fromJson(r.jsonValue), equals(r));
      }
    });
  });
}
