# Result-screen rewrite — 5-session plan

**Status:** drafted 2026-05-23, not yet started.
**Scope:** `lib/src/ui/screens/result_screen.dart` (3,668 lines, 36 classes).
**Goal:** the most considered clinical decision-support output UI any
psychotropic-switching app has shipped on Android.
**Estimated effort:** 14-19h spread over 5 dedicated sessions, plus
2-3h on-device verification at the end.

---

## Principles

1. **Each session ships independently** — analyze clean, all tests pass,
   APK builds, installable on the Fold. Never leave the screen broken
   mid-session.
2. **Behaviour preserved unless explicitly redesigned** — the engine
   integration is the deepest in the app. Every score computation,
   DDI severity ranking, context warning, and citation grading keeps
   working exactly as today unless this plan says otherwise.
3. **One subsystem per session.** Hero one week, schedule the next,
   etc. No "small touch-ups across the screen" sessions — each one
   has a single focus so it ends in a coherent shippable state.
4. **Tests grow with the rewrite.** Today: 4 plan branches covered.
   Goal: 4 plan branches × 4 user-state controls = 16-24 widget-test
   cells, ideally with golden screenshots.
5. **Defer the orchestration body until last.** `_ResultBody` (624
   lines) glues every subsystem together. Refactor it after each
   subsystem is in its final shape — not before.

## Success criteria (end of session 5)

- [ ] `result_screen.dart` reduced to ~1,800-2,200 lines (extractions
      moved to widget files; orchestration tightened).
- [ ] At least 12 new widget tests covering plan-branch × user-state
      combinations.
- [ ] All 4 plan branches read their verdict in **≤1.5s** of opening
      the screen (Ive's "first impression" rule).
- [ ] Every safety signal (DDI, context warning, safety flag) has a
      visible priority — danger before warning before info, no overlap.
- [ ] Citation count vs citation depth doesn't compete with the
      verdict for primary attention.
- [ ] All 24 user-state combinations rendered + checked on the Fold.
- [ ] One commit per session, each ship-ready.

---

## Pre-work (do BEFORE session 1)

Half-day of prep, not a "session":

1. **On-device baseline screenshots** of the current Result screen
   across all 4 plan branches × representative user states. Save to
   `store/screenshots/result-pre-rewrite/` so we can A/B against the
   final state.
2. **Tester feedback collection plan** — if any of the 5 closed-beta
   clinicians have used the current Result screen, capture what they
   said in `store/CLINICAL_FEEDBACK.md`. This drives priority.
3. **Verify the engine API is stable** — no in-flight changes to
   `SwitchPlan`, `ScaleResult`, `ScoreInputs`, or the safety/DDI
   types. The rewrite assumes the engine is frozen for ~3 weeks.
4. **Bring up a Result-screen-specific test scaffold** that supports
   pumping all 4 plan branches in a single `testWidgets`, with helpers
   for switching user-state providers (`_scheduleViewProvider`,
   `_taperSpeedProvider`, `_conservativeProvider`) between assertions.
   This unlocks the test growth in sessions 1-5.

If none of these are done, do them BEFORE booking session 1. Without
the baseline, you can't verify the rewrite preserved every behaviour.

---

## Session 1 — Hero + verdict band

**Goal:** the clinician knows the safety verdict from the hero alone,
in ≤1.5s of opening the screen.

**Surfaces touched:**
- `_ResultHero` (75 lines)
- `_HeroDrugBand` (69 lines)
- `_HeroDrugCell` (102 lines)
- `_HeroVerdictBand` (56 lines)
- `_OkVerdict` (165 lines)
- `_ToneVerdict` (81 lines)
- `_ClozapineVerdict` (91 lines)

**~640 lines total.**

**Design decisions to make in this session:**
- Score: ring vs big-number-with-tone. (Today: ring, score number
  inside.) Likely move to **big-number-primary + ring-as-frame** for
  scannability.
- Drug pair typography: today FROM and TO are equally weighted. Should
  the *to* drug read larger (because that's the destination) or stay
  symmetric (the journey)?
- Verdict colour-tone: today danger/warning/info chips. Should the
  whole hero card *itself* tone-tint by verdict so the first-glance
  colour is the safety signal?
- Duration display: today buried in the eyebrow. Promote it.

**Deliverable:** refactored hero, 4 verdict variants visually unified,
~600 LOC. Same engine inputs, same test contract strings (`'FROM'`,
`'TO'`, `'Reviewed schedule'`, `'MAOI WASHOUT'`, `'CLOZAPINE INITIATION'`,
`'NO REVIEWED RULE'`).

**Tests added:**
- For each of the 4 plan branches: assert verdict tone is correct
- For OK: assert score range (low/mid/high) produces expected hero
  tone

**Done when:**
- Analyze clean, full suite green
- Each plan branch produces a hero that communicates verdict in ≤1.5s
  (subjective — verified on Fold)
- 4 new widget tests for verdict tone

**Estimated: 3-4h**

---

## Session 2 — Schedule presentation

**Goal:** the day-by-day taper plan is **scannable at a glance**.
Special events (overlap peak, washout, target day) stand out.

**Surfaces touched:**
- `_ScheduleCard` (58 lines)
- `_ScheduleStepBlock` (126 lines)
- `_ScheduleDoseRow` (90 lines)

**~275 lines today, likely growing to ~400 with new features.**

**Design decisions to make in this session:**
- View options: today single linear list. Should there be a **compact**
  view for long schedules (>14 days) and a **calendar** view (week
  grid)? Toggle?
- Day-number alignment: right-align tabular figures so the column
  scans without eye movement
- Special-event highlighting: tone-tinted left-rail for
  - Day 1 (start)
  - Overlap peak (highest combined dose)
  - Washout days (MAOI bridge)
  - Final day (taper-off complete)
- Dose progression visualization: today bars. Could be linear graph
  with both drug doses overlaid (Apple Numbers feel)
- Skeleton state while the schedule recomputes (when user changes
  taper speed)

**Deliverable:** refactored schedule with view toggle (linear /
calendar), tinted-rail special events, right-aligned days, optional
graph overlay. ~400 LOC.

**Tests added:**
- Schedule renders for OK plan with N days
- Special events surface (Day 1, overlap peak, washout)
- View toggle works (linear ↔ calendar/compact)

**Done when:**
- All taper-speed combinations render correctly
- The 14-day, 21-day, and 28-day schedules from the actual rule set
  all look intentional (not just "fit on screen")
- 3-4 new widget tests for schedule states

**Estimated: 3-4h**

---

## Session 3 — User-controllable state

**Goal:** the four orthogonal controls (adaptive, taper speed, soften
day-1, conservative) feel like **one considered system**, not four
separate toggles bolted together.

**Surfaces touched:**
- `_AdaptiveScheduleBanner` (172 lines)
- `_AdaptiveToggleButton` (68 lines)
- `_TaperSpeedSelector` (97 lines)
- `_TaperSpeedSegment` (94 lines)
- `_SoftenDay1Card` (251 lines)
- `_NotApplicableBody` (41 lines)
- `_SoftenReasoningRow` (59 lines)
- `_FixedProtocolNotice` (44 lines)

**~826 lines today. Likely shrinks to ~500 with unification.**

**Design decisions to make in this session:**
- Group all four controls into one **"Tune the plan"** section, or
  keep them inline with the schedule? (Today: inline.)
- Live preview: today each control updates the schedule. Should
  there be an explicit "compare" mode (slider over the schedule)?
- Defaults visualisation: clearly mark which is the rule's default vs
  user-modified
- Reset-to-default action: today no clear way back
- Each control's explanation copy: today a mix of inline help and
  expandable cards. Standardise.

**Deliverable:** unified PlanControls section, consistent UI per
control, live preview maintained, reset action. ~500 LOC.

**Tests added:**
- Toggling adaptive updates schedule
- Each taper speed produces a different last-day number
- Soften day-1 applied when applicable
- Reset returns to defaults

**Done when:**
- All 24 user-state combinations render without overlap or layout
  break
- On-device check on Fold for each combination
- 6-8 new widget tests

**Estimated: 4-5h** (highest risk session — combinatorial state)

---

## Session 4 — Safety signals + citations

**Goal:** every safety signal has a **clear visual priority** — danger
before warning before info, never overlapping. Citations are
navigable (tap → source, expanded inline).

**Surfaces touched:**
- `_ContextWarningsCard` (66 lines)
- `_SafetyFlagsCard` (18 lines)
- `_FlagChip` (29 lines)
- `_CitationsCard` (30 lines)
- `_CitationRow` (191 lines)
- `_CitationInfo` (164 lines) — extract to its own file
- `_MonitoringPlanCard` (117 lines) — extract to its own file

**~615 lines, with extractions ~400 lines net in result_screen.dart.**

**Design decisions to make in this session:**
- One unified **Safety** section header above context warnings, safety
  flags, and DDI signals (DDI doesn't have a card today — it's only
  in the hero meta chips). Promote.
- Priority colour: danger always red, warning always amber, info
  always accent. No mixing.
- Citations: today a list. Should they be **inline** next to the
  recommendation they support? Or anchored?
- Citation tap behaviour: today opens an info expansion. Could open
  a sheet, navigate to glossary, or copy-to-share.
- Monitoring plan: today a list of "check X at week N". Could be a
  calendar with dates computed from the case's start date.

**Deliverable:** unified Safety section, priority-ranked signals,
extracted CitationInfo + MonitoringPlanCard files, refactored
citation tap behaviour. ~400 LOC in result_screen.dart + 2 new
widget files.

**Tests added:**
- Safety section renders all three signal types when present
- Citation tap opens info expansion
- Monitoring plan respects case start date

**Done when:**
- DDI / context warnings / safety flags all visible and not stepping
  on each other
- Citation expansion works
- 4-6 new widget tests

**Estimated: 3-4h**

---

## Session 5 — Orchestration + footer + final polish

**Goal:** the glue is clean, the footer is considered, the share
menu reads as one polished surface, and the full screen has been
verified on the Fold across all 24 user-state combinations.

**Surfaces touched:**
- `_ResultBody` (624 lines) — main orchestration
- `_ResultFooter` (82 lines)
- `_StartAnotherButton` (18 lines)
- `_ShareMenu` (164 lines)
- `_SaveCaseDialog` (64 lines)
- `_Banner` (62 lines)
- `_Card` (40 lines)

**~1,054 lines today. Should drop to ~700 with extractions from
prior sessions + tighter orchestration.**

**Design decisions to make in this session:**
- `_ResultBody.build` is currently 100+ lines. Extract per-plan-branch
  sub-bodies (`_OkBody`, `_MaoiBody`, `_ClozapineBody`, `_NoRuleBody`)
  so the orchestration just dispatches
- Footer: today "Start another switch" + "Back to home". Add a
  "Print / Export" affordance if Tier 2-G (print/export styles) gets
  scheduled
- Share menu: 164 lines for a simple share affordance. Slim it
- Cascade choreography across all sub-bodies — verify timing reads
  as one arrival, not jittery sequencing
- Final on-device verification: 4 plan branches × 6 user states =
  24 cells, screenshot each, compare to baseline from pre-work

**Deliverable:** cleaned `_ResultBody`, extracted plan-branch
sub-bodies, slimmer share menu, ~700 LOC final. Code review
written.

**Tests added:**
- Plan-branch dispatch (each branch lands on correct sub-body)
- Footer renders for every branch
- Save case dialog flow works end-to-end

**Done when:**
- All 24 user-state combinations verified on Fold
- 2-4 new widget tests
- Code review covers all 5 sessions' work
- `result_screen.dart` ≤2,200 lines
- Total session count of new widget tests: ≥12 (success criterion met)

**Estimated: 2-3h** (lowest risk; most of the work is consolidation)

---

## Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Subtle engine wiring break | Medium | Each session adds widget tests; full suite must pass before commit. |
| Visual regression in user-state combination not tested | High | Session 5 mandates on-device verification across all 24 cells with screenshots. Skip this and the rewrite is half-done. |
| Session bleed-over (one session opens scope for another) | High | Hard stop at each session's stated surfaces. If session 2 reveals schedule depends on hero contract → finish session 2 with what's available, file a follow-up for session 1 amendments. |
| Tester feedback arrives mid-rewrite contradicting design decisions | Medium | Pause the rewrite. Re-plan from the new evidence. Sunk cost is OK; shipping a rewrite that contradicts what users said is not. |
| Engine API changes mid-rewrite | Low | Pre-work step 3 verifies stability. If engine work resumes during the 3-week window, pause the rewrite. |

---

## What happens after session 5

1. **Beta-distribute the new build** to all closed-beta testers with
   release notes that explicitly call out the Result-screen redesign
   ("Tap any plan, look at the new verdict band — feedback welcome").
2. **Track 2-week feedback window.** Pull complaints/requests into
   `store/CLINICAL_FEEDBACK.md`.
3. **Iterate selectively.** Any complaint that fits within one of the
   5 sub-systems gets a focused mini-session (1-2h). Not a wholesale
   re-rewrite.
4. **Lock for v1.0.** After 2 cycles of beta iteration, the Result
   screen is feature-frozen for the v1.0 Play Store release.

---

## Status log

| Date | Session | Status | Notes |
|---|---|---|---|
| 2026-05-23 | Plan drafted | — | This document. Not started. |
| TBD | Pre-work | — | Baseline screenshots + test scaffold + engine API verification. |
| TBD | Session 1 | — | Hero + verdict band. |
| TBD | Session 2 | — | Schedule presentation. |
| TBD | Session 3 | — | User controls. |
| TBD | Session 4 | — | Safety + citations. |
| TBD | Session 5 | — | Orchestration + final polish + code review. |

---

## Decision check — before starting

**Don't start session 1 unless ALL of these are true:**

- [ ] You have a 3h+ unbroken window for the first session
- [ ] The Fold is connected for on-device verification mid-session
- [ ] At least one clinician has used the current Result screen for
      ≥1 week and provided concrete feedback (or you've explicitly
      decided to rewrite without that signal — fine, just be honest)
- [ ] No engine refactoring is in flight
- [ ] You've read the "What happens after session 5" section and
      accept that the rewrite is followed by ≥2 weeks of beta iteration
- [ ] You're willing to pause mid-rewrite if tester feedback
      contradicts a design decision

If any unchecked, do the pre-work first or wait. **Starting this with
caveats unaddressed = burning 14-19 hours.**
