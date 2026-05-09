// Tests for the Dart monitoring port.
// Mirrors engine/__tests__/monitoring.test.ts.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/monitoring.dart';
import 'package:psychswitch/src/engine/patient_context_pure.dart';

void main() {
  group('monitoring schedule generator', () {
    test('lithium baseline includes U&E + TFT + Ca + ECG', () {
      final plan = generateMonitoringPlan(toDrugId: 'lithium');
      final labels = plan.entries.map((e) => e.label).toList();
      expect(labels, containsAll(<String>['U&E + eGFR', 'TFT', 'Calcium', 'ECG']));
    });

    test('lithium recurring level expands at 90-day interval', () {
      final plan = generateMonitoringPlan(
        toDrugId: 'lithium',
        durationDays: 365,
      );
      final days = plan.entries
          .where((e) => e.label == 'Lithium level')
          .map((e) => e.dayOffset)
          .toList();
      expect(days, containsAll(<int>[7, 90, 180, 270]));
    });

    test('clozapine generates weekly FBC for 18 weeks', () {
      final plan = generateMonitoringPlan(
        toDrugId: 'clozapine',
        durationDays: 365,
      );
      final weeklyFbc =
          plan.entries.where((e) => e.label == 'Weekly FBC').toList();
      expect(weeklyFbc.length, equals(18));
    });

    test('antidepressant fallback includes mood/suicidality review at D14', () {
      final plan = generateMonitoringPlan(toDrugId: 'sertraline');
      expect(
        plan.entries.any(
          (e) => e.label == 'Mood + suicidality' && e.dayOffset == 14,
        ),
        isTrue,
      );
    });

    test('cardiac comorbidity adds baseline ECG even without QT-prolonger', () {
      final plan = generateMonitoringPlan(
        toDrugId: 'mirtazapine',
        context: const PatientContext(
          ageYears: 50,
          sex: Sex.male,
          comorbidities: Comorbidities(cardiac: true),
        ),
      );
      expect(
        plan.entries.any((e) => e.label == 'ECG (cardiac hx)'),
        isTrue,
      );
    });

    test('plan has citations and a non-zero span', () {
      final plan = generateMonitoringPlan(toDrugId: 'lithium');
      expect(plan.citations, isNotEmpty);
      expect(plan.spanDays, greaterThan(0));
    });

    test('entries are sorted by dayOffset', () {
      final plan = generateMonitoringPlan(toDrugId: 'olanzapine');
      for (var i = 1; i < plan.entries.length; i++) {
        expect(
          plan.entries[i].dayOffset,
          greaterThanOrEqualTo(plan.entries[i - 1].dayOffset),
        );
      }
    });

    test('unknown drug returns empty plan', () {
      final plan = generateMonitoringPlan(toDrugId: 'not-a-drug');
      expect(plan.entries, isEmpty);
    });
  });

  group('MonitoringCategory jsonValue round-trips', () {
    test('every category parses back', () {
      for (final c in MonitoringCategory.values) {
        expect(MonitoringCategory.fromJson(c.jsonValue), equals(c));
      }
    });
  });

  group('MonitoringEntry.toJson', () {
    test('omits drugId/citation/recurring when null', () {
      const e = MonitoringEntry(
        dayOffset: 0,
        label: 'X',
        detail: 'd',
        category: MonitoringCategory.lab,
      );
      final j = e.toJson();
      expect(j.containsKey('drugId'), isFalse);
      expect(j.containsKey('citation'), isFalse);
      expect(j.containsKey('recurring'), isFalse);
    });

    test('includes recurring with everyDays + optional untilDay', () {
      const e = MonitoringEntry(
        dayOffset: 7,
        label: 'Weekly X',
        detail: 'd',
        category: MonitoringCategory.lab,
        recurring: MonitoringRecurrence(everyDays: 7, untilDay: 28),
      );
      final j = e.toJson();
      expect(
        j['recurring'],
        equals(<String, dynamic>{'everyDays': 7, 'untilDay': 28}),
      );
    });
  });
}
