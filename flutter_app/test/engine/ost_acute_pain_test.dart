import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/ost_acute_pain.dart';

void main() {
  test('default → methadone, mild-moderate', () {
    final p = buildOstAcutePainPlan();
    expect(p.agent, OstAgentForPain.methadone);
    expect(p.severity, PainSeverity.mildModerate);
  });

  test('continue-maintenance principle always first', () {
    final p = buildOstAcutePainPlan();
    expect(p.steps.first, contains('CONTINUE the usual maintenance'));
  });

  test('buprenorphine surfaces the high-affinity caution', () {
    final p = buildOstAcutePainPlan(
      agent: OstAgentForPain.buprenorphine,
    );
    expect(p.cautions.join(' '), contains('high mu affinity'));
  });

  test('naltrexone surfaces the blockade caution + planning step',
      () {
    final p = buildOstAcutePainPlan(
      agent: OstAgentForPain.naltrexone,
    );
    expect(p.cautions.join(' '), contains('BLOCKS opioid analgesia'));
    expect(p.steps.join(' '), contains('72 h'));
  });

  test('severe/surgical adds a specialist-led titration step', () {
    final p = buildOstAcutePainPlan(
      severity: PainSeverity.severeOrSurgical,
    );
    expect(p.steps.join(' '), contains('Severe/surgical'));
  });

  test('clipboard summary reports agent + severity', () {
    final s = buildOstAcutePainPlan(
      agent: OstAgentForPain.buprenorphine,
      severity: PainSeverity.severeOrSurgical,
    ).clipboardSummary();
    expect(s, contains('Acute pain on OST'));
    expect(s, contains('Cautions:'));
  });
}
