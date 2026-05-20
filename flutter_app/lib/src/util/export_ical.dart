// Lints relaxed:
//   • cascade_invocations — VCALENDAR header writes are clearer as
//     separate statements than chained cascades.
//   • unnecessary_raw_strings / use_raw_strings — kept inconsistent
//     to keep the iCal escape table readable.
//   • document_ignores — this comment.
// ignore_for_file: cascade_invocations, unnecessary_raw_strings, use_raw_strings, document_ignores
//
// iCal (.ics) export — turns a cross-taper plan into a sequence of
// all-day VEVENT entries the clinician can pull into Apple Calendar,
// Google Calendar, Outlook, or any RFC-5545 client.
//
// Events generated:
//   • One all-day event per schedule step ("Day 4: sertraline 50 mg,
//     escitalopram 5 mg") with the step note in the description.
//   • One event per monitoring touchpoint computed from the engine's
//     `generateMonitoringPlan(...)` (e.g. "FBC due — week 2").
//   • A "Switch complete" anchor on the final day so the clinician
//     gets a single calendar dot marking the journey end.
//
// Pure Dart — no Flutter import — and emits a UTF-8 string that the
// caller passes to `share_plus` or writes to a tmp file.

import 'package:psychswitch_engine/monitoring.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';

/// Build the iCalendar payload for a switch plan starting on
/// [startDate] (local midnight). [contextOrNull] is forwarded to the
/// monitoring planner so context-conditional flags (pregnancy, renal
/// etc.) generate matching events.
String formatPlanForIcal({
  required Drug fromDrug,
  required Drug toDrug,
  required SwitchPlanOk plan,
  required DateTime startDate,
  PatientContext? contextOrNull,
  String? caseLabel,
}) {
  final buf = StringBuffer();
  final stamp = _icalStamp(DateTime.now().toUtc());
  final caseSlug = (caseLabel ?? '${fromDrug.id}-to-${toDrug.id}')
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
      .toLowerCase();

  buf.writeln('BEGIN:VCALENDAR');
  buf.writeln('VERSION:2.0');
  buf.writeln('PRODID:-//PsychSwitch//Cross-taper plan//EN');
  buf.writeln('CALSCALE:GREGORIAN');
  buf.writeln('METHOD:PUBLISH');

  // ── Schedule step events ──────────────────────────────────────────
  for (final s in plan.schedule) {
    final date = startDate.add(Duration(days: s.day - 1));
    final summary = s.fromDoseMg == 0
        ? 'Day ${s.day} · '
            'Stop ${fromDrug.genericName} · '
            '${toDrug.genericName} '
            '${_formatDose(s.toDoseMg)} mg'
        : 'Day ${s.day} · '
            '${fromDrug.genericName} '
            '${_formatDose(s.fromDoseMg)} mg · '
            '${toDrug.genericName} '
            '${_formatDose(s.toDoseMg)} mg';
    final body = StringBuffer()
      ..writeln(summary)
      ..writeln();
    if (s.notes != null && s.notes!.isNotEmpty) {
      body.writeln(s.notes);
    }
    body.writeln();
    body.writeln('Source: PsychSwitch — reviewed cross-titration.');
    _writeAllDayEvent(
      buf,
      uid: 'psychswitch-$caseSlug-step-${s.day}@psychswitch.app',
      stamp: stamp,
      date: date,
      summary: summary,
      description: body.toString().trim(),
      categories: 'TAPER,PSYCHSWITCH',
    );
  }

  // ── Monitoring touchpoint events ──────────────────────────────────
  final monPlan = generateMonitoringPlan(
    fromDrugId: fromDrug.id,
    toDrugId: toDrug.id,
    context: contextOrNull ?? const PatientContext(),
  );
  // MonitoringEntry has no stable id field — derive a deterministic
  // slug from category + label + dayOffset for the iCal UID so the
  // same case re-exports with the same UIDs (calendar clients
  // dedup on UID).
  for (final m in monPlan.entries) {
    final date = startDate.add(Duration(days: m.dayOffset));
    final summary = '${m.label} — monitoring';
    final body = StringBuffer()
      ..writeln(m.label)
      ..writeln()
      ..writeln(m.detail)
      ..writeln()
      ..writeln('Day ${m.dayOffset} of the cross-taper.');
    final monSlug = '${m.category.name}-d${m.dayOffset}-'
        '${m.label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
    _writeAllDayEvent(
      buf,
      uid: 'psychswitch-$caseSlug-mon-$monSlug@psychswitch.app',
      stamp: stamp,
      date: date,
      summary: summary,
      description: body.toString().trim(),
      categories: 'MONITORING,PSYCHSWITCH',
    );
  }

  // ── "Switch complete" anchor on the final day ─────────────────────
  if (plan.schedule.isNotEmpty) {
    final lastDay = plan.schedule.last.day;
    final endDate = startDate.add(Duration(days: lastDay - 1));
    _writeAllDayEvent(
      buf,
      uid: 'psychswitch-$caseSlug-end@psychswitch.app',
      stamp: stamp,
      date: endDate,
      summary:
          'Switch complete — ${fromDrug.genericName} → ${toDrug.genericName}',
      description:
          'Cross-titration journey ends. Confirm tolerability at '
          'this visit and book the next routine review per the '
          'maintenance plan.',
      categories: 'COMPLETION,PSYCHSWITCH',
    );
  }

  buf.writeln('END:VCALENDAR');
  return buf.toString();
}

void _writeAllDayEvent(
  StringBuffer buf, {
  required String uid,
  required String stamp,
  required DateTime date,
  required String summary,
  required String description,
  required String categories,
}) {
  final ymd = _icalDate(date);
  final ymdNext = _icalDate(date.add(const Duration(days: 1)));
  buf
    ..writeln('BEGIN:VEVENT')
    ..writeln('UID:$uid')
    ..writeln('DTSTAMP:$stamp')
    ..writeln('DTSTART;VALUE=DATE:$ymd')
    ..writeln('DTEND;VALUE=DATE:$ymdNext')
    ..writeln('SUMMARY:${_icalEscape(summary)}')
    ..writeln('DESCRIPTION:${_icalEscape(description)}')
    ..writeln('CATEGORIES:$categories')
    ..writeln('TRANSP:TRANSPARENT')
    ..writeln('END:VEVENT');
}

String _icalDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}';

String _icalStamp(DateTime utc) {
  final d = utc;
  return '${_icalDate(d)}T'
      '${d.hour.toString().padLeft(2, '0')}'
      '${d.minute.toString().padLeft(2, '0')}'
      '${d.second.toString().padLeft(2, '0')}'
      'Z';
}

/// RFC 5545 §3.3.11 — escape commas, semicolons, backslashes, and
/// fold newlines to literal `\n`.
String _icalEscape(String s) {
  return s
      .replaceAll('\\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\n', r'\n');
}

String _formatDose(num n) {
  if (n is int || n == n.toInt()) return n.toInt().toString();
  return n.toString();
}
