// Lab interpreter — the labs a psychiatrist reads many times a week.
//
// Each lab has reference bands keyed to clinically meaningful tiers
// (low / normal / high / critical) with a one-line action the
// clinician can paste into the note. Adult-only ranges (paediatric
// labs out of scope for first release).
//
// Sources: Maudsley 15e · Stahl 7e · UK National Formulary · MOH
// Clinical Practice Guidelines.

enum LabTier {
  criticalLow('critical_low'),
  low('low'),
  normal('normal'),
  high('high'),
  criticalHigh('critical_high');

  const LabTier(this.jsonValue);
  final String jsonValue;
}

String labTierLabel(LabTier t) {
  switch (t) {
    case LabTier.criticalLow:
      return 'Critically low';
    case LabTier.low:
      return 'Low';
    case LabTier.normal:
      return 'Within range';
    case LabTier.high:
      return 'High';
    case LabTier.criticalHigh:
      return 'Critically high';
  }
}

class LabBand {
  const LabBand({
    required this.upper,
    required this.tier,
    required this.action,
  });

  /// Upper bound of this tier (inclusive).
  final double upper;
  final LabTier tier;

  /// One-line action to paste into the note.
  final String action;
}

class LabTest {
  const LabTest({
    required this.id,
    required this.name,
    required this.unit,
    required this.context,
    required this.bands,
  });

  final String id;
  final String name;

  /// Display unit (e.g. "mIU/L", "× 10⁹/L").
  final String unit;

  /// Short context line under the test name (when to order / what
  /// drugs need this monitoring).
  final String context;

  /// Bands ordered from lowest upper-bound to highest. The final
  /// band is treated as "anything above the previous upper bound".
  final List<LabBand> bands;
}

class LabInterpretation {
  const LabInterpretation({
    required this.test,
    required this.value,
    required this.tier,
    required this.action,
  });

  final LabTest test;
  final double value;
  final LabTier tier;
  final String action;

  String clipboardSummary() {
    return '${test.name}: $value ${test.unit} — ${labTierLabel(tier)}. '
        '$action';
  }
}

/// Interpret a value against the test's bands. Walks bands until the
/// value fits an upper bound; final band catches anything above.
LabInterpretation interpretLab(LabTest test, double value) {
  for (final b in test.bands) {
    if (value <= b.upper) {
      return LabInterpretation(
        test: test,
        value: value,
        tier: b.tier,
        action: b.action,
      );
    }
  }
  final last = test.bands.last;
  return LabInterpretation(
    test: test,
    value: value,
    tier: last.tier,
    action: last.action,
  );
}

const List<LabTest> kLabTests = <LabTest>[
  LabTest(
    id: 'tsh',
    name: 'TSH',
    unit: 'mIU/L',
    context: 'Baseline + 6-monthly on lithium. Annual on quetiapine, '
        'olanzapine, carbamazepine.',
    bands: <LabBand>[
      LabBand(
        upper: 0.1,
        tier: LabTier.criticalLow,
        action: 'Critically suppressed — check fT4 / fT3; '
            'discuss with endocrine. Hyperthyroidism may worsen mood.',
      ),
      LabBand(
        upper: 0.4,
        tier: LabTier.low,
        action: 'Below range — repeat in 6 weeks; check fT4.',
      ),
      LabBand(
        upper: 4.0,
        tier: LabTier.normal,
        action: 'Within range. Continue routine monitoring.',
      ),
      LabBand(
        upper: 10.0,
        tier: LabTier.high,
        action: 'Subclinical hypothyroidism — repeat in 6 weeks. '
            'Common on lithium; consider levothyroxine if symptomatic '
            'or TSH > 10 on repeat.',
      ),
      LabBand(
        upper: 999,
        tier: LabTier.criticalHigh,
        action: 'Overt hypothyroidism — start levothyroxine; '
            'continue lithium with co-prescription.',
      ),
    ],
  ),
  LabTest(
    id: 'prolactin',
    name: 'Prolactin',
    unit: 'mIU/L',
    context: 'Baseline + when symptomatic on antipsychotics. '
        'Risperidone, amisulpride, paliperidone are highest-risk.',
    bands: <LabBand>[
      LabBand(
        upper: 500,
        tier: LabTier.normal,
        action: 'Within range.',
      ),
      LabBand(
        upper: 1000,
        tier: LabTier.high,
        action: 'Mildly elevated — likely drug-induced. Review for '
            'sexual / menstrual symptoms; consider switching to a '
            'prolactin-sparing agent (aripiprazole, quetiapine).',
      ),
      LabBand(
        upper: 2500,
        tier: LabTier.high,
        action: 'Moderate hyperprolactinaemia — strongly consider '
            'switch. Check menstrual / sexual / breast symptoms; '
            'screen for amenorrhoea-related bone loss.',
      ),
      LabBand(
        upper: 999999,
        tier: LabTier.criticalHigh,
        action: 'Marked hyperprolactinaemia — exclude prolactinoma '
            'with MRI pituitary BEFORE attributing to medication.',
      ),
    ],
  ),
  LabTest(
    id: 'anc',
    name: 'ANC',
    unit: '× 10⁹/L',
    context: 'Clozapine — weekly × 18 weeks, then fortnightly × 1 '
        'year, then 4-weekly. Halt + register if ANC < 1.5.',
    bands: <LabBand>[
      LabBand(
        upper: 0.5,
        tier: LabTier.criticalLow,
        action: 'AGRANULOCYTOSIS — stop clozapine immediately. '
            'Haematology referral; protective isolation; G-CSF if '
            'persistent. Permanent registry flag.',
      ),
      LabBand(
        upper: 1.0,
        tier: LabTier.criticalLow,
        action: 'Severe neutropenia — STOP clozapine. Daily FBC; '
            'haematology input.',
      ),
      LabBand(
        upper: 1.5,
        tier: LabTier.low,
        action: 'Mild neutropenia — REPEAT FBC tomorrow. '
            'Investigate other causes (infection, ethnic '
            'neutropenia — benign ethnic neutropenia common in '
            'Malay / African ancestry).',
      ),
      LabBand(
        upper: 7.5,
        tier: LabTier.normal,
        action: 'Within range. Continue protocol monitoring.',
      ),
      LabBand(
        upper: 999,
        tier: LabTier.high,
        action: 'Elevated — consider infection; recheck inflammatory '
            'markers.',
      ),
    ],
  ),
  LabTest(
    id: 'sodium',
    name: 'Sodium',
    unit: 'mmol/L',
    context: 'Baseline + at week 2 on SSRIs / SNRIs in patients ≥ 65 '
        'or on diuretics. Carbamazepine + oxcarbazepine also cause '
        'hyponatraemia.',
    bands: <LabBand>[
      LabBand(
        upper: 125,
        tier: LabTier.criticalLow,
        action: 'Severe hyponatraemia — admit for inpatient '
            'correction. STOP the offending drug. Risk of '
            'seizures + cerebral oedema.',
      ),
      LabBand(
        upper: 130,
        tier: LabTier.low,
        action: 'Moderate hyponatraemia — likely drug-induced SIADH. '
            'STOP / switch agent; fluid-restrict; recheck daily.',
      ),
      LabBand(
        upper: 135,
        tier: LabTier.low,
        action: 'Mild hyponatraemia — recheck in 1 week. Review '
            'medication list (SSRI / SNRI / carbamazepine + '
            'thiazide are the usual culprits).',
      ),
      LabBand(
        upper: 145,
        tier: LabTier.normal,
        action: 'Within range.',
      ),
      LabBand(
        upper: 999,
        tier: LabTier.high,
        action: 'Hypernatraemia — assess hydration status; check for '
            'diabetes insipidus (lithium-induced nephrogenic DI).',
      ),
    ],
  ),
  LabTest(
    id: 'creatinine',
    name: 'Creatinine',
    unit: 'μmol/L',
    context: 'Baseline + 6-monthly on lithium. Use Cockcroft-Gault '
        'to confirm before any psychotropic with renal clearance.',
    bands: <LabBand>[
      LabBand(
        upper: 60,
        tier: LabTier.low,
        action: 'Lower than expected — confirm muscle mass / age; '
            'low creatinine in cachectic patients can mask renal '
            'dysfunction.',
      ),
      LabBand(
        upper: 110,
        tier: LabTier.normal,
        action: 'Within range.',
      ),
      LabBand(
        upper: 150,
        tier: LabTier.high,
        action: 'Mildly elevated — calculate eGFR; review lithium '
            'dosing + NSAIDs / ACE-inhibitors / diuretics.',
      ),
      LabBand(
        upper: 999,
        tier: LabTier.criticalHigh,
        action: 'Significant impairment — nephrology input. Lithium '
            'and depot LAIs need dose review; some psychotropics '
            'contraindicated.',
      ),
    ],
  ),
  LabTest(
    id: 'hba1c',
    name: 'HbA1c',
    unit: '%',
    context: 'Baseline + annual on atypical antipsychotics. '
        'Olanzapine + clozapine highest risk; aripiprazole + '
        'lurasidone lowest.',
    bands: <LabBand>[
      LabBand(
        upper: 5.6,
        tier: LabTier.normal,
        action: 'Within range.',
      ),
      LabBand(
        upper: 6.4,
        tier: LabTier.high,
        action: 'Pre-diabetes — lifestyle counselling + monitor; '
            'consider switching to a lower-metabolic-risk '
            'antipsychotic.',
      ),
      LabBand(
        upper: 9.0,
        tier: LabTier.high,
        action: 'Diabetes — endocrine referral, start metformin per '
            'protocol. Strongly consider antipsychotic switch.',
      ),
      LabBand(
        upper: 999,
        tier: LabTier.criticalHigh,
        action: 'Poorly controlled diabetes — urgent endocrine input '
            'and antipsychotic review.',
      ),
    ],
  ),
  LabTest(
    id: 'ldl',
    name: 'LDL cholesterol',
    unit: 'mmol/L',
    context: 'Baseline + annual on atypical antipsychotics.',
    bands: <LabBand>[
      LabBand(
        upper: 3.0,
        tier: LabTier.normal,
        action: 'Within target.',
      ),
      LabBand(
        upper: 4.0,
        tier: LabTier.high,
        action: 'Elevated — lifestyle counselling. If high CV risk, '
            'consider statin.',
      ),
      LabBand(
        upper: 999,
        tier: LabTier.criticalHigh,
        action: 'Markedly elevated — start statin; consider '
            'antipsychotic switch to lower-metabolic-risk agent.',
      ),
    ],
  ),
  LabTest(
    id: 'ck',
    name: 'Creatine kinase',
    unit: 'U/L',
    context: 'Suspected NMS — peak typically 1000–10 000 U/L. Also '
        'rises with restraint, IM injection, exercise.',
    bands: <LabBand>[
      LabBand(
        upper: 200,
        tier: LabTier.normal,
        action: 'Within range.',
      ),
      LabBand(
        upper: 1000,
        tier: LabTier.high,
        action: 'Elevated — likely from IM injection or restraint. '
            'Recheck in 24 hours; correlate with rigidity / fever.',
      ),
      LabBand(
        upper: 5000,
        tier: LabTier.criticalHigh,
        action: 'NMS concerning — STOP antipsychotic; check '
            'rigidity / fever / autonomic; IV hydration to protect '
            'kidneys.',
      ),
      LabBand(
        upper: 999999,
        tier: LabTier.criticalHigh,
        action: 'Rhabdomyolysis — STOP offending drug, IV fluids at '
            '> 200 mL/h, monitor renal function + electrolytes; ICU '
            'admission usually required.',
      ),
    ],
  ),
  LabTest(
    id: 'alt',
    name: 'ALT',
    unit: 'U/L',
    context: 'Baseline + 4-weekly × 3 months on valproate, '
        'carbamazepine, lamotrigine. Annual on chronic clozapine.',
    bands: <LabBand>[
      LabBand(
        upper: 40,
        tier: LabTier.normal,
        action: 'Within range.',
      ),
      LabBand(
        upper: 120,
        tier: LabTier.high,
        action: 'Mildly elevated (< 3× ULN) — recheck in 2 weeks; '
            'review alcohol + concurrent hepatotoxic drugs.',
      ),
      LabBand(
        upper: 240,
        tier: LabTier.high,
        action: 'Moderately elevated (3–6× ULN) — hold the suspect '
            'drug, screen viral hepatitis, urgent recheck.',
      ),
      LabBand(
        upper: 999,
        tier: LabTier.criticalHigh,
        action: 'Markedly elevated (> 6× ULN) — STOP suspect '
            'hepatotoxic agents, hepatology referral.',
      ),
    ],
  ),
];

LabTest? labTestById(String id) {
  for (final t in kLabTests) {
    if (t.id == id) return t;
  }
  return null;
}
