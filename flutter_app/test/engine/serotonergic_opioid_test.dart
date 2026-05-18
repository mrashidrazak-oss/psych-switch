import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/serotonergic_opioid.dart';

void main() {
  test('pethidine + MAOI → contraindicated', () {
    final r = evaluateSerotonergicOpioid(
      opioidId: 'pethidine',
      agentId: 'maoi',
    );
    expect(r.risk, OpioidSerotonergicRisk.contraindicated);
    expect(r.headline, contains('Do NOT'));
  });

  test('tramadol + SSRI → high risk', () {
    final r = evaluateSerotonergicOpioid(
      opioidId: 'tramadol',
      agentId: 'ssri',
    );
    expect(r.risk, OpioidSerotonergicRisk.highRisk);
  });

  test('weak opioid + MAOI → high risk', () {
    final r = evaluateSerotonergicOpioid(
      opioidId: 'fentanyl',
      agentId: 'maoi',
    );
    expect(r.risk, OpioidSerotonergicRisk.highRisk);
  });

  test('morphine + SSRI → low risk', () {
    final r = evaluateSerotonergicOpioid(
      opioidId: 'morphine',
      agentId: 'ssri',
    );
    expect(r.risk, OpioidSerotonergicRisk.lowRisk);
  });

  test('weak opioid + moderate agent → low risk', () {
    final r = evaluateSerotonergicOpioid(
      opioidId: 'oxycodone',
      agentId: 'lithium',
    );
    expect(r.risk, OpioidSerotonergicRisk.lowRisk);
  });

  test('safer alternatives + Hunter caution always present', () {
    final r = evaluateSerotonergicOpioid(
      opioidId: 'tramadol',
      agentId: 'snri',
    );
    expect(r.saferAlternatives.join(' '), contains('Morphine'));
    expect(r.cautions.join(' '), contains('Hunter criteria'));
  });

  test('clipboard summary reports risk label', () {
    final s = evaluateSerotonergicOpioid(
      opioidId: 'pethidine',
      agentId: 'maoi',
    ).clipboardSummary();
    expect(s, contains('Contraindicated combination'));
    expect(s, contains('Steps:'));
  });
}
