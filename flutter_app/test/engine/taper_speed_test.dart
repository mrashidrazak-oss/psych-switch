// Tests for the Dart taper_speed port.
// Mirrors engine/__tests__/taperSpeed.test.ts.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/taper_speed.dart';
import 'package:psychswitch/src/engine/types/schedule_step.dart';

const _standardCrossTaper = <ScheduleStep>[
  ScheduleStep(
    day: 1,
    fromDoseMg: 100,
    toDoseMg: 5,
    notes: 'Start cross-taper',
  ),
  ScheduleStep(day: 7, fromDoseMg: 75, toDoseMg: 10),
  ScheduleStep(day: 14, fromDoseMg: 50, toDoseMg: 15, notes: 'Half dose'),
  ScheduleStep(day: 21, fromDoseMg: 25, toDoseMg: 20),
  ScheduleStep(day: 28, fromDoseMg: 0, toDoseMg: 20, notes: 'Stop'),
];

void main() {
  group('compressSchedule', () {
    test('standard speed returns the original list reference (no-op)', () {
      final out = compressSchedule(_standardCrossTaper, TaperSpeed.standard);
      expect(identical(out, _standardCrossTaper), isTrue);
    });

    test('faster speed compresses 28-day taper to ~14 days', () {
      final out = compressSchedule(_standardCrossTaper, TaperSpeed.faster);
      expect(out.map((s) => s.day).toList(), equals(<int>[1, 4, 8, 11, 15]));
      expect(out.last.day, lessThanOrEqualTo(15));
    });

    test('slower speed expands 28-day taper to ~42 days', () {
      final out = compressSchedule(_standardCrossTaper, TaperSpeed.slower);
      expect(out.first.day, equals(1));
      expect(out.last.day, greaterThanOrEqualTo(40));
      expect(out.last.day, lessThanOrEqualTo(42));
    });

    test('preserves dose values and notes across all steps', () {
      final out = compressSchedule(_standardCrossTaper, TaperSpeed.faster);
      for (var i = 0; i < out.length; i++) {
        expect(out[i].fromDoseMg, equals(_standardCrossTaper[i].fromDoseMg));
        expect(out[i].toDoseMg, equals(_standardCrossTaper[i].toDoseMg));
        expect(out[i].notes, equals(_standardCrossTaper[i].notes));
      }
    });

    test(
        'day numbers are strictly monotonically increasing after compression',
        () {
      // A close-spaced schedule that would otherwise collapse to duplicate
      // days under naive rounding (e.g. days 1, 2, 3 → 1, 1, 1 at faster).
      const tight = <ScheduleStep>[
        ScheduleStep(day: 1, fromDoseMg: 40, toDoseMg: 0),
        ScheduleStep(day: 2, fromDoseMg: 30, toDoseMg: 5),
        ScheduleStep(day: 3, fromDoseMg: 20, toDoseMg: 10),
        ScheduleStep(day: 4, fromDoseMg: 0, toDoseMg: 15),
      ];
      final out = compressSchedule(tight, TaperSpeed.faster);
      for (var i = 1; i < out.length; i++) {
        expect(out[i].day, greaterThan(out[i - 1].day));
      }
    });

    test('empty schedule returns empty schedule', () {
      expect(compressSchedule(<ScheduleStep>[], TaperSpeed.faster), isEmpty);
      expect(compressSchedule(<ScheduleStep>[], TaperSpeed.slower), isEmpty);
    });

    test('single-step schedule keeps its single day untouched', () {
      const single = <ScheduleStep>[
        ScheduleStep(
          day: 1,
          fromDoseMg: 0,
          toDoseMg: 10,
          notes: 'Direct switch',
        ),
      ];
      expect(compressSchedule(single, TaperSpeed.faster), equals(single));
      expect(compressSchedule(single, TaperSpeed.slower), equals(single));
    });
  });

  group('speedToggleApplies', () {
    test('applies for a full 28-day cross-taper', () {
      expect(speedToggleApplies(_standardCrossTaper), isTrue);
    });

    test('does not apply for a 1-step direct switch', () {
      const direct = <ScheduleStep>[
        ScheduleStep(day: 1, fromDoseMg: 0, toDoseMg: 10),
      ];
      expect(speedToggleApplies(direct), isFalse);
    });

    test('does not apply for a very short schedule (< 10 days)', () {
      const short = <ScheduleStep>[
        ScheduleStep(day: 1, fromDoseMg: 100, toDoseMg: 0),
        ScheduleStep(day: 3, fromDoseMg: 50, toDoseMg: 10),
        ScheduleStep(day: 7, fromDoseMg: 0, toDoseMg: 20),
      ];
      expect(speedToggleApplies(short), isFalse);
    });

    test('applies for a 14-day schedule at the boundary', () {
      const boundary = <ScheduleStep>[
        ScheduleStep(day: 1, fromDoseMg: 100, toDoseMg: 0),
        ScheduleStep(day: 7, fromDoseMg: 50, toDoseMg: 10),
        ScheduleStep(day: 14, fromDoseMg: 0, toDoseMg: 20),
      ];
      expect(speedToggleApplies(boundary), isTrue);
    });
  });

  group('adjustedDurationDays', () {
    test('returns original duration for standard', () {
      expect(adjustedDurationDays(28, TaperSpeed.standard), equals(28));
      expect(adjustedDurationDays(14, TaperSpeed.standard), equals(14));
    });

    test('halves duration for faster', () {
      expect(adjustedDurationDays(28, TaperSpeed.faster), equals(14));
      expect(adjustedDurationDays(14, TaperSpeed.faster), equals(7));
    });

    test('extends duration ~1.5× for slower', () {
      expect(adjustedDurationDays(28, TaperSpeed.slower), equals(42));
      expect(adjustedDurationDays(14, TaperSpeed.slower), equals(21));
    });

    test('never returns less than 1 day', () {
      expect(
        adjustedDurationDays(1, TaperSpeed.faster),
        greaterThanOrEqualTo(1),
      );
      expect(
        adjustedDurationDays(0, TaperSpeed.faster),
        greaterThanOrEqualTo(1),
      );
    });
  });

  group('TaperSpeed jsonValue round-trips', () {
    test('every speed parses back', () {
      for (final s in TaperSpeed.values) {
        expect(TaperSpeed.fromJson(s.jsonValue), equals(s));
      }
    });
  });
}
