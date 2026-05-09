// Tests for the Dart mood_stabilizer_tapering port. No TS counterpart;
// tests focus on JSON parsing of the canonical lithium-tapering shape.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/mood_stabilizer_tapering.dart';

Map<String, dynamic> _canonicalLithiumJson() => <String, dynamic>{
      'id': 'lithium-tapering',
      'title': 'Lithium tapering protocol',
      'rationale':
          'Rapid discontinuation increases relapse risk sevenfold (Maudsley 15 ch 5).',
      'whenToConsiderStopping': <String>[
        'Sustained euthymia ≥2 years',
        'Patient preference after informed discussion',
      ],
      'withdrawalEffects': <String, dynamic>{
        'rationale':
            'Lithium withdrawal carries rebound mania risk in the first 90 days.',
        'physical': <String>['Tremor reduction', 'Polyuria resolution'],
        'psychological': <String>[
          'Rebound mania (highest risk in first 90 d)',
        ],
      },
      'tapering': <String, dynamic>{
        'principle':
            'Hyperbolic — proportional reductions, not linear.',
        'rapidVsGradual':
            'Rapid (<14 days) is unsafe in maintenance unless toxicity.',
        'initialReduction': 'Reduce by 25% of current dose every 4 weeks.',
        'minimumDoseBeforeStop':
            'Stabilise at 200 mg/day for 4 weeks before stopping.',
        'maudsleyRegimen': <String, dynamic>{
          'title': 'Maudsley 4-month taper',
          'steps': <Map<String, dynamic>>[
            <String, dynamic>{
              'phase': 'Phase 1',
              'stepDoseMg': 200,
              'interval': 'Reduce by 200 mg every 4 weeks',
              'untilDoseMg': 600,
              'notes': 'Slowest start.',
            },
            <String, dynamic>{
              'phase': 'Phase 2',
              'stepDoseMg': 100,
              'interval': 'Reduce by 100 mg every 4 weeks',
              'untilDoseMg': 200,
              'notes': 'Slow further as approaching stop.',
            },
            <String, dynamic>{
              'phase': 'Stop',
              'stepDoseMg': 0,
              'interval': '4 weeks at 200 mg, then stop',
              'untilDoseMg': 0,
              'notes': 'Final hold then discontinuation.',
            },
          ],
          'totalDurationMonths': 4,
          'totalDurationNote':
              'Maintain 12-monthly review of mood thereafter.',
        },
      },
      'monitoringDuringTaper': <String>[
        'Lithium level every 2 weeks',
        'Mood diary',
      ],
      'ifSymptomsEmerge': <String>[
        'Pause taper',
        'Re-establish previous dose',
      ],
      'neverDoThis': <String>[
        'Stop abruptly except in toxicity',
        'Skip the 200 mg hold step',
      ],
      'otherMoodStabilizers':
          'Valproate / lamotrigine / carbamazepine share the hyperbolic principle.',
      'citations': <String>['maudsley15_ch5_p331'],
      'lastReviewedISO': '2026-04-01',
      'reviewedBy': 'Test',
    };

void main() {
  group('TaperingProtocol.fromJson', () {
    test('decodes the canonical lithium payload', () {
      final p = TaperingProtocol.fromJson(_canonicalLithiumJson());
      expect(p.id, equals('lithium-tapering'));
      expect(p.tapering.maudsleyRegimen.totalDurationMonths, equals(4));
      expect(p.tapering.maudsleyRegimen.steps.length, equals(3));
      expect(p.withdrawalEffects.psychological, isNotEmpty);
      expect(p.citations, contains('maudsley15_ch5_p331'));
    });

    test('TaperStep records dose increments', () {
      final p = TaperingProtocol.fromJson(_canonicalLithiumJson());
      final phase1 = p.tapering.maudsleyRegimen.steps.first;
      expect(phase1.stepDoseMg, equals(200));
      expect(phase1.untilDoseMg, equals(600));
    });

    test('preserves enumerated lists in order', () {
      final p = TaperingProtocol.fromJson(_canonicalLithiumJson());
      expect(
        p.whenToConsiderStopping.first,
        contains('Sustained euthymia'),
      );
      expect(p.neverDoThis.first, contains('Stop abruptly'));
    });
  });
}
