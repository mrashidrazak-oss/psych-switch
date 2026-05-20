// Taper-speed adjustment for cross-taper schedules.
//
// Why this exists:
// Maudsley 15th edition uses a 28-day cross-taper as its standard. Real-world
// clinical practice is often faster — published audits and other guidelines
// suggest:
//
//   • Spanish national registry (real-world):  ~16 days average taper
//   • NHS / NICE inpatient with monitoring:    3–7 days
//   • Stahl's Essential Psychopharmacology:    14–28 days routine, 4–8 wks high-risk
//   • Carlat meta-analysis (n≈1,400):          7–14 days most common; immediate
//                                              switches equally effective for symptoms
//   • RANZCP / FDA aripiprazole guidance:      14-day overlap minimum
//
// The dose progression in a reviewed rule (e.g. 100% → 75% → 50% → 25% → 0)
// is the clinically reviewed component — receptor occupancy and discontinuation
// risk hinge on the dose ratios. The DAY INTERVALS between those steps are
// context-dependent: fast for stable, monitored patients; slow for first
// episode or high relapse risk.
//
// This utility lets the user pick a speed and the schedule scales accordingly,
// keeping the dose progression intact. The UI flags non-default speeds with
// a clear warning that they sit outside the reviewed Maudsley schedule.
//
// Dart port of engine/taperSpeed.ts.

import 'package:psychswitch_engine/types/schedule_step.dart';

/// Taper-speed selection.
enum TaperSpeed {
  faster('faster'),
  standard('standard'),
  slower('slower');

  const TaperSpeed(this.jsonValue);

  final String jsonValue;

  static TaperSpeed fromJson(String value) {
    for (final s in TaperSpeed.values) {
      if (s.jsonValue == value) return s;
    }
    throw ArgumentError.value(value, 'value', 'unknown TaperSpeed');
  }
}

/// Speed → time-scaling factor.
///  * faster   ≈ 0.5×  (a 28-day taper becomes ~14 days)
///  * standard = 1.0× (Maudsley 15th, the reviewed schedule)
///  * slower   ≈ 1.5×  (28 days → 42 days, for FEP / high-relapse-risk)
const Map<TaperSpeed, double> speedFactor = <TaperSpeed, double>{
  TaperSpeed.faster: 0.5,
  TaperSpeed.standard: 1,
  TaperSpeed.slower: 1.5,
};

/// All speeds in display order (Faster | Standard | Slower).
const List<TaperSpeed> taperSpeeds = <TaperSpeed>[
  TaperSpeed.faster,
  TaperSpeed.standard,
  TaperSpeed.slower,
];

const Map<TaperSpeed, String> speedLabel = <TaperSpeed, String>{
  TaperSpeed.faster: 'Faster',
  TaperSpeed.standard: 'Standard',
  TaperSpeed.slower: 'Slower',
};

const Map<TaperSpeed, String> speedSublabel = <TaperSpeed, String>{
  TaperSpeed.faster: '~½ duration',
  TaperSpeed.standard: 'Maudsley',
  TaperSpeed.slower: '~1½× duration',
};

const Map<TaperSpeed, String> speedBasis = <TaperSpeed, String>{
  TaperSpeed.faster:
      'Compressed taper (~½ Maudsley duration). Consistent with NHS inpatient / Stahl / real-world practice (Spanish registry average: 16 days). Use for stable patients, inpatient monitoring, or low relapse risk.',
  TaperSpeed.standard:
      'Maudsley Prescribing Guidelines 15th edition — the reviewed reference schedule. Default for outpatient use.',
  TaperSpeed.slower:
      'Extended taper (~1½× Maudsley). Use for first-episode psychosis, high relapse risk, history of poor adherence, or where discontinuation symptoms have previously been a problem.',
};

/// Whether a meaningful schedule remains after compression.
/// Direct switches (1–2 day) and extremely short schedules don't benefit
/// from speed adjustment — the toggle should be hidden in those cases.
bool speedToggleApplies(List<ScheduleStep> schedule) {
  if (schedule.length < 3) return false;
  return schedule.last.day >= 10;
}

/// Scale a schedule's day intervals by the speed factor while keeping
/// dose values, notes and step count identical.
///
/// Day-mapping rules:
///   * Day 1 always stays Day 1 (the start day is anchor).
///   * Other days scale: `newDay = max(prev + 1, round((day − 1) × factor + 1))`.
///     The `prev + 1` floor guarantees day numbers are strictly increasing
///     so steps never collapse into the same day after rounding.
///
/// For [TaperSpeed.standard] this is a no-op — returns the original list.
List<ScheduleStep> compressSchedule(
  List<ScheduleStep> schedule,
  TaperSpeed speed,
) {
  if (speed == TaperSpeed.standard || schedule.isEmpty) return schedule;

  final factor = speedFactor[speed]!;
  final out = <ScheduleStep>[];
  var prevDay = 0;

  for (var i = 0; i < schedule.length; i++) {
    final step = schedule[i];
    final int newDay;
    if (i == 0) {
      newDay = step.day; // anchor first step (typically day 1)
    } else {
      final scaled = ((step.day - 1) * factor + 1).round();
      newDay = scaled > prevDay + 1 ? scaled : prevDay + 1;
    }
    out.add(step.copyWith(day: newDay));
    prevDay = newDay;
  }
  return out;
}

/// Approximate total schedule duration after applying speed.
/// Used by the UI to surface "X-day taper" labels without re-deriving from
/// the schedule array.
int adjustedDurationDays(int originalDurationDays, TaperSpeed speed) {
  if (speed == TaperSpeed.standard) return originalDurationDays;
  final scaled = (originalDurationDays * speedFactor[speed]!).round();
  return scaled < 1 ? 1 : scaled;
}
