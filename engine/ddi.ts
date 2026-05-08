// Drug-drug interaction (DDI) checker — focused on the overlap window
// of a cross-titration. Not a general-purpose interaction database.
//
// Scope (narrow on purpose):
//   1. Serotonergic stacking      — SSRI + SSRI, SSRI + SNRI, SSRI + MAOI, etc.
//   2. CYP-mediated dose-warpers — fluoxetine/paroxetine + risperidone/aripiprazole, etc.
//   3. QTc additive               — covered by separate qtcStacker; we
//                                   re-flag here when both drugs are on the list.
//   4. Anticholinergic burden     — relevant in older adults during overlap.
//   5. Pharmacodynamic conflict   — D2 partial agonist (aripiprazole) +
//                                   D2 antagonist (risperidone) early in overlap.
//
// Source-of-truth notes
//   • Maudsley 15th, Chapter 1 (interactions) and per-drug profiles.
//   • Stockley's Drug Interactions, 12th ed.
//   • FDA / EMA labels for the specific pairs flagged.

export type DdiSeverity = 'info' | 'caution' | 'warning' | 'avoid';
export type DdiMechanism =
  | 'serotonergic'
  | 'cyp_inhibition'
  | 'cyp_induction'
  | 'qtc_additive'
  | 'anticholinergic'
  | 'pharmacodynamic'
  | 'sedation_additive'
  | 'orthostasis';

export interface DdiHit {
  pair: [string, string];
  severity: DdiSeverity;
  mechanism: DdiMechanism;
  message: string;
  /** During cross-taper, how to mitigate. */
  mitigation?: string;
  citation?: string;
}

interface DdiPattern {
  // Either explicit drug ids, or a class predicate.
  match: (a: string, b: string) => boolean;
  severity: DdiSeverity;
  mechanism: DdiMechanism;
  message: string;
  mitigation?: string;
  citation?: string;
}

const SSRIs    = new Set(['fluoxetine', 'sertraline', 'paroxetine', 'fluvoxamine', 'escitalopram']);
const SNRIs    = new Set(['venlafaxine', 'desvenlafaxine', 'duloxetine']);
const MAOIs    = new Set(['phenelzine', 'tranylcypromine', 'moclobemide']);
const CYP2D6_INHIBITORS_STRONG = new Set(['fluoxetine', 'paroxetine', 'bupropion']);
const CYP1A2_INHIBITORS_STRONG = new Set(['fluvoxamine']);
const CYP3A4_INHIBITORS_MOD    = new Set(['fluvoxamine']); // moderate
const CYP2D6_SUBSTRATES = new Set(['risperidone', 'aripiprazole', 'haloperidol', 'venlafaxine']);
const CYP1A2_SUBSTRATES = new Set(['clozapine', 'olanzapine']);
const QT_PROLONGERS_STRONG = new Set(['haloperidol', 'sulpiride', 'amisulpride']);
const QT_PROLONGERS_MOD    = new Set(['citalopram', 'escitalopram', 'chlorpromazine']);
const SEDATIVES = new Set(['mirtazapine', 'olanzapine', 'quetiapine', 'clozapine', 'chlorpromazine']);

const has = (set: Set<string>, x: string) => set.has(x);
const anyPair = (a: string, b: string, sa: Set<string>, sb: Set<string>) =>
  (has(sa, a) && has(sb, b)) || (has(sa, b) && has(sb, a));

const PATTERNS: DdiPattern[] = [
  // ── Serotonergic stacking ──
  {
    match: (a, b) => a !== b && (
      anyPair(a, b, SSRIs, SSRIs) ||
      anyPair(a, b, SSRIs, SNRIs) ||
      anyPair(a, b, SNRIs, SNRIs)
    ),
    severity: 'caution',
    mechanism: 'serotonergic',
    message: 'Two serotonergic agents — additive serotonin effect during overlap.',
    mitigation: 'Cross-taper slowly (10–14 d). Counsel for serotonin syndrome (clonus, hyperthermia, autonomic).',
    citation: 'maudsley15_serotonin_syndrome',
  },
  {
    match: (a, b) => anyPair(a, b, SSRIs, MAOIs) || anyPair(a, b, SNRIs, MAOIs),
    severity: 'avoid',
    mechanism: 'serotonergic',
    message: 'SSRI/SNRI + MAOI: contraindicated. Risk of fatal serotonin syndrome.',
    mitigation: '14-day washout from irreversible MAOI; 5-week from fluoxetine before MAOI.',
    citation: 'maudsley15_maoi_washout',
  },
  // Add mirtazapine to MAOI flag
  {
    match: (a, b) => anyPair(a, b, new Set(['mirtazapine']), MAOIs),
    severity: 'warning',
    mechanism: 'serotonergic',
    message: 'Mirtazapine + MAOI: theoretical risk; usually avoided.',
    mitigation: '14-day MAOI washout before mirtazapine.',
  },

  // ── CYP-mediated ──
  {
    match: (a, b) => anyPair(a, b, CYP2D6_INHIBITORS_STRONG, CYP2D6_SUBSTRATES),
    severity: 'warning',
    mechanism: 'cyp_inhibition',
    message: 'Strong CYP2D6 inhibitor + substrate — substrate level may double.',
    mitigation: 'Reduce substrate dose ~50% during overlap; review at 7 days.',
    citation: 'maudsley15_cyp_table',
  },
  {
    match: (a, b) => anyPair(a, b, CYP1A2_INHIBITORS_STRONG, CYP1A2_SUBSTRATES),
    severity: 'warning',
    mechanism: 'cyp_inhibition',
    message: 'Fluvoxamine + clozapine/olanzapine — substrate levels rise sharply.',
    mitigation: 'Reduce substrate dose; check trough level if combined intentionally.',
  },
  {
    match: (a, b) => anyPair(a, b, CYP3A4_INHIBITORS_MOD, new Set(['quetiapine', 'aripiprazole', 'lurasidone'])),
    severity: 'caution',
    mechanism: 'cyp_inhibition',
    message: 'Moderate CYP3A4 inhibition — substrate levels rise.',
    mitigation: 'Consider 25–50% substrate dose reduction during co-administration.',
  },

  // ── QTc additive (extends qtcStacker.ts) ──
  {
    match: (a, b) => a !== b && (
      (has(QT_PROLONGERS_STRONG, a) && has(QT_PROLONGERS_STRONG, b)) ||
      (has(QT_PROLONGERS_STRONG, a) && has(QT_PROLONGERS_MOD, b)) ||
      (has(QT_PROLONGERS_MOD, a) && has(QT_PROLONGERS_STRONG, b))
    ),
    severity: 'warning',
    mechanism: 'qtc_additive',
    message: 'Both drugs prolong QTc — additive effect during overlap.',
    mitigation: 'ECG before overlap, repeat at peak of overlap (Day 7–14). Use shortest overlap reasonable.',
    citation: 'maudsley15_qtc',
  },

  // ── Pharmacodynamic conflict ──
  {
    match: (a, b) =>
      (a === 'aripiprazole' && b === 'risperidone') ||
      (b === 'aripiprazole' && a === 'risperidone') ||
      (a === 'aripiprazole' && b === 'haloperidol') ||
      (b === 'aripiprazole' && a === 'haloperidol'),
    severity: 'caution',
    mechanism: 'pharmacodynamic',
    message: 'D2 partial agonist (aripiprazole) competing with full antagonist — early relapse risk.',
    mitigation: 'Plateau cross-taper: hold full antagonist at therapeutic dose for 2 weeks before tapering.',
  },

  // ── Sedation additive ──
  {
    match: (a, b) => a !== b && has(SEDATIVES, a) && has(SEDATIVES, b),
    severity: 'caution',
    mechanism: 'sedation_additive',
    message: 'Two sedating agents — additive somnolence during overlap.',
    mitigation: 'Counsel re: driving / falls. Consider once-daily nocte dosing of both.',
  },

  // ── Anticholinergic burden ──
  {
    match: (a, b) =>
      (a === 'chlorpromazine' && b === 'paroxetine') ||
      (b === 'chlorpromazine' && a === 'paroxetine') ||
      (a === 'olanzapine'     && b === 'paroxetine') ||
      (b === 'olanzapine'     && a === 'paroxetine'),
    severity: 'caution',
    mechanism: 'anticholinergic',
    message: 'Combined anticholinergic load — confusion / falls in older adults.',
    mitigation: 'Avoid in older adults if possible. Otherwise minimise overlap window.',
  },
];

/**
 * Check a drug pair for known overlap-window interactions.
 */
export function checkPair(a: string, b: string): DdiHit[] {
  const out: DdiHit[] = [];
  for (const p of PATTERNS) {
    if (p.match(a, b)) {
      out.push({
        pair: [a, b],
        severity: p.severity,
        mechanism: p.mechanism,
        message: p.message,
        mitigation: p.mitigation,
        citation: p.citation,
      });
    }
  }
  return out;
}

/**
 * Check a list of drugs for any pairwise interactions. Used by the
 * QtcStacker-style "current medications" flow.
 */
export function checkAll(drugIds: string[]): DdiHit[] {
  const out: DdiHit[] = [];
  for (let i = 0; i < drugIds.length; i++) {
    for (let j = i + 1; j < drugIds.length; j++) {
      out.push(...checkPair(drugIds[i], drugIds[j]));
    }
  }
  return out;
}

export function severityRank(s: DdiSeverity): number {
  return { info: 0, caution: 1, warning: 2, avoid: 3 }[s];
}
