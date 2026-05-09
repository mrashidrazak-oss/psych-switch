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

(none yet — get porting)
