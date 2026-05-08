// Clinical jargon glossary — short explanations for terms that
// non-psychiatrists (or trainees, or visiting GPs) might not recognise.
//
// Used by the Glossary tooltip component. Keep entries terse — they're
// read in 3 seconds at the bedside, not studied.

export interface GlossaryEntry {
  /** Lowercased lookup key. */
  term: string;
  /** Patient/clinician-readable expansion or definition. */
  definition: string;
  /** Optional clinical relevance hint. */
  relevance?: string;
}

const ENTRIES: GlossaryEntry[] = [
  {
    term: 'esrs',
    definition: 'Extrapyramidal Symptom Rating Scale — clinical tool for grading parkinsonism, dystonia, and dyskinesia.',
    relevance: 'A score >6 is clinically significant.',
  },
  {
    term: 'eps',
    definition: 'Extrapyramidal symptoms — parkinsonism, dystonia, akathisia, and tardive dyskinesia.',
    relevance: 'Common with high-potency D2 antagonists (haloperidol, risperidone).',
  },
  {
    term: 'akathisia',
    definition: 'Subjective restlessness with an inability to sit still. Most often dose-dependent.',
    relevance: 'Treat with propranolol 20–80 mg or mirtazapine 15 mg.',
  },
  {
    term: 'qtc',
    definition: 'Heart-rate-corrected QT interval on ECG.',
    relevance: 'Stop QT-prolonging drugs if QTc >500 ms or rises >60 ms from baseline.',
  },
  {
    term: 'cpz-eq',
    definition: 'Chlorpromazine equivalent dose — antipsychotic dose normalised to the reference of CPZ 100 mg.',
    relevance: 'Useful for orienting cumulative load and cross-titrations.',
  },
  {
    term: 'flx-eq',
    definition: 'Fluoxetine equivalent dose — antidepressant dose normalised to fluoxetine 40 mg.',
  },
  {
    term: 'dzp-eq',
    definition: 'Diazepam equivalent dose — benzodiazepine dose normalised to diazepam 10 mg.',
    relevance: 'Standard for benzodiazepine tapers via the Ashton method.',
  },
  {
    term: 'lai',
    definition: 'Long-acting injectable. A depot antipsychotic given every 2–12 weeks.',
    relevance: 'Use for relapse prevention or when adherence is the limiting factor.',
  },
  {
    term: 'pp1m',
    definition: 'Paliperidone palmitate, monthly (Invega Sustenna).',
  },
  {
    term: 'pp3m',
    definition: 'Paliperidone palmitate, 3-monthly (Invega Trinza). Only after 4+ months stable on PP1M.',
  },
  {
    term: 'maoi',
    definition: 'Monoamine oxidase inhibitor — phenelzine, tranylcypromine, moclobemide.',
    relevance: 'Requires a 14-day washout before/after another serotonergic agent (5 weeks from fluoxetine).',
  },
  {
    term: 'snri',
    definition: 'Serotonin–noradrenaline reuptake inhibitor — venlafaxine, desvenlafaxine, duloxetine.',
  },
  {
    term: 'ssri',
    definition: 'Selective serotonin reuptake inhibitor.',
  },
  {
    term: 'cyp2d6',
    definition: 'Cytochrome P450 2D6 — major drug-metabolising enzyme.',
    relevance: 'Strong inhibitors (fluoxetine, paroxetine, bupropion) raise levels of risperidone and aripiprazole.',
  },
  {
    term: 'cyp1a2',
    definition: 'Cytochrome P450 1A2 — major metaboliser of clozapine and olanzapine.',
    relevance: 'Smoking induces CYP1A2 → 50% lower levels. Levels rise sharply if smoking stops.',
  },
  {
    term: 'cyp3a4',
    definition: 'Cytochrome P450 3A4 — major drug-metabolising enzyme.',
    relevance: 'Inhibition raises levels of quetiapine, aripiprazole, lurasidone.',
  },
  {
    term: 'serotonin syndrome',
    definition: 'Cognitive (agitation, confusion) + autonomic (tachycardia, hyperthermia) + neuromuscular (clonus, hyperreflexia) triad from serotonergic excess.',
    relevance: 'Most often during cross-tapers of two serotonergic agents, or MAOI overlaps.',
  },
  {
    term: 'fbc',
    definition: 'Full blood count.',
    relevance: 'Weekly during clozapine weeks 1–18; stop if ANC <1.5.',
  },
  {
    term: 'anc',
    definition: 'Absolute neutrophil count. Calculated as WBC × neutrophil %.',
    relevance: 'ANC ≥2.0 required to start clozapine; <1.5 → stop and consult.',
  },
  {
    term: 'tfts',
    definition: 'Thyroid function tests — TSH ± fT4.',
    relevance: 'Baseline + 6-monthly on lithium (hypothyroidism risk).',
  },
  {
    term: 'u&e',
    definition: 'Urea and electrolytes — baseline renal panel.',
  },
  {
    term: 'lft',
    definition: 'Liver function tests.',
    relevance: 'Baseline before valproate, carbamazepine, agomelatine.',
  },
  {
    term: 'egfr',
    definition: 'Estimated glomerular filtration rate — renal function indicator.',
    relevance: '<60 reduces clearance of amisulpride, paliperidone, lithium.',
  },
];

const INDEX = new Map<string, GlossaryEntry>(ENTRIES.map((e) => [e.term, e]));

export function lookupTerm(term: string): GlossaryEntry | null {
  return INDEX.get(term.toLowerCase().trim()) ?? null;
}

export function listGlossary(): GlossaryEntry[] {
  return [...ENTRIES].sort((a, b) => a.term.localeCompare(b.term));
}
