// Tests for the Dart citations port. Mirrors engine/__tests__/citations.test.ts
// where it exists, plus extra checks for the specific keys used by
// existing rule JSONs.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/citations.dart';

void main() {
  group('getCitation', () {
    test('curated key returns full entry with paraphrase', () {
      final c = getCitation('maudsley15_ch3_p369_table_3_7');
      expect(c.key, equals('maudsley15_ch3_p369_table_3_7'));
      expect(c.source, equals(CitationSource.maudsley15));
      expect(c.locator, contains('Ch. 3'));
      expect(c.paraphrase, isNotNull);
      expect(c.paraphrase, contains('Cross-tapering antidepressants'));
    });

    test('uncurated maudsley key falls back to pattern source', () {
      final c = getCitation('maudsley15_unknown_random_thing');
      expect(c.source, equals(CitationSource.maudsley15));
      expect(c.reference, contains('Maudsley'));
      expect(c.paraphrase, isNull);
      expect(c.locator, isNotNull); // humanized
    });

    test('manufacturer prefixes resolve via pattern', () {
      expect(getCitation('invega_xyz').source,
          equals(CitationSource.manufacturer));
      expect(getCitation('abilify_xyz').source,
          equals(CitationSource.manufacturer));
      expect(getCitation('janssen_xyz').source,
          equals(CitationSource.manufacturer));
    });

    test('cipriani prefix resolves to meta-analysis', () {
      expect(getCitation('cipriani_random').source,
          equals(CitationSource.metaAnalysis));
    });

    test('completely unknown key resolves to other', () {
      final c = getCitation('foo_bar_baz');
      expect(c.source, equals(CitationSource.other));
    });
  });

  group('gradeCitations', () {
    test('empty list → D', () {
      expect(gradeCitations(<String>[]), equals(EvidenceGrade.d));
    });

    test('single Maudsley → A', () {
      expect(
        gradeCitations(<String>['maudsley15_ch3_p369_table_3_7']),
        equals(EvidenceGrade.a),
      );
    });

    test('mixed: Maudsley + expert → picks A (best wins)', () {
      expect(
        gradeCitations(
          <String>['stahl_random', 'maudsley15_ch3_p369_table_3_7'],
        ),
        equals(EvidenceGrade.a),
      );
    });

    test('Horowitz alone → B', () {
      expect(
        gradeCitations(<String>['horowitz2020_hyperbolic_tapering']),
        equals(EvidenceGrade.b),
      );
    });

    test('Stahl alone → C', () {
      expect(
        gradeCitations(<String>['stahl_random']),
        equals(EvidenceGrade.c),
      );
    });

    test('unknown alone → D', () {
      expect(
        gradeCitations(<String>['foo_unknown']),
        equals(EvidenceGrade.d),
      );
    });
  });

  group('grade labels and descriptions', () {
    test('all 4 grades have non-empty label + description', () {
      for (final g in EvidenceGrade.values) {
        expect(gradeLabel(g), isNotEmpty);
        expect(gradeDescription(g), isNotEmpty);
      }
    });

    test('A label mentions guideline', () {
      expect(gradeLabel(EvidenceGrade.a).toLowerCase(),
          contains('guideline'));
    });
  });

  group('CitationSource jsonValue round-trips', () {
    test('every source serialises and parses identically', () {
      for (final s in CitationSource.values) {
        final back = CitationSource.fromJson(s.jsonValue);
        expect(back, equals(s));
      }
    });
  });

  group('EvidenceGrade jsonValue round-trips', () {
    test('every grade serialises and parses identically', () {
      for (final g in EvidenceGrade.values) {
        final back = EvidenceGrade.fromJson(g.jsonValue);
        expect(back, equals(g));
      }
    });
  });
}
