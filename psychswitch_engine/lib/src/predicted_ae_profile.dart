// Predicted adverse-effect profile for the to-drug.
//
// Cross-references the ADVERSE_EFFECTS table (engine/adverse_effects.dart)
// and the to-drug's per-AE risk fields (sedation, epsRisk, prolactinRisk,
// qtcRisk, metabolicRisk, discontinuationSyndromeRisk) to surface a
// prioritized list of "watch out for these on the new drug".
//
// Two data sources, in priority order:
//   1. Per-drug risk fields on the JSON (qualitative 'low' | 'moderate'
//      | 'high' | 'very high'). Maps directly to a likelihood tier.
//   2. The reverse-lookup table in adverse_effects.dart (drug appears in
//      `causedBy` → likely; drug appears in `switchCandidates` →
//      unlikely relative to the from-drug).
//
// We deliberately don't try to give a numeric percentage. Cipriani 2018
// and Leucht 2013 NMAs report drug-vs-placebo odds ratios, not absolute
// risks, and copying those out of context would be misleading. Instead
// we surface tiers — clinicians know what "high prolactin risk" looks
// like for risperidone, they don't need a percentage.
//
// Dart port of engine/predictedAeProfile.ts.

import 'package:psychswitch_engine/adverse_effects.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/enums.dart';

/// Likelihood tier for a single AE on the to-drug.
enum AeLikelihood {
  high('high'),
  moderate('moderate'),
  low('low'),
  lowerThanCurrent('lower-than-current'),
  unknown('unknown');

  const AeLikelihood(this.jsonValue);

  final String jsonValue;

  static AeLikelihood fromJson(String value) {
    for (final l in AeLikelihood.values) {
      if (l.jsonValue == value) return l;
    }
    throw ArgumentError.value(value, 'value', 'unknown AeLikelihood');
  }
}

/// One predicted AE row.
class PredictedAe {
  const PredictedAe({
    required this.ae,
    required this.likelihood,
    required this.reason,
  });

  /// Reference to the adverse-effect entry (id, label, summary, etc.).
  final AdverseEffect ae;

  final AeLikelihood likelihood;

  /// Why we chose this tier — for the "?" tooltip / breakdown row.
  final String reason;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ae': ae.toJson(),
        'likelihood': likelihood.jsonValue,
        'reason': reason,
      };
}

/// Full prediction output for a to-drug.
class PredictedAeProfile {
  const PredictedAeProfile({required this.toDrug, required this.predictions});

  final Drug toDrug;

  /// Sorted list — high → moderate → low → lower-than-current → unknown.
  final List<PredictedAe> predictions;
}

const Map<RiskLevel, AeLikelihood> _riskToLikelihood = <RiskLevel, AeLikelihood>{
  RiskLevel.veryHigh: AeLikelihood.high,
  RiskLevel.high: AeLikelihood.high,
  RiskLevel.moderate: AeLikelihood.moderate,
  RiskLevel.lowModerate: AeLikelihood.moderate,
  RiskLevel.low: AeLikelihood.low,
};

/// Generate a predicted AE profile for the to-drug, optionally
/// comparing against the from-drug to highlight what's *better* on the
/// new agent.
PredictedAeProfile predictAeProfile(Drug toDrug, [Drug? fromDrug]) {
  final predictions = <PredictedAe>[];
  for (final ae in adverseEffects) {
    final pred = _predictOne(ae, toDrug, fromDrug);
    if (pred != null) predictions.add(pred);
  }
  predictions.sort(
    (a, b) => _likelihoodRank(b.likelihood) - _likelihoodRank(a.likelihood),
  );
  return PredictedAeProfile(toDrug: toDrug, predictions: predictions);
}

PredictedAe? _predictOne(
  AdverseEffect ae,
  Drug toDrug,
  Drug? fromDrug,
) {
  // Source 1 — per-drug typed risk fields.
  final fieldRisk = _pickRiskField(toDrug, ae.id);
  final fieldTier = fieldRisk != null ? _riskToLikelihood[fieldRisk] : null;

  // Source 2 — adverseEffects reverse-lookup.
  final inCauses = ae.causedBy.contains(toDrug.id);
  final inAvoids = ae.switchCandidates.contains(toDrug.id);
  final fromCauses =
      fromDrug != null && ae.causedBy.contains(fromDrug.id);

  AeLikelihood? lookupTier;
  var lookupReason = '';
  if (inCauses && inAvoids) {
    lookupTier = AeLikelihood.moderate;
    lookupReason = 'Listed in both candidates and causes.';
  } else if (inCauses) {
    lookupTier = AeLikelihood.high;
    lookupReason = 'Commonly caused by this drug.';
  } else if (inAvoids && fromCauses) {
    lookupTier = AeLikelihood.lowerThanCurrent;
    lookupReason =
        'Recommended switch target for ${ae.label.toLowerCase()}.';
  } else if (inAvoids) {
    lookupTier = AeLikelihood.low;
    lookupReason = 'Not typically caused by this drug.';
  }

  // Comparative hint always wins — it's the most useful signal in
  // a switching context.
  if (lookupTier == AeLikelihood.lowerThanCurrent) {
    return PredictedAe(
      ae: ae,
      likelihood: AeLikelihood.lowerThanCurrent,
      reason: lookupReason,
    );
  }

  if (fieldTier == null && lookupTier == null) return null;

  final winner = _takeHigher(fieldTier, lookupTier);
  final String reason;
  if (fieldTier != null && lookupTier != null) {
    reason = winner == fieldTier
        ? 'Drug profile: ${fieldRisk!.jsonValue} risk.'
        : lookupReason;
  } else if (fieldTier != null) {
    reason = 'Drug profile: ${fieldRisk!.jsonValue} risk.';
  } else {
    reason = lookupReason;
  }
  return PredictedAe(ae: ae, likelihood: winner, reason: reason);
}

AeLikelihood _takeHigher(AeLikelihood? a, AeLikelihood? b) {
  if (a == null && b == null) return AeLikelihood.unknown;
  if (a == null) return b!;
  if (b == null) return a;
  return _likelihoodRank(a) >= _likelihoodRank(b) ? a : b;
}

/// Map an AE id to the matching risk field on the Drug object. We only
/// surface a few common AEs through the typed fields; everything else
/// falls through to the reverse-lookup table.
RiskLevel? _pickRiskField(Drug drug, String aeId) {
  switch (aeId) {
    case 'sedation':
      return drug.sedation;
    case 'eps_akathisia':
      return drug.epsRisk;
    case 'hyperprolactinaemia':
      return drug.prolactinRisk;
    case 'qtc_prolongation':
      return drug.qtcRisk;
    case 'weight_gain':
      return drug.metabolicRisk?.score;
    case 'discontinuation_difficult':
      return drug.discontinuationSyndromeRisk?.score;
    default:
      return null;
  }
}

int _likelihoodRank(AeLikelihood l) {
  switch (l) {
    case AeLikelihood.high:
      return 4;
    case AeLikelihood.moderate:
      return 3;
    case AeLikelihood.low:
      return 2;
    case AeLikelihood.lowerThanCurrent:
      return 1;
    case AeLikelihood.unknown:
      return 0;
  }
}

/// Display label for an [AeLikelihood].
String likelihoodLabel(AeLikelihood l) {
  switch (l) {
    case AeLikelihood.high:
      return 'High likelihood';
    case AeLikelihood.moderate:
      return 'Moderate likelihood';
    case AeLikelihood.low:
      return 'Low likelihood';
    case AeLikelihood.lowerThanCurrent:
      return 'Lower than current drug';
    case AeLikelihood.unknown:
      return 'Unknown';
  }
}

/// Semantic colour-token pair for a likelihood. UI maps to AppColors.
({String bg, String text}) likelihoodColorTokens(AeLikelihood l) {
  switch (l) {
    case AeLikelihood.high:
      return (bg: 'danger', text: 'danger');
    case AeLikelihood.moderate:
      return (bg: 'warning', text: 'warning');
    case AeLikelihood.low:
      return (bg: 'accent', text: 'accent');
    case AeLikelihood.lowerThanCurrent:
      return (bg: 'to', text: 'to');
    case AeLikelihood.unknown:
      return (bg: 'border', text: 'muted');
  }
}
