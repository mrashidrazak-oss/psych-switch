# PsychSwitch

> Reviewed cross-titration schedules, depot protocols, and clozapine
> monitoring — built for the bedside.

PsychSwitch is a privacy-first clinical decision-support app for
psychotropic medication switching. It produces evidence-graded,
adaptive, citation-backed schedules drawn from the Maudsley 15th
edition, BAP, NICE, FDA prescribing information, and the Malaysian
CPGs.

Built with React Native + Expo. Targets iOS and Android from one
codebase. **Local-first, no PHI ever leaves the device unless the
clinician explicitly taps Share.**

[![verify](https://github.com/mrashidrazak-oss/psych-switch/actions/workflows/verify.yml/badge.svg)](https://github.com/mrashidrazak-oss/psych-switch/actions/workflows/verify.yml)
[![tests](https://img.shields.io/badge/tests-302%20passing-brightgreen)]()
[![mcp-smoke](https://img.shields.io/badge/MCP%20smoke-24%2F24-brightgreen)]()
[![evidence](https://img.shields.io/badge/evidence-A%20%E2%87%A2%20D-blue)]()

---

## What's inside

### Clinical engines
- **~95 reviewed switching rules** across antidepressants and oral
  antipsychotics (mood stabilizers + LAI rules are registered in the
  engine but currently gated from the patient picker pending more
  clinical research — see v0.4.15 changelog)
- **Adaptive schedule scaler** — proportional / fixed-step / no-scale,
  with formulation-aware rounding
- **Citation registry** with paraphrased Maudsley / BAP / NICE quotes
- **Evidence grading** (A → D) derived automatically from the strongest
  citation
- **PsychSwitch Score** — single 0–100 number summarising fit for the
  patient
- **Overlap intensity tier** — low / moderate / high / severe with
  mechanism-stacking flags + Conservative-mode transform
- **Predicted side-effect profile** with likelihood tiers, plus
  quantitative effect sizes from Leucht 2013 + Cipriani 2018 NMAs
- **Smart drug picker** — re-ranks targets by reviewed-rule existence,
  AE alignment, context safety, DDI severity
- **Dose equivalents** — chlorpromazine, fluoxetine, diazepam
- **DDI checker** — serotonergic, CYP, QTc, anticholinergic,
  pharmacodynamic
- **Patient context engine** — age band, eGFR, hepatic, pregnancy,
  comorbidities → context-driven warnings
- **Specialty depth** — pregnancy / breastfeeding / pediatric /
  geriatric tier-ranked recommendations with dose modifiers
- **Monitoring schedule generator** with 90-day review cadence
- **Pharmacokinetic overlay** with predicted effective levels
- **Receptor-occupancy curves** for hyperbolic-taper reasoning
- **Discontinuation flagger** with bridge-to-fluoxetine for high-risk
  drugs
- **Cost data** — Malaysian formulary monthly cost in MYR with
  affordability tier
- **Clozapine module** — titration, FBC monitoring, ANC checker, rechallenge
- **QTc stacker**, **Ramadan mode**, **case manager**, **glossary**,
  **adverse-effect lookup**, **errata feed**

### Workflow loop
- Discharge summary block (EMR-paste-ready)
- Patient counselling card (plain language)
- Real PDF export via `expo-print`

### Trust signals
- Per-step citation chips
- Rule provenance card with last-reviewed + next-review-due
- Report-an-issue mailto with templated context
- Privacy + Terms screens

### Polish
- Haptic feedback wired to key CTAs
- 4-card onboarding tour
- Clinical-term glossary (23 entries) inline + standalone
- Unified design primitives — Chip, Banner, SegmentedControl, SwitchRow
- Codified typography scale (eyebrow / micro / caption / body /
  subtitle / title / heading / display)
- Error boundary with crash-reporter hook (Sentry stub for now —
  reactivates with custom dev build)

---

## Quick start

```bash
cd ~/Desktop/psych-switch
pnpm install
pnpm start            # opens Expo Go QR
```

Scan from Expo Go on your device. The app's home screen has a
"Start a switch" CTA that walks you through the 4-step picker.

### Verify
```bash
pnpm verify        # typecheck + 302 jest + 24 MCP smoke (~30s)
pnpm preflight     # verify + expo-doctor (run before any production build)
```

### Run on simulator / device
```bash
pnpm ios           # iOS simulator (Mac only, needs Xcode)
pnpm android       # Connected Android device via adb
```

---

## Architecture

```
/App.tsx                        – entry point, navigation, disclaimer + onboarding gates
/screens/                       – one file per screen (Home, Switch, Result, …)
/components/                    – reusable UI pieces
/engine/                        – pure clinical logic
   ├── switchingEngine.ts       – plan generation
   ├── scaleSchedule.ts         – adaptive rounding
   ├── monitoring.ts            – per-drug monitoring schedules
   ├── ddi.ts                   – overlap-window interactions
   ├── adverseEffects.ts        – AE registry + reverse lookup
   ├── citations.ts             – citation registry + evidence grading
   ├── psychSwitchScore.ts      – composite 0-100 score
   ├── predictedAeProfile.ts    – AE prediction
   ├── pkSimulation.ts          – one-compartment exponential model
   ├── patientContext.ts        – context warnings + register
   ├── smartPicker.ts           – relevance ranking
   ├── search.ts                – cross-content search
   ├── caseManager.ts           – local saved cases
   ├── glossary.ts              – clinical-term reference
   ├── settings.ts              – app-wide preferences
   ├── changelog.ts             – versioned change log
   └── __tests__/               – engine unit tests
/content/                       – CLINICAL CONTENT (the actual product)
   ├── drugs/                   – one JSON per drug
   ├── switching-rules/         – one JSON per from→to pair
   ├── clozapine/               – clozapine-specific protocols
   ├── mood-stabilizers/        – mood stabilizer profiles
   ├── maudsley15/              – Maudsley fallback strategies
   ├── qtc/                     – QTc stacker data
   └── ramadan/                 – Ramadan mode data
/utils/                         – shared types + helpers
```

The `/content/` folder is the source of truth for clinical data. Code
never hardcodes dose values; engines reference content via the
`engine/switchingEngine.ts` registry.

---

## Privacy

- **Local-first**: patient context, saved cases, sign-offs all stored
  in AsyncStorage on the device.
- **No tracking**: no analytics, no telemetry, no usage events sent
  off-device.
- **Crash reporting**: Sentry hook is plumbed but ships disabled. User
  must opt in via Settings → Privacy.
- **Patient-identifying data**: never collected, never transmitted. The
  app explicitly forbids it in the UI.
- **Errata reports** include only rule ID, app version, and reviewer
  attribution. No patient context or dose inputs.

See `screens/PrivacyScreen.tsx` for the full policy text shown in-app.

---

## Contributing

The clinical content (`/content/`) is open under
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
The app source is MIT-licensed. See [CONTRIBUTING.md](./CONTRIBUTING.md)
for the workflow on submitting rule corrections, new drug profiles, or
translations.

To report a clinical issue with a specific rule, use the in-app
"Report an issue" button on any Result screen — it opens a templated
email with the rule ID + app version pre-filled.

---

## Common operations

### Add a new drug
1. Create `content/drugs/<id>.json` matching the schema in
   `engine/types.ts` (`Drug` interface).
2. Register it in `engine/switchingEngine.ts`'s drug array.
3. Add a unit test asserting it loads.
4. See [docs/CONTENT_SCHEMA.md](./docs/CONTENT_SCHEMA.md) for full
   field reference.

### Add a new switching rule
1. Create `content/switching-rules/<from>-to-<to>.json`.
2. Register it in `engine/switchingEngine.ts`'s rule array.
3. Test the pair in the UI (run the switch, verify the schedule).

### Add a glossary term
Edit `engine/glossary.ts` — entries are inline. The `<GlossaryTerm/>`
component picks them up automatically.

### Bump the version
Edit `app.json` (`expo.version`) and add a top-of-list entry to
`engine/changelog.ts`. The in-app "What's new" screen reflects it
automatically.

---

## Roadmap

- ✅ **v0.4.5** — MCP server (queryable engine for EMR + AI
  assistants) — 18 tools live, 24/24 smoke
- ✅ **v0.4.20** — New brand mark (two crossing taper curves)
- ✅ **v0.4.22** — Production-ready EAS build pipeline
- ✅ **v0.4.23** — Renamed PsychSwitch ASEAN → PsychSwitch (scope
  narrowed to Malaysia)
- 🟡 **v0.5.0** — Play Store internal track launch (account
  registered, awaiting verification)
- 🔵 **v0.5.x** — Mood-stabilizer + LAI un-gating once content review
  completes
- 🔵 **v0.5.x** — Bahasa Malaysia translation
- 🔵 **v0.6** — TestFlight (iOS) launch
- 🔵 **v0.7** — CME accreditation partnership

---

## License

App source: **MIT**. Clinical content: **CC BY-NC-SA 4.0**. See
[LICENSE](./LICENSE) for details.

The app is decision-support reference material for qualified
clinicians. It is not medical advice. Always cross-check against the
primary source before acting on any plan.
