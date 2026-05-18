// Tests for the hyperbolic antidepressant taper planner.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/deprescribing.dart';

void main() {
  test('deprescribeDrugById returns expected drugs', () {
    expect(deprescribeDrugById('paroxetine')?.name, 'Paroxetine');
    expect(deprescribeDrugById('venlafaxine')?.name, 'Venlafaxine');
    expect(deprescribeDrugById('imaginary'), isNull);
  });

  group('hyperbolic taper shape', () {
    final parox = deprescribeDrugById('paroxetine')!;

    test('first step holds the starting dose', () {
      final plan = buildTaperPlan(
        drug: parox,
        speed: TaperSpeed.moderate,
      );
      expect(plan.steps.first.doseMg, parox.startDoseMg);
      expect(plan.steps.first.cumulativeDay, 0);
    });

    test('doses are monotonically non-increasing and end at 0', () {
      final plan = buildTaperPlan(
        drug: parox,
        speed: TaperSpeed.cautious,
      );
      for (var i = 1; i < plan.steps.length; i++) {
        expect(plan.steps[i].doseMg <= plan.steps[i - 1].doseMg, isTrue);
      }
      expect(plan.steps.last.doseMg, 0);
    });

    test('reductions get smaller in absolute terms (hyperbolic)', () {
      final plan = buildTaperPlan(
        drug: parox,
        speed: TaperSpeed.moderate,
      );
      // Compare the first reduction with a later one.
      final firstDrop = plan.steps[0].doseMg - plan.steps[1].doseMg;
      final laterDrop =
          plan.steps[2].doseMg - plan.steps[3].doseMg;
      expect(laterDrop < firstDrop, isTrue);
    });

    test('cautious plan is longer than faster plan', () {
      final slow = buildTaperPlan(
        drug: parox,
        speed: TaperSpeed.cautious,
      );
      final fast = buildTaperPlan(
        drug: parox,
        speed: TaperSpeed.faster,
      );
      expect(slow.totalDays > fast.totalDays, isTrue);
    });

    test('custom start dose is honoured', () {
      final plan = buildTaperPlan(
        drug: parox,
        speed: TaperSpeed.moderate,
        startDoseMg: 40,
      );
      expect(plan.startDoseMg, 40);
      expect(plan.steps.first.doseMg, 40);
    });

    test('plan terminates (no runaway loop) for every drug+speed', () {
      for (final d in kDeprescribeDrugs) {
        for (final s in TaperSpeed.values) {
          final plan = buildTaperPlan(drug: d, speed: s);
          expect(plan.steps.length, lessThan(62));
          expect(plan.steps.last.doseMg, 0);
        }
      }
    });

    test('clipboard summary mentions drug + STOP', () {
      final plan = buildTaperPlan(
        drug: parox,
        speed: TaperSpeed.moderate,
      );
      final s = plan.clipboardSummary();
      expect(s, contains('Paroxetine'));
      expect(s, contains('STOP'));
    });
  });
}
