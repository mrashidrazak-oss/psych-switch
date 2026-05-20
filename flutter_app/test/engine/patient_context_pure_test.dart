// Tests for the Dart patient_context_pure port.
// Mirrors engine/__tests__/patientContext.test.ts.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';

void main() {
  group('patient context helpers', () {
    test('ageBand bins correctly', () {
      expect(
        ageBand(const PatientContext(ageYears: 12)),
        equals(AgeBand.pediatric),
      );
      expect(
        ageBand(const PatientContext(ageYears: 30)),
        equals(AgeBand.adult),
      );
      expect(
        ageBand(const PatientContext(ageYears: 65)),
        equals(AgeBand.olderAdult),
      );
      expect(
        ageBand(const PatientContext(ageYears: 80)),
        equals(AgeBand.olderAdult),
      );
      expect(ageBand(const PatientContext()), isNull);
    });

    test('renalBandFromEgfr maps K/DOQI bands', () {
      expect(renalBandFromEgfr(95), equals(RenalFn.normal));
      expect(renalBandFromEgfr(75), equals(RenalFn.mild));
      expect(renalBandFromEgfr(45), equals(RenalFn.moderate));
      expect(renalBandFromEgfr(20), equals(RenalFn.severe));
    });

    test('bmi calculation', () {
      final b = bmi(const PatientContext(weightKg: 70, heightCm: 170));
      expect(b, closeTo(24.22, 0.1));
    });

    test('bmi returns null when missing inputs', () {
      expect(bmi(const PatientContext()), isNull);
      expect(bmi(const PatientContext(weightKg: 70)), isNull);
    });

    test('isComplete requires age and sex', () {
      expect(isComplete(const PatientContext()), isFalse);
      expect(isComplete(const PatientContext(ageYears: 30)), isFalse);
      expect(
        isComplete(const PatientContext(ageYears: 30, sex: Sex.male)),
        isTrue,
      );
    });
  });

  group('context warnings', () {
    test('lithium + severe CKD = danger', () {
      final w = warningsForDrug(
        const PatientContext(renal: RenalFn.severe),
        'lithium',
      );
      expect(
        w.any((x) => x.severity == WarningSeverity.danger),
        isTrue,
      );
    });

    test('valproate + pregnancy = danger', () {
      final w = warningsForDrug(
        const PatientContext(pregnant: true),
        'valproate',
      );
      expect(
        w.any((x) => x.severity == WarningSeverity.danger),
        isTrue,
      );
    });

    test('older adult + olanzapine = warning', () {
      final w = warningsForDrug(
        const PatientContext(ageYears: 75, sex: Sex.female),
        'olanzapine',
      );
      expect(
        w.any((x) => x.severity == WarningSeverity.warning),
        isTrue,
      );
    });

    test('smoker + clozapine = info', () {
      final w = warningsForDrug(
        const PatientContext(smoker: true),
        'clozapine',
      );
      expect(
        w.any((x) => x.severity == WarningSeverity.info),
        isTrue,
      );
    });

    test('benign pair = no warnings', () {
      expect(
        warningsForDrug(
          const PatientContext(ageYears: 30, sex: Sex.male),
          'sertraline',
        ),
        isEmpty,
      );
    });

    test('renal eGFR derives band when explicit renal not set', () {
      // egfr 20 → severe → lithium danger
      final w = warningsForDrug(
        const PatientContext(egfr: 20),
        'lithium',
      );
      expect(
        w.any((x) => x.severity == WarningSeverity.danger),
        isTrue,
      );
    });

    test('cardiac + QTc-prolonger triggers warning', () {
      final w = warningsForDrug(
        const PatientContext(
          comorbidities: Comorbidities(cardiac: true),
        ),
        'haloperidol',
      );
      expect(
        w.any((x) => x.severity == WarningSeverity.warning),
        isTrue,
      );
    });

    test('hepatic moderate + valproate = danger', () {
      final w = warningsForDrug(
        const PatientContext(hepatic: HepaticFn.moderate),
        'valproate',
      );
      expect(
        w.any((x) => x.severity == WarningSeverity.danger),
        isTrue,
      );
    });
  });

  group('jsonValue round-trips', () {
    test('every enum has stable jsonValue', () {
      // Just confirm the values are non-empty strings — fromJson is not
      // exposed for these (they are not serialised at engine boundary).
      for (final a in AgeBand.values) {
        expect(a.jsonValue, isNotEmpty);
      }
      for (final r in RenalFn.values) {
        expect(r.jsonValue, isNotEmpty);
      }
      for (final h in HepaticFn.values) {
        expect(h.jsonValue, isNotEmpty);
      }
      for (final s in Sex.values) {
        expect(s.jsonValue, isNotEmpty);
      }
      for (final s in WarningSeverity.values) {
        expect(s.jsonValue, isNotEmpty);
      }
    });
  });

  group('ContextWarning.toJson', () {
    test('omits drugId when null and includes when present', () {
      const a = ContextWarning(
        severity: WarningSeverity.info,
        message: 'Generic',
      );
      const b = ContextWarning(
        severity: WarningSeverity.warning,
        drugId: 'olanzapine',
        message: 'Drug-specific',
      );
      expect(a.toJson().containsKey('drugId'), isFalse);
      expect(b.toJson()['drugId'], equals('olanzapine'));
    });
  });
}
