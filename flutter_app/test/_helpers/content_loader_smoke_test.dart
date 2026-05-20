// Smoke test for the test content loader.
//
// Asserts that every drug + rule + the Maudsley matrix in /content/
// parses cleanly through the Dart engine types — i.e. the schema
// matches what the engine consumes. This catches content drift the
// instant a JSON file diverges from the strict Dart type.

import 'package:flutter_test/flutter_test.dart';

import 'content_loader.dart';

void main() {
  group('content loader', () {
    test('loadAllDrugs parses every drug JSON', () {
      final drugs = loadAllDrugs();
      expect(drugs.length, equals(40));
      // Every id is non-empty and the registry includes the canonical
      // antidepressants + clozapine.
      final ids = drugs.map((d) => d.id).toSet();
      expect(ids, contains('sertraline'));
      expect(ids, contains('escitalopram'));
      expect(ids, contains('clozapine'));
      expect(ids, contains('moclobemide'));
      expect(ids.length, equals(drugs.length));
    });

    test('loadAllSwitchingRules parses 126 of 133 (skips 7 LAI rules)',
        () {
      final rules = loadAllSwitchingRules();
      // 133 total minus the 7 LAI-to-oral rules whose safetyFlags ship
      // as object arrays (see POST_FLUTTER_DEBT.md).
      expect(rules.length, equals(126));
      // Spot-check that a high-stakes rule made it through.
      expect(
        rules.any((r) => r.id == 'olanzapine-to-aripiprazole'),
        isTrue,
      );
      expect(
        rules.any((r) => r.id == 'paroxetine-to-sertraline'),
        isTrue,
      );
    });

    test('loadMaudsley15 returns matrix with class map + rules', () {
      final m = loadMaudsley15();
      expect(m.drugClassMap, isNotEmpty);
      expect(m.rules, isNotEmpty);
      // Sertraline is mapped to ssri_other in the matrix.
      expect(m.drugClassMap['sertraline'], equals('ssri_other'));
    });

    test('loadSwitchingEngine assembles a working engine', () {
      final engine = loadSwitchingEngine();
      expect(engine.listAllDrugs().length, equals(40));
      expect(engine.listRules(), isNotEmpty);
      // Sanity: an unscoped drug is found via getDrug.
      expect(engine.getDrug('sertraline'), isNotNull);
    });
  });
}
