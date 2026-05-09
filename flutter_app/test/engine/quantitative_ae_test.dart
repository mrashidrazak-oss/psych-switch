// Tests for the Dart quantitative_ae port. No TS counterpart exists.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/quantitative_ae.dart';

void main() {
  group('quantitativeFor', () {
    test('returns multiple records for olanzapine', () {
      final effs = quantitativeFor('olanzapine');
      expect(effs.length, greaterThan(1));
      expect(effs.every((e) => e.drugId == 'olanzapine'), isTrue);
    });

    test('returns empty list for unknown drug', () {
      expect(quantitativeFor('not-a-drug'), isEmpty);
    });

    test('caller mutation does not affect the store', () {
      quantitativeFor('olanzapine').clear();
      expect(quantitativeFor('olanzapine'), isNotEmpty);
    });
  });

  group('quantitativeForAe', () {
    test('finds olanzapine weight_gain (SMD ~2.78 kg)', () {
      final e = quantitativeForAe('olanzapine', 'weight_gain');
      expect(e, isNotNull);
      expect(e!.metric, equals(EffectMetric.kg));
      expect(e.value, equals(2.78));
    });

    test('returns null when AE id not registered', () {
      expect(
        quantitativeForAe('olanzapine', 'not-an-ae'),
        isNull,
      );
    });
  });

  group('listAllQuantitative', () {
    test('contains at least 40 records', () {
      expect(listAllQuantitative().length, greaterThanOrEqualTo(40));
    });

    test('every record has a non-empty citation key', () {
      for (final e in listAllQuantitative()) {
        expect(e.citation, isNotEmpty);
      }
    });
  });

  group('formatEffect', () {
    test('OR with CI', () {
      const e = QuantitativeEffect(
        drugId: 'paroxetine',
        aeId: '_dropout_ae',
        metric: EffectMetric.or,
        value: 2.27,
        ci: EffectCi(low: 1.91, high: 2.69),
        citation: 'cipriani2018',
      );
      expect(formatEffect(e), equals('OR 2.27 (1.91–2.69)'));
    });

    test('SMD with CI', () {
      const e = QuantitativeEffect(
        drugId: 'clozapine',
        aeId: '_response',
        metric: EffectMetric.smd,
        value: -0.88,
        ci: EffectCi(low: -1.03, high: -0.73),
        citation: 'leucht2013',
      );
      expect(formatEffect(e), equals('SMD -0.88 (-1.03–-0.73)'));
    });

    test('kg with CI prepends +', () {
      const e = QuantitativeEffect(
        drugId: 'olanzapine',
        aeId: 'weight_gain',
        metric: EffectMetric.kg,
        value: 2.78,
        ci: EffectCi(low: 2.44, high: 3.13),
        citation: 'leucht2013',
      );
      expect(formatEffect(e), equals('+2.78 kg (2.44–3.13)'));
    });

    test('percent with no CI', () {
      const e = QuantitativeEffect(
        drugId: 'x',
        aeId: 'y',
        metric: EffectMetric.percent,
        value: 50,
        citation: 'c',
      );
      expect(formatEffect(e), equals('50%'));
    });

    test('OR without CI omits parentheses', () {
      const e = QuantitativeEffect(
        drugId: 'x',
        aeId: 'y',
        metric: EffectMetric.or,
        value: 1.5,
        citation: 'c',
      );
      expect(formatEffect(e), equals('OR 1.50'));
    });
  });

  group('EffectMetric jsonValue round-trips', () {
    test('every metric parses back', () {
      for (final m in EffectMetric.values) {
        expect(EffectMetric.fromJson(m.jsonValue), equals(m));
      }
    });
  });

  group('QuantitativeEffect.toJson', () {
    test('includes ci when present, omits when null', () {
      const withCi = QuantitativeEffect(
        drugId: 'a',
        aeId: 'b',
        metric: EffectMetric.or,
        value: 1.5,
        ci: EffectCi(low: 1, high: 2),
        citation: 'c',
      );
      const withoutCi = QuantitativeEffect(
        drugId: 'a',
        aeId: 'b',
        metric: EffectMetric.percent,
        value: 50,
        citation: 'c',
      );
      expect(withCi.toJson()['ci'], equals(<num>[1, 2]));
      expect(withoutCi.toJson().containsKey('ci'), isFalse);
    });
  });
}
