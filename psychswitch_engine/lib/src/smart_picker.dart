// Smart drug-picker relevance ranking.
//
// When a clinician picks the from-drug, this ranks the to-drug list by
// what's clinically relevant for THIS pair + THIS patient context:
//
//   1. Reviewed switching rule exists (+ explicit rule beats Maudsley fallback)
//   2. Pair won't trigger an "avoid"-severity DDI hit
//   3. Drug doesn't trigger a danger-severity context warning for this patient
//   4. Drug *avoids* the AE the patient is having (when AE filter is set)
//
// The ranker doesn't HIDE drugs — it just sorts and tags them, so the
// clinician can still pick something the engine considers low-relevance
// (e.g. a no-rule pair with the explicit understanding it's a fallback).
//
// Dart port of engine/smartPicker.ts. The list of reviewed rules is
// passed in by the caller (vs the TS port which imported it from
// switchingEngine) so the engine stays pure-testable.

import 'package:psychswitch_engine/adverse_effects.dart';
import 'package:psychswitch_engine/ddi.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/switching_rule.dart';

/// Inputs to [rankDrugs].
class RankInput {
  const RankInput({
    required this.rules,
    this.fromDrugId,
    this.context,
    this.avoidAeId,
  });

  /// All registered switching rules. Caller passes in (engine doesn't
  /// statically import — keeps the module decoupled).
  final List<SwitchingRule> rules;

  final String? fromDrugId;
  final PatientContext? context;

  /// When set, prefer drugs that AVOID this AE (i.e. listed in
  /// switchCandidates).
  final String? avoidAeId;
}

/// Relevance tier produced by [rankDrugs].
enum RelevanceTier {
  top('top'),
  reviewed('reviewed'),
  fallback('fallback'),
  caution('caution'),
  avoid('avoid');

  const RelevanceTier(this.jsonValue);

  final String jsonValue;

  static RelevanceTier fromJson(String value) {
    for (final t in RelevanceTier.values) {
      if (t.jsonValue == value) return t;
    }
    throw ArgumentError.value(value, 'value', 'unknown RelevanceTier');
  }
}

/// One ranked drug — the unit returned by [rankDrugs].
class RankedDrug {
  const RankedDrug({
    required this.drug,
    required this.tier,
    required this.score,
    required this.tags,
    required this.blocked,
  });

  final Drug drug;
  final RelevanceTier tier;

  /// Score used for sort within tier (higher = more relevant).
  final num score;

  /// Short tags shown next to the drug name in the picker.
  final List<String> tags;

  /// True when picking this drug would trigger an "avoid"-grade DDI or
  /// context flag.
  final bool blocked;
}

const Map<RelevanceTier, int> _tierRank = <RelevanceTier, int>{
  RelevanceTier.top: 4,
  RelevanceTier.reviewed: 3,
  RelevanceTier.fallback: 2,
  RelevanceTier.caution: 1,
  RelevanceTier.avoid: 0,
};

/// Rank a list of candidate to-drugs against a given from-drug + context.
/// Pure function — easy to test.
List<RankedDrug> rankDrugs(List<Drug> drugs, RankInput input) {
  final fromDrugId = input.fromDrugId;
  final context = input.context;
  final ae = input.avoidAeId == null
      ? null
      : adverseEffects.cast<AdverseEffect?>().firstWhere(
            (a) => a?.id == input.avoidAeId,
            orElse: () => null,
          );

  // Pre-compute the set of to-drugs that have an explicit reviewed
  // rule from this from-drug.
  final reviewedToIds = <String>{};
  if (fromDrugId != null) {
    for (final r in input.rules) {
      if (r.fromDrugId == fromDrugId) reviewedToIds.add(r.toDrugId);
    }
  }

  final ranked = drugs
      .map((d) => _rankOne(d, fromDrugId, reviewedToIds, context, ae))
      .toList()
    ..sort((a, b) {
      final aRank = _tierRank[a.tier]!;
      final bRank = _tierRank[b.tier]!;
      if (aRank != bRank) return bRank - aRank;
      if (a.score != b.score) return (b.score - a.score).toInt();
      return a.drug.genericName.compareTo(b.drug.genericName);
    });
  return ranked;
}

RankedDrug _rankOne(
  Drug d,
  String? fromDrugId,
  Set<String> reviewedToIds,
  PatientContext? context,
  AdverseEffect? ae,
) {
  final tags = <String>[];
  num score = 0;
  var tier = RelevanceTier.fallback;
  var blocked = false;

  final reviewed = fromDrugId != null && reviewedToIds.contains(d.id);
  if (reviewed) {
    score += 100;
    tags.add('Reviewed');
    tier = RelevanceTier.reviewed;
  }

  // AE filter — preferred candidate?
  if (ae != null) {
    if (ae.switchCandidates.contains(d.id)) {
      score += 60;
      final firstWord = ae.label.split(' ').first.toLowerCase();
      tags.add('avoids $firstWord');
      tier = tier == RelevanceTier.reviewed
          ? RelevanceTier.top
          : RelevanceTier.reviewed;
    } else if (ae.causedBy.contains(d.id)) {
      score -= 40;
      final firstWord = ae.label.split(' ').first.toLowerCase();
      tags.add('causes $firstWord');
      tier = RelevanceTier.caution;
    }
  }

  // Context warnings on this drug
  if (context != null) {
    final warnings = warningsForDrug(context, d.id);
    final hasDanger =
        warnings.any((w) => w.severity == WarningSeverity.danger);
    final hasWarning =
        warnings.any((w) => w.severity == WarningSeverity.warning);
    if (hasDanger) {
      score -= 200;
      tags.add('contra');
      tier = RelevanceTier.avoid;
      blocked = true;
    } else if (hasWarning) {
      score -= 30;
      tags.add('caution');
      if (tier == RelevanceTier.top || tier == RelevanceTier.reviewed) {
        tier = RelevanceTier.caution;
      }
    }
  }

  // DDI on the pair
  if (fromDrugId != null && fromDrugId != d.id) {
    final hits = checkPair(fromDrugId, d.id);
    var worst = 0;
    for (final h in hits) {
      final r = severityRank(h.severity);
      if (r > worst) worst = r;
    }
    if (worst >= 3) {
      // 'avoid'-grade DDI
      score -= 200;
      tags.add('avoid');
      tier = RelevanceTier.avoid;
      blocked = true;
    } else if (worst >= 2) {
      // 'warning'-grade DDI
      score -= 20;
      tags.add('DDI');
      if (tier != RelevanceTier.avoid &&
          (tier == RelevanceTier.top ||
              tier == RelevanceTier.reviewed)) {
        tier = RelevanceTier.caution;
      }
    }
  }

  return RankedDrug(
    drug: d,
    tier: tier,
    score: score,
    tags: tags,
    blocked: blocked,
  );
}
