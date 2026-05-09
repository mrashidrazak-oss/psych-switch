// Drug-drug interaction (DDI) checker — focused on the overlap window
// of a cross-titration. Not a general-purpose interaction database.
//
// Scope (narrow on purpose):
//   1. Serotonergic stacking      — SSRI + SSRI, SSRI + SNRI, SSRI + MAOI, etc.
//   2. CYP-mediated dose-warpers  — fluoxetine/paroxetine + risperidone/aripiprazole, etc.
//   3. QTc additive               — covered by separate qtc_stacker; we
//                                   re-flag here when both drugs are on the list.
//   4. Anticholinergic burden     — relevant in older adults during overlap.
//   5. Pharmacodynamic conflict   — D2 partial agonist (aripiprazole) +
//                                   D2 antagonist (risperidone) early in overlap.
//
// Source-of-truth notes
//   • Maudsley 15th, Chapter 1 (interactions) and per-drug profiles.
//   • Stockley's Drug Interactions, 12th ed.
//   • FDA / EMA labels for the specific pairs flagged.
//
// Dart port of engine/ddi.ts.

/// Severity tier for a DDI hit.
enum DdiSeverity {
  info('info'),
  caution('caution'),
  warning('warning'),
  avoid('avoid');

  const DdiSeverity(this.jsonValue);

  final String jsonValue;

  static DdiSeverity fromJson(String value) {
    for (final s in DdiSeverity.values) {
      if (s.jsonValue == value) return s;
    }
    throw ArgumentError.value(value, 'value', 'unknown DdiSeverity');
  }
}

/// Mechanism category for a DDI hit.
enum DdiMechanism {
  serotonergic('serotonergic'),
  cypInhibition('cyp_inhibition'),
  cypInduction('cyp_induction'),
  qtcAdditive('qtc_additive'),
  anticholinergic('anticholinergic'),
  pharmacodynamic('pharmacodynamic'),
  sedationAdditive('sedation_additive'),
  orthostasis('orthostasis');

  const DdiMechanism(this.jsonValue);

  final String jsonValue;

  static DdiMechanism fromJson(String value) {
    for (final m in DdiMechanism.values) {
      if (m.jsonValue == value) return m;
    }
    throw ArgumentError.value(value, 'value', 'unknown DdiMechanism');
  }
}

/// One DDI hit produced by [checkPair] / [checkAll].
class DdiHit {
  const DdiHit({
    required this.pair,
    required this.severity,
    required this.mechanism,
    required this.message,
    this.mitigation,
    this.citation,
  });

  final List<String> pair;
  final DdiSeverity severity;
  final DdiMechanism mechanism;
  final String message;

  /// During cross-taper, how to mitigate.
  final String? mitigation;

  final String? citation;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pair': pair,
        'severity': severity.jsonValue,
        'mechanism': mechanism.jsonValue,
        'message': message,
        if (mitigation != null) 'mitigation': mitigation,
        if (citation != null) 'citation': citation,
      };
}

// ── Class predicates ─────────────────────────────────────────────────

const Set<String> _ssris = <String>{
  'fluoxetine',
  'sertraline',
  'paroxetine',
  'fluvoxamine',
  'escitalopram',
};
const Set<String> _snris = <String>{
  'venlafaxine',
  'desvenlafaxine',
  'duloxetine',
};
const Set<String> _maois = <String>{
  'phenelzine',
  'tranylcypromine',
  'moclobemide',
};
const Set<String> _cyp2d6InhibitorsStrong = <String>{
  'fluoxetine',
  'paroxetine',
  'bupropion',
};
const Set<String> _cyp1a2InhibitorsStrong = <String>{'fluvoxamine'};
const Set<String> _cyp3a4InhibitorsMod = <String>{'fluvoxamine'};
const Set<String> _cyp2d6Substrates = <String>{
  'risperidone',
  'aripiprazole',
  'haloperidol',
  'venlafaxine',
};
const Set<String> _cyp1a2Substrates = <String>{'clozapine', 'olanzapine'};
const Set<String> _qtProlongersStrong = <String>{
  'haloperidol',
  'sulpiride',
  'amisulpride',
};
const Set<String> _qtProlongersMod = <String>{
  'citalopram',
  'escitalopram',
  'chlorpromazine',
};
const Set<String> _sedatives = <String>{
  'mirtazapine',
  'olanzapine',
  'quetiapine',
  'clozapine',
  'chlorpromazine',
};

bool _anyPair(String a, String b, Set<String> sa, Set<String> sb) =>
    (sa.contains(a) && sb.contains(b)) ||
    (sa.contains(b) && sb.contains(a));

class _Pattern {
  const _Pattern({
    required this.match,
    required this.severity,
    required this.mechanism,
    required this.message,
    this.mitigation,
    this.citation,
  });

  final bool Function(String a, String b) match;
  final DdiSeverity severity;
  final DdiMechanism mechanism;
  final String message;
  final String? mitigation;
  final String? citation;
}

final List<_Pattern> _patterns = <_Pattern>[
  // ── Serotonergic stacking ──
  _Pattern(
    match: (a, b) =>
        a != b &&
        (_anyPair(a, b, _ssris, _ssris) ||
            _anyPair(a, b, _ssris, _snris) ||
            _anyPair(a, b, _snris, _snris)),
    severity: DdiSeverity.caution,
    mechanism: DdiMechanism.serotonergic,
    message:
        'Two serotonergic agents — additive serotonin effect during overlap.',
    mitigation:
        'Cross-taper slowly (10–14 d). Counsel for serotonin syndrome (clonus, hyperthermia, autonomic).',
    citation: 'maudsley15_serotonin_syndrome',
  ),
  _Pattern(
    match: (a, b) =>
        _anyPair(a, b, _ssris, _maois) || _anyPair(a, b, _snris, _maois),
    severity: DdiSeverity.avoid,
    mechanism: DdiMechanism.serotonergic,
    message:
        'SSRI/SNRI + MAOI: contraindicated. Risk of fatal serotonin syndrome.',
    mitigation:
        '14-day washout from irreversible MAOI; 5-week from fluoxetine before MAOI.',
    citation: 'maudsley15_maoi_washout',
  ),
  _Pattern(
    match: (a, b) =>
        _anyPair(a, b, const <String>{'mirtazapine'}, _maois),
    severity: DdiSeverity.warning,
    mechanism: DdiMechanism.serotonergic,
    message: 'Mirtazapine + MAOI: theoretical risk; usually avoided.',
    mitigation: '14-day MAOI washout before mirtazapine.',
  ),

  // ── CYP-mediated ──
  _Pattern(
    match: (a, b) =>
        _anyPair(a, b, _cyp2d6InhibitorsStrong, _cyp2d6Substrates),
    severity: DdiSeverity.warning,
    mechanism: DdiMechanism.cypInhibition,
    message:
        'Strong CYP2D6 inhibitor + substrate — substrate level may double.',
    mitigation:
        'Reduce substrate dose ~50% during overlap; review at 7 days.',
    citation: 'maudsley15_cyp_table',
  ),
  _Pattern(
    match: (a, b) =>
        _anyPair(a, b, _cyp1a2InhibitorsStrong, _cyp1a2Substrates),
    severity: DdiSeverity.warning,
    mechanism: DdiMechanism.cypInhibition,
    message:
        'Fluvoxamine + clozapine/olanzapine — substrate levels rise sharply.',
    mitigation:
        'Reduce substrate dose; check trough level if combined intentionally.',
  ),
  _Pattern(
    match: (a, b) => _anyPair(
      a,
      b,
      _cyp3a4InhibitorsMod,
      const <String>{'quetiapine', 'aripiprazole', 'lurasidone'},
    ),
    severity: DdiSeverity.caution,
    mechanism: DdiMechanism.cypInhibition,
    message: 'Moderate CYP3A4 inhibition — substrate levels rise.',
    mitigation:
        'Consider 25–50% substrate dose reduction during co-administration.',
  ),

  // ── QTc additive (extends qtc_stacker.dart) ──
  _Pattern(
    match: (a, b) =>
        a != b &&
        ((_qtProlongersStrong.contains(a) &&
                _qtProlongersStrong.contains(b)) ||
            (_qtProlongersStrong.contains(a) &&
                _qtProlongersMod.contains(b)) ||
            (_qtProlongersMod.contains(a) &&
                _qtProlongersStrong.contains(b))),
    severity: DdiSeverity.warning,
    mechanism: DdiMechanism.qtcAdditive,
    message: 'Both drugs prolong QTc — additive effect during overlap.',
    mitigation:
        'ECG before overlap, repeat at peak of overlap (Day 7–14). Use shortest overlap reasonable.',
    citation: 'maudsley15_qtc',
  ),

  // ── Pharmacodynamic conflict ──
  _Pattern(
    match: (a, b) =>
        (a == 'aripiprazole' && b == 'risperidone') ||
        (b == 'aripiprazole' && a == 'risperidone') ||
        (a == 'aripiprazole' && b == 'haloperidol') ||
        (b == 'aripiprazole' && a == 'haloperidol'),
    severity: DdiSeverity.caution,
    mechanism: DdiMechanism.pharmacodynamic,
    message:
        'D2 partial agonist (aripiprazole) competing with full antagonist — early relapse risk.',
    mitigation:
        'Plateau cross-taper: hold full antagonist at therapeutic dose for 2 weeks before tapering.',
  ),

  // ── Sedation additive ──
  _Pattern(
    match: (a, b) =>
        a != b && _sedatives.contains(a) && _sedatives.contains(b),
    severity: DdiSeverity.caution,
    mechanism: DdiMechanism.sedationAdditive,
    message:
        'Two sedating agents — additive somnolence during overlap.',
    mitigation:
        'Counsel re: driving / falls. Consider once-daily nocte dosing of both.',
  ),

  // ── Anticholinergic burden ──
  _Pattern(
    match: (a, b) =>
        (a == 'chlorpromazine' && b == 'paroxetine') ||
        (b == 'chlorpromazine' && a == 'paroxetine') ||
        (a == 'olanzapine' && b == 'paroxetine') ||
        (b == 'olanzapine' && a == 'paroxetine'),
    severity: DdiSeverity.caution,
    mechanism: DdiMechanism.anticholinergic,
    message:
        'Combined anticholinergic load — confusion / falls in older adults.',
    mitigation:
        'Avoid in older adults if possible. Otherwise minimise overlap window.',
  ),
];

/// Check a drug pair for known overlap-window interactions.
List<DdiHit> checkPair(String a, String b) {
  final out = <DdiHit>[];
  for (final p in _patterns) {
    if (p.match(a, b)) {
      out.add(
        DdiHit(
          pair: <String>[a, b],
          severity: p.severity,
          mechanism: p.mechanism,
          message: p.message,
          mitigation: p.mitigation,
          citation: p.citation,
        ),
      );
    }
  }
  return out;
}

/// Check a list of drugs for any pairwise interactions. Used by the
/// "current medications" flow that mirrors qtcStacker.
List<DdiHit> checkAll(List<String> drugIds) {
  final out = <DdiHit>[];
  for (var i = 0; i < drugIds.length; i++) {
    for (var j = i + 1; j < drugIds.length; j++) {
      out.addAll(checkPair(drugIds[i], drugIds[j]));
    }
  }
  return out;
}

/// Numeric rank for a [DdiSeverity]. info=0 … avoid=3.
int severityRank(DdiSeverity s) {
  switch (s) {
    case DdiSeverity.info:
      return 0;
    case DdiSeverity.caution:
      return 1;
    case DdiSeverity.warning:
      return 2;
    case DdiSeverity.avoid:
      return 3;
  }
}
