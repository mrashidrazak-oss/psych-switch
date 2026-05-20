// Tests for the DSM-5-TR quick-criteria engine.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/dsm.dart';

void main() {
  group('dsmById', () {
    test('returns the expected disorders', () {
      expect(dsmById('mdd')?.name, 'Major Depressive Episode');
      expect(dsmById('gad')?.name, 'Generalized Anxiety Disorder');
      expect(dsmById('schizophrenia')?.name, 'Schizophrenia');
      expect(dsmById('ocd')?.code, 'F42');
    });

    test('null on unknown id', () {
      expect(dsmById('imaginary'), isNull);
    });
  });

  group('MDD evaluation', () {
    final mdd = dsmById('mdd')!;

    test('all-empty → no group met', () {
      final e = evaluateDsm(mdd, <String>{});
      expect(e.metAll, isFalse);
      expect(e.groups.first.met, isFalse);
      expect(e.groups.first.hits, 0);
    });

    test('5 of 9 symptoms WITHOUT mood/anhedonia → criterion A NOT met '
        '(missing core anchor)', () {
      final e = evaluateDsm(mdd, <String>{
        'mdd_a_weight', 'mdd_a_sleep', 'mdd_a_psychomotor',
        'mdd_a_fatigue', 'mdd_a_concentration',
      });
      expect(e.groups.first.hits, 5);
      expect(e.groups.first.coreHits, 0);
      expect(e.groups.first.met, isFalse);
    });

    test('5 of 9 symptoms WITH depressed mood → criterion A met', () {
      final e = evaluateDsm(mdd, <String>{
        'mdd_a_mood', 'mdd_a_weight', 'mdd_a_sleep',
        'mdd_a_psychomotor', 'mdd_a_fatigue',
      });
      expect(e.groups.first.met, isTrue);
    });

    test('full classic SIGECAPS + impairment + non-substance → meets', () {
      final e = evaluateDsm(mdd, <String>{
        'mdd_a_mood', 'mdd_a_anhedonia', 'mdd_a_sleep',
        'mdd_a_guilt', 'mdd_a_fatigue', 'mdd_a_concentration',
        'mdd_a_suicidality',
        'mdd_b_impairment',
        'mdd_c_substance',
      });
      expect(e.metAll, isTrue);
    });
  });

  group('Schizophrenia anchor item rule', () {
    final sch = dsmById('schizophrenia')!;

    test('two negative + catatonic but NO delusion/halluc/speech → '
        'criterion A not met', () {
      final e = evaluateDsm(sch, <String>{
        'sch_a_behaviour', 'sch_a_negative',
      });
      expect(e.groups.first.hits, 2);
      expect(e.groups.first.coreHits, 0);
      expect(e.groups.first.met, isFalse);
    });

    test('delusion + negative meets criterion A (one anchor + total ≥ 2)',
        () {
      final e = evaluateDsm(sch, <String>{
        'sch_a_delusions', 'sch_a_negative',
        'sch_b_function',
        'sch_c_duration',
      });
      expect(e.metAll, isTrue);
    });
  });

  group('AUD severity threshold (≥ 2 of 11)', () {
    final aud = dsmById('aud')!;

    test('1 criterion → not met', () {
      final e = evaluateDsm(aud, <String>{'aud_craving'});
      expect(e.groups.first.met, isFalse);
    });

    test('2 criteria → met (mild)', () {
      final e = evaluateDsm(aud, <String>{'aud_craving', 'aud_tolerance'});
      expect(e.groups.first.met, isTrue);
      expect(e.metAll, isTrue);
    });
  });

  test('summary text reflects met / not-met state', () {
    final mdd = dsmById('mdd')!;
    final notMet = evaluateDsm(mdd, <String>{});
    expect(notMet.summary(), contains('not all criteria met'));

    final met = evaluateDsm(mdd, <String>{
      'mdd_a_mood', 'mdd_a_anhedonia', 'mdd_a_sleep', 'mdd_a_fatigue',
      'mdd_a_guilt', 'mdd_b_impairment', 'mdd_c_substance',
    });
    expect(met.metAll, isTrue);
    expect(met.summary(), contains('appear met'));
  });

  test('every disorder has at least one group', () {
    for (final d in kDsmDisorders) {
      expect(d.groups, isNotEmpty);
    }
  });
}
