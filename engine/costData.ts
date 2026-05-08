// Cost data — drug-level estimated monthly cost in Malaysian Ringgit.
//
// Sources:
//   • Malaysian Ministry of Health Drug Formulary (MOH 2024)
//   • Pharmaniaga + Bidayuh patient assistance pricing
//   • Public retail pharmacy aggregates (Watsons, Caring Pharmacy)
//
// CAVEAT: Prices vary between government / private / brand / generic
// channels. The values below are CURATED ROUGH ESTIMATES at typical
// adult target dose, intended only to support a *relative* affordability
// hint. Any procurement decision should use the actual local quote.
//
// Currency: MYR (Malaysian Ringgit). 1 MYR ≈ 0.21 USD as of 2026.

export interface CostEntry {
  drugId: string;
  /** Estimated monthly cost in MYR at typical target dose. */
  monthlyCostMyr: number;
  /** Tier — affordable / moderate / expensive — for fast UI rendering. */
  tier: 'subsidised' | 'affordable' | 'moderate' | 'expensive';
  /** Channel: government formulary / private retail / both. */
  channel: 'gov' | 'private' | 'both';
  /** Free-form note (e.g. "Generic only on government list"). */
  note?: string;
  /** Last review date (ISO). */
  lastReviewedISO: string;
}

const DATA: CostEntry[] = [
  // ── Antidepressants ─────────────────────────────────────────────
  { drugId: 'fluoxetine',     monthlyCostMyr: 8,    tier: 'subsidised', channel: 'both',    note: 'Generic widely available.', lastReviewedISO: '2026-04-01' },
  { drugId: 'sertraline',     monthlyCostMyr: 25,   tier: 'affordable', channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'escitalopram',   monthlyCostMyr: 60,   tier: 'moderate',   channel: 'both',    note: 'Generic newer; brand more common.', lastReviewedISO: '2026-04-01' },
  { drugId: 'paroxetine',     monthlyCostMyr: 35,   tier: 'affordable', channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'fluvoxamine',    monthlyCostMyr: 65,   tier: 'moderate',   channel: 'private', note: 'Limited availability on government list.', lastReviewedISO: '2026-04-01' },
  { drugId: 'venlafaxine',    monthlyCostMyr: 45,   tier: 'affordable', channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'desvenlafaxine', monthlyCostMyr: 110,  tier: 'expensive',  channel: 'private', note: 'Brand only.', lastReviewedISO: '2026-04-01' },
  { drugId: 'duloxetine',     monthlyCostMyr: 90,   tier: 'moderate',   channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'mirtazapine',    monthlyCostMyr: 30,   tier: 'affordable', channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'agomelatine',    monthlyCostMyr: 130,  tier: 'expensive',  channel: 'private', note: 'Brand only; LFT monitoring adds lab cost.', lastReviewedISO: '2026-04-01' },
  { drugId: 'vortioxetine',   monthlyCostMyr: 180,  tier: 'expensive',  channel: 'private', note: 'Brand only; not on government list.', lastReviewedISO: '2026-04-01' },

  // ── Antipsychotics ──────────────────────────────────────────────
  { drugId: 'haloperidol',    monthlyCostMyr: 5,    tier: 'subsidised', channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'chlorpromazine', monthlyCostMyr: 7,    tier: 'subsidised', channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'trifluoperazine',monthlyCostMyr: 12,   tier: 'subsidised', channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'sulpiride',      monthlyCostMyr: 25,   tier: 'affordable', channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'risperidone',    monthlyCostMyr: 25,   tier: 'affordable', channel: 'both',    note: 'Generic.', lastReviewedISO: '2026-04-01' },
  { drugId: 'olanzapine',     monthlyCostMyr: 50,   tier: 'moderate',   channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'quetiapine',     monthlyCostMyr: 60,   tier: 'moderate',   channel: 'both',    note: 'IR generic; XR brand-only.', lastReviewedISO: '2026-04-01' },
  { drugId: 'amisulpride',    monthlyCostMyr: 90,   tier: 'moderate',   channel: 'private', lastReviewedISO: '2026-04-01' },
  { drugId: 'aripiprazole',   monthlyCostMyr: 110,  tier: 'expensive',  channel: 'both',    note: 'Generic available; significantly cheaper than brand.', lastReviewedISO: '2026-04-01' },
  { drugId: 'paliperidone',   monthlyCostMyr: 220,  tier: 'expensive',  channel: 'both',    note: 'Brand-only; PP1M much cheaper at MOH list.', lastReviewedISO: '2026-04-01' },
  { drugId: 'lurasidone',     monthlyCostMyr: 200,  tier: 'expensive',  channel: 'private', note: 'Brand only.', lastReviewedISO: '2026-04-01' },
  { drugId: 'clozapine',      monthlyCostMyr: 90,   tier: 'moderate',   channel: 'both',    note: 'Drug cheap, monitoring adds significant cost.', lastReviewedISO: '2026-04-01' },

  // ── LAIs (per injection cost — depot) ──
  { drugId: 'haloperidol-lai',       monthlyCostMyr: 35,   tier: 'affordable', channel: 'both',    note: 'Per monthly injection.', lastReviewedISO: '2026-04-01' },
  { drugId: 'fluphenazine-lai',      monthlyCostMyr: 25,   tier: 'subsidised', channel: 'both',    note: 'Per fortnightly injection.', lastReviewedISO: '2026-04-01' },
  { drugId: 'flupenthixol-lai',      monthlyCostMyr: 30,   tier: 'affordable', channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'zuclopenthixol-lai',    monthlyCostMyr: 30,   tier: 'affordable', channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'risperidone-lai',       monthlyCostMyr: 380,  tier: 'expensive',  channel: 'both',    note: 'Per fortnightly injection.', lastReviewedISO: '2026-04-01' },
  { drugId: 'paliperidone-lai',      monthlyCostMyr: 700,  tier: 'expensive',  channel: 'both',    note: 'PP1M monthly injection. PP3M ~3× monthly cost equivalent.', lastReviewedISO: '2026-04-01' },
  { drugId: 'aripiprazole-lai',      monthlyCostMyr: 850,  tier: 'expensive',  channel: 'both',    note: 'Maintena monthly injection.', lastReviewedISO: '2026-04-01' },

  // ── Mood stabilisers ───────────────────────────────────────────
  { drugId: 'lithium',        monthlyCostMyr: 12,   tier: 'subsidised', channel: 'both',    note: 'Drug cheap; level monitoring adds cost.', lastReviewedISO: '2026-04-01' },
  { drugId: 'valproate',      monthlyCostMyr: 25,   tier: 'affordable', channel: 'both',    lastReviewedISO: '2026-04-01' },
  { drugId: 'lamotrigine',    monthlyCostMyr: 45,   tier: 'affordable', channel: 'both',    note: 'Generic widely available.', lastReviewedISO: '2026-04-01' },
  { drugId: 'carbamazepine',  monthlyCostMyr: 18,   tier: 'subsidised', channel: 'both',    lastReviewedISO: '2026-04-01' },
];

const INDEX = new Map<string, CostEntry>(DATA.map((e) => [e.drugId, e]));

export function costFor(drugId: string): CostEntry | null {
  return INDEX.get(drugId) ?? null;
}

export function listCostEntries(): CostEntry[] {
  return [...DATA];
}

export function tierColor(t: CostEntry['tier']): { bg: string; text: string } {
  switch (t) {
    case 'subsidised': return { bg: 'bg-to/15',      text: 'text-to' };
    case 'affordable': return { bg: 'bg-accent/15',  text: 'text-accent' };
    case 'moderate':   return { bg: 'bg-warning/15', text: 'text-warning' };
    case 'expensive':  return { bg: 'bg-danger/15',  text: 'text-danger' };
  }
}

export function tierLabel(t: CostEntry['tier']): string {
  switch (t) {
    case 'subsidised': return 'Subsidised';
    case 'affordable': return 'Affordable';
    case 'moderate':   return 'Moderate';
    case 'expensive':  return 'Expensive';
  }
}

export function formatMyr(amount: number): string {
  return `RM ${amount.toFixed(0)}`;
}
