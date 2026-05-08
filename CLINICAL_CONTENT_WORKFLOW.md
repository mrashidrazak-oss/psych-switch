# Clinical content workflow

This document explains how to add or update the clinical knowledge in
PsychSwitch ASEAN. The maintainer (Rashid Razak) is also the clinical
author for v0.1. No coding background is assumed in this document.

## What "clinical content" means here

All clinical knowledge in the app lives as plain JSON files under
`/content/`. Code never contains dose numbers, half-lives, or schedule
steps. This means:

- You can review the entire clinical knowledge base by reading text files.
- Updating a drug's profile is editing one JSON file — no code change
  required.
- The same JSON files drive what the app shows on screen.

There are two folders inside `/content/`:

```
/content/drugs/                  – one file per drug (e.g. sertraline.json)
/content/switching-rules/        – one file per from→to switch pair
```

## Reviewing existing content

1. Open the project folder in any editor.
2. Open the file you want to review (e.g. `content/drugs/sertraline.json`).
3. Every clinical field that has not been formally signed off is marked
   `PENDING_CLINICAL_REVIEW` in its `notes` text, and the file's
   `reviewedBy` field reads `"PENDING - Rashid Razak (clinical author)"`.
4. After review, edit `lastReviewedISO` to today's date (format
   `YYYY-MM-DD`) and `reviewedBy` to `"Dr. Rashid Razak, Consultant
   Psychiatrist"`. Remove the `PENDING_CLINICAL_REVIEW` markers from any
   text you've reviewed.

## Adding a new drug

1. Copy `content/drugs/sertraline.json` to a new file using the drug's
   lowercase generic name, e.g. `content/drugs/escitalopram.json`.
2. Replace every field with the new drug's data. Keep the same field
   structure — do not rename or remove fields.
3. Required fields:
   - `id` — lowercase generic name, no spaces.
   - `genericName` — clinical name (e.g. "Escitalopram").
   - `drugClass` — e.g. "SSRI", "SNRI", "NaSSA".
   - `malaysianBrandNames` — actual brands in Malaysian pharmacies.
   - `halfLife.meanHours` and `halfLife.rangeHours` — numeric, in hours.
   - `activeMetabolite` — set `clinicallySignificant` to `false` if the
     metabolite has no meaningful pharmacological effect.
   - `cypInteractions` — listing the CYP enzymes the drug is metabolised
     by and which it inhibits, plus a short note on switching relevance.
   - `maoiWashout` — days off before and after MAOI. Special case:
     fluoxetine is **5 weeks (35 days)**, not 14, due to norfluoxetine.
   - `discontinuationSyndromeRisk.score` — one of `low`, `moderate`,
     `high`, `very high`.
   - `dosing` — starting dose, typical target range, max dose, available
     formulations in Malaysia.
   - `citations` — at least one short reference key per claim.
4. Open `engine/switchingEngine.ts` and add an `import` line plus an
   entry in the `DRUGS` array. Rashid will do this part.
5. Save. Run `pnpm test` to confirm nothing breaks.

## Adding a new switching rule

1. Copy `content/switching-rules/sertraline-to-escitalopram.json` to a
   new file named `<from>-to-<to>.json`.
2. Set `fromDrugId` and `toDrugId` to the drug ids you used in step 1
   above.
3. Choose `strategy`:
   - `direct` — stop one, start the other the next day. Only safe when
     half-lives are similar and there is no MAOI involvement.
   - `cross-taper` — overlap with graded dose changes. Most common.
   - `washout` — full discontinuation before starting the new drug.
     Required for any switch involving an MAOI.
4. Fill `schedule` with day-by-day steps. Each step has:
   - `day` — day number, starting at 1.
   - `fromDoseMg` — dose of the original drug on that day.
   - `toDoseMg` — dose of the new drug on that day.
   - `notes` — short clinical note for that step.
5. Set `doseRatios.fromCurrentDoseMg` and `doseRatios.toTargetDoseMg`
   to the reference doses your schedule was built around. The engine
   will only return this schedule when the user requests an exact match.
6. List `safetyFlags` from this set:
   - `serotonin_syndrome_overlap_low`
   - `serotonin_syndrome_overlap_high`
   - `discontinuation_syndrome_high`
   - `anticholinergic_rebound`
   - `maoi_washout_required_14_day`
   - `maoi_washout_required_5_week`
   (Add new flag keys as you encounter them — keep them lowercase with
   underscores.)
7. **At least 2 citations are required** per switching rule. Use short
   reference keys, not full quotes. Examples:
   - `maudsley14_p339_swap_table`
   - `bap2015_switching_antidepressants`
   - `nice_ng222_treatment_resistant_depression`
   - DOIs, e.g. `doi_10.1177_0269881115581093`
8. Open `engine/switchingEngine.ts` and add an `import` line plus an
   entry in the `RULES` array. Rashid will do this part.
9. Save. Run `pnpm test`.

## Review checklist before signing off a rule

Before changing `reviewedBy` to your name and removing `PENDING_*`
markers, please confirm:

- [ ] Half-life and metabolite values match Maudsley 14th edition.
- [ ] MAOI washout requirements are correct in both directions.
- [ ] Discontinuation risk score reflects published evidence and clinical
      experience.
- [ ] The schedule's overlap window is safe given the half-lives of both
      drugs.
- [ ] Dose equivalency in `doseRatios.equivalencyNote` is consistent with
      a recognised reference.
- [ ] At least 2 citations are present.
- [ ] Brand names listed are actually available in Malaysian pharmacies.
- [ ] No copyrighted text from textbooks has been pasted into any field.
      Citations are reference keys only.

## Citation format

Use short opaque keys, not full text. The app will later map keys to full
reference strings in a separate, version-controlled file. Reproducing
copyrighted text inside `/content/` is forbidden.

Good: `"maudsley14_p339_swap_table"`
Good: `"doi_10.1177_0269881115581093"`
Bad: pasting two paragraphs from Maudsley.

## Who decides what

- **Clinical content (everything in `/content/`)**: Dr. Rashid Razak
  (Consultant Psychiatrist) is the clinical author and final reviewer.
- **App behaviour (engine logic, UI, navigation)**: Rashid maintains.
  Engine logic that affects clinical safety (e.g. dose-scaling rules,
  MAOI washout enforcement) is reviewed by him in his clinical capacity.
- **Anything ambiguous**: stop and ask. Clinical guesses kill the
  product.

## Versioning

Each JSON file carries `lastReviewedISO`. When a guideline changes (e.g.
new BAP recommendations), bump the date and update the affected fields.
The git history shows the diff so the change is reviewable.
