# PsychSwitch

> Reviewed cross-titration schedules, depot protocols, and clozapine
> monitoring — built for the bedside.

PsychSwitch is a privacy-first clinical decision-support app for
psychotropic medication switching. It produces evidence-graded,
adaptive, citation-backed schedules drawn from the Maudsley 15th
edition, BAP, NICE, FDA prescribing information, and the Malaysian
CPGs.

Built with **Flutter 3.27+** and a pure-Dart engine. Targets iOS and
Android from one codebase. **Local-first, no PHI ever leaves the
device unless the clinician explicitly taps Share.**

---

## What's inside

### Clinical engines (Dart, fully ported)
- **~95 reviewed switching rules** across antidepressants and oral
  antipsychotics (mood stabilisers + LAI rules are also registered;
  oral mood-stabiliser module is live, LAI cross-LAI rules currently
  gated from the picker pending more clinical research)
- **Adaptive schedule scaler** — proportional / fixed-step / no-scale,
  with formulation-aware rounding
- **Citation registry** with paraphrased Maudsley / BAP / NICE quotes
- **Evidence grading** (A → D) derived automatically from the strongest
  citation
- **PsychSwitch Score** — single 0–100 number summarising fit for the
  patient, with animated dial on Result
- **Predicted side-effect profile** with likelihood tiers, plus
  quantitative effect sizes from Leucht 2013 + Cipriani 2018 NMAs
- **Smart drug picker** — re-ranks targets by reviewed-rule existence,
  AE alignment, context safety, DDI severity
- **Dose equivalents** — chlorpromazine, fluoxetine, diazepam (with
  bedside calculator screen)
- **DDI checker** — serotonergic, CYP, QTc, anticholinergic,
  pharmacodynamic
- **Patient context engine** — age band, eGFR, hepatic, pregnancy,
  comorbidities → context-driven warnings
- **Specialty depth** — pregnancy / breastfeeding / pediatric /
  geriatric tier-ranked recommendations with dose modifiers
- **Monitoring schedule generator** with 90-day review cadence and
  on-device scheduled reminders (opt-in)
- **Discontinuation flagger** with bridge-to-fluoxetine for high-risk
  drugs
- **Cost data** — Malaysian formulary monthly cost in MYR with
  affordability tier
- **Clozapine module** — titration, FBC monitoring, ANC checker, rechallenge
- **Mood-stabiliser module** — lithium / VPA / LTG / CBZ profiles +
  Maudsley 15 Box 2.3 lithium taper screen
- **Depot LAI module** — Sustenna / Trinza / Maintena protocols
- **QTc stacker**, **adverse-effect lookup**, **errata feed**,
  **dose equivalency calculator**, **glossary**

### Workflow loop
- **Plain-text plan share** via the system share sheet (WhatsApp / SMS /
  email) — pure-Dart formatter, no patient identifiers
- **PDF export** — A4 portrait with brand header, dose-mapping callout,
  schedule table, monitoring checklist, citations, decision-support
  footer. Hands off to the OS print/share sheet via `printing`.
- **Patient counselling card** — collapsible plain-language handout on
  Result, copy + share

### Trust signals
- Per-step citation chips on the Result schedule
- Rule-provenance card with last-reviewed + next-review-due (90-day
  cadence) + an errata badge that taps through to the public errata
  feed
- Disclaimer gate on first launch — clinical surfaces are unreachable
  until the user acknowledges the decision-support framing

### Polish
- Tokenised design system (4-pt spacing grid, AppRadii, AppTextSizes,
  full ThemeData with sub-theme tree)
- Animated entrance staggers, fade-through page transitions, and
  reduced-motion compliance
- Haptic-feedback tiers (tap / confirm / warning) wired to clinical
  commits — confirm on Generate plan / Save case / Apply context,
  warning on RED ANC zone + delete-all
- Accessibility-correct semantics on every hero surface (composed
  VoiceOver labels for the score ring, drug-pair header, status pills)
- Branded PS monogram launcher icon + native cold-start splash (no
  white flash)

---

## Repo layout

```
/flutter_app/                  – the Flutter app (entry point)
   ├── lib/src/
   │   ├── ui/screens/         – one file per screen (Home, Switch,
   │   │                         Result, Clozapine, Depot, Mood
   │   │                         stabilisers, Lithium taper, QTc,
   │   │                         Errata, AE lookup, Equivalency,
   │   │                         Glossary, Settings, About,
   │   │                         Disclaimer, History)
   │   ├── ui/widgets/         – reusable widgets (StatusPill,
   │   │                         EntranceFade, ScoreRing,
   │   │                         CrossoverChart, all the Result cards)
   │   ├── ui/theme/           – tokens.dart + app_theme.dart
   │   ├── providers/          – Riverpod scope (engine, prefs,
   │   │                         saved cases, patient context,
   │   │                         disclaimer, qtc, lithium-tapering)
   │   ├── services/           – notification_service.dart
   │   ├── util/               – format_counselling, share_plan,
   │   │                         export_pdf
   │   ├── data/               – content_loader, drift database
   │   ├── observability/      – sentry_init
   │   └── router.dart         – go_router config (fade-through pages)
   ├── test/                   – unit + widget tests (606+ passing)
   └── tool/bundle_content.dart – build-time JSON bundler
/psychswitch_engine/           – pure-Dart clinical engine
   ├── lib/src/
   │   ├── switching_engine.dart    – plan generation
   │   ├── scale_schedule.dart      – adaptive rounding
   │   ├── monitoring.dart          – per-drug monitoring schedules
   │   ├── ddi.dart                 – overlap-window interactions
   │   ├── adverse_effects.dart     – AE registry + reverse lookup
   │   ├── citations.dart           – citation registry + evidence
   │   │                              grading
   │   ├── psych_switch_score.dart  – composite 0-100 score
   │   ├── predicted_ae_profile.dart– AE prediction
   │   ├── quantitative_ae.dart     – effect-size table (Leucht /
   │   │                              Cipriani)
   │   ├── patient_context_pure.dart– context warnings
   │   ├── smart_picker.dart        – relevance ranking
   │   ├── case_pulse.dart          – saved case + monitoring pulse
   │   ├── glossary.dart            – clinical-term reference
   │   ├── errata.dart              – append-only audit trail
   │   ├── clozapine.dart           – titration + FBC + rechallenge
   │   ├── qtc_stacker.dart         – QTc additive risk
   │   ├── dose_equivalents.dart    – CPZ/FLX/DZP equivalents
   │   ├── cost_data.dart           – Malaysian formulary cost
   │   ├── discontinuation.dart     – stop-syndrome flags
   │   ├── mood_stabilizer_tapering.dart – Maudsley 15 Box 2.3
   │   ├── specialty.dart           – pregnancy / breastfeeding /
   │   │                              pediatric / geriatric
   │   └── maudsley15.dart          – class-level fallback matrix
   └── test/                   – engine unit tests
/psychswitch_mcp/              – Dart MCP server (drop-in replacement
                                  for the retired Node implementation;
                                  18 tools, JSON-RPC over stdio)
/content/                      – CLINICAL CONTENT (the actual product)
   ├── drugs/                  – one JSON per drug
   ├── switching-rules/        – one JSON per from→to pair
   ├── clozapine/              – clozapine-specific protocols
   ├── mood-stabilizers/       – mood-stabiliser profiles + lithium
   │                             taper
   ├── maudsley15/             – Maudsley fallback strategies
   ├── qtc/                    – QTc stacker data
   └── ramadan/                – Ramadan mode data (UI WIP)
/test/golden/                  – cross-engine golden fixtures consumed
                                 by both the Dart and (now retired) TS
                                 test runners
/assets/                       – brand source SVGs + Play Store
                                 listing materials
/docs/                         – content schema, brand kit, build
                                 notes, migration audit
/secrets/                      – local-only env / signing keys
                                 (gitignored)
```

The `/content/` folder is the source of truth for clinical data. Code
never hardcodes dose values; engines reference content via the
build-time bundler at `flutter_app/tool/bundle_content.dart`, which
emits `flutter_app/assets/content_bundle.json` consumed at runtime.

---

## Quick start

```bash
cd ~/Desktop/psych-switch/flutter_app
flutter pub get
flutter run                # connected device or simulator
```

The app's home screen has a "Start a switch" CTA that walks you
through the 4-step picker.

### Verify
```bash
cd flutter_app
flutter analyze            # static analysis (very_good_analysis lints)
flutter test               # 606+ unit + widget tests (~10 s)
```

### Build
```bash
flutter build apk --debug          # debug APK for testing
flutter build apk --release        # release APK for distribution
flutter build appbundle --release  # AAB for the Play Store
```

### Bundle clinical content
The content bundle is rebuilt automatically as part of the Flutter
asset pipeline. To rebuild manually:
```bash
cd flutter_app
dart run tool/bundle_content.dart
```

---

## Privacy

- **Local-first**: patient context, saved cases, preferences all
  stored on the device (drift SQLite + SharedPreferences).
- **No tracking**: no analytics, no telemetry, no usage events sent
  off-device.
- **Notifications**: monitoring reminders fire as local notifications
  only — never via remote push, never with patient identifiers.
- **Crash reporting**: Sentry hook is plumbed via `SENTRY_DSN`
  build-time variable. Disabled by default.
- **Patient-identifying data**: never collected, never transmitted.
  The app explicitly forbids it in the Save dialog copy.
- **Errata reports** include only rule ID, app version, and reviewer
  attribution. No patient context or dose inputs.

The Disclaimer screen on first launch acknowledges the decision-support
framing — the app refuses to show clinical surfaces until the user
taps "I am a healthcare professional".

---

## Contributing

The clinical content (`/content/`) is open under
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
The app source is MIT-licensed. See [CONTRIBUTING.md](./CONTRIBUTING.md)
for the workflow on submitting rule corrections, new drug profiles, or
translations.

To report a clinical issue with a specific rule, email the address in
the in-app About screen. Errata are publicly logged in the in-app
Errata feed (open-by-default trust signal).

---

## Common operations

### Add a new drug
1. Create `content/drugs/<id>.json` matching the schema in
   `psychswitch_engine/lib/src/types/drug.dart` (`Drug` class).
2. Run `dart run tool/bundle_content.dart` from `flutter_app/`.
3. Add a roundtrip test in
   `flutter_app/test/engine/types/drug_roundtrip_test.dart`.
4. See [docs/CONTENT_SCHEMA.md](./docs/CONTENT_SCHEMA.md) for full
   field reference.

### Add a new switching rule
1. Create `content/switching-rules/<from>-to-<to>.json`.
2. Re-bundle (above).
3. Test the pair in the app (run the switch, verify the schedule).

### Add a glossary term
Edit `psychswitch_engine/lib/src/glossary.dart` — entries are inline.
The Glossary screen picks them up automatically.

### Bump the version
Edit `flutter_app/pubspec.yaml` (`version:`) and add an entry to
`docs/POST_FLUTTER_DEBT.md` (or future changelog).

---

## Migration history

This codebase started as a React Native + Expo SDK 54 project. The
Flutter migration ran through Phases 0–8:

- **Phases 1–3** — engine extraction to a pure-Dart package
  (`psychswitch_engine/`), content bundler, golden-file harness
- **Phase 4** — UI build (Home, Switch, Result, Clozapine, Depot,
  Mood stabilisers) + design-system polish
- **Phase 5** — saved cases (drift SQLite), Today's Pulse, history
- **Phase 6** — Dart MCP server (`psychswitch_mcp/`), drop-in
  replacement for the Node version
- **Phase 7** — remaining surfaces (Glossary, Settings, About,
  Patient context sheet)
- **Phase 8 — cutover** (this commit). React Native side retired:
  `App.tsx`, `screens/`, `components/`, `engine/` (TS), `utils/` (TS),
  `mcp-server/` (Node) all deleted along with their build configs and
  `node_modules`. Repo is now Flutter + Dart only.

---

## License

App source: **MIT**. Clinical content: **CC BY-NC-SA 4.0**. See
[LICENSE](./LICENSE) for details.

The app is decision-support reference material for qualified
clinicians. It is not medical advice. Always cross-check against the
primary source before acting on any plan.
