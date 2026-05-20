// Tests for the Dart ddi port.
// Mirrors engine/__tests__/ddi.test.ts.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/ddi.dart';

void main() {
  group('DDI checker', () {
    test('SSRI + SSRI flags serotonergic stacking', () {
      final hits = checkPair('fluoxetine', 'sertraline');
      expect(
        hits.any((h) => h.mechanism == DdiMechanism.serotonergic),
        isTrue,
      );
    });

    test('SSRI + MAOI is "avoid"', () {
      final hits = checkPair('fluoxetine', 'phenelzine');
      final hit = hits.firstWhere(
        (h) => h.mechanism == DdiMechanism.serotonergic,
      );
      expect(hit.severity, equals(DdiSeverity.avoid));
    });

    test('paroxetine + risperidone flags CYP2D6 inhibition', () {
      final hits = checkPair('paroxetine', 'risperidone');
      expect(
        hits.any((h) => h.mechanism == DdiMechanism.cypInhibition),
        isTrue,
      );
    });

    test('fluvoxamine + clozapine flags CYP1A2 inhibition', () {
      final hits = checkPair('fluvoxamine', 'clozapine');
      expect(
        hits.any((h) => h.mechanism == DdiMechanism.cypInhibition),
        isTrue,
      );
    });

    test('aripiprazole + risperidone flags pharmacodynamic conflict', () {
      final hits = checkPair('aripiprazole', 'risperidone');
      expect(
        hits.any((h) => h.mechanism == DdiMechanism.pharmacodynamic),
        isTrue,
      );
    });

    test('haloperidol + amisulpride flags QTc additive', () {
      final hits = checkPair('haloperidol', 'amisulpride');
      expect(
        hits.any((h) => h.mechanism == DdiMechanism.qtcAdditive),
        isTrue,
      );
    });

    test('olanzapine + quetiapine flags sedation additive', () {
      final hits = checkPair('olanzapine', 'quetiapine');
      expect(
        hits.any((h) => h.mechanism == DdiMechanism.sedationAdditive),
        isTrue,
      );
    });

    test('a benign pair returns no hits', () {
      expect(checkPair('lurasidone', 'agomelatine'), isEmpty);
    });

    test('checkAll considers every pair', () {
      final all = checkAll(<String>['fluoxetine', 'sertraline', 'phenelzine']);
      expect(all.length, greaterThanOrEqualTo(3));
    });

    test('severityRank ordering', () {
      expect(
        severityRank(DdiSeverity.avoid),
        greaterThan(severityRank(DdiSeverity.info)),
      );
      expect(
        severityRank(DdiSeverity.warning),
        greaterThan(severityRank(DdiSeverity.caution)),
      );
    });
  });

  group('jsonValue round-trips', () {
    test('every DdiSeverity parses back', () {
      for (final s in DdiSeverity.values) {
        expect(DdiSeverity.fromJson(s.jsonValue), equals(s));
      }
    });

    test('every DdiMechanism parses back', () {
      for (final m in DdiMechanism.values) {
        expect(DdiMechanism.fromJson(m.jsonValue), equals(m));
      }
    });
  });

  group('DdiHit.toJson', () {
    test('includes mitigation/citation when set, omits when null', () {
      final hits = checkPair('fluoxetine', 'sertraline');
      expect(hits.first.toJson()['mitigation'], isNotNull);
      expect(hits.first.toJson()['citation'], isNotNull);

      // Mirtazapine + MAOI has mitigation but NO citation.
      final mirt = checkPair('mirtazapine', 'phenelzine');
      expect(mirt.first.toJson()['mitigation'], isNotNull);
      expect(mirt.first.toJson().containsKey('citation'), isFalse);
    });
  });
}
