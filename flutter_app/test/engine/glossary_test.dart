// Tests for the Dart glossary port. Mirrors engine/__tests__/glossary.test.ts.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/glossary.dart';

void main() {
  group('glossary lookups', () {
    test('finds known terms case-insensitively', () {
      expect(lookupTerm('esrs'), isNotNull);
      expect(lookupTerm('ESRS'), isNotNull);
      expect(lookupTerm('Esrs'), isNotNull);
    });

    test('returns null for unknown terms', () {
      expect(lookupTerm('not-a-real-term'), isNull);
      expect(lookupTerm(''), isNull);
    });

    test('common abbreviations are all registered', () {
      const abbrevs = <String>[
        'QTc',
        'EPS',
        'akathisia',
        'MAOI',
        'LAI',
        'CYP2D6',
        'FBC',
        'eGFR',
      ];
      for (final term in abbrevs) {
        expect(lookupTerm(term), isNotNull, reason: 'missing: $term');
      }
    });

    test('listGlossary returns alphabetical list', () {
      final list = listGlossary();
      expect(list.length, greaterThan(15));
      for (var i = 1; i < list.length; i++) {
        expect(
          list[i].term.compareTo(list[i - 1].term),
          greaterThanOrEqualTo(0),
        );
      }
    });

    test('every entry has a non-empty definition', () {
      for (final e in listGlossary()) {
        expect(e.definition, isNotEmpty);
      }
    });

    test('lookup trims whitespace', () {
      expect(lookupTerm('  qtc  '), isNotNull);
    });

    test('relevance is preserved when present and absent when not', () {
      // 'esrs' has a relevance hint; 'ssri' does not.
      expect(lookupTerm('esrs')?.relevance, isNotNull);
      expect(lookupTerm('ssri')?.relevance, isNull);
    });
  });
}
