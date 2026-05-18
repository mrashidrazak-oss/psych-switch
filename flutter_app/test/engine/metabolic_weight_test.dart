import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/metabolic_weight.dart';

void main() {
  test('no gain → minimal', () {
    final r = evaluateMetabolicWeight();
    expect(r.tier, WeightGainTier.minimal);
  });

  test('weight-gain bands map correctly', () {
    expect(evaluateMetabolicWeight(percentGain: 1).tier,
        WeightGainTier.minimal);
    expect(evaluateMetabolicWeight(percentGain: 4).tier,
        WeightGainTier.emerging);
    expect(evaluateMetabolicWeight(percentGain: 9).tier,
        WeightGainTier.significant);
    expect(evaluateMetabolicWeight(percentGain: 18).tier,
        WeightGainTier.marked);
  });

  test('≥7% triggers metformin + switch consideration', () {
    final r = evaluateMetabolicWeight(percentGain: 8);
    final joined = r.steps.join(' ');
    expect(joined, contains('metformin'));
    expect(joined, contains('switching'));
  });

  test('high-risk agent adds proactive step at minimal tier', () {
    final r = evaluateMetabolicWeight(
      percentGain: 1,
      highRiskAgent: true,
    );
    expect(r.steps.join(' '), contains('olanzapine/clozapine'));
  });

  test('negative input is clamped to zero', () {
    final r = evaluateMetabolicWeight(percentGain: -5);
    expect(r.percentGain, 0);
    expect(r.tier, WeightGainTier.minimal);
  });

  test('no-abrupt-stop caution always present', () {
    final r = evaluateMetabolicWeight(percentGain: 9);
    expect(r.cautions.join(' '), contains('Never stop an effective'));
  });

  test('clipboard summary reports tier + %', () {
    final s = evaluateMetabolicWeight(percentGain: 18)
        .clipboardSummary();
    expect(s, contains('Marked gain'));
    expect(s, contains('18.0%'));
  });
}
