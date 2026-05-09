// Tests for the Dart maudsley15 port.
// No TS counterpart exists; the function is exercised indirectly through
// switchingEngine on the TS side.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/maudsley15.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/enums.dart';

Drug _drug(String id) => Drug(
      id: id,
      genericName: id,
      drugClass: 'antidepressant',
      malaysianBrandNames: const <String>[],
      halfLife: const HalfLife(meanHours: 24, rangeHours: <double>[]),
      activeMetabolite: const ActiveMetabolite(
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

Maudsley15Data _data() => const Maudsley15Data(
      id: 'test',
      rationale: 'Test',
      drugClassMap: <String, String>{
        'sertraline': 'ssri_other',
        'escitalopram': 'ssri_other',
        'venlafaxine': 'snri',
        'fluoxetine': 'fluoxetine',
      },
      rules: <MatrixRule>[
        MatrixRule(
          fromClass: 'ssri_other',
          toClass: 'ssri_other',
          strategy: Maudsley15Strategy.directSwitch,
          headline: 'Direct switch possible',
          detail: 'Stop one, start the other.',
          citations: <String>['maudsley15_ch3'],
        ),
        MatrixRule(
          fromClass: 'ssri_other',
          toClass: 'snri',
          strategy: Maudsley15Strategy.crossTaperCautiously,
          headline: 'Cross-taper cautiously',
          detail: 'Overlap and reduce.',
          citations: <String>['maudsley15_ch3'],
        ),
        MatrixRule(
          fromClass: 'fluoxetine',
          toClass: 'snri',
          strategy: Maudsley15Strategy.taperThenWait,
          headline: 'Stop fluoxetine, wait 14 days',
          detail: 'Long t½ requires washout.',
          waitDays: 14,
          citations: <String>['maudsley15_ch3'],
        ),
      ],
      lastReviewedISO: '2026-04-01',
      reviewedBy: 'Test',
    );

void main() {
  group('lookupMaudsley15Strategy', () {
    test('SSRI → SSRI returns directSwitch guidance', () {
      final g = lookupMaudsley15Strategy(
        _drug('sertraline'),
        _drug('escitalopram'),
        _data(),
      );
      expect(g, isNotNull);
      expect(g!.strategy, equals(Maudsley15Strategy.directSwitch));
      expect(g.headline, contains('Direct switch'));
    });

    test('SSRI → SNRI returns crossTaperCautiously', () {
      final g = lookupMaudsley15Strategy(
        _drug('sertraline'),
        _drug('venlafaxine'),
        _data(),
      );
      expect(g!.strategy, equals(Maudsley15Strategy.crossTaperCautiously));
    });

    test('Fluoxetine → SNRI returns taperThenWait with waitDays', () {
      final g = lookupMaudsley15Strategy(
        _drug('fluoxetine'),
        _drug('venlafaxine'),
        _data(),
      );
      expect(g!.strategy, equals(Maudsley15Strategy.taperThenWait));
      expect(g.waitDays, equals(14));
    });

    test('returns null when from-drug is not in class map', () {
      final g = lookupMaudsley15Strategy(
        _drug('haloperidol'),
        _drug('sertraline'),
        _data(),
      );
      expect(g, isNull);
    });

    test('returns null when no rule matches the class pair', () {
      // SNRI → fluoxetine pair has no rule in our test fixture.
      final g = lookupMaudsley15Strategy(
        _drug('venlafaxine'),
        _drug('fluoxetine'),
        _data(),
      );
      expect(g, isNull);
    });
  });

  group('Maudsley15Data.fromJson', () {
    test('round-trips a minimal payload', () {
      final raw = <String, dynamic>{
        'id': 'mat',
        'rationale': 'r',
        'drugClassMap': <String, dynamic>{'sertraline': 'ssri_other'},
        'rules': <Map<String, dynamic>>[
          <String, dynamic>{
            'fromClass': 'ssri_other',
            'toClass': 'ssri_other',
            'strategy': 'direct_switch',
            'headline': 'Direct',
            'detail': 'Stop one start the other.',
            'citations': <String>['maudsley15_ch3'],
          },
        ],
        'lastReviewedISO': '2026-04-01',
        'reviewedBy': 'Test',
      };
      final d = Maudsley15Data.fromJson(raw);
      expect(d.rules.length, equals(1));
      expect(d.rules.first.strategy, equals(Maudsley15Strategy.directSwitch));
      expect(d.drugClassMap['sertraline'], equals('ssri_other'));
    });
  });

  group('Maudsley15Guidance.toJson', () {
    test('includes waitDays when set, omits when null', () {
      const a = Maudsley15Guidance(
        strategy: Maudsley15Strategy.taperThenWait,
        headline: 'Wait',
        detail: 'D',
        waitDays: 7,
        citations: <String>['c'],
      );
      const b = Maudsley15Guidance(
        strategy: Maudsley15Strategy.directSwitch,
        headline: 'Direct',
        detail: 'D',
        citations: <String>[],
      );
      expect(a.toJson()['waitDays'], equals(7));
      expect(b.toJson().containsKey('waitDays'), isFalse);
    });
  });
}
