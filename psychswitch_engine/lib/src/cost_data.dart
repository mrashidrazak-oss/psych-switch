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
//
// Dart port of engine/costData.ts. Data is byte-equivalent. The
// `tierColor` helper from TS emitted Tailwind utility classes; Dart UI
// uses AppColors directly via [tierColorToken], which returns a
// semantic-token name (success/accent/warning/danger).

/// Affordability tier for fast UI rendering.
enum CostTier {
  subsidised('subsidised'),
  affordable('affordable'),
  moderate('moderate'),
  expensive('expensive');

  const CostTier(this.jsonValue);

  /// String literal as used in JSON (matches TS union).
  final String jsonValue;

  static CostTier fromJson(String value) {
    for (final t in CostTier.values) {
      if (t.jsonValue == value) return t;
    }
    throw ArgumentError.value(value, 'value', 'unknown CostTier');
  }
}

/// Channel through which the drug is typically procured.
enum CostChannel {
  gov('gov'),
  private('private'),
  both('both');

  const CostChannel(this.jsonValue);

  final String jsonValue;

  static CostChannel fromJson(String value) {
    for (final c in CostChannel.values) {
      if (c.jsonValue == value) return c;
    }
    throw ArgumentError.value(value, 'value', 'unknown CostChannel');
  }
}

/// One cost row.
class CostEntry {
  const CostEntry({
    required this.drugId,
    required this.monthlyCostMyr,
    required this.tier,
    required this.channel,
    required this.lastReviewedISO,
    this.note,
  });

  final String drugId;

  /// Estimated monthly cost in MYR at typical target dose.
  final num monthlyCostMyr;

  final CostTier tier;
  final CostChannel channel;

  /// Free-form note (e.g. "Generic only on government list").
  final String? note;

  /// Last review date (ISO).
  final String lastReviewedISO;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'drugId': drugId,
        'monthlyCostMyr': monthlyCostMyr,
        'tier': tier.jsonValue,
        'channel': channel.jsonValue,
        if (note != null) 'note': note,
        'lastReviewedISO': lastReviewedISO,
      };
}

const List<CostEntry> _data = <CostEntry>[
  // ── Antidepressants ─────────────────────────────────────────────
  CostEntry(drugId: 'fluoxetine',     monthlyCostMyr: 8,    tier: CostTier.subsidised, channel: CostChannel.both,    note: 'Generic widely available.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'sertraline',     monthlyCostMyr: 25,   tier: CostTier.affordable, channel: CostChannel.both,    lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'escitalopram',   monthlyCostMyr: 60,   tier: CostTier.moderate,   channel: CostChannel.both,    note: 'Generic newer; brand more common.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'paroxetine',     monthlyCostMyr: 35,   tier: CostTier.affordable, channel: CostChannel.both,    lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'fluvoxamine',    monthlyCostMyr: 65,   tier: CostTier.moderate,   channel: CostChannel.private, note: 'Limited availability on government list.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'venlafaxine',    monthlyCostMyr: 45,   tier: CostTier.affordable, channel: CostChannel.both,    lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'desvenlafaxine', monthlyCostMyr: 110,  tier: CostTier.expensive,  channel: CostChannel.private, note: 'Brand only.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'duloxetine',     monthlyCostMyr: 90,   tier: CostTier.moderate,   channel: CostChannel.both,    lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'mirtazapine',    monthlyCostMyr: 30,   tier: CostTier.affordable, channel: CostChannel.both,    lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'agomelatine',    monthlyCostMyr: 130,  tier: CostTier.expensive,  channel: CostChannel.private, note: 'Brand only; LFT monitoring adds lab cost.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'vortioxetine',   monthlyCostMyr: 180,  tier: CostTier.expensive,  channel: CostChannel.private, note: 'Brand only; not on government list.', lastReviewedISO: '2026-04-01'),

  // ── Antipsychotics ──────────────────────────────────────────────
  CostEntry(drugId: 'haloperidol',     monthlyCostMyr: 5,    tier: CostTier.subsidised, channel: CostChannel.both,    lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'chlorpromazine',  monthlyCostMyr: 7,    tier: CostTier.subsidised, channel: CostChannel.both,    lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'trifluoperazine', monthlyCostMyr: 12,   tier: CostTier.subsidised, channel: CostChannel.both,    lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'sulpiride',       monthlyCostMyr: 25,   tier: CostTier.affordable, channel: CostChannel.both,    lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'risperidone',     monthlyCostMyr: 25,   tier: CostTier.affordable, channel: CostChannel.both,    note: 'Generic.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'olanzapine',      monthlyCostMyr: 50,   tier: CostTier.moderate,   channel: CostChannel.both,    lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'quetiapine',      monthlyCostMyr: 60,   tier: CostTier.moderate,   channel: CostChannel.both,    note: 'IR generic; XR brand-only.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'amisulpride',     monthlyCostMyr: 90,   tier: CostTier.moderate,   channel: CostChannel.private, lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'aripiprazole',    monthlyCostMyr: 110,  tier: CostTier.expensive,  channel: CostChannel.both,    note: 'Generic available; significantly cheaper than brand.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'paliperidone',    monthlyCostMyr: 220,  tier: CostTier.expensive,  channel: CostChannel.both,    note: 'Brand-only; PP1M much cheaper at MOH list.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'lurasidone',      monthlyCostMyr: 200,  tier: CostTier.expensive,  channel: CostChannel.private, note: 'Brand only.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'clozapine',       monthlyCostMyr: 90,   tier: CostTier.moderate,   channel: CostChannel.both,    note: 'Drug cheap, monitoring adds significant cost.', lastReviewedISO: '2026-04-01'),

  // ── LAIs (per injection cost — depot) ──
  CostEntry(drugId: 'haloperidol-lai',    monthlyCostMyr: 35,   tier: CostTier.affordable, channel: CostChannel.both, note: 'Per monthly injection.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'fluphenazine-lai',   monthlyCostMyr: 25,   tier: CostTier.subsidised, channel: CostChannel.both, note: 'Per fortnightly injection.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'flupenthixol-lai',   monthlyCostMyr: 30,   tier: CostTier.affordable, channel: CostChannel.both, lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'zuclopenthixol-lai', monthlyCostMyr: 30,   tier: CostTier.affordable, channel: CostChannel.both, lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'risperidone-lai',    monthlyCostMyr: 380,  tier: CostTier.expensive,  channel: CostChannel.both, note: 'Per fortnightly injection.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'paliperidone-lai',   monthlyCostMyr: 700,  tier: CostTier.expensive,  channel: CostChannel.both, note: 'PP1M monthly injection. PP3M ~3× monthly cost equivalent.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'aripiprazole-lai',   monthlyCostMyr: 850,  tier: CostTier.expensive,  channel: CostChannel.both, note: 'Maintena monthly injection.', lastReviewedISO: '2026-04-01'),

  // ── Mood stabilisers ───────────────────────────────────────────
  CostEntry(drugId: 'lithium',       monthlyCostMyr: 12,   tier: CostTier.subsidised, channel: CostChannel.both, note: 'Drug cheap; level monitoring adds cost.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'valproate',     monthlyCostMyr: 25,   tier: CostTier.affordable, channel: CostChannel.both, lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'lamotrigine',   monthlyCostMyr: 45,   tier: CostTier.affordable, channel: CostChannel.both, note: 'Generic widely available.', lastReviewedISO: '2026-04-01'),
  CostEntry(drugId: 'carbamazepine', monthlyCostMyr: 18,   tier: CostTier.subsidised, channel: CostChannel.both, lastReviewedISO: '2026-04-01'),
];

final Map<String, CostEntry> _index = <String, CostEntry>{
  for (final e in _data) e.drugId: e,
};

/// Look up the cost entry for a drug. Returns `null` if not registered.
CostEntry? costFor(String drugId) => _index[drugId];

/// Snapshot of every cost entry. Caller may mutate the returned list freely.
List<CostEntry> listCostEntries() => List<CostEntry>.from(_data);

/// Semantic colour token for a tier — UI maps this to AppColors.
///
/// Returns one of:
/// - `to`        — subsidised (green-ish "to")
/// - `accent`    — affordable (blue accent)
/// - `warning`   — moderate (amber)
/// - `danger`    — expensive (red)
///
/// The TS port returned Tailwind utility classes; Flutter uses semantic
/// tokens to keep the engine UI-agnostic.
String tierColorToken(CostTier t) {
  switch (t) {
    case CostTier.subsidised:
      return 'to';
    case CostTier.affordable:
      return 'accent';
    case CostTier.moderate:
      return 'warning';
    case CostTier.expensive:
      return 'danger';
  }
}

/// Human-readable label for a tier.
String tierLabel(CostTier t) {
  switch (t) {
    case CostTier.subsidised:
      return 'Subsidised';
    case CostTier.affordable:
      return 'Affordable';
    case CostTier.moderate:
      return 'Moderate';
    case CostTier.expensive:
      return 'Expensive';
  }
}

/// Format a MYR amount as `RM <int>` (no decimals).
/// Mirrors TS `formatMyr` which uses `toFixed(0)`.
String formatMyr(num amount) => 'RM ${amount.toStringAsFixed(0)}';
