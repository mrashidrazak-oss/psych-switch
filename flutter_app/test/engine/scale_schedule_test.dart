// Tests for the Dart scale_schedule port.
// Mirrors engine/__tests__/scaleSchedule.test.ts but uses inline Drug
// + SwitchingRule fixtures rather than depending on switchingEngine.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/scale_schedule.dart';
import 'package:psychswitch/src/engine/types/drug.dart';
import 'package:psychswitch/src/engine/types/enums.dart';
import 'package:psychswitch/src/engine/types/schedule_step.dart';
import 'package:psychswitch/src/engine/types/switching_rule.dart';

const _emptyMetabolite = ActiveMetabolite(
  name: null,
  halfLifeHours: null,
  clinicallySignificant: false,
);
const _emptyCyp = CypInteractions(
  substrateOf: <String>[],
  inhibitorOf: <String>[],
  switchingRelevance: '',
);

Drug _drug({
  required String id,
  required List<double> increments,
  required double maxDoseMg,
  Formulation? formulation,
}) =>
    Drug(
      id: id,
      genericName: id,
      drugClass: 'antipsychotic-sga',
      malaysianBrandNames: const <String>[],
      formulation: formulation,
      halfLife: const HalfLife(meanHours: 24, rangeHours: <double>[]),
      activeMetabolite: _emptyMetabolite,
      cypInteractions: _emptyCyp,
      dosing: Dosing(
        startingDoseMg: increments.isNotEmpty ? increments.first : 0,
        typicalTargetRangeMg: const <double>[10, 20],
        maxDoseMg: maxDoseMg,
        increments: increments,
        formulationsAvailableMy: const <String>[],
      ),
      formulationNotes: '',
      citations: const <String>[],
      lastReviewedISO: '2026-04-01',
      reviewedBy: 'Test',
    );

Drug _olanzapine() => _drug(
      id: 'olanzapine',
      increments: const <double>[2.5, 5, 7.5, 10, 15, 20, 25, 30],
      maxDoseMg: 30,
    );

Drug _aripiprazole() => _drug(
      id: 'aripiprazole',
      increments: const <double>[2, 5, 10, 15, 20, 30],
      maxDoseMg: 30,
    );

Drug _lai() => _drug(
      id: 'aripiprazole-lai',
      increments: const <double>[300, 400],
      maxDoseMg: 400,
      formulation: Formulation.lai,
    );

SwitchingRule _olzToAripRule() => const SwitchingRule(
      id: 'olanzapine-aripiprazole',
      fromDrugId: 'olanzapine',
      toDrugId: 'aripiprazole',
      strategy: Strategy.crossTaper,
      rationale: 'Cross-taper.',
      durationDays: 28,
      schedule: <ScheduleStep>[
        ScheduleStep(day: 1, fromDoseMg: 20, toDoseMg: 5),
        ScheduleStep(day: 7, fromDoseMg: 15, toDoseMg: 10),
        ScheduleStep(day: 14, fromDoseMg: 10, toDoseMg: 15),
        ScheduleStep(day: 21, fromDoseMg: 5, toDoseMg: 15),
        ScheduleStep(day: 28, fromDoseMg: 0, toDoseMg: 15),
      ],
      doseRatios: DoseRatios(
        fromCurrentDoseMg: 20,
        toTargetDoseMg: 15,
        equivalencyNote: '',
      ),
      safetyFlags: <String>[],
      citations: <String>[],
      contraindications: <String>[],
      lastReviewedISO: '2026-04-01',
      reviewedBy: 'Test',
    );

SwitchingRule _aripToLaiRule() => const SwitchingRule(
      id: 'aripiprazole-aripiprazole-lai',
      fromDrugId: 'aripiprazole',
      toDrugId: 'aripiprazole-lai',
      strategy: Strategy.overlapTaper,
      rationale: 'LAI loading.',
      durationDays: 28,
      schedule: <ScheduleStep>[
        ScheduleStep(day: 1, fromDoseMg: 15, toDoseMg: 400),
        ScheduleStep(day: 14, fromDoseMg: 10, toDoseMg: 400),
        ScheduleStep(day: 28, fromDoseMg: 0, toDoseMg: 400),
      ],
      doseRatios: DoseRatios(
        fromCurrentDoseMg: 15,
        toTargetDoseMg: 400,
        equivalencyNote: '',
      ),
      safetyFlags: <String>[],
      citations: <String>[],
      contraindications: <String>[],
      lastReviewedISO: '2026-04-01',
      reviewedBy: 'Test',
    );

void main() {
  group('adaptStepNotes', () {
    test('substitutes both from-dose and to-dose mentions', () {
      expect(
        adaptStepNotes(
          'Start sertraline 50 mg. Continue agomelatine 25 mg nocte.',
          25,
          50,
          30,
          60,
        ),
        equals(
          'Start sertraline 60 mg. Continue agomelatine 30 mg nocte.',
        ),
      );
    });

    test(
      'preserves future-tense dose mentions that do not match step doses',
      () {
        final out = adaptStepNotes(
          'Stop agomelatine. Continue sertraline 50 mg. Titrate sertraline to 100 mg at 4 weeks.',
          0,
          50,
          0,
          60,
        );
        expect(out, contains('sertraline 60 mg'));
        expect(out, contains('100 mg at 4 weeks'));
      },
    );

    test('returns notes unchanged when no doses changed', () {
      const original = 'Continue sertraline 50 mg.';
      expect(adaptStepNotes(original, 50, 50, 50, 50), equals(original));
    });

    test('returns null for null input', () {
      expect(adaptStepNotes(null, 25, 50, 30, 60), isNull);
    });

    test('handles half-mg doses (regex escapes the decimal)', () {
      expect(
        adaptStepNotes('Reduce olanzapine to 7.5 mg.', 7.5, 0, 10, 0),
        equals('Reduce olanzapine to 10 mg.'),
      );
    });

    test('does not substitute numbers without "mg" suffix', () {
      expect(
        adaptStepNotes(
          'Review at 4 weeks; sertraline 50 mg ongoing.',
          0,
          50,
          0,
          60,
        ),
        equals('Review at 4 weeks; sertraline 60 mg ongoing.'),
      );
    });

    test('largest-first ordering prevents partial replacement', () {
      expect(
        adaptStepNotes(
          'Reduce X 50 mg. Reduce Y 5 mg.',
          50,
          5,
          100,
          10,
        ),
        equals('Reduce X 100 mg. Reduce Y 10 mg.'),
      );
    });

    test('strips trailing zeros in the substituted dose', () {
      expect(
        adaptStepNotes('Continue at 5 mg.', 5, 0, 10, 0),
        equals('Continue at 10 mg.'),
      );
    });
  });

  group('roundToIncrement', () {
    test('rounds to the closest entry', () {
      expect(
        roundToIncrement(22.5, const <num>[2.5, 5, 7.5, 10, 15, 20]),
        equals(20),
      );
      expect(
        roundToIncrement(7.4, const <num>[2.5, 5, 7.5, 10, 15, 20]),
        equals(7.5),
      );
      expect(
        roundToIncrement(6.7, const <num>[5, 10, 15, 20, 30]),
        equals(5),
      );
    });

    test('preserves 0 (stop signal)', () {
      expect(roundToIncrement(0, const <num>[2.5, 5, 7.5]), equals(0));
      expect(roundToIncrement(-1, const <num>[2.5, 5, 7.5]), equals(0));
    });

    test('handles empty increments gracefully', () {
      expect(roundToIncrement(7.5, const <num>[]), equals(7.5));
    });
  });

  group('pickScalingMode', () {
    test('LAI on either side → noScale', () {
      expect(
        pickScalingMode(_aripToLaiRule(), _aripiprazole(), _lai()),
        equals(ScalingMode.noScale),
      );
    });

    test('Oral → oral cross-taper defaults to proportional', () {
      expect(
        pickScalingMode(_olzToAripRule(), _olanzapine(), _aripiprazole()),
        equals(ScalingMode.proportional),
      );
    });

    test('explicit override wins', () {
      expect(
        pickScalingMode(
          _olzToAripRule(),
          _olanzapine(),
          _aripiprazole(),
          explicitMode: ScalingMode.fixedStep,
        ),
        equals(ScalingMode.fixedStep),
      );
    });
  });

  group('scaleSchedule (proportional)', () {
    test('user doses == reference → adapted: false (returns rule schedule)',
        () {
      final rule = _olzToAripRule();
      final r = scaleSchedule(
        rule: rule,
        fromDrug: _olanzapine(),
        toDrug: _aripiprazole(),
        userFromDose: rule.doseRatios.fromCurrentDoseMg,
        userToDose: rule.doseRatios.toTargetDoseMg,
      );
      expect(r.adapted, isFalse);
      expect(r.evidencePenalty, equals(0));
      // Same content as the reviewed schedule.
      expect(r.schedule.length, equals(rule.schedule.length));
      for (var i = 0; i < r.schedule.length; i++) {
        expect(r.schedule[i].fromDoseMg, equals(rule.schedule[i].fromDoseMg));
        expect(r.schedule[i].toDoseMg, equals(rule.schedule[i].toDoseMg));
      }
    });

    test('user doses differ → adapted: true + evidence penalty 1', () {
      final rule = _olzToAripRule();
      final r = scaleSchedule(
        rule: rule,
        fromDrug: _olanzapine(),
        toDrug: _aripiprazole(),
        userFromDose: rule.doseRatios.fromCurrentDoseMg * 1.5,
        userToDose: rule.doseRatios.toTargetDoseMg * 1.5,
      );
      expect(r.adapted, isTrue);
      expect(r.evidencePenalty, equals(1));
    });

    test('every adapted dose is in the drug increments OR zero', () {
      final rule = _olzToAripRule();
      final olz = _olanzapine();
      final arip = _aripiprazole();
      final r = scaleSchedule(
        rule: rule,
        fromDrug: olz,
        toDrug: arip,
        userFromDose: rule.doseRatios.fromCurrentDoseMg * 1.5,
        userToDose: rule.doseRatios.toTargetDoseMg * 1.5,
      );
      final fromIncs = olz.dosing.increments.toSet();
      final toIncs = arip.dosing.increments.toSet();
      for (final step in r.schedule) {
        expect(
          step.fromDoseMg == 0 || fromIncs.contains(step.fromDoseMg),
          isTrue,
        );
        expect(
          step.toDoseMg == 0 || toIncs.contains(step.toDoseMg),
          isTrue,
        );
      }
    });

    test('extreme scale factor produces an extreme_factor warning', () {
      final rule = _olzToAripRule();
      final r = scaleSchedule(
        rule: rule,
        fromDrug: _olanzapine(),
        toDrug: _aripiprazole(),
        userFromDose: rule.doseRatios.fromCurrentDoseMg * 3,
        userToDose: rule.doseRatios.toTargetDoseMg,
      );
      expect(
        r.warnings.any(
          (w) => w.kind == ScaleWarningKind.extremeFactorFrom,
        ),
        isTrue,
      );
    });

    test('cap-at-max generates a capped_at_max warning', () {
      final rule = _olzToAripRule();
      final olz = _olanzapine();
      final r = scaleSchedule(
        rule: rule,
        fromDrug: olz,
        toDrug: _aripiprazole(),
        userFromDose: rule.doseRatios.fromCurrentDoseMg * 5,
        userToDose: rule.doseRatios.toTargetDoseMg,
      );
      expect(
        r.warnings.any((w) => w.kind == ScaleWarningKind.cappedAtMax),
        isTrue,
      );
      for (final s in r.schedule) {
        expect(s.fromDoseMg, lessThanOrEqualTo(olz.dosing.maxDoseMg));
      }
    });

    test('rounding-to-duplicate-doses merges adjacent steps', () {
      final rule = _olzToAripRule();
      final r = scaleSchedule(
        rule: rule,
        fromDrug: _olanzapine(),
        toDrug: _aripiprazole(),
        userFromDose: rule.doseRatios.fromCurrentDoseMg * 0.25,
        userToDose: rule.doseRatios.toTargetDoseMg * 0.1,
      );
      final merged = r.warnings.any(
        (w) => w.kind == ScaleWarningKind.mergedDuplicate,
      );
      final shorter = r.schedule.length <= rule.schedule.length;
      expect(merged || shorter, isTrue);
    });

    test('invalid input returns reviewed schedule with a warning', () {
      final rule = _olzToAripRule();
      final r = scaleSchedule(
        rule: rule,
        fromDrug: _olanzapine(),
        toDrug: _aripiprazole(),
        userFromDose: 0,
        userToDose: rule.doseRatios.toTargetDoseMg,
      );
      expect(r.adapted, isFalse);
      expect(
        r.warnings.any((w) => w.kind == ScaleWarningKind.invalidInput),
        isTrue,
      );
    });
  });

  group('scaleSchedule (no-scale)', () {
    test(
      'LAI rule returns reviewed schedule untouched + no_scale warning',
      () {
        final rule = _aripToLaiRule();
        final r = scaleSchedule(
          rule: rule,
          fromDrug: _aripiprazole(),
          toDrug: _lai(),
          userFromDose: rule.doseRatios.fromCurrentDoseMg * 1.5,
          userToDose: rule.doseRatios.toTargetDoseMg,
        );
        expect(r.adapted, isFalse);
        expect(r.applied.mode, equals(ScalingMode.noScale));
        expect(
          r.warnings.any((w) => w.kind == ScaleWarningKind.noScale),
          isTrue,
        );
        // Same content as the reviewed schedule.
        expect(r.schedule.length, equals(rule.schedule.length));
      },
    );
  });

  group('ScalingMode jsonValue round-trips', () {
    test('every mode parses back', () {
      for (final m in ScalingMode.values) {
        expect(ScalingMode.fromJson(m.jsonValue), equals(m));
      }
    });
  });
}
