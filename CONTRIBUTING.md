# Contributing to PsychSwitch

Thank you for considering a contribution. PsychSwitch's clinical
content is open under CC BY-NC-SA 4.0 specifically so that qualified
clinicians outside the core team can submit corrections, additions,
and translations. The app source is MIT-licensed and welcomes the same.

There are three kinds of contributions, in order of impact:

1. **Clinical errata** — wrong dose, stale citation, missed
   contraindication, mismatch with the source guideline.
2. **New rules / drug profiles** — adding a switch the engine doesn't
   yet cover, or a drug profile we're missing.
3. **Code / UI improvements** — bug fixes, accessibility, polish.

---

## Reporting a clinical issue (no Git skills required)

Use the in-app **"Report an issue with this rule"** button on any
Result screen. It opens your mail client with rule ID, app version,
and reviewer attribution pre-filled. You only need to describe what's
wrong + (optionally) what the correction should be.

If you can't reach the in-app button, email `errata@psychswitch.health`
with the rule ID and your concern.

**No patient data, ever.** Errata reports are about the *rule*, not
the patient.

---

## Submitting a rule correction (with Git)

### What counts as a clinical errata?

Examples we welcome:
- Citation pointing to the wrong page / table
- Dose increment incompatible with the formulation
- Contraindication not flagged (e.g. lithium + severe CKD)
- Strategy mismatch with the source guideline
- Schedule duration off by 1+ weeks vs reviewed reference

### Workflow

1. Fork the repo + clone locally.
2. Find the rule JSON under `content/switching-rules/<from>-to-<to>.json`.
3. Edit. Save your changes.
4. **Update `lastReviewedISO` and `reviewedBy` to YOUR name + today's date.**
   This is the audit trail — every change must be attributable.
5. Run the test suite: `pnpm test`. All existing tests must still pass.
6. Open a pull request. In the PR body include:
   - The rule ID(s) you changed
   - The clinical justification (with page reference if applicable)
   - Your professional credentials (we won't merge clinical changes
     from anonymous accounts)

### Review process

A core maintainer (currently Dr Rashid Razak) reviews every clinical
change. Mergeable when:
- Tests pass
- The justification is sound
- Citations are properly paraphrased (≤15 words quoted at a time —
  copyright safety)
- The reviewer attribution is updated

Expect 7–10 days to first review.

---

## Adding a new switching rule

1. Create `content/switching-rules/<from-id>-to-<to-id>.json`. Copy
   the structure from any existing rule — `agomelatine-to-sertraline.json`
   is a good template.
2. Register it in `engine/switchingEngine.ts`. Add an `import` and
   include the rule in the `RULES` array.
3. Update `engine/__tests__/switchingEngine.test.ts` — there's a test
   that asserts every registered rule's IDs match. Bump the count and
   add the new ID in alphabetical order.
4. Run `pnpm test` — must be green.
5. Test the pair manually in the UI.

See [docs/CONTENT_SCHEMA.md](./docs/CONTENT_SCHEMA.md) for full schema
reference, including how to set `scalingMode`, per-step `citations`,
and the `safetyFlags` array.

---

## Adding a drug profile

Same pattern as rules:
1. Create `content/drugs/<id>.json`.
2. Register in `engine/switchingEngine.ts`'s `DRUGS` array.
3. Update the `listAllDrugs() returns N drugs` test.
4. If the drug is hidden (e.g. MAOI), set `"hidden": true` so it
   stays out of the picker but remains accessible to rules.

The schema is in `engine/types.ts` (`Drug` interface). Per-drug risk
fields (`epsRisk`, `prolactinRisk`, etc.) feed the predicted-AE engine
and the smart picker — fill them out completely.

---

## Translations (BM / ID / Tagalog)

The UI scaffold is in `utils/i18n.ts`. To add a translation:
1. Find the dictionary for your language (`MS` for Bahasa Malaysia,
   `ID` for Indonesian; create new ones for Tagalog / Thai).
2. Add new key/value pairs.
3. The key must already exist in `EN` — never add language-only keys.

**Clinical content translation** (the rule rationales, notes, etc.) is
handled separately and requires native-speaker clinical review. Open
an issue to discuss before starting.

---

## Code contributions

### Setup
```bash
git clone <your-fork>
cd psych-switch
pnpm install
pnpm test           # 217 tests must pass
pnpm typecheck      # zero errors
pnpm start          # Expo dev server
```

### Style
- TypeScript strict mode. No `any` without a comment justifying it.
- NativeWind (Tailwind classes) for layout. No StyleSheet.create unless
  you need dynamic conditional values that NativeWind can't resolve.
- Pure functions for engine logic. Tests for every new pure function.
- React components use `function` declarations (not arrow functions
  exported default).

### PR requirements
- All existing tests pass.
- New pure functions have unit tests.
- TypeScript typecheck is clean.
- Comments explain *why*, not *what* (the code shows what).
- Privacy-first: no new fields that collect patient-identifying data.

### Commits
Conventional-ish:
- `feat(engine):` for new clinical capabilities
- `fix(rule):` for clinical errata
- `chore(content):` for content additions
- `docs:` for documentation
- `refactor:` for non-behaviour-changing cleanups

---

## What we won't merge

- Clinical changes without a clear citation
- Translations from non-native speakers (we can't validate them)
- Analytics / tracking / fingerprinting
- New native dependencies that don't work in Expo Go
- Features that send PHI off-device

---

## Code of conduct

Be precise, be kind, cite your sources, respect copyright (≤15 words
of quoted material at a time, paraphrased rest). Disagreements about
clinical content are settled by the most senior current maintainer
with publication-cited evidence as the tiebreaker.

---

## License attestation

By submitting a PR you agree to license your changes under the same
licenses as the project: MIT (app source) and CC BY-NC-SA 4.0
(clinical content).
