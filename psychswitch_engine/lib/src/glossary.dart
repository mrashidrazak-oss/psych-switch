// Clinical jargon glossary — short explanations for terms that
// non-psychiatrists (or trainees, or visiting GPs) might not recognise.
//
// Used by the Glossary tooltip component. Keep entries terse — they're
// read in 3 seconds at the bedside, not studied.
//
// Dart port of engine/glossary.ts. Entries are byte-equivalent to the
// TypeScript registry; lookup semantics (case-insensitive, trimmed)
// match exactly.

/// A single glossary record.
class GlossaryEntry {
  const GlossaryEntry({
    required this.term,
    required this.definition,
    this.relevance,
  });

  /// Lowercased lookup key.
  final String term;

  /// Patient/clinician-readable expansion or definition.
  final String definition;

  /// Optional clinical relevance hint.
  final String? relevance;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'term': term,
        'definition': definition,
        if (relevance != null) 'relevance': relevance,
      };
}

const List<GlossaryEntry> _entries = <GlossaryEntry>[
  GlossaryEntry(
    term: 'esrs',
    definition:
        'Extrapyramidal Symptom Rating Scale — clinical tool for grading parkinsonism, dystonia, and dyskinesia.',
    relevance: 'A score >6 is clinically significant.',
  ),
  GlossaryEntry(
    term: 'eps',
    definition:
        'Extrapyramidal symptoms — parkinsonism, dystonia, akathisia, and tardive dyskinesia.',
    relevance:
        'Common with high-potency D2 antagonists (haloperidol, risperidone).',
  ),
  GlossaryEntry(
    term: 'akathisia',
    definition:
        'Subjective restlessness with an inability to sit still. Most often dose-dependent.',
    relevance: 'Treat with propranolol 20–80 mg or mirtazapine 15 mg.',
  ),
  GlossaryEntry(
    term: 'qtc',
    definition: 'Heart-rate-corrected QT interval on ECG.',
    relevance:
        'Stop QT-prolonging drugs if QTc >500 ms or rises >60 ms from baseline.',
  ),
  GlossaryEntry(
    term: 'cpz-eq',
    definition:
        'Chlorpromazine equivalent dose — antipsychotic dose normalised to the reference of CPZ 100 mg.',
    relevance: 'Useful for orienting cumulative load and cross-titrations.',
  ),
  GlossaryEntry(
    term: 'flx-eq',
    definition:
        'Fluoxetine equivalent dose — antidepressant dose normalised to fluoxetine 40 mg.',
  ),
  GlossaryEntry(
    term: 'dzp-eq',
    definition:
        'Diazepam equivalent dose — benzodiazepine dose normalised to diazepam 10 mg.',
    relevance: 'Standard for benzodiazepine tapers via the Ashton method.',
  ),
  GlossaryEntry(
    term: 'lai',
    definition:
        'Long-acting injectable. A depot antipsychotic given every 2–12 weeks.',
    relevance:
        'Use for relapse prevention or when adherence is the limiting factor.',
  ),
  GlossaryEntry(
    term: 'pp1m',
    definition: 'Paliperidone palmitate, monthly (Invega Sustenna).',
  ),
  GlossaryEntry(
    term: 'pp3m',
    definition:
        'Paliperidone palmitate, 3-monthly (Invega Trinza). Only after 4+ months stable on PP1M.',
  ),
  GlossaryEntry(
    term: 'maoi',
    definition:
        'Monoamine oxidase inhibitor — phenelzine, tranylcypromine, moclobemide.',
    relevance:
        'Requires a 14-day washout before/after another serotonergic agent (5 weeks from fluoxetine).',
  ),
  GlossaryEntry(
    term: 'snri',
    definition:
        'Serotonin–noradrenaline reuptake inhibitor — venlafaxine, desvenlafaxine, duloxetine.',
  ),
  GlossaryEntry(
    term: 'ssri',
    definition: 'Selective serotonin reuptake inhibitor.',
  ),
  GlossaryEntry(
    term: 'cyp2d6',
    definition: 'Cytochrome P450 2D6 — major drug-metabolising enzyme.',
    relevance:
        'Strong inhibitors (fluoxetine, paroxetine, bupropion) raise levels of risperidone and aripiprazole.',
  ),
  GlossaryEntry(
    term: 'cyp1a2',
    definition:
        'Cytochrome P450 1A2 — major metaboliser of clozapine and olanzapine.',
    relevance:
        'Smoking induces CYP1A2 → 50% lower levels. Levels rise sharply if smoking stops.',
  ),
  GlossaryEntry(
    term: 'cyp3a4',
    definition: 'Cytochrome P450 3A4 — major drug-metabolising enzyme.',
    relevance:
        'Inhibition raises levels of quetiapine, aripiprazole, lurasidone.',
  ),
  GlossaryEntry(
    term: 'serotonin syndrome',
    definition:
        'Cognitive (agitation, confusion) + autonomic (tachycardia, hyperthermia) + neuromuscular (clonus, hyperreflexia) triad from serotonergic excess.',
    relevance:
        'Most often during cross-tapers of two serotonergic agents, or MAOI overlaps.',
  ),
  GlossaryEntry(
    term: 'fbc',
    definition: 'Full blood count.',
    relevance: 'Weekly during clozapine weeks 1–18; stop if ANC <1.5.',
  ),
  GlossaryEntry(
    term: 'anc',
    definition:
        'Absolute neutrophil count. Calculated as WBC × neutrophil %.',
    relevance:
        'ANC ≥2.0 required to start clozapine; <1.5 → stop and consult.',
  ),
  GlossaryEntry(
    term: 'tfts',
    definition: 'Thyroid function tests — TSH ± fT4.',
    relevance: 'Baseline + 6-monthly on lithium (hypothyroidism risk).',
  ),
  GlossaryEntry(
    term: 'u&e',
    definition: 'Urea and electrolytes — baseline renal panel.',
  ),
  GlossaryEntry(
    term: 'lft',
    definition: 'Liver function tests.',
    relevance: 'Baseline before valproate, carbamazepine, agomelatine.',
  ),
  GlossaryEntry(
    term: 'egfr',
    definition:
        'Estimated glomerular filtration rate — renal function indicator.',
    relevance:
        '<60 reduces clearance of amisulpride, paliperidone, lithium.',
  ),
];

final Map<String, GlossaryEntry> _index = <String, GlossaryEntry>{
  for (final e in _entries) e.term: e,
};

/// Look up a glossary term. Case-insensitive, trims whitespace.
/// Returns `null` if no entry matches.
GlossaryEntry? lookupTerm(String term) {
  return _index[term.toLowerCase().trim()];
}

/// Return all entries sorted alphabetically by term.
List<GlossaryEntry> listGlossary() {
  return List<GlossaryEntry>.from(_entries)
    ..sort((a, b) => a.term.compareTo(b.term));
}
