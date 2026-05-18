import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/perioperative_psychotropics.dart';

void main() {
  test('lithium → plan/adjust with fluids + NSAID caution', () {
    final r = buildPeriopPlan(PeriopClass.lithium);
    expect(r.stance, PeriopStance.planAdjust);
    expect(r.steps.join(' '), contains('NSAID'));
  });

  test('MAOI → specialist, do not reflexively stop', () {
    final r = buildPeriopPlan(PeriopClass.maoi);
    expect(r.stance, PeriopStance.specialist);
    expect(r.steps.join(' '), contains('pethidine'));
  });

  test('clozapine → continue with re-titration awareness', () {
    final r = buildPeriopPlan(PeriopClass.clozapine);
    expect(r.stance, PeriopStance.planAdjust);
    expect(r.steps.join(' '), contains('re-titration'));
  });

  test('other antipsychotic → continue', () {
    final r = buildPeriopPlan(PeriopClass.antipsychoticOther);
    expect(r.stance, PeriopStance.continueDrug);
  });

  test('benzodiazepine → continue (withdrawal-seizure risk)', () {
    final r = buildPeriopPlan(PeriopClass.benzodiazepine);
    expect(r.stance, PeriopStance.continueDrug);
    expect(r.headline, contains('withdrawal'));
  });

  test('continue-by-default caution always present', () {
    final r = buildPeriopPlan(PeriopClass.ssriSnri);
    expect(r.cautions.join(' '),
        contains('Default is to CONTINUE'));
  });

  test('clipboard summary reports class + stance', () {
    final s = buildPeriopPlan(PeriopClass.lithium)
        .clipboardSummary();
    expect(s, contains('Lithium'));
    expect(s, contains('Steps:'));
  });
}
