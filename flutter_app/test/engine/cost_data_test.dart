// Tests for the Dart cost_data port. No TS counterpart exists, so this
// is a fresh suite that pins behaviour we rely on elsewhere.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/cost_data.dart';

void main() {
  group('costFor', () {
    test('returns entry for known drugs', () {
      final f = costFor('fluoxetine');
      expect(f, isNotNull);
      expect(f!.tier, equals(CostTier.subsidised));
      expect(f.monthlyCostMyr, equals(8));
      expect(f.channel, equals(CostChannel.both));
    });

    test('returns null for unknown drugs', () {
      expect(costFor('not-a-drug'), isNull);
      expect(costFor(''), isNull);
    });

    test('LAI ids resolve to LAI cost rows (not oral)', () {
      final lai = costFor('paliperidone-lai');
      final oral = costFor('paliperidone');
      expect(lai, isNotNull);
      expect(oral, isNotNull);
      expect(lai!.monthlyCostMyr, isNot(equals(oral!.monthlyCostMyr)));
    });
  });

  group('listCostEntries', () {
    test('returns at least the registered drug count', () {
      expect(listCostEntries().length, greaterThanOrEqualTo(30));
    });

    test('returns a fresh list (caller mutation does not affect store)', () {
      listCostEntries().clear();
      expect(listCostEntries(), isNotEmpty);
    });

    test('every entry has a non-empty ISO review date', () {
      for (final e in listCostEntries()) {
        expect(e.lastReviewedISO, isNotEmpty);
      }
    });
  });

  group('tierLabel', () {
    test('all tiers return non-empty labels', () {
      for (final t in CostTier.values) {
        expect(tierLabel(t), isNotEmpty);
      }
    });

    test('expensive label is "Expensive"', () {
      expect(tierLabel(CostTier.expensive), equals('Expensive'));
    });
  });

  group('tierColorToken', () {
    test('subsidised → to, expensive → danger', () {
      expect(tierColorToken(CostTier.subsidised), equals('to'));
      expect(tierColorToken(CostTier.affordable), equals('accent'));
      expect(tierColorToken(CostTier.moderate), equals('warning'));
      expect(tierColorToken(CostTier.expensive), equals('danger'));
    });
  });

  group('formatMyr', () {
    test('integer amount: no decimals', () {
      expect(formatMyr(60), equals('RM 60'));
    });

    test('non-integer amount: rounded to nearest int', () {
      expect(formatMyr(60.4), equals('RM 60'));
      expect(formatMyr(60.6), equals('RM 61'));
    });

    test('zero', () {
      expect(formatMyr(0), equals('RM 0'));
    });
  });

  group('CostTier and CostChannel jsonValue round-trips', () {
    test('every tier serialises and parses identically', () {
      for (final t in CostTier.values) {
        expect(CostTier.fromJson(t.jsonValue), equals(t));
      }
    });

    test('every channel serialises and parses identically', () {
      for (final c in CostChannel.values) {
        expect(CostChannel.fromJson(c.jsonValue), equals(c));
      }
    });
  });

  group('CostEntry.toJson', () {
    test('omits note when null and includes when set', () {
      final withNote = costFor('fluoxetine')!;
      final withoutNote = costFor('sertraline')!;
      expect(withNote.toJson()['note'], isNotNull);
      expect(withoutNote.toJson().containsKey('note'), isFalse);
    });

    test('serialises tier and channel as JSON literals', () {
      final j = costFor('fluoxetine')!.toJson();
      expect(j['tier'], equals('subsidised'));
      expect(j['channel'], equals('both'));
    });
  });
}
