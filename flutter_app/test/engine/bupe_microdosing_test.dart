import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/bupe_microdosing.dart';

void main() {
  test('default → fentanyl source, standard ~7-day schedule', () {
    final p = buildMicrodosePlan();
    expect(p.source, MicrodoseSource.fullAgonist);
    expect(p.pace, MicrodosePace.standard);
    expect(p.schedule.length, 7);
    expect(p.schedule.first, contains('0.5 mg'));
  });

  test('standard schedule stops the full agonist on day 6', () {
    final p = buildMicrodosePlan();
    expect(p.schedule[5], contains('STOP the full agonist'));
  });

  test('rapid pace → ~4-day schedule', () {
    final p = buildMicrodosePlan(pace: MicrodosePace.rapid);
    expect(p.schedule.length, 4);
    expect(p.schedule.last, contains('STOP the full agonist'));
  });

  test('methadone source surfaces the long-half-life caution', () {
    final p = buildMicrodosePlan(
      source: MicrodoseSource.methadone,
    );
    expect(p.cautions.join(' '), contains('long half-life'));
  });

  test('fentanyl source surfaces the accumulation caution', () {
    final p = buildMicrodosePlan();
    expect(p.cautions.join(' '), contains('tissue accumulation'));
  });

  test('clipboard summary reports source + pace', () {
    final s = buildMicrodosePlan().clipboardSummary();
    expect(s, contains('Buprenorphine micro-dosing'));
    expect(s, contains('Schedule'));
  });
}
