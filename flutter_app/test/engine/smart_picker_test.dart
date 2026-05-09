// Tests for the Dart smart_picker port.
// Mirrors engine/__tests__/smartPicker.test.ts but uses inline Drug
// + SwitchingRule fixtures rather than depending on switchingEngine.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/patient_context_pure.dart';
import 'package:psychswitch/src/engine/smart_picker.dart';
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

SwitchingRule _rule(String fromId, String toId) => SwitchingRule(
      id: '$fromId-to-$toId',
      fromDrugId: fromId,
      toDrugId: toId,
      strategy: Strategy.crossTaper,
      rationale: 'Cross-taper',
      durationDays: 28,
      schedule: const <ScheduleStep>[],
      doseRatios: const DoseRatios(
        fromCurrentDoseMg: 20,
        toTargetDoseMg: 15,
        equivalencyNote: '',
      ),
      safetyFlags: const <String>[],
      citations: const <String>[],
      contraindications: const <String>[],
      lastReviewedISO: '2026-04-01',
      reviewedBy: 'Test',
    );

void main() {
  final allDrugs = <Drug>[
    _drug('olanzapine'),
    _drug('aripiprazole'),
    _drug('quetiapine'),
    _drug('lithium'),
    _drug('paroxetine'),
    _drug('fluoxetine'),
    _drug('sertraline'),
    _drug('phenelzine'),
  ];

  final reviewedRules = <SwitchingRule>[
    _rule('olanzapine', 'aripiprazole'),
    _rule('olanzapine', 'quetiapine'),
  ];

  group('rankDrugs', () {
    test('reviewed pairs float to "reviewed" tier', () {
      final ranked = rankDrugs(
        allDrugs,
        RankInput(rules: reviewedRules, fromDrugId: 'olanzapine'),
      );
      final arip = ranked.firstWhere((r) => r.drug.id == 'aripiprazole');
      expect(
        <RelevanceTier>[RelevanceTier.reviewed, RelevanceTier.top],
        contains(arip.tier),
      );
      expect(arip.tags, contains('Reviewed'));
    });

    test('without fromDrugId, no drug is "reviewed" or "top"', () {
      final ranked = rankDrugs(
        allDrugs,
        RankInput(rules: reviewedRules),
      );
      expect(
        ranked.every(
          (r) =>
              r.tier != RelevanceTier.reviewed &&
              r.tier != RelevanceTier.top,
        ),
        isTrue,
      );
    });

    test('lithium ranked "avoid" with severe CKD context', () {
      final ranked = rankDrugs(
        <Drug>[_drug('lithium')],
        RankInput(
          rules: reviewedRules,
          fromDrugId: 'valproate',
          context: const PatientContext(renal: RenalFn.severe),
        ),
      );
      final li = ranked.firstWhere((r) => r.drug.id == 'lithium');
      expect(li.tier, equals(RelevanceTier.avoid));
      expect(li.blocked, isTrue);
    });

    test('AE filter promotes switch candidates', () {
      // Patient has weight gain on olanzapine; aripiprazole is in
      // switchCandidates for weight_gain.
      final ranked = rankDrugs(
        allDrugs,
        RankInput(
          rules: reviewedRules,
          fromDrugId: 'olanzapine',
          avoidAeId: 'weight_gain',
        ),
      );
      final arip = ranked.firstWhere((r) => r.drug.id == 'aripiprazole');
      expect(
        arip.tier == RelevanceTier.top ||
            arip.tier == RelevanceTier.reviewed,
        isTrue,
      );
    });

    test('AE filter demotes culprit drugs', () {
      final ranked = rankDrugs(
        allDrugs,
        RankInput(
          rules: reviewedRules,
          fromDrugId: 'sertraline',
          avoidAeId: 'weight_gain',
        ),
      );
      final olz = ranked.firstWhere((r) => r.drug.id == 'olanzapine');
      expect(olz.tags.any((t) => t.startsWith('causes')), isTrue);
    });

    test('SSRI + MAOI ddi-avoid blocks the pair', () {
      final ranked = rankDrugs(
        <Drug>[_drug('phenelzine')],
        RankInput(rules: reviewedRules, fromDrugId: 'fluoxetine'),
      );
      final ph = ranked.firstWhere((r) => r.drug.id == 'phenelzine');
      expect(ph.tier, equals(RelevanceTier.avoid));
      expect(ph.blocked, isTrue);
    });

    test('result is sorted by tier rank (non-increasing)', () {
      final ranked = rankDrugs(
        allDrugs,
        RankInput(rules: reviewedRules, fromDrugId: 'olanzapine'),
      );
      final ranks = ranked
          .map((r) => switch (r.tier) {
                RelevanceTier.top => 4,
                RelevanceTier.reviewed => 3,
                RelevanceTier.fallback => 2,
                RelevanceTier.caution => 1,
                RelevanceTier.avoid => 0,
              })
          .toList();
      for (var i = 1; i < ranks.length; i++) {
        expect(ranks[i], lessThanOrEqualTo(ranks[i - 1]));
      }
    });
  });

  group('RelevanceTier jsonValue round-trips', () {
    test('every tier parses back', () {
      for (final t in RelevanceTier.values) {
        expect(RelevanceTier.fromJson(t.jsonValue), equals(t));
      }
    });
  });
}
