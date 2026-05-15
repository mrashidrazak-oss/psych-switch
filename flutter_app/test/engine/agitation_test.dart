// Tests for the agitation-management algorithm.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/agitation.dart';

AgitationContext ctx({
  AgitationSeverity severity = AgitationSeverity.moderate,
  bool psychotic = false,
  bool alcoholOrBenzoWithdrawal = false,
  bool elderly = false,
  bool pregnant = false,
  bool refusingOral = false,
}) {
  return AgitationContext(
    severity: severity,
    psychotic: psychotic,
    alcoholOrBenzoWithdrawal: alcoholOrBenzoWithdrawal,
    elderly: elderly,
    pregnant: pregnant,
    refusingOral: refusingOral,
  );
}

void main() {
  test('always recommends verbal de-escalation first', () {
    final plan = buildAgitationPlan(ctx());
    expect(plan.firstLine.first, contains('Verbal de-escalation'));
  });

  test('alcohol withdrawal → benzo-only, antipsychotic caution', () {
    final plan = buildAgitationPlan(
        ctx(alcoholOrBenzoWithdrawal: true, severity: AgitationSeverity.severe));
    expect(plan.firstLine.join(' '), contains('Lorazepam'));
    expect(plan.cautions.join(' '), contains('avoid antipsychotics'));
    expect(plan.cautions.join(' '), contains('thiamine'));
  });

  test('elderly path → low-dose olanzapine / quetiapine first', () {
    final plan = buildAgitationPlan(ctx(elderly: true));
    final firstJoined = plan.firstLine.join(' ');
    expect(plan.cautions.join(' '), contains('Elderly'));
    expect(firstJoined.toLowerCase(), anyOf(contains('olanzapine'), contains('quetiapine')));
  });

  test('pregnant moderate psychotic → haloperidol / olanzapine', () {
    final plan = buildAgitationPlan(
        ctx(psychotic: true, pregnant: true));
    final joined = plan.firstLine.join(' ').toLowerCase();
    expect(joined, anyOf(contains('haloperidol'), contains('olanzapine')));
    expect(plan.cautions.join(' '), contains('Pregnancy'));
  });

  test('severe non-pregnant non-elderly psychotic → IM RT combo', () {
    final plan = buildAgitationPlan(
        ctx(severity: AgitationSeverity.severe, psychotic: true));
    final joined = plan.firstLine.join(' ');
    expect(joined.toLowerCase(), contains('haloperidol'));
    expect(joined.toLowerCase(), contains('promethazine'));
  });

  test('clipboard summary contains severity + first/second-line', () {
    final plan = buildAgitationPlan(
        ctx(severity: AgitationSeverity.severe, psychotic: true));
    final s = plan.clipboardSummary();
    expect(s, contains('Severe'));
    expect(s, contains('First-line'));
    expect(s, contains('Second-line'));
  });
}
