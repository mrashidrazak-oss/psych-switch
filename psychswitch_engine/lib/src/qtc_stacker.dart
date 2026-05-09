// QTc stacker engine — pure Dart, no Flutter dependencies.
//
// Loads no data itself — callers pass in a [QtcRiskData] (typically
// from `content/qtc/drug-qtc-risks.json`). This keeps the engine
// pure-testable. The runtime loader lives in
// `lib/src/data/content_loader.dart`.
//
// Risk categories (CredibleMeds / AzCERT-derived):
//   'known'      → Known Risk of TdP
//   'conditional'→ Conditional Risk (risk elevated under certain conditions)
//   'possible'   → Possible Risk
//   'low'        → Low / negligible risk
//
// Dart port of engine/qtcStacker.ts.

/// CredibleMeds-derived QTc risk category for a single drug.
enum QtcCategory {
  known('known'),
  conditional('conditional'),
  possible('possible'),
  low('low');

  const QtcCategory(this.jsonValue);

  final String jsonValue;

  static QtcCategory fromJson(String value) {
    for (final c in QtcCategory.values) {
      if (c.jsonValue == value) return c;
    }
    throw ArgumentError.value(value, 'value', 'unknown QtcCategory');
  }
}

/// Aggregate risk tier for a *combination* of QTc-prolonging drugs.
enum OverallRisk {
  none('none'),
  low('low'),
  moderate('moderate'),
  high('high'),
  veryHigh('very_high');

  const OverallRisk(this.jsonValue);

  final String jsonValue;

  static OverallRisk fromJson(String value) {
    for (final r in OverallRisk.values) {
      if (r.jsonValue == value) return r;
    }
    throw ArgumentError.value(value, 'value', 'unknown OverallRisk');
  }
}

/// One drug row in the QTc registry.
class QtcDrugEntry {
  const QtcDrugEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.qtcCategory,
    required this.notes,
  });

  factory QtcDrugEntry.fromJson(Map<String, dynamic> j) {
    return QtcDrugEntry(
      id: j['id'] as String,
      name: j['name'] as String,
      category: j['category'] as String,
      qtcCategory: QtcCategory.fromJson(j['qtcCategory'] as String),
      notes: j['notes'] as String,
    );
  }

  final String id;
  final String name;
  final String category;
  final QtcCategory qtcCategory;
  final String notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'category': category,
        'qtcCategory': qtcCategory.jsonValue,
        'notes': notes,
      };
}

/// Top-level QTc registry payload (matches the JSON file shape).
class QtcRiskData {
  const QtcRiskData({
    required this.id,
    required this.rationale,
    required this.riskCategories,
    required this.drugs,
    required this.riskThresholds,
    required this.citations,
    required this.lastReviewedISO,
    required this.reviewedBy,
  });

  factory QtcRiskData.fromJson(Map<String, dynamic> j) {
    final cats = j['riskCategories'] as Map<String, dynamic>;
    return QtcRiskData(
      id: j['id'] as String,
      rationale: j['rationale'] as String,
      riskCategories: <QtcCategory, String>{
        for (final entry in cats.entries)
          QtcCategory.fromJson(entry.key): entry.value as String,
      },
      drugs: (j['drugs'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(QtcDrugEntry.fromJson)
          .toList(),
      riskThresholds: QtcRiskThresholds.fromJson(
        j['riskThresholds'] as Map<String, dynamic>,
      ),
      citations:
          (j['citations'] as List<dynamic>).cast<String>().toList(),
      lastReviewedISO: j['lastReviewedISO'] as String,
      reviewedBy: j['reviewedBy'] as String,
    );
  }

  final String id;
  final String rationale;
  final Map<QtcCategory, String> riskCategories;
  final List<QtcDrugEntry> drugs;
  final QtcRiskThresholds riskThresholds;
  final List<String> citations;
  final String lastReviewedISO;
  final String reviewedBy;
}

class QtcRiskThresholds {
  const QtcRiskThresholds({required this.overallAssessmentNote});

  factory QtcRiskThresholds.fromJson(Map<String, dynamic> j) {
    return QtcRiskThresholds(
      overallAssessmentNote: j['overallAssessmentNote'] as String,
    );
  }

  final String overallAssessmentNote;
}

/// Result of [assessQtcRisk] — the aggregate risk picture for a set
/// of selected drugs.
class QtcAssessment {
  const QtcAssessment({
    required this.overallRisk,
    required this.knownCount,
    required this.conditionalCount,
    required this.possibleCount,
    required this.selectedDrugs,
    required this.summary,
    required this.recommendations,
  });

  final OverallRisk overallRisk;
  final int knownCount;
  final int conditionalCount;
  final int possibleCount;
  final List<QtcDrugEntry> selectedDrugs;
  final String summary;
  final List<String> recommendations;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'overallRisk': overallRisk.jsonValue,
        'knownCount': knownCount,
        'conditionalCount': conditionalCount,
        'possibleCount': possibleCount,
        'selectedDrugs':
            selectedDrugs.map((d) => d.toJson()).toList(),
        'summary': summary,
        'recommendations': recommendations,
      };
}

/// All drugs in the QTc registry.
List<QtcDrugEntry> listQtcDrugs(QtcRiskData data) => data.drugs;

/// Calculate aggregate QTc risk from a list of selected drug IDs.
///
/// Risk scoring:
///  * known × 1       = +3 points each
///  * conditional × 1 = +2 points each
///  * possible × 1    = +1 point each
///
/// Tier mapping:
///  * 0 points     → [OverallRisk.none]
///  * 1–2 points   → [OverallRisk.low]
///  * 3–5 points   → [OverallRisk.moderate]
///  * 6–8 points   → [OverallRisk.high]
///  * ≥ 9 points   → [OverallRisk.veryHigh]
QtcAssessment assessQtcRisk(
  List<String> selectedIds,
  QtcRiskData data,
) {
  final selectedDrugs =
      data.drugs.where((d) => selectedIds.contains(d.id)).toList();

  final knownCount = selectedDrugs
      .where((d) => d.qtcCategory == QtcCategory.known)
      .length;
  final conditionalCount = selectedDrugs
      .where((d) => d.qtcCategory == QtcCategory.conditional)
      .length;
  final possibleCount = selectedDrugs
      .where((d) => d.qtcCategory == QtcCategory.possible)
      .length;

  final score = knownCount * 3 + conditionalCount * 2 + possibleCount * 1;

  final OverallRisk overallRisk;
  if (score == 0) {
    overallRisk = OverallRisk.none;
  } else if (score <= 2) {
    overallRisk = OverallRisk.low;
  } else if (score <= 5) {
    overallRisk = OverallRisk.moderate;
  } else if (score <= 8) {
    overallRisk = OverallRisk.high;
  } else {
    overallRisk = OverallRisk.veryHigh;
  }

  final recommendations = <String>[];

  switch (overallRisk) {
    case OverallRisk.none:
      recommendations.add(
        'No selected drug has significant QTc-prolonging potential. Standard clinical monitoring sufficient.',
      );
    case OverallRisk.low:
      recommendations.add(
        'Low aggregate QTc risk. Consider baseline ECG if cardiac risk factors present.',
      );
    case OverallRisk.moderate:
      recommendations.addAll(<String>[
        'Moderate QTc risk — baseline ECG recommended before combining these drugs.',
        'Check serum potassium and magnesium at initiation and periodically.',
        'Review all QTc-prolonging agents — consider substituting a lower-risk alternative if possible.',
      ]);
    case OverallRisk.high:
    case OverallRisk.veryHigh:
      recommendations.addAll(<String>[
        'HIGH QTc risk combination — baseline ECG REQUIRED before prescribing.',
        'Repeat ECG at steady state (7–14 days) and after any dose increase.',
        'Stop or substitute if QTc > 480 ms (men) or > 500 ms (women), or if QTc increases > 60 ms from baseline.',
        'Correct electrolyte abnormalities (hypokalaemia, hypomagnesaemia) before or alongside treatment.',
        'Consider cardiology consultation if QTc prolongation persists or clinical concern.',
      ]);
  }

  if (knownCount >= 2) {
    recommendations.add(
      'Two or more KNOWN-risk drugs are selected — this is a high-stakes combination. Cardiology input strongly recommended.',
    );
  }

  final String summary;
  if (selectedDrugs.isEmpty) {
    summary = 'No drugs selected.';
  } else {
    final n = selectedDrugs.length;
    final plural = n == 1 ? '' : 's';
    summary =
        '$n drug$plural selected: $knownCount Known, $conditionalCount Conditional, $possibleCount Possible QTc risk.';
  }

  return QtcAssessment(
    overallRisk: overallRisk,
    knownCount: knownCount,
    conditionalCount: conditionalCount,
    possibleCount: possibleCount,
    selectedDrugs: selectedDrugs,
    summary: summary,
    recommendations: recommendations,
  );
}
