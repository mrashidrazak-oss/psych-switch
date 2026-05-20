// Ramadan dosing guidance — pure-data engine module.
//
// Surfaces the Suhoor / Iftar timing recommendation for each
// psychiatric drug in the registry plus the general fasting-aware
// dosing principles. Targeted at Muslim-majority Malaysia, where
// up to two-thirds of patients fast during Ramadan.
//
// The wire format is what `content/ramadan/guidance.json` ships —
// see that file for the canonical shape. Loader-side parsing lives
// in `lib/src/data/content_loader.dart`.

/// What time of day to take a medication during Ramadan.
///
/// Wire-format strings come from `recommendation` in the content
/// JSON. `discussWithTeam` is reserved for high-stakes meds where
/// the timing answer is patient-specific (clozapine initiation,
/// for example).
enum RamadanRecommendation {
  suhoor('suhoor'),
  iftar('iftar'),
  suhoorOrIftar('suhoor_or_iftar'),
  suhoorAndIftar('suhoor_and_iftar'),
  iftarOrSuhoorAndIftar('iftar_or_suhoor_and_iftar'),
  suhoorAndIftarOrIftar('suhoor_and_iftar_or_iftar'),
  discussWithTeam('discuss_with_team');

  const RamadanRecommendation(this.jsonValue);

  final String jsonValue;

  /// Short human-readable label for the chip displayed on each row.
  String get label {
    switch (this) {
      case RamadanRecommendation.suhoor:
        return 'Suhoor';
      case RamadanRecommendation.iftar:
        return 'Iftar';
      case RamadanRecommendation.suhoorOrIftar:
        return 'Suhoor or Iftar';
      case RamadanRecommendation.suhoorAndIftar:
        return 'Suhoor + Iftar';
      case RamadanRecommendation.iftarOrSuhoorAndIftar:
        return 'Iftar (or split)';
      case RamadanRecommendation.suhoorAndIftarOrIftar:
        return 'Split or Iftar';
      case RamadanRecommendation.discussWithTeam:
        return 'Discuss with team';
    }
  }

  /// Parse a wire-format string. Throws `FormatException` on unknown
  /// values so a content typo surfaces loudly rather than silently.
  static RamadanRecommendation fromJson(String raw) {
    for (final r in RamadanRecommendation.values) {
      if (r.jsonValue == raw) return r;
    }
    throw FormatException('Unknown RamadanRecommendation: $raw');
  }
}

/// Single drug's Ramadan guidance.
class RamadanDrug {
  const RamadanDrug({
    required this.id,
    required this.name,
    required this.dosing,
    required this.recommendation,
    required this.rationale,
    required this.specialNote,
  });

  factory RamadanDrug.fromJson(Map<String, dynamic> j) => RamadanDrug(
        id: j['id'] as String,
        name: j['name'] as String,
        dosing: j['dosing'] as String,
        recommendation:
            RamadanRecommendation.fromJson(j['recommendation'] as String),
        rationale: j['rationale'] as String? ?? '',
        specialNote: j['specialNote'] as String? ?? '',
      );

  final String id;
  final String name;

  /// Raw dosing pattern code from the content (OD / BD / TDS / OD_MR …).
  /// The UI prettifies into a chip — see `prettifyDosing`.
  final String dosing;

  final RamadanRecommendation recommendation;
  final String rationale;
  final String specialNote;
}

/// Map the raw `dosing` code to a clinician-facing label.
String prettifyDosing(String code) {
  switch (code) {
    case 'OD':
      return 'Once daily';
    case 'OD_MR':
      return 'Once daily (MR)';
    case 'BD':
      return 'Twice daily';
    case 'TDS':
      return 'Three times daily';
    case 'QDS':
      return 'Four times daily';
    case 'PRN':
      return 'As required';
    default:
      return code;
  }
}

/// Full Ramadan dataset.
class RamadanData {
  const RamadanData({
    required this.id,
    required this.rationale,
    required this.generalPrinciples,
    required this.drugs,
  });

  factory RamadanData.fromJson(Map<String, dynamic> j) => RamadanData(
        id: j['id'] as String,
        rationale: j['rationale'] as String,
        generalPrinciples: (j['generalPrinciples'] as List<dynamic>)
            .cast<String>()
            .toList(growable: false),
        drugs: (j['drugs'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(RamadanDrug.fromJson)
            .toList(growable: false),
      );

  final String id;

  /// Free-text framing paragraph at the top of the Ramadan guidance.
  final String rationale;

  /// Bullet list of general fasting-aware principles (OD timing,
  /// dehydration warnings, etc.).
  final List<String> generalPrinciples;

  /// Per-drug guidance. Order preserved from the content file.
  final List<RamadanDrug> drugs;
}
