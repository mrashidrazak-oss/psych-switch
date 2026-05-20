import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/tardive_dyskinesia.dart';

void main() {
  test('not confirmed → confirm step', () {
    final r = evaluateTardiveDyskinesia();
    expect(r.step, TdStep.confirm);
    expect(r.options.join(' '), contains('AIMS'));
  });

  test('confirmed, not yet optimised → modify antipsychotic', () {
    final r = evaluateTardiveDyskinesia(confirmed: true);
    expect(r.step, TdStep.modifyAntipsychotic);
    expect(r.options.join(' '), contains('clozapine'));
  });

  test('still-needed vs stoppable changes the modify option', () {
    final stop = evaluateTardiveDyskinesia(
      confirmed: true,
      antipsychoticStillNeeded: false,
    );
    expect(stop.options.join(' '), contains('withdraw slowly'));
  });

  test('persists after optimisation → VMAT-2 inhibitor', () {
    final r = evaluateTardiveDyskinesia(
      confirmed: true,
      persistsAfterOptimisation: true,
    );
    expect(r.step, TdStep.vmat2);
    expect(r.options.join(' '), contains('valbenazine'));
  });

  test('refractory → specialist options', () {
    final r = evaluateTardiveDyskinesia(
      confirmed: true,
      persistsAfterOptimisation: true,
      refractory: true,
    );
    expect(r.step, TdStep.refractory);
  });

  test('do-not-increase + anticholinergic cautions always present',
      () {
    final r = evaluateTardiveDyskinesia();
    final c = r.cautions.join(' ');
    expect(c, contains('Do NOT simply increase'));
    expect(c, contains('Anticholinergics generally WORSEN'));
  });

  test('clipboard summary reports step', () {
    final s = evaluateTardiveDyskinesia(
      confirmed: true,
      persistsAfterOptimisation: true,
    ).clipboardSummary();
    expect(s, contains('VMAT-2 inhibitor treatment'));
    expect(s, contains('Options:'));
  });
}
