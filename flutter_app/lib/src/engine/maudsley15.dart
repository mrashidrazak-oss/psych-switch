// Maudsley 15th edition strategy fallback.
//
// When the engine has no specific reviewed cross-taper rule for a drug pair,
// it consults Table 3.7 from Maudsley 15th to return broad strategy guidance:
//   - directSwitch         → "Direct switch possible"
//   - crossTaperCautiously → "Cross-taper cautiously"
//   - taperThenWait        → "Stop the original, wait N days, then start"
//   - halveAndAdd          → "Halve dose and add the new drug, then slow withdrawal"
//
// The strategy lookup is class-based (e.g. "ssri_other → snri"), not
// drug-specific, because Maudsley's table is organised that way. Drugs
// map to classes via `drugClassMap` in the JSON.
//
// Dart port of engine/maudsley15.ts. Caller passes [Maudsley15Data]
// (loaded from `content/maudsley15/strategy-matrix.json` in production).

import 'package:psychswitch/src/engine/types/drug.dart';
import 'package:psychswitch/src/engine/types/enums.dart';

/// One row of Maudsley 15th's strategy matrix.
class MatrixRule {
  const MatrixRule({
    required this.fromClass,
    required this.toClass,
    required this.strategy,
    required this.headline,
    required this.detail,
    required this.citations,
    this.waitDays,
  });

  factory MatrixRule.fromJson(Map<String, dynamic> j) {
    return MatrixRule(
      fromClass: j['fromClass'] as String,
      toClass: j['toClass'] as String,
      strategy: Maudsley15Strategy.fromJson(j['strategy'] as String),
      headline: j['headline'] as String,
      detail: j['detail'] as String,
      waitDays: j['waitDays'] as int?,
      citations:
          (j['citations'] as List<dynamic>).cast<String>().toList(),
    );
  }

  final String fromClass;
  final String toClass;
  final Maudsley15Strategy strategy;
  final String headline;
  final String detail;
  final int? waitDays;
  final List<String> citations;
}

/// Top-level Maudsley 15 strategy matrix payload.
class Maudsley15Data {
  const Maudsley15Data({
    required this.id,
    required this.rationale,
    required this.drugClassMap,
    required this.rules,
    required this.lastReviewedISO,
    required this.reviewedBy,
  });

  factory Maudsley15Data.fromJson(Map<String, dynamic> j) {
    return Maudsley15Data(
      id: j['id'] as String,
      rationale: j['rationale'] as String,
      drugClassMap:
          (j['drugClassMap'] as Map<String, dynamic>).cast<String, String>(),
      rules: (j['rules'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(MatrixRule.fromJson)
          .toList(),
      lastReviewedISO: j['lastReviewedISO'] as String,
      reviewedBy: j['reviewedBy'] as String,
    );
  }

  final String id;
  final String rationale;

  /// Drug ID → Maudsley class (e.g. 'fluoxetine' → 'ssri_other').
  final Map<String, String> drugClassMap;

  final List<MatrixRule> rules;
  final String lastReviewedISO;
  final String reviewedBy;
}

/// Class-based guidance for a drug pair when no reviewed rule exists.
class Maudsley15Guidance {
  const Maudsley15Guidance({
    required this.strategy,
    required this.headline,
    required this.detail,
    required this.citations,
    this.waitDays,
  });

  final Maudsley15Strategy strategy;
  final String headline;
  final String detail;
  final int? waitDays;
  final List<String> citations;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'strategy': strategy.jsonValue,
        'headline': headline,
        'detail': detail,
        if (waitDays != null) 'waitDays': waitDays,
        'citations': citations,
      };
}

/// Resolve a drug's Maudsley 15th class. Returns `null` if the drug is
/// not mapped (typically antipsychotics, mood stabilizers, LAIs —
/// Maudsley's antidepressant table doesn't cover them).
String? _classFor(String drugId, Maudsley15Data data) =>
    data.drugClassMap[drugId];

/// Look up the Maudsley 15th strategy for a drug pair. Returns `null`
/// when either drug is not in the antidepressant matrix.
Maudsley15Guidance? lookupMaudsley15Strategy(
  Drug fromDrug,
  Drug toDrug,
  Maudsley15Data data,
) {
  final fromClass = _classFor(fromDrug.id, data);
  final toClass = _classFor(toDrug.id, data);
  if (fromClass == null || toClass == null) return null;

  for (final rule in data.rules) {
    if (rule.fromClass == fromClass && rule.toClass == toClass) {
      return Maudsley15Guidance(
        strategy: rule.strategy,
        headline: rule.headline,
        detail: rule.detail,
        waitDays: rule.waitDays,
        citations: rule.citations,
      );
    }
  }
  return null;
}
