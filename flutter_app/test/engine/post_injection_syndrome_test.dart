import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/post_injection_syndrome.dart';

void main() {
  test('no features → continue observation', () {
    final r = evaluatePostInjection();
    expect(r.action, PdssAction.continueObservation);
    expect(r.protocol.join(' '), contains('3 hours'));
  });

  test('any feature → suspected PDSS', () {
    final r = evaluatePostInjection(
      features: <String>{'sedation'},
    );
    expect(r.action, PdssAction.suspectedPdss);
    expect(r.steps.first, contains('Do not discharge'));
  });

  test('no-antidote caution always present', () {
    final r = evaluatePostInjection();
    expect(r.cautions.join(' '), contains('no specific antidote'));
  });

  test('clipboard summary reports action + protocol', () {
    final r = evaluatePostInjection(
      features: <String>{'reduced_gcs'},
    );
    final s = r.clipboardSummary();
    expect(s, contains('Suspected PDSS'));
    expect(s, contains('Observation protocol:'));
  });
}
