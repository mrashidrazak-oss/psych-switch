import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/antipsychotic_high_dose.dart';

void main() {
  test('no doses → not high dose', () {
    final r = evaluateHighDose(<String, double>{});
    expect(r.isHighDose, isFalse);
    expect(r.totalPercent, 0);
  });

  test('single drug at half max → 50%', () {
    final r = evaluateHighDose(<String, double>{'olanzapine': 10});
    expect(r.totalPercent, closeTo(50, 0.01));
    expect(r.isHighDose, isFalse);
  });

  test('cumulative polypharmacy can exceed 100%', () {
    final r = evaluateHighDose(<String, double>{
      'olanzapine': 20, // 100%
      'haloperidol': 10, // 50%
    });
    expect(r.totalPercent, closeTo(150, 0.01));
    expect(r.isHighDose, isTrue);
    expect(r.safeguards, isNotEmpty);
  });

  test('exactly 100% is not high dose', () {
    final r = evaluateHighDose(<String, double>{'olanzapine': 20});
    expect(r.totalPercent, closeTo(100, 0.01));
    expect(r.isHighDose, isFalse);
  });

  test('per-drug breakdown is reported', () {
    final r = evaluateHighDose(<String, double>{'risperidone': 8});
    expect(r.perDrug.first, contains('Risperidone'));
    expect(r.perDrug.first, contains('50%'));
  });

  test('formulary caution always present', () {
    final r = evaluateHighDose(<String, double>{'clozapine': 450});
    expect(r.cautions.join(' '), contains('local formulary'));
  });

  test('clipboard summary reports cumulative %', () {
    final r = evaluateHighDose(<String, double>{
      'olanzapine': 20,
      'quetiapine': 800,
    });
    final s = r.clipboardSummary();
    expect(s, contains('200% of maximum'));
    expect(s, contains('HDAT safeguards:'));
  });
}
