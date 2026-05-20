// Tests for the Dart adverse_effects port. No TS counterpart exists.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/adverse_effects.dart';

void main() {
  group('adverseEffects registry', () {
    test('every entry has a non-empty id, label, summary, and management',
        () {
      for (final ae in adverseEffects) {
        expect(ae.id, isNotEmpty);
        expect(ae.label, isNotEmpty);
        expect(ae.summary, isNotEmpty);
        expect(ae.management, isNotEmpty);
      }
    });

    test('every causedBy and switchCandidates list is non-empty', () {
      for (final ae in adverseEffects) {
        expect(ae.causedBy, isNotEmpty, reason: 'ae=${ae.id}');
        expect(ae.switchCandidates, isNotEmpty, reason: 'ae=${ae.id}');
      }
    });

    test('ids are unique', () {
      final ids = adverseEffects.map((e) => e.id).toSet();
      expect(ids.length, equals(adverseEffects.length));
    });
  });

  group('findAeFor', () {
    test('olanzapine causes weight_gain and sedation', () {
      final aes = findAeFor('olanzapine').map((e) => e.id).toSet();
      expect(aes, contains('weight_gain'));
      expect(aes, contains('sedation'));
    });

    test('category filter narrows results', () {
      final all = findAeFor('haloperidol');
      final cardio = findAeFor(
        'haloperidol',
        category: AdverseEffectCategory.cardiovascular,
      );
      expect(all.length, greaterThan(cardio.length));
      for (final ae in cardio) {
        expect(ae.category, equals(AdverseEffectCategory.cardiovascular));
      }
    });

    test('returns empty list for drug with no registered AEs', () {
      expect(findAeFor('not-a-drug'), isEmpty);
    });
  });

  group('listByCategory', () {
    test('returns a key for every category', () {
      final grouped = listByCategory();
      for (final c in AdverseEffectCategory.values) {
        expect(grouped.containsKey(c), isTrue, reason: 'category=$c');
      }
    });

    test('every AE appears under its declared category', () {
      final grouped = listByCategory();
      for (final ae in adverseEffects) {
        expect(grouped[ae.category]!.map((e) => e.id), contains(ae.id));
      }
    });
  });

  group('categoryLabels', () {
    test('every category has a non-empty label', () {
      for (final c in AdverseEffectCategory.values) {
        expect(categoryLabels[c], isNotNull);
        expect(categoryLabels[c], isNotEmpty);
      }
    });
  });

  group('AdverseEffectCategory jsonValue round-trips', () {
    test('every category serialises and parses identically', () {
      for (final c in AdverseEffectCategory.values) {
        expect(
          AdverseEffectCategory.fromJson(c.jsonValue),
          equals(c),
        );
      }
    });
  });

  group('AdverseEffect.toJson', () {
    test('includes all required keys', () {
      final json = adverseEffects.first.toJson();
      expect(json.keys, containsAll(<String>[
        'id',
        'category',
        'label',
        'summary',
        'causedBy',
        'switchCandidates',
        'management',
        'citations',
      ]));
    });
  });
}
