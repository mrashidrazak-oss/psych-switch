// Anticholinergic burden scoring.
//
// Uses the Anticholinergic Cognitive Burden (ACB) scale (Boustani 2008
// /  Aging Brain Care 2012 update), the most widely cited burden score
// in geriatric psychiatry:
//
//   • 0 — none / negligible
//   • 1 — possible (low-affinity muscarinic effects, in vitro evidence)
//   • 2 — definite, low / moderate (clinically observable AC effects)
//   • 3 — definite, severe (high anticholinergic activity)
//
// Sum across a patient's regimen → composite burden. Established
// thresholds: a cumulative ACB ≥ 3 is associated with a clinically
// meaningful increase in cognitive decline and ≥ 5 with substantial
// risk of dementia in older adults.
//
// PsychSwitch focus: only the psychotropics that ship in our registry
// today, plus the most common comorbid drugs that come up in shared-
// regimen reviews (oxybutynin, hyoscine, prochlorperazine, amitriptyline,
// hydroxyzine, etc.). Extend the table when content expands.

import 'package:psychswitch_engine/types/drug.dart';

/// One drug's anticholinergic-cognitive-burden tier.
///
/// `jsonValue` is the wire string used by future content files; for
/// now the table is inline because the data is small and the
/// classification rarely changes.
enum AcbTier {
  none('none', 0),
  possible('possible', 1),
  definiteLow('definite_low', 2),
  definiteSevere('definite_severe', 3);

  const AcbTier(this.jsonValue, this.score);

  final String jsonValue;
  final int score;
}

/// Tier label for the UI chip.
String acbTierLabel(AcbTier t) {
  switch (t) {
    case AcbTier.none:
      return 'No effect';
    case AcbTier.possible:
      return 'Possible';
    case AcbTier.definiteLow:
      return 'Definite (low)';
    case AcbTier.definiteSevere:
      return 'Definite (severe)';
  }
}

/// Drug-id → ACB tier. Conservative — when there's no published ACB
/// classification we default to `none` (caller can override).
///
/// Sources:
///   • Boustani et al. (2008) — original ACB scale
///   • Aging Brain Care Center (2012, 2020) update
///   • Maudsley 15th edition cross-references
///   • Stahl's Essential Psychopharmacology for high-AC SSRIs
///   • PENDING_CLINICAL_REVIEW — Rashid Razak.
const Map<String, AcbTier> _acbTable = <String, AcbTier>{
  // ── Antidepressants ───────────────────────────────────────────
  'amitriptyline': AcbTier.definiteSevere, // TCA classic
  'nortriptyline': AcbTier.definiteSevere,
  'clomipramine': AcbTier.definiteSevere,
  'doxepin': AcbTier.definiteSevere,
  'paroxetine': AcbTier.definiteLow, // most AC of the SSRIs
  'fluvoxamine': AcbTier.possible,
  'mirtazapine': AcbTier.possible, // M1 affinity via mCPP metabolite
  // most other SSRIs / SNRIs are negligible
  'fluoxetine': AcbTier.none,
  'sertraline': AcbTier.none,
  'escitalopram': AcbTier.none,
  'venlafaxine': AcbTier.none,
  'duloxetine': AcbTier.none,
  'moclobemide': AcbTier.none,
  // ── Antipsychotics ────────────────────────────────────────────
  'clozapine': AcbTier.definiteSevere,
  'olanzapine': AcbTier.definiteLow,
  'quetiapine': AcbTier.definiteLow,
  'chlorpromazine': AcbTier.definiteSevere,
  'thioridazine': AcbTier.definiteSevere,
  'haloperidol': AcbTier.possible, // mild
  'risperidone': AcbTier.possible, // low M1 but receptor occupancy
  'paliperidone': AcbTier.possible,
  'aripiprazole': AcbTier.none, // partial-D2 agonist, low AC
  'amisulpride': AcbTier.none,
  'ziprasidone': AcbTier.possible,
  'lurasidone': AcbTier.possible,
  // ── Mood stabilisers ──────────────────────────────────────────
  'lithium': AcbTier.none,
  'valproate': AcbTier.none,
  'lamotrigine': AcbTier.none,
  'carbamazepine': AcbTier.possible, // mild AC
  // ── Sedatives / anxiolytics commonly co-prescribed ────────────
  'hydroxyzine': AcbTier.definiteSevere,
  'promethazine': AcbTier.definiteSevere,
  'diphenhydramine': AcbTier.definiteSevere,
  'chlorpheniramine': AcbTier.definiteSevere,
  // ── Anti-EPS adjuncts (very common in clinic) ─────────────────
  'procyclidine': AcbTier.definiteSevere,
  'benztropine': AcbTier.definiteSevere,
  'trihexyphenidyl': AcbTier.definiteSevere,
  // ── Urological / GI / vestibular commonly seen on a chart ─────
  'oxybutynin': AcbTier.definiteSevere,
  'tolterodine': AcbTier.definiteSevere,
  'hyoscine': AcbTier.definiteSevere,
  'prochlorperazine': AcbTier.definiteLow,
};

/// Look up the ACB tier for a drug id. Returns `AcbTier.none` when
/// the drug isn't in the table — callers can ignore those rows or
/// surface "no published score" in the UI.
AcbTier acbTierFor(String drugId) =>
    _acbTable[drugId.toLowerCase()] ?? AcbTier.none;

/// Convenience overload for callers holding the full Drug.
AcbTier acbTierForDrug(Drug d) => acbTierFor(d.id);

/// Aggregate result across a regimen.
class AcbAssessment {
  const AcbAssessment({
    required this.entries,
    required this.totalScore,
  });

  /// Per-drug rows in the same order they were passed in.
  final List<AcbEntry> entries;

  /// Sum of all per-drug tier scores.
  final int totalScore;

  /// Categorical interpretation of the total. Thresholds derive from
  /// Boustani 2008 + UK ACB Calculator (Salahudeen 2015):
  ///   • 0     → no concern
  ///   • 1–2   → low burden
  ///   • 3–4   → moderate — monitor cognition
  ///   • ≥ 5   → high — strongly consider deprescribing
  AcbCategory get category {
    if (totalScore == 0) return AcbCategory.none;
    if (totalScore <= 2) return AcbCategory.low;
    if (totalScore <= 4) return AcbCategory.moderate;
    return AcbCategory.high;
  }
}

class AcbEntry {
  const AcbEntry({required this.drugId, required this.tier});
  final String drugId;
  final AcbTier tier;
}

enum AcbCategory { none, low, moderate, high }

String acbCategoryLabel(AcbCategory c) {
  switch (c) {
    case AcbCategory.none:
      return 'No anticholinergic burden';
    case AcbCategory.low:
      return 'Low burden';
    case AcbCategory.moderate:
      return 'Moderate burden — monitor cognition';
    case AcbCategory.high:
      return 'High burden — consider deprescribing';
  }
}

/// Score a regimen of drug ids.
AcbAssessment assessAnticholinergicBurden(List<String> drugIds) {
  final entries = <AcbEntry>[];
  var total = 0;
  for (final id in drugIds) {
    final tier = acbTierFor(id);
    entries.add(AcbEntry(drugId: id, tier: tier));
    total += tier.score;
  }
  return AcbAssessment(entries: entries, totalScore: total);
}
