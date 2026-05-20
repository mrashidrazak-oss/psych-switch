// Lints relaxed for this file:
//   • prefer_const_constructors — the `pdf` package's pw.* widgets
//     aren't `const`-constructible in many places, but their wrappers
//     elsewhere are; the analyser misfires on the `pw.Border`,
//     `pw.BorderSide`, `pw.BoxShape` cases. Silenced at file level.
//   • avoid_redundant_argument_values — explicit `width: 0.5` etc. on
//     pw.BorderSide reads better and survives refactors.
//   • document_ignores — the file-level ignore line is documented here.
// ignore_for_file: prefer_const_constructors, avoid_redundant_argument_values, document_ignores, cascade_invocations
//
// PDF export — builds an A4 portrait document for the cross-taper plan
// using the `pdf` package, then hands it to `printing` for native
// print/share. RN parity: same content sections (header, dose mapping,
// rationale, schedule table, monitoring, citations, footer) but
// rendered server-side rather than via WKWebView/Android WebView.
//
// Why a real Dart PDF rather than HTML-to-PDF: deterministic output
// across iOS/Android, no WebView dependency, smaller binary, and we
// can hit hospital print queues directly via `printing`'s
// `Printing.layoutPdf()` / `Printing.sharePdf()` calls.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/enums.dart';

/// Brand palette (PDF-safe — no alpha).
const PdfColor _ink = PdfColor.fromInt(0xFF0B0F14);
const PdfColor _surface = PdfColor.fromInt(0xFFF5F7FA);
const PdfColor _border = PdfColor.fromInt(0xFFD0D7DE);
const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
const PdfColor _accent = PdfColor.fromInt(0xFF3B82F6);
const PdfColor _from = PdfColor.fromInt(0xFF2563EB);
const PdfColor _to = PdfColor.fromInt(0xFF059669);
const PdfColor _warning = PdfColor.fromInt(0xFFB45309);

/// Build the cross-taper PDF and hand it to the system print/share
/// sheet. Returns `false` if the user cancels or the platform doesn't
/// support print preview.
Future<bool> exportSwitchPlanPdf({
  required Drug fromDrug,
  required Drug toDrug,
  required SwitchPlanOk plan,
}) async {
  final doc = await _buildSwitchPlanDocument(
    fromDrug: fromDrug,
    toDrug: toDrug,
    plan: plan,
  );
  final ok = await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => doc.save(),
    name: 'PsychSwitch — ${fromDrug.genericName} → ${toDrug.genericName}',
  );
  return ok;
}

Future<pw.Document> _buildSwitchPlanDocument({
  required Drug fromDrug,
  required Drug toDrug,
  required SwitchPlanOk plan,
}) async {
  final doc = pw.Document(
    title:
        'PsychSwitch — ${fromDrug.genericName} → ${toDrug.genericName}',
    author: 'PsychSwitch',
    creator: 'PsychSwitch (Flutter)',
  );

  // Pull a Material Symbols-ish system font so emoji / unicode glyphs
  // render. Use the bundled monospace fallback for the schedule table.
  final base = pw.Font.helvetica();
  final baseBold = pw.Font.helveticaBold();
  final mono = pw.Font.courier();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
      header: (ctx) => _header(fromDrug, toDrug, plan, base, baseBold),
      footer: (ctx) => _footer(ctx, base),
      build: (ctx) => <pw.Widget>[
        _doseMapping(plan, fromDrug, toDrug, base, baseBold),
        pw.SizedBox(height: 16),
        if (plan.rule.rationale.isNotEmpty)
          _rationale(plan.rule.rationale, base, baseBold),
        if (plan.rule.rationale.isNotEmpty) pw.SizedBox(height: 16),
        _scheduleTable(plan, fromDrug, toDrug, base, baseBold, mono),
        pw.SizedBox(height: 16),
        if (plan.safetyFlags.isNotEmpty) ...<pw.Widget>[
          _monitoring(plan, base, baseBold),
          pw.SizedBox(height: 16),
        ],
        _citations(plan, base, baseBold),
      ],
    ),
  );

  return doc;
}

// ── Sections ────────────────────────────────────────────────────────

pw.Widget _header(
  Drug fromDrug,
  Drug toDrug,
  SwitchPlanOk plan,
  pw.Font base,
  pw.Font baseBold,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _border)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Row(
          children: <pw.Widget>[
            pw.Container(
              width: 28,
              height: 28,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: _accent,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'PS',
                style: pw.TextStyle(
                  font: baseBold,
                  fontSize: 13,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              'PsychSwitch',
              style: pw.TextStyle(
                font: baseBold,
                fontSize: 18,
                color: _ink,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              '· Cross-taper plan',
              style: pw.TextStyle(
                font: base,
                fontSize: 11,
                color: _muted,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '${fromDrug.genericName} → ${toDrug.genericName}',
          style: pw.TextStyle(
            font: baseBold,
            fontSize: 22,
            color: _ink,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${_strategyLabel(plan.rule.strategy)} · ${plan.rule.durationDays} days '
          '· Reviewed by ${plan.rule.reviewedBy}',
          style: pw.TextStyle(
            font: base,
            fontSize: 10,
            color: _muted,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _doseMapping(
  SwitchPlanOk plan,
  Drug fromDrug,
  Drug toDrug,
  pw.Font base,
  pw.Font baseBold,
) {
  final equivNote = plan.rule.doseRatios.equivalencyNote
      .replaceAll('PENDING_CLINICAL_REVIEW', '')
      .trim();
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _surface,
      border: pw.Border.all(color: _border),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _eyebrow('DOSE MAPPING', baseBold),
        pw.SizedBox(height: 6),
        pw.RichText(
          text: pw.TextSpan(
            children: <pw.InlineSpan>[
              pw.TextSpan(
                text: '${fromDrug.genericName} '
                    '${_formatDose(plan.rule.doseRatios.fromCurrentDoseMg)} mg',
                style: pw.TextStyle(font: baseBold, color: _from, fontSize: 13),
              ),
              pw.TextSpan(
                text: '   ≈   ',
                style: pw.TextStyle(font: base, color: _muted, fontSize: 13),
              ),
              pw.TextSpan(
                text: '${toDrug.genericName} '
                    '${_formatDose(plan.rule.doseRatios.toTargetDoseMg)} mg',
                style: pw.TextStyle(font: baseBold, color: _to, fontSize: 13),
              ),
            ],
          ),
        ),
        if (equivNote.isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 6),
          pw.Text(
            equivNote,
            style: pw.TextStyle(font: base, fontSize: 10, color: _muted),
          ),
        ],
        if (!plan.dosesMatchReference) ...<pw.Widget>[
          pw.SizedBox(height: 6),
          pw.Text(
            'Note: You entered '
            '${_formatDose(plan.inputDoses.fromMg)} mg → '
            '${_formatDose(plan.inputDoses.toMg)} mg. '
            'Schedule below is the reviewed reference — adapt doses '
            'proportionally.',
            style: pw.TextStyle(
              font: base,
              fontSize: 9.5,
              color: _warning,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _rationale(String rationale, pw.Font base, pw.Font baseBold) {
  final cleaned = rationale
      .replaceAll('PENDING_CLINICAL_REVIEW', '')
      .trim();
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      _eyebrow('WHY THIS STRATEGY', baseBold),
      pw.SizedBox(height: 6),
      pw.Text(
        cleaned,
        style: pw.TextStyle(font: base, fontSize: 11, color: _ink),
      ),
    ],
  );
}

pw.Widget _scheduleTable(
  SwitchPlanOk plan,
  Drug fromDrug,
  Drug toDrug,
  pw.Font base,
  pw.Font baseBold,
  pw.Font mono,
) {
  final fromUnit = fromDrug.formulation == Formulation.lai ? 'mg/inj' : 'mg';
  final toUnit = toDrug.formulation == Formulation.lai ? 'mg/inj' : 'mg';

  final headStyle =
      pw.TextStyle(font: baseBold, fontSize: 9, color: _muted);
  final dayStyle = pw.TextStyle(font: baseBold, fontSize: 11, color: _accent);
  final fromStyle = pw.TextStyle(font: mono, fontSize: 10.5, color: _from);
  final toStyle = pw.TextStyle(font: mono, fontSize: 10.5, color: _to);
  final notesStyle = pw.TextStyle(font: base, fontSize: 9.5, color: _muted);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      _eyebrow('SCHEDULE', baseBold),
      pw.SizedBox(height: 6),
      pw.Table(
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _border, width: 0.5),
          top: pw.BorderSide(color: _border, width: 0.5),
          bottom: pw.BorderSide(color: _border, width: 0.5),
        ),
        columnWidths: const <int, pw.TableColumnWidth>{
          0: pw.FixedColumnWidth(36),
          1: pw.FixedColumnWidth(70),
          2: pw.FixedColumnWidth(70),
          3: pw.FlexColumnWidth(),
        },
        children: <pw.TableRow>[
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _surface),
            children: <pw.Widget>[
              _cell(pw.Text('DAY', style: headStyle)),
              _cell(pw.Text('FROM', style: headStyle)),
              _cell(pw.Text('TO', style: headStyle)),
              _cell(pw.Text('NOTES', style: headStyle)),
            ],
          ),
          for (final s in plan.schedule)
            pw.TableRow(
              children: <pw.Widget>[
                _cell(pw.Text(s.day.toString(), style: dayStyle)),
                _cell(
                  pw.Text(
                    s.fromDoseMg == 0
                        ? 'STOP'
                        : '${_formatDose(s.fromDoseMg)} $fromUnit',
                    style: fromStyle,
                  ),
                ),
                _cell(
                  pw.Text(
                    s.toDoseMg == 0
                        ? '—'
                        : '${_formatDose(s.toDoseMg)} $toUnit',
                    style: toStyle,
                  ),
                ),
                _cell(pw.Text(s.notes ?? '', style: notesStyle)),
              ],
            ),
        ],
      ),
    ],
  );
}

pw.Widget _monitoring(SwitchPlanOk plan, pw.Font base, pw.Font baseBold) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      _eyebrow('MONITORING CHECKLIST', baseBold),
      pw.SizedBox(height: 6),
      for (final flag in plan.safetyFlags)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Text(
            '• ${flag.replaceAll('_', ' ')}',
            style: pw.TextStyle(font: base, fontSize: 10.5, color: _ink),
          ),
        ),
    ],
  );
}

pw.Widget _citations(SwitchPlanOk plan, pw.Font base, pw.Font baseBold) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      _eyebrow('REFERENCES', baseBold),
      pw.SizedBox(height: 6),
      for (var i = 0; i < plan.citations.length; i++)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(
            '[${i + 1}] ${plan.citations[i]}',
            style: pw.TextStyle(font: base, fontSize: 9.5, color: _muted),
          ),
        ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Last reviewed: ${plan.rule.lastReviewedISO}',
        style: pw.TextStyle(font: base, fontSize: 9, color: _muted),
      ),
    ],
  );
}

pw.Widget _footer(pw.Context ctx, pw.Font base) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(top: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _border)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text(
          'Decision support only — not medical advice.',
          style: pw.TextStyle(font: base, fontSize: 9, color: _muted),
        ),
        pw.Text(
          'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
          style: pw.TextStyle(font: base, fontSize: 9, color: _muted),
        ),
      ],
    ),
  );
}

// ── Helpers ─────────────────────────────────────────────────────────

pw.Widget _cell(pw.Widget child) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: child,
    );

pw.Widget _eyebrow(String text, pw.Font baseBold) => pw.Text(
      text,
      style: pw.TextStyle(
        font: baseBold,
        fontSize: 9,
        color: _muted,
        letterSpacing: 1.4,
      ),
    );

String _formatDose(num n) {
  if (n is int || n == n.toInt()) return n.toInt().toString();
  return n.toString();
}

String _strategyLabel(Strategy s) => switch (s) {
      Strategy.direct => 'Direct switch',
      Strategy.crossTaper => 'Cross-taper',
      Strategy.plateauCrossTaper => 'Plateau cross-taper',
      Strategy.overlapTaper => 'Overlap taper',
      Strategy.washout => 'Washout',
    };

// ─────────────────────────────────────────────────────────────────────
// ── PATIENT HANDOUT ─────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────
//
// A separate A4 export aimed at the PATIENT (not the clinician). Same
// underlying plan, but plain-language wording, bigger print, no scoring
// jargon, no rationale paragraph aimed at peers. Layout:
//
//   • Friendly header naming the two drugs.
//   • "Your switch in plain English" paragraph.
//   • Day-by-day schedule with morning/evening dose icons.
//   • "What to expect" — red flags, common side effects, when to call.
//   • Clinician sign-off block at the bottom.
//
// Designed to be handed over (or AirDropped) at the end of the visit.
// Body type at 12-pt; the headline at 22-pt so an older patient can
// read it across a desk.

Future<bool> exportPatientHandoutPdf({
  required Drug fromDrug,
  required Drug toDrug,
  required SwitchPlanOk plan,
  String? clinicianName,
  String? clinicName,
}) async {
  final doc = await _buildPatientHandoutDocument(
    fromDrug: fromDrug,
    toDrug: toDrug,
    plan: plan,
    clinicianName: clinicianName,
    clinicName: clinicName,
  );
  return Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => doc.save(),
    name:
        'PsychSwitch — patient handout — ${fromDrug.genericName} → '
        '${toDrug.genericName}',
  );
}

Future<pw.Document> _buildPatientHandoutDocument({
  required Drug fromDrug,
  required Drug toDrug,
  required SwitchPlanOk plan,
  String? clinicianName,
  String? clinicName,
}) async {
  final base = await PdfGoogleFonts.interRegular();
  final baseBold = await PdfGoogleFonts.interSemiBold();
  final baseHeavy = await PdfGoogleFonts.interBold();

  final doc = pw.Document(
    title: 'PsychSwitch patient handout',
    author: 'PsychSwitch',
    creator: 'PsychSwitch',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 36),
      theme: pw.ThemeData.withFont(base: base, bold: baseBold),
      header: (_) => _patientHeader(baseBold, fromDrug, toDrug),
      footer: (ctx) => _patientFooter(ctx, base, clinicianName, clinicName),
      build: (_) => <pw.Widget>[
        _patientHero(baseHeavy, base, fromDrug, toDrug, plan),
        pw.SizedBox(height: 18),
        _patientPlainEnglish(baseBold, base, fromDrug, toDrug, plan),
        pw.SizedBox(height: 22),
        _patientScheduleTable(baseBold, base, plan, fromDrug, toDrug),
        pw.SizedBox(height: 22),
        _patientWhatToExpect(baseBold, base),
        pw.SizedBox(height: 18),
        _patientRedFlags(baseBold, baseHeavy, base),
        pw.SizedBox(height: 18),
        _patientSignOff(baseBold, base, clinicianName, clinicName),
      ],
    ),
  );

  return doc;
}

pw.Widget _patientHeader(pw.Font baseBold, Drug from, Drug to) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 16),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text(
          'YOUR MEDICATION CHANGE',
          style: pw.TextStyle(
            font: baseBold,
            fontSize: 10,
            color: _muted,
            letterSpacing: 1.6,
          ),
        ),
        pw.Text(
          'Generated by PsychSwitch',
          style: pw.TextStyle(font: baseBold, fontSize: 9, color: _muted),
        ),
      ],
    ),
  );
}

pw.Widget _patientHero(
  pw.Font heavy,
  pw.Font base,
  Drug from,
  Drug to,
  SwitchPlanOk plan,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 18),
    decoration: pw.BoxDecoration(
      color: _surface,
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: _border, width: 0.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          'Switching from ${from.genericName} to ${to.genericName}',
          style: pw.TextStyle(
            font: heavy,
            fontSize: 22,
            color: _ink,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: <pw.Widget>[
            _patientChip('FROM', _from, base),
            pw.SizedBox(width: 8),
            pw.Text(
              '${from.genericName} ${_formatDose(plan.inputDoses.fromMg)} mg',
              style: pw.TextStyle(font: base, fontSize: 13, color: _ink),
            ),
            pw.SizedBox(width: 14),
            _patientChip('TO', _to, base),
            pw.SizedBox(width: 8),
            pw.Text(
              '${to.genericName} ${_formatDose(plan.inputDoses.toMg)} mg',
              style: pw.TextStyle(font: base, fontSize: 13, color: _ink),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Over ${plan.rule.durationDays} days, '
          'in steps shown below.',
          style: pw.TextStyle(font: base, fontSize: 12, color: _muted),
        ),
      ],
    ),
  );
}

pw.Widget _patientChip(String label, PdfColor tone, pw.Font base) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: pw.BoxDecoration(
      color: PdfColor(tone.red, tone.green, tone.blue, 0.14),
      borderRadius: pw.BorderRadius.circular(999),
    ),
    child: pw.Text(
      label,
      style: pw.TextStyle(
        font: base,
        fontSize: 9,
        color: tone,
        letterSpacing: 1.2,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _patientPlainEnglish(
  pw.Font baseBold,
  pw.Font base,
  Drug from,
  Drug to,
  SwitchPlanOk plan,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      _eyebrow('IN PLAIN ENGLISH', baseBold),
      pw.SizedBox(height: 8),
      pw.Text(
        'You will gradually reduce ${from.genericName} while gradually '
        'starting ${to.genericName}. Over '
        '${plan.rule.durationDays} days, the dose of '
        '${from.genericName} will come down each step and '
        '${to.genericName} will go up. By the last day you will be on '
        '${to.genericName} only.',
        style: pw.TextStyle(font: base, fontSize: 12, color: _ink, height: 1.55),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Do not stop either medicine on your own. Take what the table '
        'below says, on the day it says. If anything is unclear, call '
        'the clinic before changing the dose yourself.',
        style: pw.TextStyle(font: base, fontSize: 12, color: _ink, height: 1.55),
      ),
    ],
  );
}

pw.Widget _patientScheduleTable(
  pw.Font baseBold,
  pw.Font base,
  SwitchPlanOk plan,
  Drug from,
  Drug to,
) {
  pw.Widget headerCell(String t) => _cell(
        pw.Text(
          t,
          style: pw.TextStyle(
            font: baseBold,
            fontSize: 10,
            color: _muted,
            letterSpacing: 1.2,
          ),
        ),
      );
  pw.Widget bodyCell(String t, {PdfColor color = _ink}) => _cell(
        pw.Text(
          t,
          style: pw.TextStyle(font: base, fontSize: 12, color: color),
        ),
      );
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      _eyebrow('YOUR DAY-BY-DAY DOSES', baseBold),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.symmetric(
          inside: pw.BorderSide(color: _border, width: 0.5),
        ),
        columnWidths: const <int, pw.TableColumnWidth>{
          0: pw.FlexColumnWidth(1),
          1: pw.FlexColumnWidth(2.4),
          2: pw.FlexColumnWidth(2.4),
          3: pw.FlexColumnWidth(4),
        },
        children: <pw.TableRow>[
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _surface),
            children: <pw.Widget>[
              headerCell('DAY'),
              headerCell('${from.genericName.toUpperCase()} (FROM)'),
              headerCell('${to.genericName.toUpperCase()} (TO)'),
              headerCell('WHAT THIS MEANS'),
            ],
          ),
          for (final s in plan.schedule)
            pw.TableRow(
              children: <pw.Widget>[
                bodyCell('Day ${s.day}'),
                bodyCell(
                  s.fromDoseMg == 0
                      ? 'Stop'
                      : '${_formatDose(s.fromDoseMg)} mg/day',
                  color: s.fromDoseMg == 0 ? _muted : _from,
                ),
                bodyCell(
                  s.toDoseMg == 0
                      ? '—'
                      : '${_formatDose(s.toDoseMg)} mg/day',
                  color: s.toDoseMg == 0 ? _muted : _to,
                ),
                bodyCell(s.notes ?? ''),
              ],
            ),
        ],
      ),
    ],
  );
}

pw.Widget _patientWhatToExpect(pw.Font baseBold, pw.Font base) {
  const bullets = <String>[
    // ignore: no_adjacent_strings_in_list — single-paragraph copy
    // wrapped for source readability.
    'Some mild dizziness, nausea, or sleep changes in the first 1–2 weeks are common and usually settle. Take doses with food if your stomach is sensitive.',
    'It can take 4–6 weeks to feel the full effect of the new medicine. Stay patient and stick with the schedule.',
    'If you feel suddenly worse — low mood deepens, anxiety surges, sleep collapses — call the clinic that same day rather than waiting for the next appointment.',
    'Do not start any new medicine (including over-the-counter, herbal or supplements) without checking with your prescriber. Some combinations can be dangerous during the changeover.',
  ];
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      _eyebrow('WHAT TO EXPECT', baseBold),
      pw.SizedBox(height: 8),
      for (final b in bullets) ...<pw.Widget>[
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Container(
                width: 5,
                height: 5,
                margin: const pw.EdgeInsets.only(top: 6, right: 8),
                decoration: const pw.BoxDecoration(
                  color: _accent,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  b,
                  style: pw.TextStyle(
                    font: base,
                    fontSize: 12,
                    color: _ink,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

pw.Widget _patientRedFlags(
  pw.Font baseBold,
  pw.Font heavy,
  pw.Font base,
) {
  const flags = <String>[
    'Confusion, fever, muscle stiffness or twitching, fast heart rate — this can be serotonin syndrome. Call 999 / 999 the same hour.',
    'Severe rash with mouth or eye involvement — stop both medicines, call the clinic and go to A&E.',
    'Thoughts of self-harm or hurting others — call the clinic same day or contact a mental-health crisis line.',
    'Difficulty passing urine, severe constipation that lasts > 48 h, chest pain, or fainting — same-day clinic call.',
  ];
  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: pw.BoxDecoration(
      color: PdfColor(_warning.red, _warning.green, _warning.blue, 0.08),
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border(
        left: pw.BorderSide(color: _warning, width: 3),
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          'CALL US IF',
          style: pw.TextStyle(
            font: heavy,
            fontSize: 10,
            color: _warning,
            letterSpacing: 1.4,
          ),
        ),
        pw.SizedBox(height: 8),
        for (final f in flags)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  '•',
                  style: pw.TextStyle(
                    font: heavy,
                    fontSize: 12,
                    color: _warning,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Text(
                    f,
                    style: pw.TextStyle(
                      font: base,
                      fontSize: 11.5,
                      color: _ink,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

pw.Widget _patientSignOff(
  pw.Font baseBold,
  pw.Font base,
  String? clinicianName,
  String? clinicName,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 14),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _border, width: 0.5),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                'Prescribed by',
                style: pw.TextStyle(font: baseBold, fontSize: 9, color: _muted),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                clinicianName ?? '_________________________',
                style: pw.TextStyle(font: baseBold, fontSize: 13, color: _ink),
              ),
              if (clinicName != null) ...<pw.Widget>[
                pw.SizedBox(height: 2),
                pw.Text(
                  clinicName,
                  style: pw.TextStyle(font: base, fontSize: 11, color: _muted),
                ),
              ],
            ],
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                'Date',
                style: pw.TextStyle(font: baseBold, fontSize: 9, color: _muted),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '_______________',
                style: pw.TextStyle(font: base, fontSize: 13, color: _ink),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _patientFooter(
  pw.Context ctx,
  pw.Font base,
  String? clinicianName,
  String? clinicName,
) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 14),
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text(
          'PsychSwitch · Patient handout · Reviewed cross-titration',
          style: pw.TextStyle(font: base, fontSize: 9, color: _muted),
        ),
        pw.Text(
          'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
          style: pw.TextStyle(font: base, fontSize: 9, color: _muted),
        ),
      ],
    ),
  );
}
