import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/antipsychotic_in_parkinsonism.dart';

void main() {
  test("Parkinson's psychosis → quetiapine/clozapine preferred", () {
    final r = evaluateNeuroAntipsychotic(
      NeuroContext.parkinsonsPsychosis,
    );
    expect(r.preferred.join(' '), contains('Quetiapine'));
    expect(r.preferred.join(' '), contains('Clozapine'));
    expect(r.avoid.join(' '), contains('Typical antipsychotics'));
  });

  test('Lewy body → severe neuroleptic sensitivity headline', () {
    final r = evaluateNeuroAntipsychotic(NeuroContext.lewyBody);
    expect(r.headline, contains('SEVERE neuroleptic sensitivity'));
    expect(r.avoid.join(' '), contains('risperidone'));
  });

  test('Lewy body cautions warn carers about emergency', () {
    final r = evaluateNeuroAntipsychotic(NeuroContext.lewyBody);
    expect(r.cautions.join(' '), contains('urgent help'));
  });

  test('BPSD → risperidone limited-licence option', () {
    final r = evaluateNeuroAntipsychotic(
      NeuroContext.alzheimersVascularBpsd,
    );
    expect(r.preferred.join(' '), contains('Risperidone'));
  });

  test('stroke/mortality caution present in every context', () {
    for (final c in NeuroContext.values) {
      final r = evaluateNeuroAntipsychotic(c);
      expect(r.cautions.join(' '),
          contains('increased risk of stroke and death'));
    }
  });

  test('non-drug-first step present in every context', () {
    for (final c in NeuroContext.values) {
      final r = evaluateNeuroAntipsychotic(c);
      expect(r.firstSteps.join(' '),
          contains('Non-pharmacological'));
    }
  });

  test('clipboard summary reports context + sections', () {
    final s = evaluateNeuroAntipsychotic(NeuroContext.lewyBody)
        .clipboardSummary();
    expect(s, contains('Lewy body disease'));
    expect(s, contains('Avoid:'));
  });
}
