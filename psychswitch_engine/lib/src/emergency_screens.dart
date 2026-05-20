// Emergency-psychiatry rapid screeners.
//
// Two life-threatening differentials a psychiatrist must catch within
// minutes of bedside review:
//
//   • Neuroleptic Malignant Syndrome (NMS) — Levenson 1985 criteria.
//   • Serotonin Syndrome — Hunter Toxicity Criteria (Dunkley 2003).
//
// Both engines take a checked-set of criteria and return a tier
// (clear / probable / definite) plus a one-line recommendation.

// ── NMS — Neuroleptic Malignant Syndrome ────────────────────────────

class NmsCriterion {
  const NmsCriterion({
    required this.id,
    required this.label,
    required this.tier,
  });

  final String id;
  final String label;

  /// 'major' or 'minor' per Levenson criteria.
  final String tier;
}

const List<NmsCriterion> kNmsMajor = <NmsCriterion>[
  NmsCriterion(
    id: 'nms_maj_fever',
    label: 'Fever ≥ 38.0 °C',
    tier: 'major',
  ),
  NmsCriterion(
    id: 'nms_maj_rigidity',
    label: 'Generalised muscle rigidity ("lead-pipe")',
    tier: 'major',
  ),
  NmsCriterion(
    id: 'nms_maj_ck',
    label: 'Elevated creatine kinase (CK)',
    tier: 'major',
  ),
];

const List<NmsCriterion> kNmsMinor = <NmsCriterion>[
  NmsCriterion(
    id: 'nms_min_tachy',
    label: 'Tachycardia',
    tier: 'minor',
  ),
  NmsCriterion(
    id: 'nms_min_bp',
    label: 'Abnormal blood pressure (high or labile)',
    tier: 'minor',
  ),
  NmsCriterion(
    id: 'nms_min_tachypnoea',
    label: 'Tachypnoea',
    tier: 'minor',
  ),
  NmsCriterion(
    id: 'nms_min_consciousness',
    label: 'Altered consciousness (confusion, mutism, stupor, coma)',
    tier: 'minor',
  ),
  NmsCriterion(
    id: 'nms_min_diaphoresis',
    label: 'Diaphoresis',
    tier: 'minor',
  ),
  NmsCriterion(
    id: 'nms_min_leukocytosis',
    label: 'Leukocytosis',
    tier: 'minor',
  ),
];

enum NmsTier {
  unlikely('unlikely'),
  possible('possible'),
  probable('probable'),
  definite('definite');

  const NmsTier(this.jsonValue);
  final String jsonValue;
}

class NmsResult {
  const NmsResult({
    required this.tier,
    required this.majorTicked,
    required this.minorTicked,
    required this.exposed,
    required this.headline,
    required this.recommendation,
  });

  final NmsTier tier;
  final int majorTicked;
  final int minorTicked;
  final bool exposed;
  final String headline;
  final String recommendation;

  String clipboardSummary() {
    return 'NMS screener — ${tier.name.toUpperCase()}: '
        '$majorTicked of 3 major + $minorTicked of 6 minor criteria '
        'with ${exposed ? "" : "no "}recent antipsychotic exposure. '
        '$recommendation';
  }
}

/// Evaluate NMS criteria. Levenson criteria:
///   • ≥ 3 major OR
///   • ≥ 2 major + ≥ 4 minor
/// plus recent (within 7 days) exposure to a dopamine-blocker.
NmsResult evaluateNms({
  required Set<String> ticked,
  required bool antipsychoticExposure,
}) {
  final majorTicked = kNmsMajor.where((c) => ticked.contains(c.id)).length;
  final minorTicked = kNmsMinor.where((c) => ticked.contains(c.id)).length;

  NmsTier tier;
  String headline;
  String recommendation;

  if (!antipsychoticExposure) {
    tier = NmsTier.unlikely;
    headline = 'No recent dopamine-blocker exposure — NMS unlikely.';
    recommendation =
        'Consider alternative differentials (serotonin syndrome, '
        'sepsis, encephalitis, malignant catatonia).';
  } else if (majorTicked >= 3 ||
      (majorTicked >= 2 && minorTicked >= 4)) {
    tier = NmsTier.definite;
    headline = 'Definite NMS — medical emergency.';
    recommendation =
        'STOP the offending antipsychotic. ICU transfer, supportive '
        'care (aggressive cooling, IV fluids, electrolytes). Consider '
        'dantrolene 1-2.5 mg/kg IV or bromocriptine 2.5 mg PO/NG q8h. '
        'Anticipate AKI from rhabdomyolysis.';
  } else if (majorTicked >= 2 || (majorTicked >= 1 && minorTicked >= 3)) {
    tier = NmsTier.probable;
    headline = 'Probable NMS — urgent action required.';
    recommendation =
        'STOP suspected antipsychotic. Serial vitals + CK + LFTs + '
        'creatinine. Admit for observation; have ICU prepared. Treat '
        'hyperthermia aggressively.';
  } else if (majorTicked >= 1 || minorTicked >= 2) {
    tier = NmsTier.possible;
    headline = 'Possible NMS — careful observation.';
    recommendation =
        'Hold the antipsychotic pending review. Check CK + UEC + LFT. '
        'Differentials: extrapyramidal reaction, infection, '
        'serotonin syndrome.';
  } else {
    tier = NmsTier.unlikely;
    headline = 'NMS unlikely on current features.';
    recommendation =
        'Continue treatment with monitoring. Re-screen if new '
        'autonomic or motor features emerge.';
  }

  return NmsResult(
    tier: tier,
    majorTicked: majorTicked,
    minorTicked: minorTicked,
    exposed: antipsychoticExposure,
    headline: headline,
    recommendation: recommendation,
  );
}

// ── Serotonin Syndrome — Hunter Toxicity Criteria ───────────────────
//
// Dunkley EJC et al. QJM 2003;96:635-42. The Hunter criteria use a
// decision tree (positive when in presence of serotonergic agent
// AND one of):
//   • Spontaneous clonus
//   • Inducible clonus + (agitation OR diaphoresis)
//   • Ocular clonus + (agitation OR diaphoresis)
//   • Tremor + hyperreflexia
//   • Hypertonia + temperature > 38 °C + (ocular or inducible clonus)
//
// Sensitivity 84%, specificity 97% — gold standard.

class SerotoninFeatures {
  const SerotoninFeatures({
    required this.serotonergicAgent,
    required this.spontaneousClonus,
    required this.inducibleClonus,
    required this.ocularClonus,
    required this.agitation,
    required this.diaphoresis,
    required this.tremor,
    required this.hyperreflexia,
    required this.hypertonia,
    required this.feverAbove38,
  });

  final bool serotonergicAgent;
  final bool spontaneousClonus;
  final bool inducibleClonus;
  final bool ocularClonus;
  final bool agitation;
  final bool diaphoresis;
  final bool tremor;
  final bool hyperreflexia;
  final bool hypertonia;
  final bool feverAbove38;
}

class SerotoninResult {
  const SerotoninResult({
    required this.met,
    required this.path,
    required this.headline,
    required this.recommendation,
  });

  /// True when Hunter criteria are met.
  final bool met;

  /// Which branch of the Hunter decision tree fired (for the note).
  /// Empty string when no path triggered.
  final String path;

  final String headline;
  final String recommendation;

  String clipboardSummary() {
    return 'Serotonin syndrome (Hunter): '
        '${met ? "MET — $path" : "not met"}. $recommendation';
  }
}

SerotoninResult evaluateSerotonin(SerotoninFeatures f) {
  if (!f.serotonergicAgent) {
    return const SerotoninResult(
      met: false,
      path: '',
      headline: 'No serotonergic exposure — Hunter criteria require '
          'a serotonergic agent.',
      recommendation:
          'If clinical picture suggests, review the medication list — '
          'tramadol, linezolid, MDMA, St John\'s Wort are easy to miss.',
    );
  }
  if (f.spontaneousClonus) {
    return const SerotoninResult(
      met: true,
      path: 'spontaneous clonus',
      headline: 'Serotonin syndrome — Hunter MET.',
      recommendation:
          'STOP all serotonergic agents. Supportive care, IV fluids, '
          'aggressive cooling. Cyproheptadine 12 mg PO/NG, then 2 mg '
          'q2h. Benzodiazepine for agitation. ICU for severe '
          'hyperthermia or autonomic instability.',
    );
  }
  if (f.inducibleClonus && (f.agitation || f.diaphoresis)) {
    return const SerotoninResult(
      met: true,
      path: 'inducible clonus + agitation / diaphoresis',
      headline: 'Serotonin syndrome — Hunter MET.',
      recommendation:
          'STOP serotonergic agents. Benzodiazepine for agitation. '
          'Cyproheptadine if severe. Monitor temperature + CK.',
    );
  }
  if (f.ocularClonus && (f.agitation || f.diaphoresis)) {
    return const SerotoninResult(
      met: true,
      path: 'ocular clonus + agitation / diaphoresis',
      headline: 'Serotonin syndrome — Hunter MET.',
      recommendation:
          'STOP serotonergic agents. Benzodiazepine for agitation. '
          'Cyproheptadine if severe. Monitor temperature + CK.',
    );
  }
  if (f.tremor && f.hyperreflexia) {
    return const SerotoninResult(
      met: true,
      path: 'tremor + hyperreflexia',
      headline: 'Serotonin syndrome — Hunter MET.',
      recommendation:
          'STOP serotonergic agents. Supportive care; observe for '
          'clonus and hyperthermia.',
    );
  }
  if (f.hypertonia && f.feverAbove38 &&
      (f.ocularClonus || f.inducibleClonus)) {
    return const SerotoninResult(
      met: true,
      path: 'hypertonia + fever > 38 °C + clonus',
      headline: 'Serotonin syndrome — Hunter MET (severe).',
      recommendation:
          'STOP serotonergic agents. ICU transfer for severe '
          'hyperthermia. Active cooling. Cyproheptadine. Intubate / '
          'paralyse if temperature uncontrolled. Consider differential '
          'NMS.',
    );
  }
  return const SerotoninResult(
    met: false,
    path: '',
    headline: 'Hunter criteria not met on current features.',
    recommendation:
        'Continue monitoring. Re-screen if clonus, agitation, '
        'diaphoresis, or autonomic features emerge.',
  );
}
