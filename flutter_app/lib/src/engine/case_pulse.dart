// Case pulse — derives "what's due today / soon" across all saved
// cases, used by the Home-screen TodayPulseCard and the smart in-app
// reminder banner.
//
// Computed live each time Home renders. No persistent state of its own.
//
// Semantics:
//   • A "pulse" is one due / overdue / upcoming monitoring item.
//   • Day offsets are computed from the case's `startedISO` (the date
//     the case was first saved). If the case is older than its
//     monitoring plan's spanDays, no future pulses remain.
//   • "Today" = within ±1 day of now. "Soon" = 2-7 days out.
//     "Overdue" = past + within 14 days (older just falls off).
//
// Dart port of engine/casePulse.ts. The TS port called `getDrug` and
// `generateMonitoringPlan` directly; the Dart port keeps the engine
// pure by taking a [SwitchingEngine] (for drug lookup) as a parameter,
// since [generateMonitoringPlan] is already a top-level function.

import 'package:psychswitch/src/engine/monitoring.dart';
import 'package:psychswitch/src/engine/switching_engine.dart' as engine;

/// One saved cross-titration case.
class SavedCase {
  const SavedCase({
    required this.id,
    required this.label,
    required this.fromDrugId,
    required this.fromDoseMg,
    required this.toDrugId,
    required this.toDoseMg,
    required this.startedISO,
    required this.updatedISO,
    this.notes,
    this.favourite,
  });

  final String id;
  final String label;
  final String fromDrugId;
  final num fromDoseMg;
  final String toDrugId;
  final num toDoseMg;
  final String startedISO;
  final String updatedISO;
  final String? notes;
  final bool? favourite;
}

/// Pulse tier (priority bucket).
enum PulseTier {
  overdue('overdue'),
  today('today'),
  soon('soon');

  const PulseTier(this.jsonValue);

  final String jsonValue;

  static PulseTier fromJson(String value) {
    for (final t in PulseTier.values) {
      if (t.jsonValue == value) return t;
    }
    throw ArgumentError.value(value, 'value', 'unknown PulseTier');
  }
}

/// One computed pulse (due/overdue/upcoming monitoring item).
class CasePulse {
  const CasePulse({
    required this.caseId,
    required this.caseLabel,
    required this.fromDrugId,
    required this.toDrugId,
    required this.dayOffset,
    required this.daysFromNow,
    required this.tier,
    required this.entry,
  });

  final String caseId;
  final String caseLabel;
  final String fromDrugId;
  final String toDrugId;

  /// Day offset from the case's start date that this pulse refers to.
  final int dayOffset;

  /// Calendar days from now (negative = past, 0 = today, positive = upcoming).
  final int daysFromNow;

  final PulseTier tier;
  final MonitoringEntry entry;
}

const Map<PulseTier, int> _tierRank = <PulseTier, int>{
  PulseTier.overdue: 0,
  PulseTier.today: 1,
  PulseTier.soon: 2,
};

DateTime _startOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day);

PulseTier? _pulseTier(int daysFromNow) {
  if (daysFromNow >= -1 && daysFromNow <= 1) return PulseTier.today;
  if (daysFromNow >= 2 && daysFromNow <= 7) return PulseTier.soon;
  if (daysFromNow >= -14 && daysFromNow < -1) return PulseTier.overdue;
  return null;
}

/// Compute today's pulses across all [cases].
///
/// Pass a [engine.SwitchingEngine] for drug lookups (cases reference
/// drug ids). [now] defaults to `DateTime.now()` — override for tests.
List<CasePulse> computeCasePulses(
  List<SavedCase> cases,
  engine.SwitchingEngine switchingEngine, {
  DateTime? now,
}) {
  final today = _startOfDay(now ?? DateTime.now());
  final out = <CasePulse>[];

  for (final c in cases) {
    final fromDrug = switchingEngine.getDrug(c.fromDrugId);
    final toDrug = switchingEngine.getDrug(c.toDrugId);
    if (fromDrug == null || toDrug == null) continue;

    final MonitoringPlan plan;
    try {
      plan = generateMonitoringPlan(
        toDrugId: c.toDrugId,
        fromDrugId: c.fromDrugId,
      );
    } on Object catch (_) {
      continue;
    }

    final DateTime start;
    try {
      start = _startOfDay(DateTime.parse(c.startedISO));
    } on FormatException catch (_) {
      continue;
    }

    for (final e in plan.entries) {
      final fireDay = start.add(Duration(days: e.dayOffset));
      final daysFromNow = fireDay.difference(today).inDays;
      final tier = _pulseTier(daysFromNow);
      if (tier == null) continue;
      out.add(
        CasePulse(
          caseId: c.id,
          caseLabel: c.label.isNotEmpty
              ? c.label
              : '${fromDrug.genericName} → ${toDrug.genericName}',
          fromDrugId: c.fromDrugId,
          toDrugId: c.toDrugId,
          dayOffset: e.dayOffset,
          daysFromNow: daysFromNow,
          tier: tier,
          entry: e,
        ),
      );
    }
  }

  // Overdue first, then today, then soon — within tier by daysFromNow asc.
  out.sort((a, b) {
    final r = _tierRank[a.tier]! - _tierRank[b.tier]!;
    if (r != 0) return r;
    return a.daysFromNow - b.daysFromNow;
  });
  return out;
}

/// Count pulses by tier — used for "3 overdue · 1 today · 5 this week".
Map<PulseTier, int> pulseCountsByTier(List<CasePulse> pulses) {
  final counts = <PulseTier, int>{
    PulseTier.overdue: 0,
    PulseTier.today: 0,
    PulseTier.soon: 0,
  };
  for (final p in pulses) {
    counts[p.tier] = counts[p.tier]! + 1;
  }
  return counts;
}

/// Display label for a [PulseTier].
String pulseTierLabel(PulseTier t) {
  switch (t) {
    case PulseTier.overdue:
      return 'Overdue';
    case PulseTier.today:
      return 'Today';
    case PulseTier.soon:
      return 'This week';
  }
}

/// Semantic colour-token pair for a [PulseTier]. UI maps to AppColors.
({String dot, String text}) pulseTierColorTokens(PulseTier t) {
  switch (t) {
    case PulseTier.overdue:
      return (dot: 'danger', text: 'danger');
    case PulseTier.today:
      return (dot: 'warning', text: 'warning');
    case PulseTier.soon:
      return (dot: 'accent', text: 'accent');
  }
}

/// Hex for a [PulseTier] (used in monochrome surfaces).
String pulseTierColorHex(PulseTier t) {
  switch (t) {
    case PulseTier.overdue:
      return '#ef4444';
    case PulseTier.today:
      return '#f59e0b';
    case PulseTier.soon:
      return '#3b82f6';
  }
}
