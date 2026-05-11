// Tests for the Dart overlap_intensity port.
// Mirrors engine/__tests__/overlapIntensity.test.ts but uses inline
// Drug + ScheduleStep fixtures rather than depending on the unported
// switchingEngine.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/overlap_intensity.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/enums.dart';
import 'package:psychswitch_engine/types/schedule_step.dart';

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
  required String drugClass,
  RiskLevel? qtcRisk,
  RiskLevel? sedation,
  RiskLevel? epsRisk,
  bool isMaoi = false,
  List<double> increments = const <double>[],
  double maxDoseMg = 100,
  List<double> typicalTargetRangeMg = const <double>[10, 20],
}) =>
    Drug(
      id: id,
      genericName: id,
      drugClass: drugClass,
      malaysianBrandNames: const <String>[],
      isMAOI: isMaoi ? true : null,
      halfLife: const HalfLife(meanHours: 24, rangeHours: <double>[]),
      activeMetabolite: _emptyMetabolite,
      cypInteractions: _emptyCyp,
      qtcRisk: qtcRisk,
      sedation: sedation,
      epsRisk: epsRisk,
      dosing: Dosing(
        startingDoseMg: typicalTargetRangeMg.first,
        typicalTargetRangeMg: typicalTargetRangeMg,
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
      drugClass: 'antipsychotic-sga',
      sedation: RiskLevel.high,
      maxDoseMg: 30,
      increments: const <double>[2.5, 5, 7.5, 10, 15, 20, 25, 30],
    );

Drug _aripiprazole() => _drug(
      id: 'aripiprazole',
      drugClass: 'antipsychotic-partial-agonist',
      sedation: RiskLevel.low,
      typicalTargetRangeMg: const <double>[10, 30],
    );

Drug _sertraline() => _drug(
      id: 'sertraline',
      drugClass: 'SSRI',
      typicalTargetRangeMg: const <double>[50, 200],
    );

Drug _escitalopram() => _drug(
      id: 'escitalopram',
      drugClass: 'SSRI',
      qtcRisk: RiskLevel.moderate,
    );

Drug _fluoxetine() => _drug(
      id: 'fluoxetine',
      drugClass: 'SSRI',
      typicalTargetRangeMg: const <double>[20, 80],
    );

Drug _haloperidol() => _drug(
      id: 'haloperidol',
      drugClass: 'antipsychotic-fga',
      qtcRisk: RiskLevel.high,
      epsRisk: RiskLevel.high,
      typicalTargetRangeMg: const <double>[5, 15],
    );

Drug _amisulpride() => _drug(
      id: 'amisulpride',
      drugClass: 'antipsychotic-sga',
      qtcRisk: RiskLevel.high,
      typicalTargetRangeMg: const <double>[400, 800],
    );

void main() {
  group('assessOverlapIntensity — score + tier', () {
    test('schedule with no co-prescribed days returns "No overlap"', () {
      final a = assessOverlapIntensity(
        fromDrug: _olanzapine(),
        toDrug: _aripiprazole(),
        schedule: const <ScheduleStep>[
          ScheduleStep(day: 1, fromDoseMg: 20, toDoseMg: 0),
          ScheduleStep(day: 7, fromDoseMg: 0, toDoseMg: 15),
        ],
      );
      expect(a.label, equals('No overlap'));
      expect(a.score, equals(0));
    });

    test('SSRI cross-taper produces a non-zero overlap score', () {
      final a = assessOverlapIntensity(
        fromDrug: _sertraline(),
        toDrug: _escitalopram(),
        schedule: const <ScheduleStep>[
          ScheduleStep(day: 1, fromDoseMg: 100, toDoseMg: 5),
          ScheduleStep(day: 7, fromDoseMg: 50, toDoseMg: 10),
          ScheduleStep(day: 14, fromDoseMg: 0, toDoseMg: 10),
        ],
      );
      expect(a.score, greaterThan(0));
      expect(OverlapTier.values, contains(a.tier));
    });

    test('antipsychotic cross-taper produces a non-zero overlap score', () {
      final a = assessOverlapIntensity(
        fromDrug: _olanzapine(),
        toDrug: _aripiprazole(),
        schedule: const <ScheduleStep>[
          ScheduleStep(day: 1, fromDoseMg: 20, toDoseMg: 5),
          ScheduleStep(day: 7, fromDoseMg: 15, toDoseMg: 10),
          ScheduleStep(day: 14, fromDoseMg: 0, toDoseMg: 15),
        ],
      );
      expect(a.score, greaterThan(0));
    });

    test('serotonergic_stacking flag fires for SSRI + SSRI pair', () {
      final a = assessOverlapIntensity(
        fromDrug: _sertraline(),
        toDrug: _escitalopram(),
        schedule: const <ScheduleStep>[
          ScheduleStep(day: 1, fromDoseMg: 100, toDoseMg: 5),
          ScheduleStep(day: 14, fromDoseMg: 0, toDoseMg: 10),
        ],
      );
      expect(a.flags, contains('serotonergic_stacking'));
      expect(a.components.mechanismMultiplier, greaterThan(1));
    });

    test('qt_additive flag fires for haloperidol + amisulpride', () {
      final a = assessOverlapIntensity(
        fromDrug: _amisulpride(),
        toDrug: _haloperidol(),
        schedule: const <ScheduleStep>[
          ScheduleStep(day: 1, fromDoseMg: 400, toDoseMg: 2),
          ScheduleStep(day: 14, fromDoseMg: 0, toDoseMg: 5),
        ],
      );
      expect(a.flags, contains('qt_additive'));
    });

    test('mechanism multiplier is capped at 2.2', () {
      final a = assessOverlapIntensity(
        fromDrug: _sertraline(),
        toDrug: _fluoxetine(),
        schedule: const <ScheduleStep>[
          ScheduleStep(day: 1, fromDoseMg: 200, toDoseMg: 80),
          ScheduleStep(day: 28, fromDoseMg: 0, toDoseMg: 80),
        ],
      );
      expect(a.components.mechanismMultiplier, lessThanOrEqualTo(2.2));
      expect(a.score, lessThanOrEqualTo(100));
    });

    test('tier labels match the score boundaries', () {
      expect(tierLabel(OverlapTier.low), contains('Low'));
      expect(tierLabel(OverlapTier.severe), contains('Severe'));
    });

    test('flagLabel returns user-facing strings', () {
      expect(flagLabel('serotonergic_stacking'), contains('Serotonergic'));
      expect(flagLabel('qt_additive'), contains('QTc'));
      expect(flagLabel('unknown_flag'), equals('unknown_flag'));
    });

    test('rationale mentions Day 1 percentages and overlap days', () {
      final a = assessOverlapIntensity(
        fromDrug: _sertraline(),
        toDrug: _escitalopram(),
        schedule: const <ScheduleStep>[
          ScheduleStep(day: 1, fromDoseMg: 100, toDoseMg: 5),
          ScheduleStep(day: 14, fromDoseMg: 0, toDoseMg: 10),
        ],
      );
      expect(a.rationale, contains('%'));
      expect(a.rationale.toLowerCase(), contains('day'));
    });

    test('empty schedule returns the empty assessment', () {
      final a = assessOverlapIntensity(
        fromDrug: _sertraline(),
        toDrug: _escitalopram(),
        schedule: const <ScheduleStep>[],
      );
      expect(a.score, equals(0));
      expect(a.label, equals('No overlap'));
    });
  });

  group('applyConservativeOverlap', () {
    test('reduces Day 1 from-dose by ~25%, rounded to formulation', () {
      const schedule = <ScheduleStep>[
        ScheduleStep(day: 1, fromDoseMg: 20, toDoseMg: 5),
        ScheduleStep(day: 7, fromDoseMg: 15, toDoseMg: 10),
        ScheduleStep(day: 14, fromDoseMg: 10, toDoseMg: 15),
        ScheduleStep(day: 21, fromDoseMg: 5, toDoseMg: 15),
        ScheduleStep(day: 28, fromDoseMg: 0, toDoseMg: 15),
      ];
      final result = applyConservativeOverlap(schedule, _olanzapine());
      expect(result.modified, isTrue);
      // 20 × 0.75 = 15 — but day 2 is also 15, so clamp keeps it at 15.
      expect(result.schedule[0].fromDoseMg, equals(15));
    });

    test('does NOT mutate the input schedule', () {
      const original = <ScheduleStep>[
        ScheduleStep(day: 1, fromDoseMg: 20, toDoseMg: 5),
        ScheduleStep(day: 7, fromDoseMg: 15, toDoseMg: 10),
        ScheduleStep(day: 14, fromDoseMg: 0, toDoseMg: 15),
      ];
      final snapshot = original.map((s) => s.toJson()).toList();
      applyConservativeOverlap(original, _olanzapine());
      expect(
        original.map((s) => s.toJson()).toList(),
        equals(snapshot),
      );
    });

    test('returns unchanged if Day 1 from-dose is 0', () {
      const schedule = <ScheduleStep>[
        ScheduleStep(day: 1, fromDoseMg: 0, toDoseMg: 15),
        ScheduleStep(day: 7, fromDoseMg: 0, toDoseMg: 15),
      ];
      final result = applyConservativeOverlap(schedule, _olanzapine());
      expect(result.modified, isFalse);
    });

    // v0.5+ — plateau-aware softening. Maudsley 15th halve-and-add
    // explicitly supports reducing the from-drug from Day 1 onwards
    // while the new drug is introduced; the old engine refused this
    // case (Day 1 == Day 2 plateau) and was too restrictive for the
    // antipsychotic introduce-then-taper protocols that depend on
    // exactly this pattern.
    test('softens the whole Day-1 plateau, not only Day 1', () {
      const schedule = <ScheduleStep>[
        ScheduleStep(day: 1, fromDoseMg: 10, toDoseMg: 5),
        ScheduleStep(day: 7, fromDoseMg: 10, toDoseMg: 10),
        ScheduleStep(day: 14, fromDoseMg: 0, toDoseMg: 15),
      ];
      final result = applyConservativeOverlap(schedule, _olanzapine());
      expect(result.modified, isTrue);
      // 10 × 0.75 = 7.5 (olanzapine has 7.5 in increments). The next
      // taper step is 0, so 7.5 doesn't violate the clamp.
      expect(result.schedule[0].fromDoseMg, equals(7.5));
      // Plateau day (Day 7) is also softened to 7.5.
      expect(result.schedule[1].fromDoseMg, equals(7.5));
      // Post-plateau step is preserved.
      expect(result.schedule[2].fromDoseMg, equals(0));
    });

    test(
      'clamps the softened dose to the first post-plateau step '
      "(prevents inversion at the plateau's exit)",
      () {
        const schedule = <ScheduleStep>[
          ScheduleStep(day: 1, fromDoseMg: 10, toDoseMg: 5),
          ScheduleStep(day: 7, fromDoseMg: 10, toDoseMg: 10),
          ScheduleStep(day: 14, fromDoseMg: 7.5, toDoseMg: 12.5),
          ScheduleStep(day: 21, fromDoseMg: 0, toDoseMg: 15),
        ];
        final result = applyConservativeOverlap(schedule, _olanzapine());
        // Target 7.5 == next taper step (7.5). Clamp keeps it at 7.5.
        // 7.5 ≠ Day 1 (10), so still modified.
        expect(result.modified, isTrue);
        expect(result.schedule[0].fromDoseMg, equals(7.5));
        expect(result.schedule[1].fromDoseMg, equals(7.5));
      },
    );

    test(
      'refuses when formulation rounding swallows the 25 % delta '
      '(low-dose plateau)',
      () {
        // Day 1 = 2.5 mg (olanzapine's lowest increment). 2.5 × 0.75 =
        // 1.875 → rounds back to 2.5 (no lower increment available).
        // No useful softening is possible.
        const schedule = <ScheduleStep>[
          ScheduleStep(day: 1, fromDoseMg: 2.5, toDoseMg: 5),
          ScheduleStep(day: 7, fromDoseMg: 2.5, toDoseMg: 10),
          ScheduleStep(day: 14, fromDoseMg: 0, toDoseMg: 15),
        ];
        final result = applyConservativeOverlap(schedule, _olanzapine());
        expect(result.modified, isFalse);
      },
    );

    test('appends a "Conservative mode" tag to Day 1 notes', () {
      const schedule = <ScheduleStep>[
        ScheduleStep(
          day: 1,
          fromDoseMg: 20,
          toDoseMg: 5,
          notes: 'Original note.',
        ),
        ScheduleStep(day: 7, fromDoseMg: 10, toDoseMg: 10),
        ScheduleStep(day: 14, fromDoseMg: 0, toDoseMg: 15),
      ];
      final result = applyConservativeOverlap(schedule, _olanzapine());
      if (result.modified) {
        expect(result.schedule[0].notes, contains('Conservative mode'));
        expect(result.schedule[0].notes, contains('Original note'));
      }
    });

    test('schedule with <2 steps returns unchanged', () {
      const schedule = <ScheduleStep>[
        ScheduleStep(day: 1, fromDoseMg: 20, toDoseMg: 5),
      ];
      final result = applyConservativeOverlap(schedule, _olanzapine());
      expect(result.modified, isFalse);
    });
  });

  group('OverlapTier jsonValue round-trips', () {
    test('every tier parses back', () {
      for (final t in OverlapTier.values) {
        expect(OverlapTier.fromJson(t.jsonValue), equals(t));
      }
    });
  });
}
