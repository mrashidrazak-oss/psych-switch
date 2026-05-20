// Specialty-depth orchestrator.
//
// Given a drug pair + patient context, decides which specialty
// modules apply (pregnancy, breastfeeding, pediatric, geriatric) and
// returns a unified assessment for the UI / MCP / sharing pipeline.
//
// The patient-context engine (engine/patient_context_pure.dart) already
// generates *warnings* (info / warning / danger). The specialty engine
// generates *recommendations* — tier-ranked, with dose modifiers and
// additional monitoring. Different shape, complementary purpose.
//
// Dart port of engine/specialty.ts.

import 'package:psychswitch_engine/patient_context_pure.dart';
import 'package:psychswitch_engine/specialty/geriatric.dart';
import 'package:psychswitch_engine/specialty/pediatric.dart';
import 'package:psychswitch_engine/specialty/pregnancy.dart';
import 'package:psychswitch_engine/specialty/types.dart';

export 'package:psychswitch_engine/specialty/geriatric.dart';
export 'package:psychswitch_engine/specialty/pediatric.dart';
export 'package:psychswitch_engine/specialty/pregnancy.dart';
export 'package:psychswitch_engine/specialty/types.dart';

/// One per-drug specialty recommendation.
class SpecialtyRecommendation {
  const SpecialtyRecommendation({
    required this.specialty,
    required this.drugId,
    required this.tier,
    required this.rationale,
    required this.citations,
    this.drugName,
    this.doseFactor,
    this.additionalMonitoring,
    this.knownRisks,
  });

  final Specialty specialty;
  final String drugId;

  /// Display label, e.g. "Olanzapine".
  final String? drugName;

  final SpecialtyTier tier;
  final String rationale;

  /// Dose modifier as a multiplier of the adult target (0–1).
  final num? doseFactor;

  /// Extra monitoring entries (free-form).
  final List<String>? additionalMonitoring;

  /// Specific risks this specialty raises.
  final String? knownRisks;

  final List<String> citations;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'specialty': specialty.jsonValue,
        'drugId': drugId,
        if (drugName != null) 'drugName': drugName,
        'tier': tier.jsonValue,
        'rationale': rationale,
        if (doseFactor != null) 'doseFactor': doseFactor,
        if (additionalMonitoring != null)
          'additionalMonitoring': additionalMonitoring,
        if (knownRisks != null) 'knownRisks': knownRisks,
        'citations': citations,
      };
}

/// Unified output of [assessSpecialty].
class SpecialtyAssessment {
  const SpecialtyAssessment({
    required this.applicable,
    required this.recommendations,
    required this.headline,
  });

  /// Which specialties are active for this patient.
  final List<Specialty> applicable;

  /// Tier-sorted recommendations across both drugs + active specialties.
  final List<SpecialtyRecommendation> recommendations;

  /// Single-line summary for display headers.
  final String headline;
}

const List<Specialty> _specialtyOrder = <Specialty>[
  Specialty.pregnancy,
  Specialty.breastfeeding,
  Specialty.pediatric,
  Specialty.geriatric,
];

const Map<SpecialtyTier, int> _tierRank = <SpecialtyTier, int>{
  SpecialtyTier.avoid: 0,
  SpecialtyTier.caution: 1,
  SpecialtyTier.acceptable: 2,
  SpecialtyTier.preferred: 3,
};

/// Decide which specialty modules apply given the patient context.
List<Specialty> activeSpecialties(PatientContext ctx) {
  final out = <Specialty>[];
  if (ctx.pregnant ?? false) out.add(Specialty.pregnancy);
  if (ctx.breastfeeding ?? false) out.add(Specialty.breastfeeding);
  final band = ageBand(ctx);
  if (band == AgeBand.pediatric) out.add(Specialty.pediatric);
  if (band == AgeBand.olderAdult) out.add(Specialty.geriatric);
  return out;
}

/// Run the full specialty assessment for a switch.
SpecialtyAssessment assessSpecialty({
  required String fromDrugId,
  required String toDrugId,
  required PatientContext context,
  String? fromDrugName,
  String? toDrugName,
}) {
  final applicable = activeSpecialties(context);
  final recs = <SpecialtyRecommendation>[];

  for (final drugId in <String>[fromDrugId, toDrugId]) {
    final drugName = drugId == fromDrugId ? fromDrugName : toDrugName;
    final trimester = context.trimester;
    final ageYears = context.ageYears;

    if (applicable.contains(Specialty.pregnancy)) {
      final e = pregnancyEntryFor(drugId);
      if (e != null) {
        final tier = pregnancyTierFor(drugId, trimester) ?? e.tier;
        recs.add(
          SpecialtyRecommendation(
            specialty: Specialty.pregnancy,
            drugId: drugId,
            drugName: drugName,
            tier: tier,
            rationale: e.rationale,
            knownRisks: e.knownRisks,
            additionalMonitoring: e.additionalMonitoring,
            citations: e.citations,
          ),
        );
      }
    }

    if (applicable.contains(Specialty.breastfeeding)) {
      final e = pregnancyEntryFor(drugId);
      if (e != null && e.breastfeedingTier != null) {
        recs.add(
          SpecialtyRecommendation(
            specialty: Specialty.breastfeeding,
            drugId: drugId,
            drugName: drugName,
            tier: e.breastfeedingTier!,
            rationale: e.rationale,
            citations: e.citations,
          ),
        );
      }
    }

    if (applicable.contains(Specialty.pediatric)) {
      final e = pediatricEntryFor(drugId);
      if (e != null) {
        final tier = pediatricTierFor(drugId, ageYears) ?? e.tier;
        final onLabel = e.licensedFrom != null &&
            ageYears != null &&
            ageYears >= e.licensedFrom!;
        recs.add(
          SpecialtyRecommendation(
            specialty: Specialty.pediatric,
            drugId: drugId,
            drugName: drugName,
            tier: tier,
            rationale:
                '${onLabel ? 'On-label for ${e.licensedFor}. ' : 'Off-label. '}${e.rationale}',
            doseFactor: e.doseFactor ?? 0.5,
            citations: e.citations,
          ),
        );
      }
    }

    if (applicable.contains(Specialty.geriatric)) {
      final e = geriatricEntryFor(drugId);
      if (e != null) {
        recs.add(
          SpecialtyRecommendation(
            specialty: Specialty.geriatric,
            drugId: drugId,
            drugName: drugName,
            tier: e.tier,
            rationale: e.rationale,
            doseFactor: e.doseFactor,
            additionalMonitoring: <String>[
              'Falls risk: ${e.fallsRisk.jsonValue}',
              'Cognitive risk: ${e.cognitiveRisk.jsonValue}',
            ],
            citations: e.citations,
          ),
        );
      }
    }
  }

  // Sort: most concerning tier first within each specialty group.
  recs.sort((a, b) {
    final sp = _specialtyOrder.indexOf(a.specialty) -
        _specialtyOrder.indexOf(b.specialty);
    if (sp != 0) return sp;
    return _tierRank[a.tier]!.compareTo(_tierRank[b.tier]!);
  });

  return SpecialtyAssessment(
    applicable: applicable,
    recommendations: recs,
    headline: _buildHeadline(applicable, recs),
  );
}

String _buildHeadline(
  List<Specialty> applicable,
  List<SpecialtyRecommendation> recs,
) {
  if (applicable.isEmpty) {
    return 'No specialty considerations active for this patient.';
  }
  final parts = <String>[];
  for (final sp in applicable) {
    final inSpec = recs.where((r) => r.specialty == sp).toList();
    final avoid = inSpec.where((r) => r.tier == SpecialtyTier.avoid).length;
    final caution =
        inSpec.where((r) => r.tier == SpecialtyTier.caution).length;
    final String summary;
    if (avoid > 0) {
      summary = '$avoid to avoid';
    } else if (caution > 0) {
      summary = '$caution caution';
    } else {
      summary = 'usable';
    }
    parts.add('${specialtyLabel(sp)}: $summary');
  }
  return parts.join(' · ');
}

/// Display label for a [Specialty].
String specialtyLabel(Specialty s) {
  switch (s) {
    case Specialty.pregnancy:
      return 'Pregnancy';
    case Specialty.breastfeeding:
      return 'Breastfeeding';
    case Specialty.pediatric:
      return 'Pediatric';
    case Specialty.geriatric:
      return 'Geriatric';
  }
}

/// Display label for a [SpecialtyTier].
String specialtyTierLabel(SpecialtyTier t) {
  switch (t) {
    case SpecialtyTier.preferred:
      return 'Preferred';
    case SpecialtyTier.acceptable:
      return 'Acceptable';
    case SpecialtyTier.caution:
      return 'Caution';
    case SpecialtyTier.avoid:
      return 'Avoid';
  }
}

/// Semantic colour-token triple for a [SpecialtyTier]. UI maps to AppColors.
({String bg, String border, String text, String dot}) tierTintTokens(
  SpecialtyTier t,
) {
  switch (t) {
    case SpecialtyTier.preferred:
      return (bg: 'to', border: 'to', text: 'to', dot: 'to');
    case SpecialtyTier.acceptable:
      return (
        bg: 'accent',
        border: 'accent',
        text: 'accent',
        dot: 'accent',
      );
    case SpecialtyTier.caution:
      return (
        bg: 'warning',
        border: 'warning',
        text: 'warning',
        dot: 'warning',
      );
    case SpecialtyTier.avoid:
      return (
        bg: 'danger',
        border: 'danger',
        text: 'danger',
        dot: 'danger',
      );
  }
}
