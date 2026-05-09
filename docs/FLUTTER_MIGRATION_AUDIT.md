# Flutter migration audit — Phase 0.1

**Status:** complete · **Conducted:** at v0.4.23 commit `7904bd1`

## TL;DR

- **33 TypeScript files** in `/engine/`, **7,694 LOC** total.
- **29 files (90%) are pure** — translate to Dart line-by-line with no
  architectural surgery.
- **4 files (10%) mix pure logic with framework integration** (React
  hooks + AsyncStorage + Expo modules). They need restructuring during
  the port, not significant logic changes.
- **No engine file blocks the migration.** Every concern has a clean
  Dart equivalent.

---

## Method

```bash
# Flag files importing non-portable dependencies:
grep -lE "from ['\"](react|react-native|expo-|@react-native|@react-navigation)" engine/*.ts
grep -lE "AsyncStorage" engine/*.ts
grep -lE "\\buse(State|Effect|Memo|Callback|Ref|Context|Reducer)\\b" engine/*.ts
```

Anything flagged got read in detail. Anything not flagged is pure-by-grep.

---

## File-by-file status

### ✅ Clean (29 files — port mechanically)

These have zero React, React Native, Expo, or AsyncStorage imports.
They consume only `./types` and standard library. Port to Dart 1:1.

| File | LOC | Role |
|---|---|---|
| `types.ts` | — | Domain types (Drug, SwitchingRule, ScheduleStep, etc.) |
| `switchingEngine.ts` | — | Rule registry + plan generator (the heart) |
| `scaleSchedule.ts` | — | Adaptive dose scaler |
| `psychSwitchScore.ts` | — | 0-100 composite score |
| `overlapIntensity.ts` | — | Day-1 overlap tier + score |
| `predictedAeProfile.ts` | — | AE likelihood prediction |
| `quantitativeAe.ts` | — | Leucht 2013 + Cipriani 2018 effect sizes |
| `specialty.ts` | — | Pregnancy/pediatric/geriatric matrix |
| `monitoring.ts` | — | Monitoring schedule generator |
| `ddi.ts` | — | DDI checker |
| `clozapine.ts` | — | Titration + ANC logic |
| `depotLai.ts` | — | Sustenna/Maintena/Trinza data |
| `moodStabilizerTapering.ts` | — | Lithium taper |
| `taperSpeed.ts` | — | Speed compression logic |
| `smartPicker.ts` | — | Drug relevance ranking |
| `pkSimulation.ts` | — | One-compartment exponential model |
| `qtcStacker.ts` | — | Cumulative QTc |
| `doseEquivalents.ts` | — | CPZ-eq, FLX-eq, DZP-eq |
| `glossary.ts` | — | Term registry |
| `adverseEffects.ts` | — | AE registry + reverse lookup |
| `costData.ts` | — | Malaysian formulary cost |
| `discontinuation.ts` | — | DC syndrome flagger |
| `errata.ts` | — | Errata feed |
| `casePulse.ts` | — | Saved-case proactive reminders |
| `maudsley15.ts` | — | Maudsley 15th fallback strategies |
| `citations.ts` | — | Citation registry + grading |
| `patientContextPure.ts` | 248 | Patient context types + warning rules (already split) |
| `changelog.ts` | — | Versioned changelog |
| `search.ts` | — | Cross-content search (uses listAllDrugs, listRules, getDrug — all pure) |

### ⚠️ Mixed (4 files — restructure during port)

Each has a clear pure-logic core wrapped in a React/AsyncStorage shell.
The pure core translates 1:1; the shell gets re-implemented in Dart
idioms (Riverpod + shared_preferences + flutter_local_notifications).

#### `patientContext.ts` (74 LOC) — split already prepared

```
Imports:
  - AsyncStorage  ← framework
  - useEffect, useState  ← React
  - re-exports from patientContextPure  ← pure
```

Already the cleanest of the four. Pure logic lives in
`patientContextPure.ts` (248 LOC). This file is just the React hook
wrapper.

**Dart port:**
- Port `patientContextPure.ts` → `patient_context.dart` (pure)
- Replace React hook with Riverpod `AsyncNotifierProvider`
- Replace AsyncStorage with `shared_preferences`
- ~30 LOC Dart for the provider; the pure file ports as ~250 LOC

#### `settings.ts` (99 LOC)

```
Imports:
  - AsyncStorage
  - useEffect, useState
```

Mixed: type definitions + DEFAULT_SETTINGS + getSettingsSync (pure-ish
with module-level cache) + useSettings hook (impure).

**Dart port:**
- Type definitions + DEFAULT_SETTINGS port directly as a `freezed`
  class
- `getSettingsSync` becomes a synchronous read of the cached Riverpod
  state
- `useSettings` becomes a Riverpod `NotifierProvider`
- AsyncStorage swaps for `shared_preferences`

#### `caseManager.ts` (103 LOC)

```
Imports:
  - AsyncStorage
  - useEffect, useState
```

Pure surface (saveCase, deleteCase, toggleFavourite all return
Promises with no React entanglement) + a useCases hook for
list-watching.

**Dart port:**
- Storage swaps from AsyncStorage to **drift** (SQLite). Cases
  benefit from queryability for the audit-export feature; key-value
  is the wrong shape.
- Functions become methods on a `CaseRepository` class
- `useCases` becomes a Riverpod `StreamProvider` watching the drift
  table

#### `notifications.ts` (259 LOC) — biggest port

```
Imports:
  - AsyncStorage
  - expo-constants
  - expo-notifications
  - react-native (Platform)
```

The most framework-coupled file. Heavy expo-notifications usage:
permission requests, local notification scheduling, channel setup
(Android), foreground handler config.

**Dart port:**
- expo-notifications → `flutter_local_notifications` (very similar
  API, mature plugin)
- expo-constants check (`IS_EXPO_GO`) → drop entirely (Flutter has no
  Expo Go equivalent; we're always in a custom build)
- Channel setup is more explicit in `flutter_local_notifications`
  (good — forces us to think about importance levels per channel)
- Platform.OS swap → `defaultTargetPlatform` from `flutter/foundation`
- Same 259 LOC roughly translates to ~280 LOC Dart

The pure data shapes (`CaseSchedule`, `ScheduleOptions`) port directly.

---

## What doesn't carry over from `/engine/`

Nothing. **All 33 files have a Dart implementation path with no architectural blockers.**

The 4 mixed files just need their framework shell replaced with Dart-idiomatic equivalents. The pure logic in all 33 files translates by mechanical line-by-line porting. Functions stay functions; types stay types; rules stay rules.

---

## What this means for Phase 2 (engine port)

Order of work:

1. **Pure files first** (week 1): port the 29 clean files in dependency
   order (leaves to composers). Each gets its mirrored test file.
   Golden-file harness validates output identity with the TS engine.

2. **Mixed files second** (week 2): port `patientContextPure` into the
   pure section first (there's no dependency on its React shell from
   any other engine module). Then port the 4 mixed files, one per
   day, restructuring each into a Riverpod-friendly shape:
   - `caseManager.dart` + `case_repository.dart` (drift)
   - `settings.dart` + `settings_provider.dart` (Riverpod + shared_prefs)
   - `patient_context.dart` + `patient_context_provider.dart` (Riverpod + shared_prefs)
   - `notifications.dart` (flutter_local_notifications)

3. **Tests at every step.** Every TS test file gets a Dart equivalent.
   No file is "done" until its tests pass AND the golden harness
   confirms output identity.

---

## What I need you to verify

Two things this audit can't catch automatically:

### 1. JSON content schemas
The audit only checks `/engine/*.ts`. The `/content/` JSON files (drugs, switching rules, citations, errata, glossary) need their schemas formally documented in Phase 1 so we can codegen Dart classes from them. Plan: extract the JSON schemas from the existing TS types in `engine/types.ts`. Already mostly trivial; the types file is well-disciplined.

### 2. Edge cases in casePulse.ts
`casePulse.ts` is marked clean but it consumes saved cases (which currently come from AsyncStorage via `caseManager`). Need to verify it accepts cases as a parameter rather than reading storage directly. Quick read confirms: yes, it takes `cases: SavedCase[]` as input and returns proactive `Pulse[]`. Pure. Confirmed.

---

## Risk assessment

**Low risk.** The engine's pure-functional discipline (established back in v0.3 when we split `patientContextPure`) means the port is a mechanical exercise, not an architectural one.

The MCP server already imports from `/engine/` for Node consumption, which exercised the purity boundary back then. Anything not pure was caught and refactored when MCP came online. The audit confirms that work held up.

**The migration is unblocked.** Phase 0.1 complete.
