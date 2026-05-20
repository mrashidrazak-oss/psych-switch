import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/hyperprolactinaemia.dart';

void main() {
  test('null / low prolactin → normal, no imaging', () {
    final r = evaluateHyperprolactinaemia();
    expect(r.band, ProlactinBand.normal);
    expect(r.imagingAdvised, isFalse);
  });

  test('prolactin bands map correctly', () {
    expect(evaluateHyperprolactinaemia(prolactin: 400).band,
        ProlactinBand.normal);
    expect(evaluateHyperprolactinaemia(prolactin: 700).band,
        ProlactinBand.mild);
    expect(evaluateHyperprolactinaemia(prolactin: 1500).band,
        ProlactinBand.moderate);
    expect(evaluateHyperprolactinaemia(prolactin: 2500).band,
        ProlactinBand.high);
  });

  test('markedly raised mandates pituitary imaging', () {
    final r = evaluateHyperprolactinaemia(prolactin: 3000);
    expect(r.imagingAdvised, isTrue);
    expect(r.steps.join(' '), contains('MRI'));
  });

  test('mild rise does not mandate imaging', () {
    final r = evaluateHyperprolactinaemia(prolactin: 800);
    expect(r.imagingAdvised, isFalse);
  });

  test('macroprolactin caution always present', () {
    final r = evaluateHyperprolactinaemia(prolactin: 1500);
    expect(r.cautions.join(' '), contains('Macroprolactin'));
  });

  test('clipboard summary reports band + imaging line', () {
    final r = evaluateHyperprolactinaemia(prolactin: 2500);
    final s = r.clipboardSummary();
    expect(s, contains('Markedly raised'));
    expect(s, contains('prolactinoma'));
    expect(s, contains('Steps:'));
  });
}
