import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/catatonia.dart';

void main() {
  test('14 screening signs registered', () {
    expect(kBfcsiSigns.length, 14);
  });

  test('zero signs → screen negative', () {
    final r = evaluateCatatonia(<String>{});
    expect(r.positiveCount, 0);
    expect(r.screenPositive, isFalse);
  });

  test('one sign → still negative', () {
    final r = evaluateCatatonia(<String>{'mutism'});
    expect(r.positiveCount, 1);
    expect(r.screenPositive, isFalse);
  });

  test('two signs → screen positive + lorazepam-challenge guidance', () {
    final r = evaluateCatatonia(<String>{'mutism', 'immobility'});
    expect(r.positiveCount, 2);
    expect(r.screenPositive, isTrue);
    expect(r.recommendation, contains('lorazepam challenge'));
    expect(r.recommendation, contains('Bush-Francis'));
  });

  test('unknown ids are ignored in the count', () {
    final r = evaluateCatatonia(<String>{'mutism', 'not_a_sign'});
    expect(r.positiveCount, 1);
    expect(r.screenPositive, isFalse);
  });

  test('clipboard summary reports n / 14', () {
    final r = evaluateCatatonia(<String>{'staring', 'posturing', 'rigidity'});
    expect(r.clipboardSummary(), contains('3 / 14'));
    expect(r.clipboardSummary(), contains('SCREEN POSITIVE'));
  });
}
