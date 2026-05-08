# Clinical content schema

The `/content/` folder is the source of truth for all clinical data.
Files are plain JSON — no JS, no logic. Every JSON conforms to a
TypeScript type defined in `engine/types.ts`.

This document is the field-by-field reference for content authors.

---

## Drug profile (`content/drugs/<id>.json`)

Schema source: `Drug` interface in `engine/types.ts`.

```jsonc
{
  "id": "olanzapine",                          // kebab-case, must be unique
  "genericName": "Olanzapine",                 // Title Case
  "drugClass": "SGA (atypical antipsychotic)", // free-form, used for grouping
  "category": "antipsychotic",                 // antidepressant | antipsychotic | mood-stabilizer

  "hidden": false,                             // optional; true keeps it out of pickers

  "isMAOI": false,                             // antidepressant-only; triggers washout logic
  "maoiClearanceDays": 0,                      // days off before another serotonergic agent

  "malaysianBrandNames": ["Zyprexa", "Zypine"],

  "halfLife": {
    "meanHours": 33,
    "rangeHours": [21, 54],
    "notes": "Mean t½ varies by smoking status..."
  },
  "activeMetabolite": {
    "name": null,
    "halfLifeHours": null,
    "clinicallySignificant": false,
    "notes": "..."
  },
  "cypInteractions": {
    "substrateOf": ["CYP1A2"],
    "inhibitorOf": [],
    "switchingRelevance": "Smoking induces CYP1A2..."
  },

  // Per-drug risk fields — feed the predicted-AE engine + smart picker.
  // All are 'low' | 'moderate' | 'high' | 'very high'.
  "epsRisk": "low",
  "metabolicRisk": { "score": "very high", "notes": "Highest weight gain..." },
  "prolactinRisk": "low",
  "qtcRisk": "low",
  "sedation": "high",

  "lai": { "available": false, "notes": "..." },
  "formulation": "oral",                       // oral | lai

  "reboundPsychosisRisk": { "score": "moderate", "notes": "..." },

  "discontinuationSyndromeRisk": {             // antidepressant-only typically
    "score": "low",
    "notes": "..."
  },

  "dosing": {
    "startingDoseMg": 5,
    "typicalTargetRangeMg": [10, 20],
    "maxDoseMg": 20,
    "increments": [2.5, 5, 7.5, 10, 15, 20],   // formulations available
    "formulationsAvailableMy": ["2.5 mg tab", "5 mg tab", "10 mg tab"]
  },

  "formulationNotes": "Tablets only in MY...",

  "citations": [                               // citation registry keys
    "maudsley15_schizophrenia_olanzapine_profile",
    "leucht2013_lancet_metaanalysis"
  ],
  "lastReviewedISO": "2026-04-15",
  "reviewedBy": "Dr R Razak, MMC 12345"
}
```

### Required vs optional fields

| Field | Required | Notes |
|-------|----------|-------|
| `id`, `genericName`, `drugClass`, `halfLife`, `dosing` | Required | engine breaks without these |
| `category` | Strongly recommended | defaults to `antidepressant` for legacy compat |
| `cypInteractions` | Required | use empty arrays if unknown |
| `epsRisk`, `prolactinRisk`, `qtcRisk`, `sedation`, `metabolicRisk` | Antipsychotic-only | omit for ADs |
| `discontinuationSyndromeRisk` | Antidepressant-only | omit for AP |
| `reboundPsychosisRisk` | Antipsychotic-only | omit for AD |
| `isMAOI`, `maoiClearanceDays` | Antidepressant-only | omit unless MAOI |
| `lai`, `formulation`, `laiDetails` | LAI-specific | omit for oral |

---

## Switching rule (`content/switching-rules/<from>-to-<to>.json`)

Schema source: `SwitchingRule` interface in `engine/types.ts`.

```jsonc
{
  "id": "olanzapine-to-aripiprazole",          // <from>-to-<to> kebab-case
  "fromDrugId": "olanzapine",
  "toDrugId": "aripiprazole",

  "strategy": "plateau-cross-taper",           // direct | cross-taper | plateau-cross-taper | washout
  "rationale": "Olanzapine to aripiprazole...", // 1-3 paragraphs of clinical reasoning

  "durationDays": 28,

  // Optional: 'proportional' (default) | 'fixed-step' | 'no-scale'
  // LAI rules auto-detect to no-scale via fromDrug/toDrug.formulation.
  "scalingMode": "proportional",

  "schedule": [
    {
      "day": 1,
      "fromDoseMg": 20,
      "toDoseMg": 5,
      "notes": "Continue olanzapine 20 mg. Start aripiprazole 5 mg.",
      "citations": []                          // optional per-step citations
    },
    {
      "day": 7,
      "fromDoseMg": 15,
      "toDoseMg": 10,
      "notes": "Reduce olanzapine to 15 mg, increase aripiprazole to 10 mg."
    },
    // ...
    {
      "day": 28,
      "fromDoseMg": 0,
      "toDoseMg": 15,
      "notes": "Stop olanzapine."
    }
  ],

  "doseRatios": {
    "fromCurrentDoseMg": 20,                   // reference dose the schedule was reviewed for
    "toTargetDoseMg": 15,
    "equivalencyNote": "Olanzapine 20 mg ≈ aripiprazole 15 mg per Maudsley table 4.1."
  },

  "safetyFlags": [                             // keys from utils/safetyFlags.ts
    "metabolic_monitoring_required",
    "akathisia_risk_aripiprazole"
  ],

  "citations": [                               // citation registry keys
    "maudsley15_schizophrenia_aripiprazole_profile",
    "bap2020_psychosis_switching"
  ],

  "contraindications": [],                     // free-form notes

  "lastReviewedISO": "2026-04-15",
  "reviewedBy": "Dr R Razak, MMC 12345"
}
```

### Strategy values

- **`direct`** — stop A, start B same day. ~1–2 days.
- **`cross-taper`** — overlap A taper-down with B titration. The default
  for AD↔AD and most AP switches.
- **`plateau-cross-taper`** — hold A at therapeutic dose for 1–2 weeks
  while B titrates up, then taper A. Used when switching to a partial
  agonist (aripiprazole) to mitigate early relapse.
- **`washout`** — pharmacokinetic-defined gap. MAOI washouts only.

### Scaling modes

- **`proportional`** *(default)* — multiply each step by user/reference
  ratio, round to formulation, cap at max, merge duplicates.
- **`fixed-step`** — preserve the reviewed mg-decrement-per-step,
  adapt the *number* of steps. Right for lithium-style absolute tapers.
- **`no-scale`** — return the reviewed schedule untouched. Auto-applied
  for LAI rules.

### Schedule conventions

- Day numbering starts at **1** (not 0). Day 1 is the first day of the
  switch.
- `fromDoseMg: 0` means "stop the from-drug". The UI renders this as
  "stop" / strikethrough.
- `toDoseMg: 0` in step 1 means "to-drug not yet started".
- The final step typically has `fromDoseMg: 0` (taper complete) and
  `toDoseMg: <userToDose>` (target reached).
- All numeric doses must be valid increments per the drug's
  `dosing.increments` array. The scaler enforces this on adapted
  schedules; reviewed schedules should already comply.

---

## Citation registry keys

Defined in `engine/citations.ts`. Each rule references citations by
opaque string key:

- `maudsley15_*` — anything from Maudsley 15th edition. Pattern-resolves
  to grade A automatically.
- `bap2020_*`, `bap2015_*`, `bap2016_*` — BAP guidelines. Grade A.
- `nice*` — NICE guideline. Grade A.
- `cpg*` — Malaysian CPG. Grade A.
- `leucht*`, `cipriani*`, `hayasaka*` — IPD meta-analyses. Grade A.
- `horowitz*` — Horowitz & Taylor papers. Grade B.
- `ashton*` — Ashton manual. Grade B.
- `invega_*`, `abilify_*`, `sustenna_*`, `maintena_*`, `trinza_*` —
  manufacturer PIs. Grade A (regulatory).

For a curated key (with a paraphrased quote), add an entry to the
`CURATED` map in `engine/citations.ts`. For an uncurated key, the
pattern resolver gives it a generic reference — still functional, but
no quote preview.

---

## Safety-flag keys

Defined in `utils/safetyFlags.ts`. When a rule lists a key, the engine
renders the corresponding `SafetyFlag` card on the Result screen.
Common keys:

| Key | Severity | Purpose |
|-----|----------|---------|
| `metabolic_monitoring_required` | warning | Triggers BMI + HbA1c + lipids monitoring |
| `qtc_monitoring_required` | warning | Triggers ECG monitoring chip |
| `eps_risk_increase` | info | Heads-up about parkinsonism |
| `prolactin_elevation` | info | Heads-up about hyperprolactinaemia |
| `lithium_narrow_therapeutic_index` | warning | Tighter monitoring schedule |
| `serotonin_syndrome_overlap_high` | warning | Triggers SS counselling |
| `depot_washout_long` | info | Long depot tail caveat |

See `utils/safetyFlags.ts` for the full list and tints.

---

## Validation checklist (pre-PR)

- [ ] All numeric doses are present in `drug.dosing.increments` arrays
- [ ] `lastReviewedISO` is today (or earlier — never future)
- [ ] `reviewedBy` is a real attribution, not "PENDING"
- [ ] At least one citation key is present
- [ ] Tests pass: `pnpm test`
- [ ] Typecheck clean: `pnpm typecheck`
- [ ] Manual UI test of the new rule passes
