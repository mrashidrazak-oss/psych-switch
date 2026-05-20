// Domain enums. Mirror engine/types.ts exactly.
//
// JSON encoding: each enum's `.name` field IS the wire format.
// e.g. Strategy.crossTaper serialises to 'cross-taper' via the
// custom name() helpers below — kebab-case to match the TS string
// literals.

/// Top-level strategy for a switching rule.
///
/// **Content edge case (caught during Phase 1B port):** TS Strategy is
/// `'direct' | 'cross-taper' | 'plateau-cross-taper' | 'washout'` but
/// 7 LAI-to-oral rule JSONs (aripiprazole-lai → aripiprazole, etc.)
/// ship `"strategy": "overlap-taper"`. TypeScript validated nothing
/// at runtime so this slipped through. Added as a 5th value here so
/// content round-trips byte-identical; flagged in
/// `docs/POST_FLUTTER_DEBT.md` for clinical review post-migration.
enum Strategy {
  direct,
  crossTaper,
  plateauCrossTaper,
  overlapTaper,
  washout;

  /// Wire-format JSON value (matches the TS string literals).
  String get jsonValue => switch (this) {
        Strategy.direct => 'direct',
        Strategy.crossTaper => 'cross-taper',
        Strategy.plateauCrossTaper => 'plateau-cross-taper',
        Strategy.overlapTaper => 'overlap-taper', // content edge case
        Strategy.washout => 'washout',
      };

  static Strategy fromJson(String s) => switch (s) {
        'direct' => Strategy.direct,
        'cross-taper' => Strategy.crossTaper,
        'plateau-cross-taper' => Strategy.plateauCrossTaper,
        'overlap-taper' => Strategy.overlapTaper,
        'washout' => Strategy.washout,
        _ => throw FormatException('Unknown strategy: $s'),
      };
}

/// Drug category. JSON value uses kebab-case.
enum DrugCategory {
  antidepressant,
  antipsychotic,
  moodStabilizer;

  String get jsonValue => switch (this) {
        DrugCategory.antidepressant => 'antidepressant',
        DrugCategory.antipsychotic => 'antipsychotic',
        DrugCategory.moodStabilizer => 'mood-stabilizer',
      };

  static DrugCategory fromJson(String s) => switch (s) {
        'antidepressant' => DrugCategory.antidepressant,
        'antipsychotic' => DrugCategory.antipsychotic,
        'mood-stabilizer' => DrugCategory.moodStabilizer,
        _ => throw FormatException('Unknown drug category: $s'),
      };
}

/// Risk tier used across many drug fields (epsRisk, metabolicRisk, etc.).
///
/// **Content edge case (caught during Phase 1B port):** the TS type
/// in engine/types.ts is `'low' | 'moderate' | 'high' | 'very high'`,
/// but `content/drugs/zuclopenthixol.json` ships `"low-moderate"`.
/// TypeScript validated nothing at runtime so this slipped through.
/// We accept it as a 5th value (`lowModerate`) so the existing JSON
/// round-trips byte-identical; flagged in `docs/POST_FLUTTER_DEBT.md`
/// for clinical review post-migration. UI tone mapping treats it as
/// equivalent to `moderate`.
enum RiskLevel {
  low,
  lowModerate,
  moderate,
  high,
  veryHigh;

  String get jsonValue => switch (this) {
        RiskLevel.low => 'low',
        RiskLevel.lowModerate => 'low-moderate', // content edge case
        RiskLevel.moderate => 'moderate',
        RiskLevel.high => 'high',
        RiskLevel.veryHigh => 'very high', // space, not hyphen
      };

  static RiskLevel fromJson(String s) => switch (s) {
        'low' => RiskLevel.low,
        'low-moderate' => RiskLevel.lowModerate,
        'moderate' => RiskLevel.moderate,
        'high' => RiskLevel.high,
        'very high' => RiskLevel.veryHigh,
        _ => throw FormatException('Unknown risk level: $s'),
      };
}

/// Discontinuation-syndrome risk on stopping. Wire format identical
/// to RiskLevel but kept distinct because TS treats them as different
/// types.
typedef DiscontinuationRisk = RiskLevel;

/// Drug formulation. The 'lai' value gates depot-specific UI flows.
enum Formulation {
  oral,
  lai;

  String get jsonValue => name;

  static Formulation fromJson(String s) => switch (s) {
        'oral' => Formulation.oral,
        'lai' => Formulation.lai,
        _ => throw FormatException('Unknown formulation: $s'),
      };
}

/// Maudsley 15th fallback strategy when no specific reviewed rule
/// covers a drug pair. Used by the engine's cross-category guidance.
enum Maudsley15Strategy {
  directSwitch,
  crossTaperCautiously,
  taperThenWait,
  halveAndAdd,
  special;

  String get jsonValue => switch (this) {
        Maudsley15Strategy.directSwitch => 'direct_switch',
        Maudsley15Strategy.crossTaperCautiously => 'cross_taper_cautiously',
        Maudsley15Strategy.taperThenWait => 'taper_then_wait',
        Maudsley15Strategy.halveAndAdd => 'halve_and_add',
        Maudsley15Strategy.special => 'special',
      };

  static Maudsley15Strategy fromJson(String s) => switch (s) {
        'direct_switch' => Maudsley15Strategy.directSwitch,
        'cross_taper_cautiously' => Maudsley15Strategy.crossTaperCautiously,
        'taper_then_wait' => Maudsley15Strategy.taperThenWait,
        'halve_and_add' => Maudsley15Strategy.halveAndAdd,
        'special' => Maudsley15Strategy.special,
        _ => throw FormatException('Unknown Maudsley15 strategy: $s'),
      };
}
