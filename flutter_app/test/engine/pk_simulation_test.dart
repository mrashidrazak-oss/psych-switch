// Tests for the Dart pk_simulation port.
// Mirrors engine/__tests__/pkSimulation.test.ts but uses inline Drug
// fixtures rather than loading from /content/drugs/. The values match
// the relevant fields in the canonical JSON files.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/pk_simulation.dart';
import 'package:psychswitch/src/engine/types/drug.dart';
import 'package:psychswitch/src/engine/types/schedule_step.dart';

Drug _drug({
  required String id,
  required String name,
  required double parentHalfLifeH,
  ActiveMetabolite? metabolite,
}) =>
    Drug(
      id: id,
      genericName: name,
      drugClass: 'antidepressant',
      malaysianBrandNames: const <String>[],
      halfLife: HalfLife(
        meanHours: parentHalfLifeH,
        rangeHours: const <double>[],
      ),
      activeMetabolite: metabolite ??
          const ActiveMetabolite(
            name: null,
            halfLifeHours: null,
            clinicallySignificant: false,
          ),
      cypInteractions: const CypInteractions(
        substrateOf: <String>[],
        inhibitorOf: <String>[],
        switchingRelevance: '',
      ),
      dosing: const Dosing(
        startingDoseMg: 0,
        typicalTargetRangeMg: <double>[],
        maxDoseMg: 0,
        increments: <double>[],
        formulationsAvailableMy: <String>[],
      ),
      formulationNotes: '',
      citations: const <String>[],
      lastReviewedISO: '2026-04-01',
      reviewedBy: 'Test',
    );

void main() {
  group('effectiveHalfLifeHours', () {
    test('uses parent half-life when no clinically significant metabolite',
        () {
      final sertraline = _drug(
        id: 'sertraline',
        name: 'Sertraline',
        parentHalfLifeH: 26,
      );
      expect(effectiveHalfLifeHours(sertraline), equals(26));
    });

    test(
      'extends half-life when active metabolite is clinically significant '
      '(fluoxetine)',
      () {
        final fluoxetine = _drug(
          id: 'fluoxetine',
          name: 'Fluoxetine',
          parentHalfLifeH: 72,
          metabolite: const ActiveMetabolite(
            name: 'Norfluoxetine',
            halfLifeHours: 240,
            clinicallySignificant: true,
          ),
        );
        final eff = effectiveHalfLifeHours(fluoxetine);
        expect(eff, greaterThan(72));
        expect(eff, equals(168));
      },
    );
  });

  group('simulateDailyLevels', () {
    test('starts at day-1 prescribed dose (assumes steady state at start)',
        () {
      const points = <SchedulePoint>[
        SchedulePoint(day: 1, doseMg: 100),
        SchedulePoint(day: 4, doseMg: 50),
      ];
      final sim = simulateDailyLevels(points, 26, 14);
      expect(sim[0].day, equals(1));
      expect(sim[0].prescribedDoseMg, equals(100));
      expect(sim[0].effectiveLevelMg, equals(100));
    });

    test('effective level decays exponentially toward 0 after drug stopped',
        () {
      const points = <SchedulePoint>[
        SchedulePoint(day: 1, doseMg: 100),
        SchedulePoint(day: 2, doseMg: 0),
      ];
      final sim = simulateDailyLevels(points, 24, 10);
      expect(sim[1].effectiveLevelMg, closeTo(50, 0.1));
      expect(sim[2].effectiveLevelMg, closeTo(25, 0.1));
      expect(sim[4].effectiveLevelMg, lessThan(10));
    });

    test('long-half-life drug shows long washout tail (fluoxetine)', () {
      final fluoxetine = _drug(
        id: 'fluoxetine',
        name: 'Fluoxetine',
        parentHalfLifeH: 72,
        metabolite: const ActiveMetabolite(
          name: 'Norfluoxetine',
          halfLifeHours: 240,
          clinicallySignificant: true,
        ),
      );
      const points = <SchedulePoint>[
        SchedulePoint(day: 1, doseMg: 20),
        SchedulePoint(day: 4, doseMg: 0),
      ];
      final sim = simulateDailyLevels(
        points,
        effectiveHalfLifeHours(fluoxetine),
        30,
      );
      final day18 = sim.firstWhere((p) => p.day == 18);
      expect(day18.effectiveLevelMg, greaterThan(2));
    });

    test('returns empty for empty schedule', () {
      expect(simulateDailyLevels(<SchedulePoint>[], 24, 5), isEmpty);
    });
  });

  group('simulateSwitch', () {
    test('returns matched-length from and to series with trailing days', () {
      final fromDrug = _drug(
        id: 'sertraline',
        name: 'Sertraline',
        parentHalfLifeH: 26,
      );
      final toDrug = _drug(
        id: 'escitalopram',
        name: 'Escitalopram',
        parentHalfLifeH: 30,
      );
      final schedule = <ScheduleStep>[
        const ScheduleStep(day: 1, fromDoseMg: 100, toDoseMg: 5),
        const ScheduleStep(day: 11, fromDoseMg: 0, toDoseMg: 10),
      ];
      final sim = simulateSwitch(schedule, fromDrug, toDrug);
      expect(sim.totalDays, equals(25));
      expect(sim.from.length, equals(25));
      expect(sim.to.length, equals(25));
      expect(
        sim.from.last.effectiveLevelMg,
        lessThan(sim.from.first.effectiveLevelMg),
      );
      expect(
        sim.to.last.effectiveLevelMg,
        greaterThan(sim.to.first.effectiveLevelMg),
      );
    });

    test('honours custom trailingDays', () {
      final d = _drug(id: 'x', name: 'X', parentHalfLifeH: 24);
      final schedule = <ScheduleStep>[
        const ScheduleStep(day: 1, fromDoseMg: 50, toDoseMg: 0),
        const ScheduleStep(day: 5, fromDoseMg: 0, toDoseMg: 25),
      ];
      final sim = simulateSwitch(schedule, d, d, trailingDays: 3);
      expect(sim.totalDays, equals(8));
    });
  });
}
