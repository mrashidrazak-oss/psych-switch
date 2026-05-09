// Tests for the Dart discontinuation port.
// Mirrors engine/__tests__/discontinuation.test.ts.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/discontinuation.dart';

void main() {
  group('discontinuation flagger', () {
    test('paroxetine = veryHigh severity', () {
      final f = getDiscontinuationFlag('paroxetine');
      expect(f?.severity, equals(DiscontinuationSeverity.veryHigh));
      expect(f?.halfLifeHours, equals(21));
    });

    test('venlafaxine bridge-to-fluoxetine strategy', () {
      final f = getDiscontinuationFlag('venlafaxine');
      expect(f?.severity, equals(DiscontinuationSeverity.veryHigh));
      expect(f?.strategy.toLowerCase(), contains('fluoxetine'));
    });

    test('fluoxetine itself = low (long t½ self-tapers)', () {
      expect(
        getDiscontinuationFlag('fluoxetine')?.severity,
        equals(DiscontinuationSeverity.low),
      );
    });

    test('clozapine = veryHigh (rebound psychosis)', () {
      final f = getDiscontinuationFlag('clozapine');
      expect(f?.severity, equals(DiscontinuationSeverity.veryHigh));
      expect(f?.symptoms.toLowerCase(), contains('rebound'));
    });

    test('unknown drug returns null', () {
      expect(getDiscontinuationFlag('imaginary'), isNull);
    });

    test('severityRank ordering', () {
      expect(
        severityRank(DiscontinuationSeverity.veryHigh),
        greaterThan(severityRank(DiscontinuationSeverity.low)),
      );
      expect(
        severityRank(DiscontinuationSeverity.high),
        greaterThan(severityRank(DiscontinuationSeverity.moderate)),
      );
    });
  });

  group('DiscontinuationSeverity jsonValue round-trips', () {
    test('every severity parses back', () {
      for (final s in DiscontinuationSeverity.values) {
        expect(DiscontinuationSeverity.fromJson(s.jsonValue), equals(s));
      }
    });
  });

  group('DiscontinuationFlag.toJson', () {
    test('omits halfLifeHours and citation when null', () {
      final f = getDiscontinuationFlag('agomelatine')!;
      final j = f.toJson();
      expect(j.containsKey('halfLifeHours'), isFalse);
      expect(j.containsKey('citation'), isFalse);
    });

    test('includes halfLifeHours and citation when set', () {
      final f = getDiscontinuationFlag('paroxetine')!;
      final j = f.toJson();
      expect(j['halfLifeHours'], equals(21));
      expect(j['citation'], isNotNull);
    });
  });
}
