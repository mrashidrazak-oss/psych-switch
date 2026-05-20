// Errata feed — every accepted correction to the clinical content,
// with date, reviewer, rule, change-kind, before/after snippet,
// rationale and citations.
//
// Two purposes:
//
//   1. Trust signal. Open-source clinical content is only as good as
//      its visible audit trail. Patients, regulators and consultants
//      can scan this list and verify the project has a working errata
//      mechanism.
//
//   2. Per-rule history. The Result-screen Provenance card shows a
//      "X corrections recorded" tag if a rule has been edited since
//      its first publication, with a "see what changed" link.
//
// The list is seeded with the historical record from v0.1 → today.
// Going forward, every accepted PR + every in-app errata report that
// the maintainer signs off on adds an entry here. Append-only —
// never edit existing entries (it's an audit trail, not a wiki).
//
// Dart port of engine/errata.ts. Entries are byte-equivalent.

/// Kind of change recorded by an errata entry.
enum ErrataChangeKind {
  /// Dose value(s) changed.
  dose('dose'),

  /// Schedule duration changed.
  duration('duration'),

  /// Strategy class changed (cross-taper → plateau, etc.).
  strategy('strategy'),

  /// Citation key added / corrected.
  citation('citation'),

  /// Safety flag added / removed.
  safetyFlag('safety_flag'),

  /// Monitoring entry added / changed.
  monitoring('monitoring'),

  /// Rationale text rewritten.
  rationale('rationale'),

  /// First publication of a rule.
  newRule('new_rule'),

  /// First publication of a drug profile.
  newDrug('new_drug'),

  /// Anything else (typo fix, formatting, etc.).
  other('other');

  const ErrataChangeKind(this.jsonValue);

  final String jsonValue;

  static ErrataChangeKind fromJson(String value) {
    for (final k in ErrataChangeKind.values) {
      if (k.jsonValue == value) return k;
    }
    throw ArgumentError.value(value, 'value', 'unknown ErrataChangeKind');
  }
}

/// Severity tier for an errata entry.
enum ErrataSeverity {
  minor('minor'),
  moderate('moderate'),
  significant('significant'),
  critical('critical');

  const ErrataSeverity(this.jsonValue);

  final String jsonValue;

  static ErrataSeverity fromJson(String value) {
    for (final s in ErrataSeverity.values) {
      if (s.jsonValue == value) return s;
    }
    throw ArgumentError.value(value, 'value', 'unknown ErrataSeverity');
  }
}

/// One errata record.
class ErrataEntry {
  const ErrataEntry({
    required this.id,
    required this.dateISO,
    required this.scope,
    required this.scopeLabel,
    required this.changeKind,
    required this.severity,
    required this.summary,
    required this.detail,
    required this.rationale,
    required this.reviewer,
    required this.citations,
    required this.appVersion,
    this.before,
    this.after,
  });

  /// Stable id — date + slug. Never reused.
  final String id;

  /// ISO date the change was accepted into main.
  final String dateISO;

  /// Affected rule id, drug id, or 'engine' / 'content' for non-rule changes.
  final String scope;

  /// Display label for the affected scope.
  final String scopeLabel;

  final ErrataChangeKind changeKind;
  final ErrataSeverity severity;

  /// One-line summary suitable for a list view.
  final String summary;

  /// Free-text "what specifically changed" — multi-line OK.
  final String detail;

  /// Before snippet (optional, for value-changes).
  final String? before;

  /// After snippet.
  final String? after;

  /// Why the change was made.
  final String rationale;

  /// Reviewer/sign-off.
  final String reviewer;

  /// Citations supporting the change.
  final List<String> citations;

  /// App version that first shipped the corrected content.
  final String appVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'dateISO': dateISO,
        'scope': scope,
        'scopeLabel': scopeLabel,
        'changeKind': changeKind.jsonValue,
        'severity': severity.jsonValue,
        'summary': summary,
        'detail': detail,
        if (before != null) 'before': before,
        if (after != null) 'after': after,
        'rationale': rationale,
        'reviewer': reviewer,
        'citations': citations,
        'appVersion': appVersion,
      };
}

const List<ErrataEntry> _entries = <ErrataEntry>[
  ErrataEntry(
    id: '2026-05-08-pp3m-bridge-dose',
    dateISO: '2026-05-08',
    scope: 'engine.depotLai',
    scopeLabel: 'Invega Trinza (PP3M)',
    changeKind: ErrataChangeKind.dose,
    severity: ErrataSeverity.significant,
    summary:
        'PP3M 525 mg eq → PP1M bridge corrected to 100 mg eq (was 150)',
    detail:
        'For patients missed >9 months of PP3M who require restart, the bridge PP1M dose for the 525 mg eq strength was previously listed as 150 mg eq. Per the FDA prescribing information (December 2024 revision), the correct bridge is 100 mg eq (= 156 mg PP). Failing to use the lower dose risks supratherapeutic plasma levels at re-establishment.',
    before: 'PP3M 525 mg eq missed-dose bridge: PP1M 150 mg eq',
    after:
        'PP3M 525 mg eq missed-dose bridge: PP1M 100 mg eq (= 156 mg PP)',
    rationale:
        'Match the FDA Trinza PI table 4 directly. The earlier value reflected an older PI revision.',
    reviewer: 'Rashid Razak (clinical author)',
    citations: <String>['invega_trinza_pi'],
    appVersion: '0.1.0',
  ),
  ErrataEntry(
    id: '2026-05-08-paroxetine-pregnancy-trimester',
    dateISO: '2026-05-08',
    scope: 'paroxetine',
    scopeLabel: 'Paroxetine — pregnancy',
    changeKind: ErrataChangeKind.safetyFlag,
    severity: ErrataSeverity.significant,
    summary:
        'Paroxetine pregnancy tier now trimester-specific (1st = avoid, 2nd-3rd = caution)',
    detail:
        'Pregnancy specialty matrix added in v0.4.3 includes per-trimester overrides for paroxetine. The 1st-trimester signal for cardiac defects is well-characterised; the 2nd and 3rd trimesters are less concerning in isolation, so the engine now uses "avoid" for 1st-trimester and "caution" thereafter rather than a flat "avoid" across pregnancy.',
    rationale: 'Match Maudsley 15th ch.8 nuance + UKTIS monograph.',
    reviewer: 'Rashid Razak',
    citations: <String>['maudsley15_ch8_paroxetine', 'uktis_paroxetine'],
    appVersion: '0.4.3',
  ),
  ErrataEntry(
    id: '2026-05-08-aripiprazole-akathisia-prediction',
    dateISO: '2026-05-08',
    scope: 'engine.predictedAeProfile',
    scopeLabel: 'Aripiprazole — akathisia',
    changeKind: ErrataChangeKind.other,
    severity: ErrataSeverity.moderate,
    summary:
        'Predicted AE engine now takes higher of drug-field vs reverse-lookup tiers',
    detail:
        'Aripiprazole carries epsRisk: low in its drug profile (correct for parkinsonism overall) but is in the causedBy[] array for eps_akathisia (correct for the akathisia-specific subtype). The earlier predictor returned drug-field-wins, which produced a misleading "low likelihood of akathisia on aripiprazole". Fixed: the predictor now returns the higher-severity tier, surfacing akathisia as high.',
    before: 'aripiprazole akathisia → low (drug field wins)',
    after:
        'aripiprazole akathisia → high (reverse-lookup wins when more severe)',
    rationale:
        "Aripiprazole's hallmark dose-limiting AE is akathisia. The earlier prediction would have missed this for clinicians fleeing akathisia on a previous antipsychotic.",
    reviewer: 'Rashid Razak',
    citations: <String>['maudsley15_schizophrenia_aripiprazole_profile'],
    appVersion: '0.3.4',
  ),
  ErrataEntry(
    id: '2026-05-07-step-notes-adapt',
    dateISO: '2026-05-07',
    scope: 'engine.scaleSchedule',
    scopeLabel: 'Adaptive scaler — step notes',
    changeKind: ErrataChangeKind.other,
    severity: ErrataSeverity.moderate,
    summary:
        'Adapted schedules now substitute reference dose mentions in notes',
    detail:
        r'When the user enters non-reference doses, the schedule rows scale and round correctly, but the notes column was still saying "Continue agomelatine 25 mg" when the actual scaled dose was 30 mg. The adaptStepNotes helper now finds and substitutes \bN mg\b matches against the reference step doses. Word-boundary regex prevents collateral substitutions ("in 25 days" stays unchanged because no "mg" follows).',
    rationale:
        'Reported by Rashid during pre-release self-testing — the dose mismatch was clinically confusing.',
    reviewer: 'Rashid Razak',
    citations: <String>[],
    appVersion: '0.3.1',
  ),
  ErrataEntry(
    id: '2026-05-07-evidence-grade-demote-on-adapt',
    dateISO: '2026-05-07',
    scope: 'engine.scaleSchedule',
    scopeLabel: 'Evidence grade demotion on adaptation',
    changeKind: ErrataChangeKind.other,
    severity: ErrataSeverity.minor,
    summary: 'Adapted schedules drop one evidence grade (A → B etc)',
    detail:
        'When the schedule has been adapted from its reviewed reference (any non-trivial dose scaling), the evidence badge now reads "B (adapted)" instead of "A". The strategy is still grade-A reviewed, but the dose values are derived rather than verbatim — honest signaling matters more than impressing the user.',
    rationale:
        'Trust calibration. A grade-A schedule and a grade-A-but-adapted schedule should not look identical to the clinician.',
    reviewer: 'Rashid Razak',
    citations: <String>[],
    appVersion: '0.3.1',
  ),
  ErrataEntry(
    id: '2026-05-06-clozapine-fbc-cadence',
    dateISO: '2026-05-06',
    scope: 'engine.monitoring',
    scopeLabel: 'Clozapine — FBC cadence',
    changeKind: ErrataChangeKind.monitoring,
    severity: ErrataSeverity.moderate,
    summary:
        'Clozapine FBC cadence corrected to weekly ×18, fortnightly ×34, then monthly',
    detail:
        'The earliest monitoring schedule had clozapine FBC as weekly ×26 then monthly. Per Maudsley 15th + UK Clozaril patient-monitoring service, the cadence is weekly weeks 1-18, fortnightly weeks 19-52, monthly thereafter. Fixed.',
    rationale: 'Match Maudsley 15th + UK CPMS.',
    reviewer: 'Rashid Razak',
    citations: <String>['maudsley15_clozapine_monitoring'],
    appVersion: '0.2.0',
  ),
  ErrataEntry(
    id: '2026-05-04-initial-rule-set',
    dateISO: '2026-05-04',
    scope: 'content',
    scopeLabel: 'Initial 133 rules + 40 drugs',
    changeKind: ErrataChangeKind.newRule,
    severity: ErrataSeverity.critical,
    summary: 'First public release of the reviewed rule set',
    detail:
        '133 cross-titration rules across antidepressants, antipsychotics (oral + LAI) and mood stabilizers. 40 drug profiles. Sources: Maudsley 15th, BAP 2020, NICE, Malaysian CPGs, FDA / EMA prescribing information.',
    rationale:
        'v0.1 baseline — every rule individually authored + reviewed by Rashid Razak.',
    reviewer: 'Rashid Razak',
    citations: <String>[
      'maudsley15_ch3_p369_table_3_7',
      'bap2020_psychosis',
      'nice_ng178',
    ],
    appVersion: '0.1.0',
  ),
];

// Cached scope index — built once at module load.
final Map<String, List<ErrataEntry>> _byScope = (() {
  final m = <String, List<ErrataEntry>>{};
  for (final e in _entries) {
    (m[e.scope] ??= <ErrataEntry>[]).add(e);
  }
  return m;
})();

// ── Public API ─────────────────────────────────────────────────────────────

/// All errata entries, sorted newest-first by [ErrataEntry.dateISO].
List<ErrataEntry> listErrata() {
  final list = List<ErrataEntry>.from(_entries)
    ..sort((a, b) => b.dateISO.compareTo(a.dateISO));
  return list;
}

/// Errata entries scoped to [scope] (rule id, drug id, or engine namespace).
/// Sorted newest-first.
List<ErrataEntry> errataForScope(String scope) {
  final source = _byScope[scope] ?? const <ErrataEntry>[];
  final list = List<ErrataEntry>.from(source)
    ..sort((a, b) => b.dateISO.compareTo(a.dateISO));
  return list;
}

/// Alias for [errataForScope] — used when the caller has a rule id and
/// wants to read it as such.
List<ErrataEntry> errataForRule(String ruleId) => errataForScope(ruleId);

/// Errata entries first shipped after [version]. Compares semver-ish.
List<ErrataEntry> errataSinceVersion(String version) {
  return listErrata()
      .where((e) => _compareVersions(e.appVersion, version) > 0)
      .toList();
}

/// Total number of registered errata entries.
int errataCount() => _entries.length;

// ── Helpers ────────────────────────────────────────────────────────────────

/// Semantic colour-token triple for a severity.
///
/// Returns one of `('border', 'border', 'muted')`, `('accent10', ...)` etc.
/// The TS port returned Tailwind classes; Dart UI maps these tokens to
/// AppColors directly.
({String bg, String border, String text}) severityColorTokens(
  ErrataSeverity s,
) {
  switch (s) {
    case ErrataSeverity.minor:
      return (bg: 'border', border: 'border', text: 'muted');
    case ErrataSeverity.moderate:
      return (bg: 'accent', border: 'accent', text: 'accent');
    case ErrataSeverity.significant:
      return (bg: 'warning', border: 'warning', text: 'warning');
    case ErrataSeverity.critical:
      return (bg: 'danger', border: 'danger', text: 'danger');
  }
}

/// Human-readable label for an [ErrataSeverity].
String severityLabel(ErrataSeverity s) {
  switch (s) {
    case ErrataSeverity.minor:
      return 'Minor';
    case ErrataSeverity.moderate:
      return 'Moderate';
    case ErrataSeverity.significant:
      return 'Significant';
    case ErrataSeverity.critical:
      return 'Critical';
  }
}

/// Human-readable label for an [ErrataChangeKind].
String changeKindLabel(ErrataChangeKind k) {
  switch (k) {
    case ErrataChangeKind.dose:
      return 'Dose';
    case ErrataChangeKind.duration:
      return 'Duration';
    case ErrataChangeKind.strategy:
      return 'Strategy';
    case ErrataChangeKind.citation:
      return 'Citation';
    case ErrataChangeKind.safetyFlag:
      return 'Safety flag';
    case ErrataChangeKind.monitoring:
      return 'Monitoring';
    case ErrataChangeKind.rationale:
      return 'Rationale';
    case ErrataChangeKind.newRule:
      return 'New rule';
    case ErrataChangeKind.newDrug:
      return 'New drug';
    case ErrataChangeKind.other:
      return 'Other';
  }
}

/// Compare two semver-ish strings (e.g. "0.4.3" vs "0.4.2"). Returns
/// negative if a < b, positive if a > b, 0 if equal. Tolerant of
/// missing patch ("0.4" works).
int _compareVersions(String a, String b) {
  final pa = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final pb = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final av = i < pa.length ? pa[i] : 0;
    final bv = i < pb.length ? pb[i] : 0;
    if (av != bv) return av - bv;
  }
  return 0;
}
