import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/lithium_toxicity.dart';

void main() {
  test('no level + no features → no toxicity', () {
    final r = evaluateLithiumToxicity(features: <String>{});
    expect(r.tier, LithiumToxTier.none);
    expect(r.dialysisIndicated, isFalse);
  });

  test('level bands map correctly', () {
    expect(
        evaluateLithiumToxicity(level: 1, features: <String>{}).tier,
        LithiumToxTier.none);
    expect(
        evaluateLithiumToxicity(level: 1.8, features: <String>{}).tier,
        LithiumToxTier.mild);
    expect(
        evaluateLithiumToxicity(level: 2.8, features: <String>{}).tier,
        LithiumToxTier.moderate);
    expect(
        evaluateLithiumToxicity(level: 3.8, features: <String>{}).tier,
        LithiumToxTier.severe);
  });

  test('clinical features override a therapeutic level', () {
    final r = evaluateLithiumToxicity(
      level: 0.9,
      features: <String>{'ataxia'},
    );
    expect(r.tier, LithiumToxTier.moderate);
  });

  test('worst of level vs features wins', () {
    final r = evaluateLithiumToxicity(
      level: 1.8, // mild
      features: <String>{'seizures'}, // severe
    );
    expect(r.tier, LithiumToxTier.severe);
  });

  test('dialysis at level ≥ 4.0 regardless of symptoms', () {
    final r = evaluateLithiumToxicity(level: 4.2, features: <String>{});
    expect(r.dialysisIndicated, isTrue);
    expect(r.dialysisRationale, contains('4.0'));
  });

  test('dialysis at ≥ 2.5 with severe clinical / renal failure', () {
    final r = evaluateLithiumToxicity(
      level: 2.8,
      features: <String>{'reduced_gcs'},
    );
    expect(r.dialysisIndicated, isTrue);
  });

  test('no dialysis for moderate level + mild features', () {
    final r = evaluateLithiumToxicity(
      level: 2.6,
      features: <String>{'gi'},
    );
    expect(r.dialysisIndicated, isFalse);
  });

  test('clipboard summary reports tier + level', () {
    final r = evaluateLithiumToxicity(
      level: 3.8,
      features: <String>{'seizures'},
    );
    final s = r.clipboardSummary();
    expect(s, contains('Severe'));
    expect(s, contains('3.80 mmol/L'));
    expect(s, contains('Haemodialysis'));
  });
}
