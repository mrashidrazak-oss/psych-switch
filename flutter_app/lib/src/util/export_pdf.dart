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
