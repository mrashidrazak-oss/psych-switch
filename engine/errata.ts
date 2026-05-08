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

export type ErrataChangeKind =
  | 'dose'           // dose value(s) changed
  | 'duration'       // schedule duration changed
  | 'strategy'       // strategy class changed (cross-taper → plateau, etc.)
  | 'citation'       // citation key added / corrected
  | 'safety_flag'    // safety flag added / removed
  | 'monitoring'     // monitoring entry added / changed
  | 'rationale'      // rationale text rewritten
  | 'new_rule'       // first publication of a rule
  | 'new_drug'       // first publication of a drug profile
  | 'other';         // anything else (typo fix, formatting, etc.)

export type ErrataSeverity = 'minor' | 'moderate' | 'significant' | 'critical';

export interface ErrataEntry {
  /** Stable id — date + slug. Never reused. */
  id: string;
  /** ISO date the change was accepted into main. */
  dateISO: string;
  /** Affected rule id, drug id, or 'engine' / 'content' for non-rule changes. */
  scope: string;
  /** Display label for the affected scope. */
  scopeLabel: string;
  changeKind: ErrataChangeKind;
  severity: ErrataSeverity;
  /** One-line summary suitable for a list view. */
  summary: string;
  /** Free-text "what specifically changed" — multi-line OK. */
  detail: string;
  /** Before snippet (optional, for value-changes). */
  before?: string;
  /** After snippet. */
  after?: string;
  /** Why the change was made. */
  rationale: string;
  /** Reviewer/sign-off. */
  reviewer: string;
  /** Citations supporting the change. */
  citations: string[];
  /** App version that first shipped the corrected content. */
  appVersion: string;
}

const ENTRIES: ErrataEntry[] = [
  {
    id: '2026-05-08-pp3m-bridge-dose',
    dateISO: '2026-05-08',
    scope: 'engine.depotLai',
    scopeLabel: 'Invega Trinza (PP3M)',
    changeKind: 'dose',
    severity: 'significant',
    summary: 'PP3M 525 mg eq → PP1M bridge corrected to 100 mg eq (was 150)',
    detail:
      'For patients missed >9 months of PP3M who require restart, the bridge PP1M dose for the 525 mg eq strength was previously listed as 150 mg eq. Per the FDA prescribing information (December 2024 revision), the correct bridge is 100 mg eq (= 156 mg PP). Failing to use the lower dose risks supratherapeutic plasma levels at re-establishment.',
    before: 'PP3M 525 mg eq missed-dose bridge: PP1M 150 mg eq',
    after: 'PP3M 525 mg eq missed-dose bridge: PP1M 100 mg eq (= 156 mg PP)',
    rationale: 'Match the FDA Trinza PI table 4 directly. The earlier value reflected an older PI revision.',
    reviewer: 'Rashid Razak (clinical author)',
    citations: ['invega_trinza_pi'],
    appVersion: '0.1.0',
  },
  {
    id: '2026-05-08-paroxetine-pregnancy-trimester',
    dateISO: '2026-05-08',
    scope: 'paroxetine',
    scopeLabel: 'Paroxetine — pregnancy',
    changeKind: 'safety_flag',
    severity: 'significant',
    summary: 'Paroxetine pregnancy tier now trimester-specific (1st = avoid, 2nd-3rd = caution)',
    detail:
      'Pregnancy specialty matrix added in v0.4.3 includes per-trimester overrides for paroxetine. The 1st-trimester signal for cardiac defects is well-characterised; the 2nd and 3rd trimesters are less concerning in isolation, so the engine now uses "avoid" for 1st-trimester and "caution" thereafter rather than a flat "avoid" across pregnancy.',
    rationale: 'Match Maudsley 15th ch.8 nuance + UKTIS monograph.',
    reviewer: 'Rashid Razak',
    citations: ['maudsley15_ch8_paroxetine', 'uktis_paroxetine'],
    appVersion: '0.4.3',
  },
  {
    id: '2026-05-08-aripiprazole-akathisia-prediction',
    dateISO: '2026-05-08',
    scope: 'engine.predictedAeProfile',
    scopeLabel: 'Aripiprazole — akathisia',
    changeKind: 'other',
    severity: 'moderate',
    summary: 'Predicted AE engine now takes higher of drug-field vs reverse-lookup tiers',
    detail:
      'Aripiprazole carries epsRisk: low in its drug profile (correct for parkinsonism overall) but is in the causedBy[] array for eps_akathisia (correct for the akathisia-specific subtype). The earlier predictor returned drug-field-wins, which produced a misleading "low likelihood of akathisia on aripiprazole". Fixed: the predictor now returns the higher-severity tier, surfacing akathisia as high.',
    before: 'aripiprazole akathisia → low (drug field wins)',
    after: 'aripiprazole akathisia → high (reverse-lookup wins when more severe)',
    rationale: "Aripiprazole's hallmark dose-limiting AE is akathisia. The earlier prediction would have missed this for clinicians fleeing akathisia on a previous antipsychotic.",
    reviewer: 'Rashid Razak',
    citations: ['maudsley15_schizophrenia_aripiprazole_profile'],
    appVersion: '0.3.4',
  },
  {
    id: '2026-05-07-step-notes-adapt',
    dateISO: '2026-05-07',
    scope: 'engine.scaleSchedule',
    scopeLabel: 'Adaptive scaler — step notes',
    changeKind: 'other',
    severity: 'moderate',
    summary: 'Adapted schedules now substitute reference dose mentions in notes',
    detail:
      'When the user enters non-reference doses, the schedule rows scale and round correctly, but the notes column was still saying "Continue agomelatine 25 mg" when the actual scaled dose was 30 mg. The adaptStepNotes helper now finds and substitutes \\bN mg\\b matches against the reference step doses. Word-boundary regex prevents collateral substitutions ("in 25 days" stays unchanged because no "mg" follows).',
    rationale: 'Reported by Rashid during pre-release self-testing — the dose mismatch was clinically confusing.',
    reviewer: 'Rashid Razak',
    citations: [],
    appVersion: '0.3.1',
  },
  {
    id: '2026-05-07-evidence-grade-demote-on-adapt',
    dateISO: '2026-05-07',
    scope: 'engine.scaleSchedule',
    scopeLabel: 'Evidence grade demotion on adaptation',
    changeKind: 'other',
    severity: 'minor',
    summary: 'Adapted schedules drop one evidence grade (A → B etc)',
    detail:
      'When the schedule has been adapted from its reviewed reference (any non-trivial dose scaling), the evidence badge now reads "B (adapted)" instead of "A". The strategy is still grade-A reviewed, but the dose values are derived rather than verbatim — honest signaling matters more than impressing the user.',
    rationale: 'Trust calibration. A grade-A schedule and a grade-A-but-adapted schedule should not look identical to the clinician.',
    reviewer: 'Rashid Razak',
    citations: [],
    appVersion: '0.3.1',
  },
  {
    id: '2026-05-06-clozapine-fbc-cadence',
    dateISO: '2026-05-06',
    scope: 'engine.monitoring',
    scopeLabel: 'Clozapine — FBC cadence',
    changeKind: 'monitoring',
    severity: 'moderate',
    summary: 'Clozapine FBC cadence corrected to weekly ×18, fortnightly ×34, then monthly',
    detail:
      'The earliest monitoring schedule had clozapine FBC as weekly ×26 then monthly. Per Maudsley 15th + UK Clozaril patient-monitoring service, the cadence is weekly weeks 1-18, fortnightly weeks 19-52, monthly thereafter. Fixed.',
    rationale: 'Match Maudsley 15th + UK CPMS.',
    reviewer: 'Rashid Razak',
    citations: ['maudsley15_clozapine_monitoring'],
    appVersion: '0.2.0',
  },
  {
    id: '2026-05-04-initial-rule-set',
    dateISO: '2026-05-04',
    scope: 'content',
    scopeLabel: 'Initial 133 rules + 40 drugs',
    changeKind: 'new_rule',
    severity: 'critical',
    summary: 'First public release of the reviewed rule set',
    detail:
      '133 cross-titration rules across antidepressants, antipsychotics (oral + LAI) and mood stabilizers. 40 drug profiles. Sources: Maudsley 15th, BAP 2020, NICE, Malaysian CPGs, FDA / EMA prescribing information.',
    rationale: 'v0.1 baseline — every rule individually authored + reviewed by Rashid Razak.',
    reviewer: 'Rashid Razak',
    citations: [
      'maudsley15_ch3_p369_table_3_7',
      'bap2020_psychosis',
      'nice_ng178',
    ],
    appVersion: '0.1.0',
  },
];

const BY_SCOPE = (() => {
  const m = new Map<string, ErrataEntry[]>();
  for (const e of ENTRIES) {
    if (!m.has(e.scope)) m.set(e.scope, []);
    m.get(e.scope)!.push(e);
  }
  return m;
})();

// ── Public API ─────────────────────────────────────────────────────────────

export function listErrata(): ErrataEntry[] {
  return [...ENTRIES].sort((a, b) => b.dateISO.localeCompare(a.dateISO));
}

export function errataForScope(scope: string): ErrataEntry[] {
  return [...(BY_SCOPE.get(scope) ?? [])].sort((a, b) =>
    b.dateISO.localeCompare(a.dateISO),
  );
}

export function errataForRule(ruleId: string): ErrataEntry[] {
  return errataForScope(ruleId);
}

export function errataSinceVersion(version: string): ErrataEntry[] {
  return listErrata().filter((e) => compareVersions(e.appVersion, version) > 0);
}

export function errataCount(): number {
  return ENTRIES.length;
}

// ── Helpers ────────────────────────────────────────────────────────────────

export function severityColor(s: ErrataSeverity): {
  bg: string;
  border: string;
  text: string;
} {
  switch (s) {
    case 'minor':       return { bg: 'bg-border',     border: 'border-border',     text: 'text-muted' };
    case 'moderate':    return { bg: 'bg-accent/10',  border: 'border-accent/30',  text: 'text-accent' };
    case 'significant': return { bg: 'bg-warning/10', border: 'border-warning/30', text: 'text-warning' };
    case 'critical':    return { bg: 'bg-danger/10',  border: 'border-danger/30',  text: 'text-danger' };
  }
}

export function severityLabel(s: ErrataSeverity): string {
  switch (s) {
    case 'minor': return 'Minor';
    case 'moderate': return 'Moderate';
    case 'significant': return 'Significant';
    case 'critical': return 'Critical';
  }
}

export function changeKindLabel(k: ErrataChangeKind): string {
  switch (k) {
    case 'dose': return 'Dose';
    case 'duration': return 'Duration';
    case 'strategy': return 'Strategy';
    case 'citation': return 'Citation';
    case 'safety_flag': return 'Safety flag';
    case 'monitoring': return 'Monitoring';
    case 'rationale': return 'Rationale';
    case 'new_rule': return 'New rule';
    case 'new_drug': return 'New drug';
    case 'other': return 'Other';
  }
}

/**
 * Compare two semver-ish strings ("0.4.3" vs "0.4.2"). Returns
 * negative if a < b, positive if a > b, 0 if equal. Tolerant of
 * missing patch ("0.4" works).
 */
function compareVersions(a: string, b: string): number {
  const pa = a.split('.').map((p) => parseInt(p, 10) || 0);
  const pb = b.split('.').map((p) => parseInt(p, 10) || 0);
  const n = Math.max(pa.length, pb.length);
  for (let i = 0; i < n; i++) {
    const av = pa[i] ?? 0;
    const bv = pb[i] ?? 0;
    if (av !== bv) return av - bv;
  }
  return 0;
}
