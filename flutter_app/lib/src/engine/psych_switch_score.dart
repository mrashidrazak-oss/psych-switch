// PsychSwitch Score — a single 0–100 number that summarises everything
// the engine knows about a switch. Inspired by Stripe's Elements
// confidence score, FICO scores, and clinical risk indices like
// CHA₂DS₂-VASc — clinicians scan one number then dive into the
// breakdown if it looks off.
//
// Composition (start at 100, subtract penalties, floor at 0):
//
//   • Evidence (max 30 penalty): A=0, B=10, C=20, D=30
//   • Adverse-effect alignment (max 20 penalty / +5 bonus when avoids):
//       to-drug causes patient's flagged AE → -20
//       to-drug avoids patient's flagged AE → +5 (cap at 100)
//   • Patient-context safety (max 30 penalty): -8 per warning,
//       -25 per danger-level warning
//   • DDI safety (max 35 penalty):
//       caution → -5, warning → -15, avoid → -35
//   • Dose fidelity (max 10 penalty):
//       exact match → 0, mild adaptation → -3, extreme adaptation → -10
//
// Bands:
//   90+ excellent  · 75-89 good  · 50-74 caution  · <50 poor
//
// All inputs are already-computed engine outputs — this module is pure
// composition, no engine reruns. Easy to test, easy to render.
//
// Dart port of engine/psychSwitchScore.ts.

import 'package:psychswitch/src/engine/adverse_effects.dart';
import 'package:psychswitch/src/engine/citations.dart';
import 'package:psychswitch/src/engine/ddi.dart';
import 'package:psychswitch/src/engine/patient_context_pure.dart';
import 'package:psychswitch/src/engine/scale_schedule.dart';
import 'package:psychswitch/src/engine/types/drug.dart';

/// Score band tier.
enum ScoreBand {
  excellent('excellent'),
  good('good'),
  caution('caution'),
  poor('poor');

  const ScoreBand(this.jsonValue);

  final String jsonValue;

  static ScoreBand fromJson(String value) {
    for (final b in ScoreBand.values) {
      if (b.jsonValue == value) return b;
    }
    throw ArgumentError.value(value, 'value', 'unknown ScoreBand');
  }
}

/// One score component.
class ScoreComponent {
  const ScoreComponent({required this.delta, required this.note});

  /// 0 = no penalty, negative = penalty applied, positive = bonus.
  final int delta;

  /// One-line clinician-facing explanation of the delta.
  final String note;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'delta': delta,
        'note': note,
      };
}

/// Component-by-component breakdown.
class ScoreComponents {
  const ScoreComponents({
    required this.evidence,
    required this.aeAlignment,
    required this.contextSafety,
    required this.ddiSafety,
    required this.doseFidelity,
  });

  final ScoreComponent evidence;
  final ScoreComponent aeAlignment;
  final ScoreComponent contextSafety;
  final ScoreComponent ddiSafety;
  final ScoreComponent doseFidelity;
}

/// Full score result — what the Result-screen ring + breakdown card render.
class PsychSwitchScore {
  const PsychSwitchScore({
    required this.total,
    required this.band,
    required this.headline,
    required this.components,
  });

  /// 0–100.
  final int total;
  final ScoreBand band;

  /// Short headline like "Excellent fit · grade A · no contraindications".
  final String headline;

  final ScoreComponents components;
}

/// Composed inputs to the score function.
class ScoreInputs {
  const ScoreInputs({
    required this.toDrug,
    required this.scaleResult,
    required this.ddiHits,
    required this.contextWarnings,
    required this.evidenceGrade,
    this.avoidAe,
  });

  final Drug toDrug;
  final ScaleResult scaleResult;
  final List<DdiHit> ddiHits;
  final List<ContextWarning> contextWarnings;
  final EvidenceGrade evidenceGrade;

  /// When the patient context flags an AE the switch is fleeing.
  final AdverseEffect? avoidAe;
}

const Map<EvidenceGrade, int> _evidencePenalty = <EvidenceGrade, int>{
  EvidenceGrade.a: 0,
  EvidenceGrade.b: 10,
  EvidenceGrade.c: 20,
  EvidenceGrade.d: 30,
};

/// Compute the [PsychSwitchScore] for a switch.
PsychSwitchScore computePsychSwitchScore(ScoreInputs input) {
  final evidence = _scoreEvidence(input.evidenceGrade);
  final aeAlignment = _scoreAeAlignment(input.toDrug, input.avoidAe);
  final contextSafety = _scoreContextSafety(input.contextWarnings);
  final ddiSafety = _scoreDdiSafety(input.ddiHits);
  final doseFidelity = _scoreDoseFidelity(input.scaleResult);

  final raw = 100 +
      evidence.delta +
      aeAlignment.delta +
      contextSafety.delta +
      ddiSafety.delta +
      doseFidelity.delta;
  final total = raw.clamp(0, 100);
  final band = bandFor(total);

  return PsychSwitchScore(
    total: total,
    band: band,
    headline: _buildHeadline(band, input),
    components: ScoreComponents(
      evidence: evidence,
      aeAlignment: aeAlignment,
      contextSafety: contextSafety,
      ddiSafety: ddiSafety,
      doseFidelity: doseFidelity,
    ),
  );
}

// ── Component scorers ────────────────────────────────────────────────────

ScoreComponent _scoreEvidence(EvidenceGrade grade) {
  final penalty = -_evidencePenalty[grade]!;
  if (grade == EvidenceGrade.a) {
    return const ScoreComponent(delta: 0, note: 'Direct guideline source.');
  }
  final letter = grade.jsonValue;
  final note = penalty < 0
      ? 'Evidence grade $letter — ${penalty.abs()} pt deduction.'
      : 'Evidence grade $letter — no deduction.';
  return ScoreComponent(delta: penalty, note: note);
}

ScoreComponent _scoreAeAlignment(Drug toDrug, AdverseEffect? avoidAe) {
  if (avoidAe == null) {
    return const ScoreComponent(delta: 0, note: 'No AE filter set.');
  }
  if (avoidAe.switchCandidates.contains(toDrug.id)) {
    return ScoreComponent(
      delta: 5,
      note: 'Target drug avoids ${avoidAe.label.toLowerCase()}.',
    );
  }
  if (avoidAe.causedBy.contains(toDrug.id)) {
    return ScoreComponent(
      delta: -20,
      note: 'Target drug commonly causes ${avoidAe.label.toLowerCase()}.',
    );
  }
  return ScoreComponent(
    delta: 0,
    note: 'Target drug not flagged for ${avoidAe.label.toLowerCase()}.',
  );
}

ScoreComponent _scoreContextSafety(List<ContextWarning> warnings) {
  if (warnings.isEmpty) {
    return const ScoreComponent(
      delta: 0,
      note: 'No context-driven warnings.',
    );
  }
  var delta = 0;
  var dangerCount = 0;
  var warningCount = 0;
  var infoCount = 0;
  for (final w in warnings) {
    switch (w.severity) {
      case WarningSeverity.danger:
        delta -= 25;
        dangerCount++;
      case WarningSeverity.warning:
        delta -= 8;
        warningCount++;
      case WarningSeverity.info:
        delta -= 2;
        infoCount++;
    }
  }
  if (delta < -30) delta = -30;
  final parts = <String>[];
  if (dangerCount > 0) {
    parts.add('$dangerCount contraindication${dangerCount > 1 ? 's' : ''}');
  }
  if (warningCount > 0) {
    parts.add('$warningCount warning${warningCount > 1 ? 's' : ''}');
  }
  if (infoCount > 0) {
    parts.add('$infoCount note${infoCount > 1 ? 's' : ''}');
  }
  return ScoreComponent(
    delta: delta,
    note: 'Patient context: ${parts.join(', ')}.',
  );
}

ScoreComponent _scoreDdiSafety(List<DdiHit> hits) {
  if (hits.isEmpty) {
    return const ScoreComponent(
      delta: 0,
      note: 'No overlap-window interactions.',
    );
  }
  var worst = 0;
  var countAvoid = 0;
  var countWarning = 0;
  var countCaution = 0;
  for (final h in hits) {
    final r = severityRank(h.severity);
    if (r > worst) worst = r;
    switch (h.severity) {
      case DdiSeverity.avoid:
        countAvoid++;
      case DdiSeverity.warning:
        countWarning++;
      case DdiSeverity.caution:
        countCaution++;
      case DdiSeverity.info:
        break;
    }
  }
  var delta = 0;
  if (worst == 3) {
    delta = -35;
  } else if (worst == 2) {
    delta = -15;
  } else if (worst == 1) {
    delta = -5;
  }
  final String summary;
  if (worst == 3) {
    summary =
        '$countAvoid contraindicated interaction${countAvoid > 1 ? 's' : ''}';
  } else if (worst == 2) {
    summary =
        '$countWarning interaction warning${countWarning > 1 ? 's' : ''}';
  } else {
    summary =
        '$countCaution interaction caution${countCaution > 1 ? 's' : ''}';
  }
  return ScoreComponent(delta: delta, note: 'Overlap window: $summary.');
}

ScoreComponent _scoreDoseFidelity(ScaleResult scale) {
  if (!scale.adapted) {
    return const ScoreComponent(
      delta: 0,
      note: 'Doses match the reviewed reference.',
    );
  }
  final fromF = scale.applied.fromFactor;
  final toF = scale.applied.toFactor;
  bool extreme(num f) => f < 0.5 || f > 2.0;
  if (extreme(fromF) || extreme(toF)) {
    return ScoreComponent(
      delta: -10,
      note:
          'Extreme dose adaptation (${fromF.toStringAsFixed(2)}× / ${toF.toStringAsFixed(2)}×).',
    );
  }
  return ScoreComponent(
    delta: -3,
    note:
        'Mild dose adaptation (${fromF.toStringAsFixed(2)}× / ${toF.toStringAsFixed(2)}×).',
  );
}

// ── Helpers ──────────────────────────────────────────────────────────────

/// Map a 0–100 score to its band.
ScoreBand bandFor(int total) {
  if (total >= 90) return ScoreBand.excellent;
  if (total >= 75) return ScoreBand.good;
  if (total >= 50) return ScoreBand.caution;
  return ScoreBand.poor;
}

/// Display label for a [ScoreBand].
String bandLabel(ScoreBand b) {
  switch (b) {
    case ScoreBand.excellent:
      return 'Excellent fit';
    case ScoreBand.good:
      return 'Good fit';
    case ScoreBand.caution:
      return 'Use with caution';
    case ScoreBand.poor:
      return 'Poor fit';
  }
}

/// Semantic colour-token triple for a band. UI maps to AppColors.
({String bg, String border, String text}) bandColorTokens(ScoreBand b) {
  switch (b) {
    case ScoreBand.excellent:
      return (bg: 'to', border: 'to', text: 'to');
    case ScoreBand.good:
      return (bg: 'accent', border: 'accent', text: 'accent');
    case ScoreBand.caution:
      return (bg: 'warning', border: 'warning', text: 'warning');
    case ScoreBand.poor:
      return (bg: 'danger', border: 'danger', text: 'danger');
  }
}

String _buildHeadline(ScoreBand band, ScoreInputs input) {
  final parts = <String>[
    bandLabel(band),
    'grade ${input.evidenceGrade.jsonValue}',
  ];
  if (input.contextWarnings.any((w) => w.severity == WarningSeverity.danger)) {
    parts.add('contraindication flagged');
  } else if (input.ddiHits.any((h) => h.severity == DdiSeverity.avoid)) {
    parts.add('avoid-grade DDI');
  } else if (input.contextWarnings.isEmpty && input.ddiHits.isEmpty) {
    parts.add('no warnings');
  }
  return parts.join(' · ');
}
