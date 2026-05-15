// Tests for the anticholinergic-burden (ACB) engine. Locks in the
// scoring tiers and aggregate category thresholds so any future
// edits to `_acbTable` deliberately update these tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/anticholinergic.dart';

void main() {
  group('acbTierFor', () {
    test('classic TCA → definite severe (score 3)', () {
      expect(acbTierFor('amitriptyline'), AcbTier.definiteSevere);
      expect(acbTierFor('amitriptyline').score, 3);
    });

    test('paroxetine — most AC of the SSRIs → definite low (score 2)', () {
      expect(acbTierFor('paroxetine'), AcbTier.definiteLow);
      expect(acbTierFor('paroxetine').score, 2);
    });

    test('sertraline / escitalopram → none (score 0)', () {
      expect(acbTierFor('sertraline'), AcbTier.none);
      expect(acbTierFor('escitalopram'), AcbTier.none);
    });

    test('clozapine → definite severe (score 3)', () {
      expect(acbTierFor('clozapine'), AcbTier.definiteSevere);
    });

    test('aripiprazole → none', () {
      expect(acbTierFor('aripiprazole'), AcbTier.none);
    });

    test('unknown drug id → none (conservative default)', () {
      expect(acbTierFor('imaginary-drug-xyz'), AcbTier.none);
    });

    test('lookup is case-insensitive', () {
      expect(acbTierFor('AmiTrIpTyLiNe'), AcbTier.definiteSevere);
    });
  });

  group('assessAnticholinergicBurden', () {
    test('empty regimen → none category, zero total', () {
      final a = assessAnticholinergicBurden(<String>[]);
      expect(a.totalScore, 0);
      expect(a.category, AcbCategory.none);
      expect(a.entries, isEmpty);
    });

    test('single low-burden SSRI → low category', () {
      final a = assessAnticholinergicBurden(<String>['paroxetine']);
      expect(a.totalScore, 2);
      expect(a.category, AcbCategory.low);
    });

    test('amitriptyline + clozapine → high category (6)', () {
      final a = assessAnticholinergicBurden(
        <String>['amitriptyline', 'clozapine'],
      );
      expect(a.totalScore, 6);
      expect(a.category, AcbCategory.high);
    });

    test('threshold: total 3 → moderate', () {
      final a = assessAnticholinergicBurden(
        <String>['olanzapine', 'risperidone'],
      ); // 2 + 1
      expect(a.totalScore, 3);
      expect(a.category, AcbCategory.moderate);
    });

    test('threshold: total 5 → high', () {
      final a = assessAnticholinergicBurden(
        <String>['olanzapine', 'olanzapine', 'risperidone'],
      ); // 2 + 2 + 1
      expect(a.totalScore, 5);
      expect(a.category, AcbCategory.high);
    });

    test('preserves per-drug entry order', () {
      final a = assessAnticholinergicBurden(
        <String>['sertraline', 'amitriptyline', 'paroxetine'],
      );
      expect(a.entries.map((e) => e.drugId).toList(),
          <String>['sertraline', 'amitriptyline', 'paroxetine']);
      expect(a.entries[0].tier, AcbTier.none);
      expect(a.entries[1].tier, AcbTier.definiteSevere);
      expect(a.entries[2].tier, AcbTier.definiteLow);
    });
  });

  group('label helpers', () {
    test('every tier has a non-empty label', () {
      for (final t in AcbTier.values) {
        expect(acbTierLabel(t), isNotEmpty);
      }
    });

    test('every category has a non-empty label', () {
      for (final c in AcbCategory.values) {
        expect(acbCategoryLabel(c), isNotEmpty);
      }
    });
  });
}
