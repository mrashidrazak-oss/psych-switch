// Tests for the taper-speed adjustment helper.
//
// The contract we're locking down here:
//   1. 'standard' is a no-op (never mutate or copy unnecessarily).
//   2. Day intervals scale by the speed factor; doses and notes are preserved.
//   3. Day numbers are strictly monotonically increasing — even when
//      compression rounding would otherwise collapse two steps into the
//      same day (e.g. days 1, 2, 3 at faster speed).
//   4. Day 1 is always anchored as the start (no step starts before day 1).
import {
  adjustedDurationDays,
  compressSchedule,
  speedToggleApplies,
} from '../taperSpeed';
import type { ScheduleStep } from '../types';

const standardCrossTaper: ScheduleStep[] = [
  { day: 1, fromDoseMg: 100, toDoseMg: 5, notes: 'Start cross-taper' },
  { day: 7, fromDoseMg: 75, toDoseMg: 10 },
  { day: 14, fromDoseMg: 50, toDoseMg: 15, notes: 'Half dose' },
  { day: 21, fromDoseMg: 25, toDoseMg: 20 },
  { day: 28, fromDoseMg: 0, toDoseMg: 20, notes: 'Stop' },
];

describe('compressSchedule', () => {
  test('standard speed returns the original array reference (no-op)', () => {
    const out = compressSchedule(standardCrossTaper, 'standard');
    expect(out).toBe(standardCrossTaper);
  });

  test('faster speed compresses 28-day taper to ~14 days', () => {
    const out = compressSchedule(standardCrossTaper, 'faster');
    // Day 1 stays. Days 7,14,21,28 → ~4,7,11,14.
    expect(out.map((s) => s.day)).toEqual([1, 4, 8, 11, 15]);
    expect(out[out.length - 1]!.day).toBeLessThanOrEqual(15);
  });

  test('slower speed expands 28-day taper to ~42 days', () => {
    const out = compressSchedule(standardCrossTaper, 'slower');
    // Day 1 stays. Days 7,14,21,28 → ~10,21,31,41.
    expect(out[0]!.day).toBe(1);
    expect(out[out.length - 1]!.day).toBeGreaterThanOrEqual(40);
    expect(out[out.length - 1]!.day).toBeLessThanOrEqual(42);
  });

  test('preserves dose values and notes across all steps', () => {
    const out = compressSchedule(standardCrossTaper, 'faster');
    for (let i = 0; i < out.length; i++) {
      expect(out[i]!.fromDoseMg).toBe(standardCrossTaper[i]!.fromDoseMg);
      expect(out[i]!.toDoseMg).toBe(standardCrossTaper[i]!.toDoseMg);
      expect(out[i]!.notes).toBe(standardCrossTaper[i]!.notes);
    }
  });

  test('day numbers are strictly monotonically increasing after compression', () => {
    // A close-spaced schedule that would otherwise collapse to duplicate
    // days under naive rounding (e.g. days 1, 2, 3 → 1, 1, 1 at faster).
    const tight: ScheduleStep[] = [
      { day: 1, fromDoseMg: 40, toDoseMg: 0 },
      { day: 2, fromDoseMg: 30, toDoseMg: 5 },
      { day: 3, fromDoseMg: 20, toDoseMg: 10 },
      { day: 4, fromDoseMg: 0, toDoseMg: 15 },
    ];
    const out = compressSchedule(tight, 'faster');
    for (let i = 1; i < out.length; i++) {
      expect(out[i]!.day).toBeGreaterThan(out[i - 1]!.day);
    }
  });

  test('empty schedule returns empty schedule', () => {
    expect(compressSchedule([], 'faster')).toEqual([]);
    expect(compressSchedule([], 'slower')).toEqual([]);
  });

  test('single-step schedule keeps its single day untouched', () => {
    const single: ScheduleStep[] = [
      { day: 1, fromDoseMg: 0, toDoseMg: 10, notes: 'Direct switch' },
    ];
    expect(compressSchedule(single, 'faster')).toEqual(single);
    expect(compressSchedule(single, 'slower')).toEqual(single);
  });
});

describe('speedToggleApplies', () => {
  test('applies for a full 28-day cross-taper', () => {
    expect(speedToggleApplies(standardCrossTaper)).toBe(true);
  });

  test('does not apply for a 1-step direct switch', () => {
    const direct: ScheduleStep[] = [
      { day: 1, fromDoseMg: 0, toDoseMg: 10 },
    ];
    expect(speedToggleApplies(direct)).toBe(false);
  });

  test('does not apply for a very short schedule (< 10 days)', () => {
    const short: ScheduleStep[] = [
      { day: 1, fromDoseMg: 100, toDoseMg: 0 },
      { day: 3, fromDoseMg: 50, toDoseMg: 10 },
      { day: 7, fromDoseMg: 0, toDoseMg: 20 },
    ];
    expect(speedToggleApplies(short)).toBe(false);
  });

  test('applies for a 14-day schedule at the boundary', () => {
    const boundary: ScheduleStep[] = [
      { day: 1, fromDoseMg: 100, toDoseMg: 0 },
      { day: 7, fromDoseMg: 50, toDoseMg: 10 },
      { day: 14, fromDoseMg: 0, toDoseMg: 20 },
    ];
    expect(speedToggleApplies(boundary)).toBe(true);
  });
});

describe('adjustedDurationDays', () => {
  test('returns original duration for standard', () => {
    expect(adjustedDurationDays(28, 'standard')).toBe(28);
    expect(adjustedDurationDays(14, 'standard')).toBe(14);
  });

  test('halves duration for faster', () => {
    expect(adjustedDurationDays(28, 'faster')).toBe(14);
    expect(adjustedDurationDays(14, 'faster')).toBe(7);
  });

  test('extends duration ~1.5× for slower', () => {
    expect(adjustedDurationDays(28, 'slower')).toBe(42);
    expect(adjustedDurationDays(14, 'slower')).toBe(21);
  });

  test('never returns less than 1 day', () => {
    expect(adjustedDurationDays(1, 'faster')).toBeGreaterThanOrEqual(1);
    expect(adjustedDurationDays(0, 'faster')).toBeGreaterThanOrEqual(1);
  });
});
