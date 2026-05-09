// Citation registry + evidence grading.
//
// Two responsibilities (mirrors engine/citations.ts):
//   1. Resolve a citation key → human-readable reference + locator +
//      paraphrase. The "show your work" UI uses this.
//   2. Derive an evidence grade (A / B / C / D) for a rule based on
//      the strongest citation it carries.
//
// Grading scale:
//   A — Direct guideline / regulatory (Maudsley, BAP, NICE, FDA/EMA,
//       MoH CPG, major IPD meta-analyses)
//   B — Strong derived (Horowitz hyperbolic taper, Ashton manual)
//   C — Expert consensus (single-author chapters, narrative reviews)
//   D — Limited evidence
//
// Grading describes the EVIDENCE for a rule, not safety. A and B are
// equally usable; C and D require more individual judgement.

enum EvidenceGrade {
  a,
  b,
  c,
  d;

  String get jsonValue => switch (this) {
        EvidenceGrade.a => 'A',
        EvidenceGrade.b => 'B',
        EvidenceGrade.c => 'C',
        EvidenceGrade.d => 'D',
      };

  static EvidenceGrade fromJson(String s) => switch (s) {
        'A' => EvidenceGrade.a,
        'B' => EvidenceGrade.b,
        'C' => EvidenceGrade.c,
        'D' => EvidenceGrade.d,
        _ => throw FormatException('Unknown evidence grade: $s'),
      };
}

enum CitationSource {
  maudsley15,
  bap,
  nice,
  fda,
  ema,
  cpgMy,
  metaAnalysis,
  ashton,
  horowitz,
  manufacturer,
  expert,
  other;

  String get jsonValue => switch (this) {
        CitationSource.maudsley15 => 'Maudsley15',
        CitationSource.bap => 'BAP',
        CitationSource.nice => 'NICE',
        CitationSource.fda => 'FDA',
        CitationSource.ema => 'EMA',
        CitationSource.cpgMy => 'CPG-MY',
        CitationSource.metaAnalysis => 'meta-analysis',
        CitationSource.ashton => 'Ashton',
        CitationSource.horowitz => 'Horowitz',
        CitationSource.manufacturer => 'manufacturer',
        CitationSource.expert => 'expert',
        CitationSource.other => 'other',
      };

  static CitationSource fromJson(String s) => switch (s) {
        'Maudsley15' => CitationSource.maudsley15,
        'BAP' => CitationSource.bap,
        'NICE' => CitationSource.nice,
        'FDA' => CitationSource.fda,
        'EMA' => CitationSource.ema,
        'CPG-MY' => CitationSource.cpgMy,
        'meta-analysis' => CitationSource.metaAnalysis,
        'Ashton' => CitationSource.ashton,
        'Horowitz' => CitationSource.horowitz,
        'manufacturer' => CitationSource.manufacturer,
        'expert' => CitationSource.expert,
        'other' => CitationSource.other,
        _ => throw FormatException('Unknown citation source: $s'),
      };
}

class CitationEntry {
  const CitationEntry({
    required this.key,
    required this.source,
    required this.reference,
    this.locator,
    this.paraphrase,
  });

  final String key;
  final CitationSource source;
  final String reference;
  final String? locator;
  final String? paraphrase;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'source': source.jsonValue,
        'reference': reference,
        if (locator != null) 'locator': locator,
        if (paraphrase != null) 'paraphrase': paraphrase,
      };
}

// Internal helper for the curated map — same shape as CitationEntry
// minus `key`.
class _C {
  const _C({
    required this.source,
    required this.reference,
    this.locator,
    this.paraphrase,
  });

  final CitationSource source;
  final String reference;
  final String? locator;
  final String? paraphrase;
}

const _maudsley15Ref =
    'Maudsley Prescribing Guidelines, 15th ed.';

// ── Curated entries — direct port of engine/citations.ts CURATED ─────
const Map<String, _C> _curated = <String, _C>{
  // ── Maudsley 15th ──
  'maudsley15_ch3_p369_table_3_7': _C(
    source: CitationSource.maudsley15,
    reference:
        'Taylor D, Barnes TRE, Young AH. Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 3, p.369, Table 3.7',
    paraphrase:
        'Cross-tapering antidepressants: matrix of recommended strategies (direct, cross-taper cautiously, taper-then-wait, halve-and-add).',
  ),
  'maudsley15_ch3_p374_withdrawal': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 3, p.374',
    paraphrase:
        'Antidepressant discontinuation symptoms: hyperbolic tapering reduces severity and duration; bridge venlafaxine/paroxetine to fluoxetine for severe cases.',
  ),
  'maudsley15_ch3_snri_profile': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 3 — SNRI class profile',
    paraphrase:
        'SNRIs (venlafaxine, desvenlafaxine, duloxetine): NA reuptake activity at higher doses; high discontinuation risk with venlafaxine.',
  ),
  'maudsley15_ch3_vortioxetine_profile': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 3 — Vortioxetine profile',
    paraphrase:
        'Vortioxetine: multimodal serotonergic. CYP2D6 substrate — halve dose with strong inhibitors.',
  ),
  'maudsley15_serotonin_syndrome': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 3 — Serotonin syndrome',
    paraphrase:
        'Serotonin syndrome triad: cognitive (agitation, confusion), autonomic (tachycardia, hyperthermia, diaphoresis), neuromuscular (clonus, hyperreflexia).',
  ),
  'maudsley15_maoi_washout': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 3 — MAOI washout',
    paraphrase:
        'MAOI washout: 14 days off irreversible MAOIs before another serotonergic agent; 5 weeks from fluoxetine before MAOI (long t½ of norfluoxetine).',
  ),
  'maudsley15_cyp_table': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 1 — CYP interactions table',
    paraphrase:
        'Strong CYP2D6 inhibitors (fluoxetine, paroxetine, bupropion) raise substrate levels — halve dose of risperidone, aripiprazole during overlap.',
  ),
  'maudsley15_aps_metabolic': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 4 — Antipsychotic metabolic monitoring',
    paraphrase:
        'Antipsychotic metabolic monitoring: BMI + waist + lipids + HbA1c at baseline, 3 months, then yearly.',
  ),
  'maudsley15_aps_qtc': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 4 — Antipsychotic QTc',
    paraphrase:
        'Highest-risk QTc: haloperidol (esp. IV), pimozide, sertindole. Moderate: amisulpride, sulpiride. Lowest: aripiprazole, lurasidone.',
  ),
  'maudsley15_qtc': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 4 — QTc and antipsychotics',
    paraphrase:
        'Stop QT-prolonger if QTc >500 ms or rises >60 ms from baseline. Correct K+/Mg2+. Switch to lower-risk agent.',
  ),
  'maudsley15_clozapine_monitoring': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 4 — Clozapine monitoring',
    paraphrase:
        'Clozapine FBC: weekly weeks 1–18, fortnightly weeks 19–52, monthly thereafter. Stop if ANC <1.5.',
  ),
  'maudsley15_clozapine_stopping': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 4 — Stopping clozapine',
    paraphrase:
        'Severe rebound psychosis within 48–72 h of abrupt clozapine discontinuation. Cross-taper over ≥4 weeks unless agranulocytosis.',
  ),
  'maudsley15_mood_lithium_monitoring': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 5 — Lithium monitoring',
    paraphrase:
        'Lithium: U&E + TFT + Ca at baseline, level 5–7 d after each dose change, then 3-monthly. 6-monthly U&E + TFT.',
  ),
  'maudsley15_lithium_stopping': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 5 — Stopping lithium',
    paraphrase:
        'Rebound mania risk after abrupt lithium discontinuation. Taper over ≥3 months unless toxicity.',
  ),
  'maudsley15_lithium_tox': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 5 — Lithium toxicity',
    paraphrase:
        'Lithium toxicity: tremor, GI, ataxia, dysarthria, eventually seizures. Levels >1.5 mmol/L = clinical concern.',
  ),
  'maudsley15_mood_valproate': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 5 — Valproate',
    paraphrase:
        'Valproate: hepatotoxicity + thrombocytopenia. Baseline LFT + FBC + βHCG. 30–40% major malformation rate in pregnancy.',
  ),
  'maudsley15_mood_carbamazepine': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 5 — Carbamazepine',
    paraphrase:
        'Carbamazepine: agranulocytosis + hepatitis + SIADH. Auto-induces CYP3A4 — level rechecked at week 4.',
  ),
  'maudsley15_valproate_pregnancy': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 5 — Valproate in pregnancy',
    paraphrase:
        'Valproate contraindicated in pregnancy and women of reproductive age unless PPP. Lamotrigine is preferred bipolar maintenance in pregnancy.',
  ),
  'maudsley15_eps_management': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 4 — EPS management',
    paraphrase:
        'Akathisia: propranolol 20–80 mg or mirtazapine 15 mg. Parkinsonism: dose reduction or anticholinergic. Tardive: switch to clozapine.',
  ),
  'maudsley15_prolactin': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 4 — Hyperprolactinaemia',
    paraphrase:
        'Aripiprazole 5–15 mg adjunct often normalises prolactin without need to switch.',
  ),
  'maudsley15_sedation': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 4 — Antipsychotic sedation',
    paraphrase:
        'Most sedating: olanzapine, quetiapine, clozapine, chlorpromazine. Least: aripiprazole, lurasidone.',
  ),
  'maudsley15_sexual_ad': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 3 — AD sexual dysfunction',
    paraphrase:
        'Lowest sexual dysfunction: mirtazapine, agomelatine, vortioxetine. Highest: paroxetine.',
  ),
  'maudsley15_discontinuation': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 3 — Discontinuation',
    paraphrase:
        'Severe discontinuation: paroxetine, venlafaxine. Bridge to fluoxetine 20 mg for 1–2 weeks then taper fluoxetine.',
  ),
  'maudsley15_discontinuation_paroxetine': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 3 — Paroxetine discontinuation',
    paraphrase:
        'Paroxetine: dizziness, electric-shock sensations, irritability within 1–3 days of stopping. Hyperbolic taper or fluoxetine bridge.',
  ),
  'maudsley15_discontinuation_venlafaxine': _C(
    source: CitationSource.maudsley15,
    reference: _maudsley15Ref,
    locator: 'Ch. 3 — Venlafaxine discontinuation',
    paraphrase:
        'Venlafaxine missed-dose syndrome: severe within 12–24 h. Switch to fluoxetine 20 mg before stopping.',
  ),

  // ── BAP ──
  'bap2020_psychosis': _C(
    source: CitationSource.bap,
    reference:
        'Barnes TRE et al. Evidence-based guidelines for the pharmacological treatment of psychosis. J Psychopharmacol 2020;34(1):3–78.',
    paraphrase:
        'BAP 2020: antipsychotic choice driven by tolerability profile + patient preference; metabolic side effects most often determine adherence.',
  ),
  'bap2020_psychosis_switching': _C(
    source: CitationSource.bap,
    reference: 'BAP 2020 — Psychosis switching',
    paraphrase:
        'Plateau cross-taper recommended when switching from an antagonist to a partial agonist (aripiprazole) to mitigate early loss of efficacy.',
  ),
  'bap2020_psychosis_lai': _C(
    source: CitationSource.bap,
    reference: 'BAP 2020 — LAI in psychosis',
    paraphrase:
        'LAI antipsychotics for relapse prevention; oral overlap during initiation per individual product PI.',
  ),
  'bap2015_switching_antidepressants': _C(
    source: CitationSource.bap,
    reference:
        'Cleare A et al. BAP guidelines for the pharmacological treatment of depression. J Psychopharmacol 2015.',
    paraphrase:
        'Cross-titration over 1–4 weeks for most AD switches; longer with paroxetine/venlafaxine due to discontinuation risk.',
  ),
  'bap2015_evidence_antidepressants': _C(
    source: CitationSource.bap,
    reference: 'BAP 2015 — Evidence base for AD switching',
    paraphrase:
        'Strongest evidence for switching: SSRI → mirtazapine (mechanistic complementarity), SSRI → vortioxetine (multimodal).',
  ),

  // ── NICE ──
  'nice_ng178': _C(
    source: CitationSource.nice,
    reference:
        'NICE NG178 (2014, updated 2020). Psychosis and schizophrenia in adults.',
  ),
  'nice_ng222': _C(
    source: CitationSource.nice,
    reference: 'NICE NG222 (2022). Depression in adults.',
  ),

  // ── Meta-analyses / IPD ──
  'leucht2013_lancet_metaanalysis': _C(
    source: CitationSource.metaAnalysis,
    reference:
        'Leucht S et al. Comparative efficacy and tolerability of 15 antipsychotic drugs in schizophrenia. Lancet 2013;382:951–62.',
    paraphrase:
        '15-drug network meta-analysis: clozapine > olanzapine ≈ amisulpride > others for efficacy; clozapine + olanzapine highest weight gain.',
  ),
  'leucht2016_ddd_schizophrenia_bulletin': _C(
    source: CitationSource.metaAnalysis,
    reference:
        'Leucht S et al. Dose equivalents for antipsychotics: DDD method. Schizophr Bull 2016;42(suppl 1):S90–S94.',
    paraphrase:
        'CPZ-equivalence by defined daily dose (DDD): 100 mg CPZ = 2 mg haloperidol = 5 mg olanzapine = 7.5 mg aripiprazole.',
  ),
  'cipriani2018_lancet_metaanalysis': _C(
    source: CitationSource.metaAnalysis,
    reference:
        'Cipriani A et al. Comparative efficacy and acceptability of 21 antidepressants. Lancet 2018;391:1357–66.',
    paraphrase:
        '21-AD network meta-analysis: agomelatine, amitriptyline, escitalopram, mirtazapine, paroxetine, vortioxetine most efficacious vs placebo.',
  ),
  'hayasaka2015_jad_dose_equivalents': _C(
    source: CitationSource.metaAnalysis,
    reference:
        'Hayasaka Y et al. Dose equivalents of antidepressants. J Affect Disord 2015;180:179–84.',
    paraphrase:
        'Fluoxetine 40 mg ≈ paroxetine 25 mg ≈ sertraline 100 mg ≈ escitalopram 18 mg ≈ venlafaxine 150 mg.',
  ),
  'horowitz2020_hyperbolic_tapering': _C(
    source: CitationSource.horowitz,
    reference:
        'Horowitz MA, Taylor D. Tapering of SSRI treatment to mitigate withdrawal symptoms. Lancet Psychiatry 2019;6(6):538–46.',
    paraphrase:
        'Hyperbolic tapering: small dose reductions at low doses (where receptor occupancy curve is steep) reduces withdrawal severity.',
  ),

  // ── Manufacturer / regulatory ──
  'invega_sustenna_pi': _C(
    source: CitationSource.manufacturer,
    reference: 'Invega Sustenna (paliperidone palmitate) PI, Janssen. DailyMed.',
    paraphrase:
        'PP1M initiation: 234 mg D1, 156 mg D8 (deltoid), then 117 mg monthly (deltoid or gluteal).',
  ),
  'invega_trinza_pi': _C(
    source: CitationSource.manufacturer,
    reference:
        'Invega Trinza (paliperidone palmitate 3-monthly) PI, Janssen. DailyMed.',
    paraphrase:
        'PP3M only after 4+ months of stable PP1M dosing; convert at 3.5× the last PP1M dose.',
  ),
  'abilify_maintena_pi': _C(
    source: CitationSource.manufacturer,
    reference: 'Abilify Maintena (aripiprazole) PI, Otsuka. DailyMed.',
    paraphrase:
        'Maintena initiation: 400 mg gluteal/deltoid + 14 days oral aripiprazole 10–20 mg overlap.',
  ),

  // ── Ashton ──
  'ashton_manual': _C(
    source: CitationSource.ashton,
    reference:
        'Ashton CH. Benzodiazepines: How They Work and How to Withdraw. Newcastle, 2002.',
    paraphrase:
        'Benzodiazepine taper: switch to diazepam-equivalent dose, then reduce by 1–2 mg diazepam every 1–2 weeks.',
  ),
};

// ── Pattern-based defaults ────────────────────────────────────────────

class _PatternResolved {
  const _PatternResolved(this.source, this.reference);
  final CitationSource source;
  final String reference;
}

_PatternResolved _resolvePattern(String key) {
  if (key.startsWith('maudsley15_')) {
    return const _PatternResolved(CitationSource.maudsley15, _maudsley15Ref);
  }
  if (key.startsWith('bap2020_')) {
    return const _PatternResolved(
        CitationSource.bap, 'BAP 2020 — Psychosis treatment guidelines.');
  }
  if (key.startsWith('bap2015_')) {
    return const _PatternResolved(
        CitationSource.bap, 'BAP 2015 — Antidepressant treatment guidelines.');
  }
  if (key.startsWith('bap2016_')) {
    return const _PatternResolved(
        CitationSource.bap, 'BAP 2016 — Bipolar treatment guidelines.');
  }
  if (key.startsWith('nice')) {
    return const _PatternResolved(CitationSource.nice,
        'NICE — National Institute for Health and Care Excellence guideline.');
  }
  if (key.startsWith('cpg')) {
    return const _PatternResolved(
        CitationSource.cpgMy, 'Malaysian CPG — Ministry of Health.');
  }
  if (key.startsWith('leucht')) {
    return const _PatternResolved(
        CitationSource.metaAnalysis, 'Leucht et al. — meta-analysis.');
  }
  if (key.startsWith('cipriani')) {
    return const _PatternResolved(CitationSource.metaAnalysis,
        'Cipriani et al. — antidepressant network meta-analysis.');
  }
  if (key.startsWith('hayasaka')) {
    return const _PatternResolved(CitationSource.metaAnalysis,
        'Hayasaka et al. — antidepressant dose equivalents.');
  }
  if (key.startsWith('horowitz')) {
    return const _PatternResolved(
        CitationSource.horowitz, 'Horowitz & Taylor — hyperbolic tapering.');
  }
  if (key.startsWith('ashton')) {
    return const _PatternResolved(
        CitationSource.ashton, 'Ashton manual — benzodiazepine withdrawal.');
  }
  if (key.startsWith('invega') ||
      key.startsWith('abilify') ||
      key.startsWith('sustenna') ||
      key.startsWith('maintena') ||
      key.startsWith('trinza') ||
      key.startsWith('janssen') ||
      key.startsWith('otsuka')) {
    return const _PatternResolved(CitationSource.manufacturer,
        'Manufacturer prescribing information (FDA / EMA / DailyMed).');
  }
  if (key.startsWith('fda') || key.startsWith('ema')) {
    return const _PatternResolved(
        CitationSource.fda, 'FDA / EMA prescribing information.');
  }
  if (key.startsWith('stahl')) {
    return const _PatternResolved(
        CitationSource.expert, 'Stahl SM. Essential Psychopharmacology.');
  }
  return _PatternResolved(CitationSource.other, 'Reference: $key');
}

// ── Public API ────────────────────────────────────────────────────────

CitationEntry getCitation(String key) {
  final curated = _curated[key];
  if (curated != null) {
    return CitationEntry(
      key: key,
      source: curated.source,
      reference: curated.reference,
      locator: curated.locator,
      paraphrase: curated.paraphrase,
    );
  }
  final p = _resolvePattern(key);
  final loc = _humanizeKey(key);
  return CitationEntry(
    key: key,
    source: p.source,
    reference: p.reference,
    locator: loc,
  );
}

String _humanizeKey(String key) {
  // e.g. "maudsley15_ch3_p369_table_3_7" → "Ch3 · p369 · table 3 7"
  final segments = key.split('_').skip(1).toList();
  final parts = <String>[];
  final collecting = <String>[];
  final chPattern = RegExp(r'^ch\d+$', caseSensitive: false);
  final pPattern = RegExp(r'^p\d+$', caseSensitive: false);
  for (final s in segments) {
    if (chPattern.hasMatch(s) || pPattern.hasMatch(s)) {
      if (collecting.isNotEmpty) {
        parts.add(collecting.join(' '));
        collecting.clear();
      }
      parts.add(s.substring(0, 1).toUpperCase() + s.substring(1));
    } else {
      collecting.add(s);
    }
  }
  if (collecting.isNotEmpty) parts.add(collecting.join(' '));
  return parts.join(' · ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

// ── Evidence grading ──────────────────────────────────────────────────

const Map<CitationSource, EvidenceGrade> _sourceGrade =
    <CitationSource, EvidenceGrade>{
  CitationSource.maudsley15: EvidenceGrade.a,
  CitationSource.bap: EvidenceGrade.a,
  CitationSource.nice: EvidenceGrade.a,
  CitationSource.fda: EvidenceGrade.a,
  CitationSource.ema: EvidenceGrade.a,
  CitationSource.cpgMy: EvidenceGrade.a,
  CitationSource.metaAnalysis: EvidenceGrade.a,
  CitationSource.manufacturer: EvidenceGrade.a, // PI is regulatory text
  CitationSource.horowitz: EvidenceGrade.b,
  CitationSource.ashton: EvidenceGrade.b,
  CitationSource.expert: EvidenceGrade.c,
  CitationSource.other: EvidenceGrade.d,
};

int _gradeRank(EvidenceGrade g) => switch (g) {
      EvidenceGrade.d => 0,
      EvidenceGrade.c => 1,
      EvidenceGrade.b => 2,
      EvidenceGrade.a => 3,
    };

/// Returns the strongest grade across the citation list.
/// Empty list → 'D' (unreviewed).
EvidenceGrade gradeCitations(List<String> keys) {
  if (keys.isEmpty) return EvidenceGrade.d;
  var best = EvidenceGrade.d;
  for (final k in keys) {
    final g = _sourceGrade[getCitation(k).source]!;
    if (_gradeRank(g) > _gradeRank(best)) best = g;
  }
  return best;
}

String gradeLabel(EvidenceGrade g) => switch (g) {
      EvidenceGrade.a => 'Direct guideline',
      EvidenceGrade.b => 'Strong derived',
      EvidenceGrade.c => 'Expert consensus',
      EvidenceGrade.d => 'Limited evidence',
    };

String gradeDescription(EvidenceGrade g) => switch (g) {
      EvidenceGrade.a =>
        'Directly cited in a major guideline (Maudsley, BAP, NICE), regulatory PI, or IPD meta-analysis.',
      EvidenceGrade.b =>
        'Derived from drug-class profiles + standard-of-care extrapolation (e.g. Horowitz hyperbolic taper).',
      EvidenceGrade.c =>
        'Expert consensus or narrative review — no direct guideline source for this exact pair.',
      EvidenceGrade.d =>
        'Limited evidence — case series or extrapolation only. Apply extra individual judgement.',
    };
