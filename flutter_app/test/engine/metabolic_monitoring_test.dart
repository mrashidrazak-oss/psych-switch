// Tests for the antipsychotic metabolic-monitoring scheduler.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/metabolic_monitoring.dart';

void main() {
  final start = DateTime(2026);

  test('generates baseline, wk6, wk12, then annual visits', () {
    final s = buildMonitoringSchedule(
      startDate: start,
      now: start,
    );
    final labels = s.visits.map((v) => v.label).toList();
    expect(labels.first, 'Baseline');
    expect(labels, contains('Week 6'));
    expect(labels, contains('Week 12'));
    expect(labels, contains('Year 1'));
    expect(labels, contains('Year 3'));
  });

  test('visit dates are correctly offset from start', () {
    final s = buildMonitoringSchedule(startDate: start, now: start);
    final wk6 = s.visits.firstWhere((v) => v.label == 'Week 6');
    expect(wk6.dueDate, DateTime(2026).add(const Duration(days: 42)));
    final yr1 = s.visits.firstWhere((v) => v.label == 'Year 1');
    expect(yr1.dueDate, DateTime(2026).add(const Duration(days: 365)));
  });

  test('overdue + due-soon flags reflect "now"', () {
    // now = 50 days after start → baseline + wk6 overdue, wk12 future.
    final now = start.add(const Duration(days: 50));
    final s = buildMonitoringSchedule(startDate: start, now: now);
    final baseline = s.visits.firstWhere((v) => v.label == 'Baseline');
    final wk6 = s.visits.firstWhere((v) => v.label == 'Week 6');
    final wk12 = s.visits.firstWhere((v) => v.label == 'Week 12');
    expect(baseline.isOverdue, isTrue);
    expect(wk6.isOverdue, isTrue);
    expect(wk12.isOverdue, isFalse);
  });

  test('due-soon window is 14 days', () {
    // now = day 75 → wk12 (day 84) is 9 days away → due soon.
    final now = start.add(const Duration(days: 75));
    final s = buildMonitoringSchedule(startDate: start, now: now);
    final wk12 = s.visits.firstWhere((v) => v.label == 'Week 12');
    expect(wk12.isDueSoon, isTrue);
    expect(wk12.isOverdue, isFalse);
  });

  test('nextDue surfaces the first overdue / due-soon visit', () {
    final now = start.add(const Duration(days: 50));
    final s = buildMonitoringSchedule(startDate: start, now: now);
    expect(s.nextDue?.label, 'Baseline');
  });

  test('baseline visit lists the full panel', () {
    final s = buildMonitoringSchedule(startDate: start, now: start);
    final baseline = s.visits.first;
    expect(baseline.params.length, greaterThanOrEqualTo(6));
    expect(
      baseline.params.map((p) => p.label).join(' '),
      contains('lipid'),
    );
  });

  test('clipboard summary lists every visit', () {
    final s = buildMonitoringSchedule(startDate: start, now: start);
    final txt = s.clipboardSummary();
    expect(txt, contains('Baseline'));
    expect(txt, contains('Week 12'));
    expect(txt, contains('Year 1'));
  });
}
