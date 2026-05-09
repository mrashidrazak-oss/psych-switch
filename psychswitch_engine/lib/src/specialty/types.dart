// Shared types for the specialty-depth modules.
//
// Dart port of engine/specialty/types.ts.

/// Per-drug ranking for a specialty subgroup.
enum SpecialtyTier {
  preferred('preferred'),
  acceptable('acceptable'),
  caution('caution'),
  avoid('avoid');

  const SpecialtyTier(this.jsonValue);

  final String jsonValue;

  static SpecialtyTier fromJson(String value) {
    for (final t in SpecialtyTier.values) {
      if (t.jsonValue == value) return t;
    }
    throw ArgumentError.value(value, 'value', 'unknown SpecialtyTier');
  }
}

/// Specialty subgroups the engine can assess.
enum Specialty {
  pregnancy('pregnancy'),
  breastfeeding('breastfeeding'),
  pediatric('pediatric'),
  geriatric('geriatric');

  const Specialty(this.jsonValue);

  final String jsonValue;

  static Specialty fromJson(String value) {
    for (final s in Specialty.values) {
      if (s.jsonValue == value) return s;
    }
    throw ArgumentError.value(value, 'value', 'unknown Specialty');
  }
}

/// Simple sub-tier risk band (sedation/orthostasis/cognitive).
enum SubgroupRiskBand {
  low('low'),
  moderate('moderate'),
  high('high'),
  veryHigh('very high');

  const SubgroupRiskBand(this.jsonValue);

  final String jsonValue;

  static SubgroupRiskBand fromJson(String value) {
    for (final r in SubgroupRiskBand.values) {
      if (r.jsonValue == value) return r;
    }
    throw ArgumentError.value(value, 'value', 'unknown SubgroupRiskBand');
  }
}

/// Pregnancy entry.
class PregnancyEntry {
  const PregnancyEntry({
    required this.drugId,
    required this.tier,
    required this.rationale,
    required this.citations,
    this.trimesterOverrides,
    this.knownRisks,
    this.additionalMonitoring,
    this.breastfeedingTier,
  });

  final String drugId;
  final SpecialtyTier tier;

  /// When set, overrides the base tier for the given trimester.
  final Map<int, SpecialtyTier>? trimesterOverrides;

  final String rationale;

  /// Specific known fetal / maternal risks.
  final String? knownRisks;

  /// Required additional monitoring. Free-form, one entry per item.
  final List<String>? additionalMonitoring;

  /// Tier for breastfeeding (often differs from pregnancy).
  final SpecialtyTier? breastfeedingTier;

  final List<String> citations;
}

/// Pediatric entry.
class PediatricEntry {
  const PediatricEntry({
    required this.drugId,
    required this.tier,
    required this.licensedFrom,
    required this.licensedFor,
    required this.rationale,
    required this.citations,
    this.doseFactor,
  });

  final String drugId;
  final SpecialtyTier tier;

  /// Age in years from which the drug is licensed (any indication).
  /// `null` = off-label all ages.
  final int? licensedFrom;

  /// Indication(s) for which licensing applies.
  final String? licensedFor;

  /// Multiplier for adult target dose. Defaults to 0.5 if absent.
  final num? doseFactor;

  final String rationale;
  final List<String> citations;
}

/// Geriatric entry.
class GeriatricEntry {
  const GeriatricEntry({
    required this.drugId,
    required this.tier,
    required this.doseFactor,
    required this.fallsRisk,
    required this.cognitiveRisk,
    required this.rationale,
    required this.citations,
  });

  final String drugId;
  final SpecialtyTier tier;

  /// Multiplier for adult target dose.
  final num doseFactor;

  /// Composite of sedation + orthostasis + EPS.
  final SubgroupRiskBand fallsRisk;

  /// Anticholinergic + cognitive blunting contribution.
  final SubgroupRiskBand cognitiveRisk;

  final String rationale;
  final List<String> citations;
}
