import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/hyponatraemia.dart';

void main() {
  test('no sodium + no features → none', () {
    final r = evaluateHyponatraemia();
    expect(r.severity, HypoNaSeverity.none);
  });

  test('sodium bands map correctly', () {
    expect(evaluateHyponatraemia(sodium: 138).severity,
        HypoNaSeverity.none);
    expect(evaluateHyponatraemia(sodium: 132).severity,
        HypoNaSeverity.mild);
    expect(evaluateHyponatraemia(sodium: 127).severity,
        HypoNaSeverity.moderate);
    expect(evaluateHyponatraemia(sodium: 121).severity,
        HypoNaSeverity.severe);
  });

  test('severe features override a near-normal sodium', () {
    final r = evaluateHyponatraemia(
      sodium: 133,
      features: <String>{'seizures'},
    );
    expect(r.severity, HypoNaSeverity.severe);
  });

  test('worst of sodium vs features wins', () {
    final r = evaluateHyponatraemia(
      sodium: 132, // mild
      features: <String>{'confusion'}, // moderate
    );
    expect(r.severity, HypoNaSeverity.moderate);
  });

  test('correction-rate caution always present when abnormal', () {
    final r = evaluateHyponatraemia(sodium: 132);
    expect(r.cautions.join(' '), contains('osmotic demyelination'));
  });

  test('acute onset surfaces the hypertonic-saline note first', () {
    final r = evaluateHyponatraemia(
      sodium: 120,
      acuteOnset: true,
    );
    expect(r.acute, isTrue);
    expect(r.cautions.first, contains('Acute'));
  });

  test('clipboard summary reports band + culprit', () {
    final r = evaluateHyponatraemia(
      sodium: 121,
      culprit: 'Carbamazepine',
    );
    final s = r.clipboardSummary();
    expect(s, contains('Severe'));
    expect(s, contains('Carbamazepine'));
    expect(s, contains('Steps:'));
  });
}
