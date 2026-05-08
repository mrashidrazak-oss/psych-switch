// Citation registry + evidence grading.
//
// Two responsibilities:
//   1. Resolve a citation key → human-readable reference (with optional
//      paraphrase / page) for the "show your work" UI.
//   2. Derive an evidence grade (A / B / C / D) for an entire rule based
//      on the strongest citation it carries.
//
// Grading scale (chosen to match how clinicians actually weigh sources):
//
//   A — Direct guideline / regulatory:
//        Maudsley 15th, BAP 2020, NICE, FDA/EMA prescribing info, MoH CPGs,
//        major IPD meta-analyses (Leucht 2013/2016, Cipriani 2018, Hayasaka 2015).
//   B — Strong derived:
//        Drug-class profiles + standard-of-care extrapolation; Horowitz &
//        Taylor 2019 (hyperbolic taper); Ashton manual.
//   C — Expert consensus:
//        Editorial consensus, single-author chapters, narrative reviews.
//   D — Limited evidence:
//        Case series, expert opinion, or no published source — clearly
//        flagged so the clinician knows it's a "best guess".
//
// IMPORTANT: grading describes the EVIDENCE for a rule, not the rule's
// safety. A "B" rule isn't unsafe — it just means the schedule is
// extrapolated from drug profiles rather than copied verbatim from a
// guideline. The clinician should treat A and B as equally usable; C and
// D require more individual judgement.

export type EvidenceGrade = 'A' | 'B' | 'C' | 'D';

export type CitationSource =
  | 'Maudsley15'
  | 'BAP'
  | 'NICE'
  | 'FDA'
  | 'EMA'
  | 'CPG-MY'
  | 'meta-analysis'
  | 'Ashton'
  | 'Horowitz'
  | 'manufacturer'
  | 'expert'
  | 'other';

export interface CitationEntry {
  key: string;
  source: CitationSource;
  /** Full bibliographic reference. */
  reference: string;
  /** Page / table / chapter pointer when known. */
  locator?: string;
  /** Short paraphrased line — what the source actually says. */
  paraphrase?: string;
  /** Public URL / DOI when available. */
  url?: string;
}

// ── Curated entries ──────────────────────────────────────────────────────────
// Hand-written for the most-cited keys. Anything not listed here falls back
// to the pattern-based resolver below — still grades correctly, just shows a
// generic reference.

const CURATED: Record<string, Omit<CitationEntry, 'key'>> = {
  // ── Maudsley 15th ──
  'maudsley15_ch3_p369_table_3_7': {
    source: 'Maudsley15',
    reference: 'Taylor D, Barnes TRE, Young AH. Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 3, p.369, Table 3.7',
    paraphrase: 'Cross-tapering antidepressants: matrix of recommended strategies (direct, cross-taper cautiously, taper-then-wait, halve-and-add).',
  },
  'maudsley15_ch3_p374_withdrawal': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 3, p.374',
    paraphrase: 'Antidepressant discontinuation symptoms: hyperbolic tapering reduces severity and duration; bridge venlafaxine/paroxetine to fluoxetine for severe cases.',
  },
  'maudsley15_ch3_snri_profile': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 3 — SNRI class profile',
    paraphrase: 'SNRIs (venlafaxine, desvenlafaxine, duloxetine): NA reuptake activity at higher doses; high discontinuation risk with venlafaxine.',
  },
  'maudsley15_ch3_vortioxetine_profile': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 3 — Vortioxetine profile',
    paraphrase: 'Vortioxetine: multimodal serotonergic. CYP2D6 substrate — halve dose with strong inhibitors.',
  },
  'maudsley15_serotonin_syndrome': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 3 — Serotonin syndrome',
    paraphrase: 'Serotonin syndrome triad: cognitive (agitation, confusion), autonomic (tachycardia, hyperthermia, diaphoresis), neuromuscular (clonus, hyperreflexia).',
  },
  'maudsley15_maoi_washout': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 3 — MAOI washout',
    paraphrase: 'MAOI washout: 14 days off irreversible MAOIs before another serotonergic agent; 5 weeks from fluoxetine before MAOI (long t½ of norfluoxetine).',
  },
  'maudsley15_cyp_table': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 1 — CYP interactions table',
    paraphrase: 'Strong CYP2D6 inhibitors (fluoxetine, paroxetine, bupropion) raise substrate levels — halve dose of risperidone, aripiprazole during overlap.',
  },
  'maudsley15_aps_metabolic': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 4 — Antipsychotic metabolic monitoring',
    paraphrase: 'Antipsychotic metabolic monitoring: BMI + waist + lipids + HbA1c at baseline, 3 months, then yearly.',
  },
  'maudsley15_aps_qtc': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 4 — Antipsychotic QTc',
    paraphrase: 'Highest-risk QTc: haloperidol (esp. IV), pimozide, sertindole. Moderate: amisulpride, sulpiride. Lowest: aripiprazole, lurasidone.',
  },
  'maudsley15_qtc': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 4 — QTc and antipsychotics',
    paraphrase: 'Stop QT-prolonger if QTc >500 ms or rises >60 ms from baseline. Correct K+/Mg2+. Switch to lower-risk agent.',
  },
  'maudsley15_clozapine_monitoring': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 4 — Clozapine monitoring',
    paraphrase: 'Clozapine FBC: weekly weeks 1–18, fortnightly weeks 19–52, monthly thereafter. Stop if ANC <1.5.',
  },
  'maudsley15_clozapine_stopping': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 4 — Stopping clozapine',
    paraphrase: 'Severe rebound psychosis within 48–72 h of abrupt clozapine discontinuation. Cross-taper over ≥4 weeks unless agranulocytosis.',
  },
  'maudsley15_mood_lithium_monitoring': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 5 — Lithium monitoring',
    paraphrase: 'Lithium: U&E + TFT + Ca at baseline, level 5–7 d after each dose change, then 3-monthly. 6-monthly U&E + TFT.',
  },
  'maudsley15_lithium_stopping': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 5 — Stopping lithium',
    paraphrase: 'Rebound mania risk after abrupt lithium discontinuation. Taper over ≥3 months unless toxicity.',
  },
  'maudsley15_lithium_tox': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 5 — Lithium toxicity',
    paraphrase: 'Lithium toxicity: tremor, GI, ataxia, dysarthria, eventually seizures. Levels >1.5 mmol/L = clinical concern.',
  },
  'maudsley15_mood_valproate': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 5 — Valproate',
    paraphrase: 'Valproate: hepatotoxicity + thrombocytopenia. Baseline LFT + FBC + βHCG. 30–40% major malformation rate in pregnancy.',
  },
  'maudsley15_mood_carbamazepine': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 5 — Carbamazepine',
    paraphrase: 'Carbamazepine: agranulocytosis + hepatitis + SIADH. Auto-induces CYP3A4 — level rechecked at week 4.',
  },
  'maudsley15_valproate_pregnancy': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 5 — Valproate in pregnancy',
    paraphrase: 'Valproate contraindicated in pregnancy and women of reproductive age unless PPP. Lamotrigine is preferred bipolar maintenance in pregnancy.',
  },
  'maudsley15_eps_management': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 4 — EPS management',
    paraphrase: 'Akathisia: propranolol 20–80 mg or mirtazapine 15 mg. Parkinsonism: dose reduction or anticholinergic. Tardive: switch to clozapine.',
  },
  'maudsley15_prolactin': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 4 — Hyperprolactinaemia',
    paraphrase: 'Aripiprazole 5–15 mg adjunct often normalises prolactin without need to switch.',
  },
  'maudsley15_sedation': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 4 — Antipsychotic sedation',
    paraphrase: 'Most sedating: olanzapine, quetiapine, clozapine, chlorpromazine. Least: aripiprazole, lurasidone.',
  },
  'maudsley15_sexual_ad': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 3 — AD sexual dysfunction',
    paraphrase: 'Lowest sexual dysfunction: mirtazapine, agomelatine, vortioxetine. Highest: paroxetine.',
  },
  'maudsley15_discontinuation': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 3 — Discontinuation',
    paraphrase: 'Severe discontinuation: paroxetine, venlafaxine. Bridge to fluoxetine 20 mg for 1–2 weeks then taper fluoxetine.',
  },
  'maudsley15_discontinuation_paroxetine': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 3 — Paroxetine discontinuation',
    paraphrase: 'Paroxetine: dizziness, electric-shock sensations, irritability within 1–3 days of stopping. Hyperbolic taper or fluoxetine bridge.',
  },
  'maudsley15_discontinuation_venlafaxine': {
    source: 'Maudsley15',
    reference: 'Maudsley Prescribing Guidelines, 15th ed.',
    locator: 'Ch. 3 — Venlafaxine discontinuation',
    paraphrase: 'Venlafaxine missed-dose syndrome: severe within 12–24 h. Switch to fluoxetine 20 mg before stopping.',
  },

  // ── BAP ──
  'bap2020_psychosis': {
    source: 'BAP',
    reference: 'Barnes TRE et al. Evidence-based guidelines for the pharmacological treatment of psychosis. J Psychopharmacol 2020;34(1):3–78.',
    paraphrase: 'BAP 2020: antipsychotic choice driven by tolerability profile + patient preference; metabolic side effects most often determine adherence.',
  },
  'bap2020_psychosis_switching': {
    source: 'BAP',
    reference: 'BAP 2020 — Psychosis switching',
    paraphrase: 'Plateau cross-taper recommended when switching from an antagonist to a partial agonist (aripiprazole) to mitigate early loss of efficacy.',
  },
  'bap2020_psychosis_lai': {
    source: 'BAP',
    reference: 'BAP 2020 — LAI in psychosis',
    paraphrase: 'LAI antipsychotics for relapse prevention; oral overlap during initiation per individual product PI.',
  },
  'bap2015_switching_antidepressants': {
    source: 'BAP',
    reference: 'Cleare A et al. BAP guidelines for the pharmacological treatment of depression. J Psychopharmacol 2015.',
    paraphrase: 'Cross-titration over 1–4 weeks for most AD switches; longer with paroxetine/venlafaxine due to discontinuation risk.',
  },
  'bap2015_evidence_antidepressants': {
    source: 'BAP',
    reference: 'BAP 2015 — Evidence base for AD switching',
    paraphrase: 'Strongest evidence for switching: SSRI → mirtazapine (mechanistic complementarity), SSRI → vortioxetine (multimodal).',
  },

  // ── NICE ──
  'nice_ng178': {
    source: 'NICE',
    reference: 'NICE NG178 (2014, updated 2020). Psychosis and schizophrenia in adults.',
  },
  'nice_ng222': {
    source: 'NICE',
    reference: 'NICE NG222 (2022). Depression in adults.',
  },

  // ── Meta-analyses / IPD ──
  'leucht2013_lancet_metaanalysis': {
    source: 'meta-analysis',
    reference: 'Leucht S et al. Comparative efficacy and tolerability of 15 antipsychotic drugs in schizophrenia. Lancet 2013;382:951–62.',
    paraphrase: '15-drug network meta-analysis: clozapine > olanzapine ≈ amisulpride > others for efficacy; clozapine + olanzapine highest weight gain.',
  },
  'leucht2016_ddd_schizophrenia_bulletin': {
    source: 'meta-analysis',
    reference: 'Leucht S et al. Dose equivalents for antipsychotics: DDD method. Schizophr Bull 2016;42(suppl 1):S90–S94.',
    paraphrase: 'CPZ-equivalence by defined daily dose (DDD): 100 mg CPZ = 2 mg haloperidol = 5 mg olanzapine = 7.5 mg aripiprazole.',
  },
  'cipriani2018_lancet_metaanalysis': {
    source: 'meta-analysis',
    reference: 'Cipriani A et al. Comparative efficacy and acceptability of 21 antidepressants. Lancet 2018;391:1357–66.',
    paraphrase: '21-AD network meta-analysis: agomelatine, amitriptyline, escitalopram, mirtazapine, paroxetine, vortioxetine most efficacious vs placebo.',
  },
  'hayasaka2015_jad_dose_equivalents': {
    source: 'meta-analysis',
    reference: 'Hayasaka Y et al. Dose equivalents of antidepressants. J Affect Disord 2015;180:179–84.',
    paraphrase: 'Fluoxetine 40 mg ≈ paroxetine 25 mg ≈ sertraline 100 mg ≈ escitalopram 18 mg ≈ venlafaxine 150 mg.',
  },
  'horowitz2020_hyperbolic_tapering': {
    source: 'Horowitz',
    reference: 'Horowitz MA, Taylor D. Tapering of SSRI treatment to mitigate withdrawal symptoms. Lancet Psychiatry 2019;6(6):538–46.',
    paraphrase: 'Hyperbolic tapering: small dose reductions at low doses (where receptor occupancy curve is steep) reduces withdrawal severity.',
  },

  // ── Manufacturer / regulatory ──
  'invega_sustenna_pi': {
    source: 'manufacturer',
    reference: 'Invega Sustenna (paliperidone palmitate) PI, Janssen. DailyMed.',
    paraphrase: 'PP1M initiation: 234 mg D1, 156 mg D8 (deltoid), then 117 mg monthly (deltoid or gluteal).',
  },
  'invega_trinza_pi': {
    source: 'manufacturer',
    reference: 'Invega Trinza (paliperidone palmitate 3-monthly) PI, Janssen. DailyMed.',
    paraphrase: 'PP3M only after 4+ months of stable PP1M dosing; convert at 3.5× the last PP1M dose.',
  },
  'abilify_maintena_pi': {
    source: 'manufacturer',
    reference: 'Abilify Maintena (aripiprazole) PI, Otsuka. DailyMed.',
    paraphrase: 'Maintena initiation: 400 mg gluteal/deltoid + 14 days oral aripiprazole 10–20 mg overlap.',
  },

  // ── Ashton ──
  'ashton_manual': {
    source: 'Ashton',
    reference: 'Ashton CH. Benzodiazepines: How They Work and How to Withdraw. Newcastle, 2002.',
    paraphrase: 'Benzodiazepine taper: switch to diazepam-equivalent dose, then reduce by 1–2 mg diazepam every 1–2 weeks.',
  },
};

// ── Pattern-based defaults ───────────────────────────────────────────────────

interface PatternResolved {
  source: CitationSource;
  /** Generic reference template — used when no curated entry exists. */
  reference: string;
}

function resolvePattern(key: string): PatternResolved {
  if (key.startsWith('maudsley15_')) return { source: 'Maudsley15', reference: 'Maudsley Prescribing Guidelines, 15th ed.' };
  if (key.startsWith('bap2020_'))    return { source: 'BAP',        reference: 'BAP 2020 — Psychosis treatment guidelines.' };
  if (key.startsWith('bap2015_'))    return { source: 'BAP',        reference: 'BAP 2015 — Antidepressant treatment guidelines.' };
  if (key.startsWith('bap2016_'))    return { source: 'BAP',        reference: 'BAP 2016 — Bipolar treatment guidelines.' };
  if (key.startsWith('nice'))        return { source: 'NICE',       reference: 'NICE — National Institute for Health and Care Excellence guideline.' };
  if (key.startsWith('cpg'))         return { source: 'CPG-MY',     reference: 'Malaysian CPG — Ministry of Health.' };
  if (key.startsWith('leucht'))      return { source: 'meta-analysis', reference: 'Leucht et al. — meta-analysis.' };
  if (key.startsWith('cipriani'))    return { source: 'meta-analysis', reference: 'Cipriani et al. — antidepressant network meta-analysis.' };
  if (key.startsWith('hayasaka'))    return { source: 'meta-analysis', reference: 'Hayasaka et al. — antidepressant dose equivalents.' };
  if (key.startsWith('horowitz'))    return { source: 'Horowitz',   reference: 'Horowitz & Taylor — hyperbolic tapering.' };
  if (key.startsWith('ashton'))      return { source: 'Ashton',     reference: 'Ashton manual — benzodiazepine withdrawal.' };
  if (key.startsWith('invega') || key.startsWith('abilify') || key.startsWith('sustenna') || key.startsWith('maintena') || key.startsWith('trinza') || key.startsWith('janssen') || key.startsWith('otsuka')) {
    return { source: 'manufacturer', reference: 'Manufacturer prescribing information (FDA / EMA / DailyMed).' };
  }
  if (key.startsWith('fda') || key.startsWith('ema'))  return { source: 'FDA', reference: 'FDA / EMA prescribing information.' };
  if (key.startsWith('stahl'))       return { source: 'expert',     reference: 'Stahl SM. Essential Psychopharmacology.' };
  return { source: 'other', reference: 'Reference: ' + key };
}

// ── Public API ───────────────────────────────────────────────────────────────

export function getCitation(key: string): CitationEntry {
  const curated = CURATED[key];
  if (curated) return { key, ...curated };
  const p = resolvePattern(key);
  // Light cleanup of the locator hint when we can extract one from the key.
  const locator = humanizeKey(key);
  return { key, source: p.source, reference: p.reference, locator };
}

function humanizeKey(key: string): string {
  // e.g. "maudsley15_ch3_p369_table_3_7" → "Ch.3 p.369 — table 3 7"
  const segments = key.split('_').slice(1); // drop the source-tag prefix
  const parts: string[] = [];
  let collecting: string[] = [];
  for (const s of segments) {
    if (/^ch\d+$/i.test(s) || /^p\d+$/i.test(s)) {
      if (collecting.length) { parts.push(collecting.join(' ')); collecting = []; }
      parts.push(s.charAt(0).toUpperCase() + s.slice(1) + (s.startsWith('p') ? '' : ''));
    } else {
      collecting.push(s);
    }
  }
  if (collecting.length) parts.push(collecting.join(' '));
  return parts.join(' · ').replace(/\s+/g, ' ').trim();
}

// ── Evidence grading ─────────────────────────────────────────────────────────

const SOURCE_GRADE: Record<CitationSource, EvidenceGrade> = {
  'Maudsley15':     'A',
  'BAP':            'A',
  'NICE':           'A',
  'FDA':            'A',
  'EMA':            'A',
  'CPG-MY':         'A',
  'meta-analysis':  'A',
  'manufacturer':   'A', // PI is regulatory text — A
  'Horowitz':       'B',
  'Ashton':         'B',
  'expert':         'C',
  'other':          'D',
};

/**
 * Grade a list of citation keys by taking the strongest source represented.
 * Returns 'D' if the list is empty (i.e. an "unreviewed" rule).
 */
export function gradeCitations(keys: string[]): EvidenceGrade {
  if (keys.length === 0) return 'D';
  let best: EvidenceGrade = 'D';
  for (const k of keys) {
    const g = SOURCE_GRADE[getCitation(k).source];
    if (gradeRank(g) > gradeRank(best)) best = g;
  }
  return best;
}

function gradeRank(g: EvidenceGrade): number {
  return { D: 0, C: 1, B: 2, A: 3 }[g];
}

export function gradeColor(g: EvidenceGrade): {
  bg: string;
  border: string;
  text: string;
} {
  switch (g) {
    case 'A': return { bg: 'bg-to/15',      border: 'border-to/40',      text: 'text-to' };
    case 'B': return { bg: 'bg-accent/15',  border: 'border-accent/40',  text: 'text-accent' };
    case 'C': return { bg: 'bg-warning/15', border: 'border-warning/40', text: 'text-warning' };
    case 'D': return { bg: 'bg-danger/15',  border: 'border-danger/40',  text: 'text-danger' };
  }
}

export function gradeLabel(g: EvidenceGrade): string {
  switch (g) {
    case 'A': return 'Direct guideline';
    case 'B': return 'Strong derived';
    case 'C': return 'Expert consensus';
    case 'D': return 'Limited evidence';
  }
}

export function gradeDescription(g: EvidenceGrade): string {
  switch (g) {
    case 'A': return 'Directly cited in a major guideline (Maudsley, BAP, NICE), regulatory PI, or IPD meta-analysis.';
    case 'B': return 'Derived from drug-class profiles + standard-of-care extrapolation (e.g. Horowitz hyperbolic taper).';
    case 'C': return 'Expert consensus or narrative review — no direct guideline source for this exact pair.';
    case 'D': return 'Limited evidence — case series or extrapolation only. Apply extra individual judgement.';
  }
}
