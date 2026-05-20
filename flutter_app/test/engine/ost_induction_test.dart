import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/ost_induction.dart';

OstInput inp({
  OstAgent agent = OstAgent.buprenorphine,
  int cows = 14,
  bool longActing = false,
  bool lowTol = false,
}) =>
    OstInput(
      agent: agent,
      cowsScore: cows,
      longActingOpioidOrFentanyl: longActing,
      lowTolerance: lowTol,
    );

void main() {
  test('buprenorphine with COWS < 12 → not ready, advise wait', () {
    final p = buildOstPlan(inp(cows: 8));
    expect(p.canStartNow, isFalse);
    expect(p.headline, contains('NOT yet'));
    expect(p.steps.first, contains('WAIT'));
  });

  test('buprenorphine with COWS ≥ 12 → induct now', () {
    final p = buildOstPlan(inp());
    expect(p.canStartNow, isTrue);
    expect(p.headline, contains('induct now'));
    expect(p.steps.join(' '), contains('4 mg'));
  });

  test('low tolerance lowers the first buprenorphine dose', () {
    final p = buildOstPlan(inp(lowTol: true));
    expect(p.steps.join(' '), contains('2 mg SL'));
  });

  test('buprenorphine always warns about precipitated withdrawal', () {
    final p = buildOstPlan(inp());
    expect(p.cautions.join(' '),
        contains('Precipitated withdrawal'));
  });

  test('methadone can start now but warns about accumulation', () {
    final p = buildOstPlan(inp(agent: OstAgent.methadone));
    expect(p.canStartNow, isTrue);
    expect(p.cautions.join(' '), contains('ACCUMULATES'));
    expect(p.steps.join(' '), contains('30 mg'));
  });

  test('methadone low tolerance lowers day-1 start', () {
    final p =
        buildOstPlan(inp(agent: OstAgent.methadone, lowTol: true));
    expect(p.steps.join(' '), contains('10–20 mg'));
  });

  test('clipboard summary lists steps + cautions', () {
    final s = buildOstPlan(inp()).clipboardSummary();
    expect(s, contains('Steps:'));
    expect(s, contains('Cautions:'));
  });
}
