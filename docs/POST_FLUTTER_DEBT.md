# Post-Flutter debt — the creep-stash

**Status:** ledger only · open during the migration

This file is the discipline tool for the no-feature-creep principle.

## Rule

**During Phases 0–8 of the Flutter migration, every "while I'm here,
let me also..." idea goes here.** Not into a commit. Not into the
running mental list. Here. With one sentence of context.

After Phase 9 (production-stable for 30 days), this file gets
re-opened. Entries get triaged, prioritized, and shipped as v0.5.x
patches with proper review.

The discipline matters because:

1. Every "while I'm here" decision adds 2-5 days. Five of them turn
   an 8-week migration into a 14-week one.
2. Behavior parity is the safety net. The moment we change
   behaviors during port, every test failure becomes ambiguous.
3. The golden-file harness only works if both engines implement
   the same logic.

If you're tempted: open this file, write the idea, close the file,
keep porting.

---

## Ledger

```
Format:
  - [date] [phase you found it in] short title
    Context: one sentence
    Effort: t-shirt size (XS/S/M/L)
    Severity: low/med/high
```

<!-- Add new entries below. Newest at top. -->

- [2026-05-09] [Phase 1B] Content shape drift: 7 LAI-discontinuation rules ship object-shape safetyFlags
  Context: aripiprazole-lai→aripiprazole, flupenthixol-lai→flupenthixol,
  fluphenazine-lai→fluphenazine, haloperidol-lai→haloperidol,
  paliperidone-lai→paliperidone, risperidone-lai→risperidone, and
  zuclopenthixol-lai→zuclopenthixol all ship `safetyFlags` as an array
  of objects (`{key, title, body, severity}`) instead of the `string[]`
  the TS type promises. TypeScript runtime didn't validate; ResultScreen
  silently never rendered them correctly either way. Skipped in the
  Dart round-trip test for now. These rules are gated content pending
  more clinical research, so the bug doesn't reach users today. Must
  fix before un-gating: convert each rule's safetyFlags to flat
  `string[]` of flag keys. The flag display registry in
  utils/safetyFlags.ts already has the {title, body, severity}
  metadata under each key — the rule files just need to reference the
  key, not duplicate the metadata.
  Effort: S · Severity: med (blocks un-gating LAI-discontinuation flow)

- [2026-05-09] [Phase 1B] Content edge case: 7 LAI-to-oral rules use "overlap-taper"
  Context: 7 rule JSONs (aripiprazole-lai→aripiprazole, fluphenazine-lai→
  fluphenazine, flupenthixol-lai→flupenthixol, paliperidone-lai→
  paliperidone, zuclopenthixol-lai→zuclopenthixol, haloperidol-lai→
  haloperidol, risperidone-lai→risperidone) ship `"strategy":
  "overlap-taper"`, not in the TS Strategy union. TypeScript runtime
  validation gap. Resolved by adding `Strategy.overlapTaper` so JSON
  round-trips byte-identical. Needs review: should the TS type include
  this? It's a real strategy distinct from cross-taper (the depot tail
  + oral overlap pattern is genuinely different from a peer-to-peer
  cross-taper). File errata to add to TS type once decided.
  Effort: XS · Severity: low (gated drugs anyway)

- [2026-05-09] [Phase 1B] Content edge case: zuclopenthixol metabolicRisk score
  Context: `content/drugs/zuclopenthixol.json` uses `"score": "low-moderate"`
  for metabolicRisk, but the TS RiskLevel union is `'low' | 'moderate' |
  'high' | 'very high'`. TypeScript silently accepted it; the strict Dart
  parser raised. Resolved by adding `lowModerate` as a 5th value in the
  Dart enum (round-trips byte-identical). Needs clinical review: is this
  intended nuance, a typo for "moderate", or should the TS type include
  "low-moderate" too? File errata once decided.
  Effort: XS · Severity: low
