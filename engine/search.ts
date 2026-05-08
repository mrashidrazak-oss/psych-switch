// Cross-content search.
//
// Looks across:
//   • Drugs (generic + brand names)
//   • Switching rules ("X to Y" / "X → Y")
//   • Tools (qtc, ramadan, equivalency, ae lookup, ctxt, cases, etc.)
//   • Modules (clozapine, depot, mood stabilizers)
//
// Returns a flat list of hits sorted by score. Used by the home-screen
// search bar.
import { listAllDrugs, listRules, getDrug } from './switchingEngine';

export type HitKind = 'drug' | 'rule' | 'tool' | 'module';

export interface SearchHit {
  kind: HitKind;
  /** Title shown in the result list. */
  title: string;
  /** Sub-line. */
  subtitle?: string;
  /** Where to navigate on tap. The HomeScreen knows how to route these. */
  target:
    | { type: 'switch'; fromId: string; toId: string }
    | { type: 'screen'; name: string }
    | { type: 'drug'; drugId: string };
  /** Higher = more relevant. */
  score: number;
}

const TOOLS: Array<{
  title: string;
  subtitle: string;
  keywords: string[];
  screen: string;
}> = [
  { title: 'Dose equivalents',     subtitle: 'CPZ-eq, FLX-eq, DZP-eq', keywords: ['equiv', 'cpz', 'chlorpromazine', 'fluoxetine', 'diazepam', 'dose', 'convert', 'dosage'], screen: 'Equivalency' },
  { title: 'QTc stacker',          subtitle: 'Cumulative cardiac risk', keywords: ['qtc', 'qt', 'ecg', 'cardiac', 'tdp'], screen: 'QtcStacker' },
  { title: 'Ramadan mode',         subtitle: 'Fasting-aware dosing',    keywords: ['ramadan', 'fast', 'puasa', 'iftar'], screen: 'RamadanMode' },
  { title: 'Adverse-effect lookup', subtitle: 'Symptom → switch target', keywords: ['adverse', 'side', 'effect', 'ae', 'weight', 'akathisia', 'sexual', 'sedation'], screen: 'AdverseEffects' },
  { title: 'Patient context',      subtitle: 'Age, eGFR, pregnancy',    keywords: ['patient', 'context', 'age', 'egfr', 'renal', 'hepatic', 'pregnan'], screen: 'PatientContext' },
  { title: 'Saved cases',          subtitle: 'Resume / star a switch',  keywords: ['saved', 'cases', 'recent', 'history'], screen: 'CaseManager' },
  { title: 'Glossary',             subtitle: 'Clinical-term reference',  keywords: ['glossary', 'definitions', 'jargon', 'esrs', 'qtc', 'maoi', 'cyp', 'lai'], screen: 'Glossary' },
  { title: 'Errata',               subtitle: 'Clinical-content corrections', keywords: ['errata', 'corrections', 'change history', 'audit', 'revisions', 'updates'], screen: 'Errata' },
  { title: 'Settings',             subtitle: 'Display, language, reset', keywords: ['settings', 'preferences', 'config', 'theme'], screen: 'Settings' },
  { title: "What's new",           subtitle: 'Changelog', keywords: ['changelog', 'whats new', 'updates', 'release'], screen: 'Changelog' },
];

const MODULES: Array<{
  title: string;
  subtitle: string;
  keywords: string[];
  screen: string;
}> = [
  { title: 'Clozapine',           subtitle: 'TRS module', keywords: ['cloz', 'trs', 'anc', 'fbc', 'rechallenge'], screen: 'ClozapineHome' },
  // LAI depot + Mood-stabilizer modules hidden from search in v0.4.15
  // pending more clinical research. Their dedicated screens (DepotHome,
  // MoodStabilizerHome, Sustenna, Maintena, Trinza, LithiumTapering,
  // MoodStabilizerDetail) remain registered in the navigator so deep
  // links and saved cases keep working — but they don't surface in the
  // generic search results.
];

/**
 * Search across all the things. Limit results to top-N by score.
 */
export function search(rawQuery: string, limit = 12): SearchHit[] {
  const q = rawQuery.trim().toLowerCase();
  if (q.length < 2) return [];

  // Detect "X to Y" / "X -> Y" / "X → Y"
  const pairMatch = q.match(/^(.+?)\s*(?:->|→|\bto\b)\s*(.+)$/);
  const hits: SearchHit[] = [];

  // ── Drugs ─────────────────────────────────────────────
  // Mood stabilizers and LAI / depot antipsychotics are hidden from the
  // generic switch picker pending more clinical research (lithium pacing,
  // SJS risk on lamotrigine, depot tail kinetics, missed-dose algorithms).
  // Surfacing them in search would route the user to a Switch flow that
  // can't actually accept them — confusing UX. They remain reachable via
  // their dedicated module screens (DepotHome / MoodStabilizerHome).
  const drugs = listAllDrugs();
  for (const d of drugs) {
    if (d.hidden) continue;
    if (d.category === 'mood-stabilizer') continue;
    if (d.formulation === 'lai') continue;
    const score = matchScore(q, [d.genericName, ...(d.malaysianBrandNames ?? []), d.id]);
    if (score > 0) {
      hits.push({
        kind: 'drug',
        title: d.genericName,
        subtitle: (d.malaysianBrandNames?.[0] ?? d.drugClass),
        target: { type: 'drug', drugId: d.id },
        score: score + 5, // exact drug names usually mean "show me this drug"
      });
    }
  }

  // ── Switching rules — "X to Y" form ───────────────────
  if (pairMatch) {
    const [, fromQ, toQ] = pairMatch;
    const rules = listRules();
    for (const r of rules) {
      const fromD = getDrug(r.fromDrugId);
      const toD = getDrug(r.toDrugId);
      if (!fromD || !toD) continue;
      // Same gate as the drug-hits loop: don't surface rules whose
      // endpoints are gated out of the switch flow.
      if (fromD.category === 'mood-stabilizer' || toD.category === 'mood-stabilizer') continue;
      if (fromD.formulation === 'lai' || toD.formulation === 'lai') continue;
      const fromS = matchScore(fromQ, [fromD.genericName, fromD.id, ...(fromD.malaysianBrandNames ?? [])]);
      const toS = matchScore(toQ, [toD.genericName, toD.id, ...(toD.malaysianBrandNames ?? [])]);
      if (fromS > 0 && toS > 0) {
        hits.push({
          kind: 'rule',
          title: `${fromD.genericName} → ${toD.genericName}`,
          subtitle: `${r.strategy.replace(/-/g, ' ')} · ${r.durationDays}d`,
          target: {
            type: 'switch',
            fromId: r.fromDrugId,
            toId: r.toDrugId,
          },
          score: fromS + toS + 10,
        });
      }
    }
  }

  // ── Tools ─────────────────────────────────────────────
  for (const t of TOOLS) {
    const score = matchScore(q, [t.title, t.subtitle, ...t.keywords]);
    if (score > 0) {
      hits.push({
        kind: 'tool',
        title: t.title,
        subtitle: t.subtitle,
        target: { type: 'screen', name: t.screen },
        score,
      });
    }
  }

  // ── Modules ───────────────────────────────────────────
  for (const m of MODULES) {
    const score = matchScore(q, [m.title, m.subtitle, ...m.keywords]);
    if (score > 0) {
      hits.push({
        kind: 'module',
        title: m.title,
        subtitle: m.subtitle,
        target: { type: 'screen', name: m.screen },
        score,
      });
    }
  }

  // Dedupe: keep highest-scoring entry per (kind+title)
  const dedup = new Map<string, SearchHit>();
  for (const h of hits) {
    const key = `${h.kind}::${h.title}`;
    const prior = dedup.get(key);
    if (!prior || h.score > prior.score) dedup.set(key, h);
  }

  return [...dedup.values()].sort((a, b) => b.score - a.score).slice(0, limit);
}

function matchScore(q: string, candidates: string[]): number {
  let best = 0;
  for (const c of candidates) {
    const lower = c.toLowerCase();
    if (lower === q) best = Math.max(best, 10);
    else if (lower.startsWith(q)) best = Math.max(best, 6);
    else if (lower.includes(q)) best = Math.max(best, 3);
  }
  return best;
}
