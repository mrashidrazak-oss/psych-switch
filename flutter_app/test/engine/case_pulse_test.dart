// Tests for the Dart case_pulse port. No TS counterpart.
// Uses inline drug fixtures + a stub SwitchingEngine.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/case_pulse.dart';
import 'package:psychswitch/src/engine/maudsley15.dart';
import 'package:psychswitch/src/engine/switching_engine.dart';
import 'package:psychswitch/src/engine/types/drug.dart';
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
const _emptyDosing = Dosing(
  startingDoseMg: 0,
  typicalTargetRangeMg: <double>[],
  maxDoseMg: 0,
  increments: <double>[],
  formulationsAvailableMy: <String>[],
);

Drug _drug(String id) => Drug(
      id: id,
      genericName: id,
      drugClass: 'antipsychotic-sga',
      malaysianBrandNames: const <String>[],
      halfLife: const HalfLife(meanHours: 24, rangeHours: <double>[]),
      activeMetabolite: _emptyMetabolite,
      cypInteractions: _emptyCyp,
      dosing: _emptyDosing,
      formulationNotes: '',
      citations: const <String>[],
      lastReviewedISO: '2026-04-01',
      reviewedBy: 'Test',
    );

SwitchingEngine _engine() => SwitchingEngine(
      drugs: <Drug>[
        _drug('olanzapine'),
        _drug('aripiprazole'),
        _drug('clozapine'),
      ],
      rules: const <SwitchingRule>[],
      maudsley15Data: const Maudsley15Data(
        id: 'm',
        rationale: '',
        drugClassMap: <String, String>{},
        rules: <MatrixRule>[],
        lastReviewedISO: '2026-04-01',
        reviewedBy: 'Test',
      ),
    );

DateTime _today() => DateTime(2026, 5, 9);

SavedCase _case({
  String id = 'case-1',
  String label = 'JD',
  String fromDrugId = 'olanzapine',
  String toDrugId = 'clozapine',
  required int daysAgo,
}) {
  final start = _today().subtract(Duration(days: daysAgo));
  return SavedCase(
    id: id,
    label: label,
    fromDrugId: fromDrugId,
    fromDoseMg: 20,
    toDrugId: toDrugId,
    toDoseMg: 200,
    startedISO: start.toIso8601String(),
    updatedISO: start.toIso8601String(),
  );
}

void main() {
  group('computeCasePulses', () {
    test('a fresh case (started today) returns at least one "today" pulse',
        () {
      // Clozapine baseline monitoring fires at day 0 → today.
      final cases = <SavedCase>[_case(daysAgo: 0)];
      final pulses = computeCasePulses(cases, _engine(), now: _today());
      expect(pulses, isNotEmpty);
      expect(
        pulses.any((p) => p.tier == PulseTier.today),
        isTrue,
      );
    });

    test('case started 7 days ago → weekly clozapine FBC fires today', () {
      final cases = <SavedCase>[_case(daysAgo: 7)];
      final pulses = computeCasePulses(cases, _engine(), now: _today());
      expect(
        pulses.any(
          (p) => p.entry.label == 'Weekly FBC' && p.tier == PulseTier.today,
        ),
        isTrue,
      );
    });

    test('case started 5 days ago → weekly FBC is "soon" (2 days away)',
        () {
      final cases = <SavedCase>[_case(daysAgo: 5)];
      final pulses = computeCasePulses(cases, _engine(), now: _today());
      expect(
        pulses.any(
          (p) => p.entry.label == 'Weekly FBC' && p.tier == PulseTier.soon,
        ),
        isTrue,
      );
    });

    test('case started 14 days ago → first weekly FBC was overdue', () {
      // Day 7 monitoring entry fired 7 days ago = overdue (within 14 d).
      final cases = <SavedCase>[_case(daysAgo: 14)];
      final pulses = computeCasePulses(cases, _engine(), now: _today());
      expect(
        pulses.any(
          (p) =>
              p.entry.label == 'Weekly FBC' && p.tier == PulseTier.overdue,
        ),
        isTrue,
      );
    });

    test('cases with unknown drug ids are silently skipped', () {
      final cases = <SavedCase>[
        _case(fromDrugId: 'not-a-drug', daysAgo: 0),
      ];
      final pulses = computeCasePulses(cases, _engine(), now: _today());
      expect(pulses, isEmpty);
    });

    test('falls back to "from → to" label when label is empty', () {
      final cases = <SavedCase>[
        SavedCase(
          id: 'c',
          label: '',
          fromDrugId: 'olanzapine',
          fromDoseMg: 20,
          toDrugId: 'clozapine',
          toDoseMg: 200,
          startedISO: _today().toIso8601String(),
          updatedISO: _today().toIso8601String(),
        ),
      ];
      final pulses = computeCasePulses(cases, _engine(), now: _today());
      expect(pulses, isNotEmpty);
      expect(pulses.first.caseLabel, contains('olanzapine'));
      expect(pulses.first.caseLabel, contains('clozapine'));
    });

    test('output is sorted: overdue → today → soon, then by daysFromNow',
        () {
      final cases = <SavedCase>[
        _case(id: 'old', daysAgo: 14),
        _case(id: 'fresh', daysAgo: 0),
      ];
      final pulses = computeCasePulses(cases, _engine(), now: _today());
      // Tier rank monotonically non-decreasing.
      const tierRank = <PulseTier, int>{
        PulseTier.overdue: 0,
        PulseTier.today: 1,
        PulseTier.soon: 2,
      };
      for (var i = 1; i < pulses.length; i++) {
        expect(
          tierRank[pulses[i].tier],
          greaterThanOrEqualTo(tierRank[pulses[i - 1].tier] ?? 0),
        );
      }
    });

    test('invalid startedISO returns no pulses for that case', () {
      final cases = <SavedCase>[
        SavedCase(
          id: 'bad',
          label: 'X',
          fromDrugId: 'olanzapine',
          fromDoseMg: 20,
          toDrugId: 'aripiprazole',
          toDoseMg: 15,
          startedISO: 'not-a-date',
          updatedISO: _today().toIso8601String(),
        ),
      ];
      final pulses = computeCasePulses(cases, _engine(), now: _today());
      expect(pulses, isEmpty);
    });
  });

  group('pulseCountsByTier', () {
    test('returns zeros for all tiers when input is empty', () {
      final counts = pulseCountsByTier(<CasePulse>[]);
      expect(counts[PulseTier.overdue], equals(0));
      expect(counts[PulseTier.today], equals(0));
      expect(counts[PulseTier.soon], equals(0));
    });

    test('counts buckets correctly', () {
      final cases = <SavedCase>[_case(daysAgo: 14)];
      final pulses = computeCasePulses(cases, _engine(), now: _today());
      final counts = pulseCountsByTier(pulses);
      // Total equals input length.
      final total = counts.values.reduce((a, b) => a + b);
      expect(total, equals(pulses.length));
    });
  });

  group('pulseTierLabel', () {
    test('every tier has a non-empty label', () {
      for (final t in PulseTier.values) {
        expect(pulseTierLabel(t), isNotEmpty);
      }
    });

    test('soon → "This week"', () {
      expect(pulseTierLabel(PulseTier.soon), equals('This week'));
    });
  });

  group('PulseTier jsonValue round-trips', () {
    test('every tier parses back', () {
      for (final t in PulseTier.values) {
        expect(PulseTier.fromJson(t.jsonValue), equals(t));
      }
    });
  });
}
