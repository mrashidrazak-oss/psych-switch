# Golden-file engine harness

The contract that prevents engine drift between the TypeScript engine
(`/engine/`, used by the v0.4.x React Native app + the MCP server) and
the Dart engine (`/flutter_app/lib/src/engine/`, used by the v0.5.0+
Flutter app).

## How it works

Each `fixtures/*.json` file is a deterministic input scenario:

```json
{
  "name": "olanzapine 20mg → aripiprazole 15mg, no context",
  "engine": "generateSwitchPlan",
  "input": {
    "fromDrugId": "olanzapine",
    "fromDoseMg": 20,
    "toDrugId": "aripiprazole",
    "toDoseMg": 15
  }
}
```

For each fixture, both engine implementations run the named function
against `input`, and their output JSON is compared byte-for-byte against
a captured `snapshots/<fixture-name>.json` snapshot.

If the two engines produce different output, both test suites fail —
that's the safety net.

## Workflow

### Adding a new fixture
1. Create `fixtures/<short-name>.json` with `name`, `engine`, `input`.
2. Run `pnpm test:golden:capture` — captures the TS engine's output
   to `snapshots/<short-name>.json`. Review the snapshot diff before
   committing — this is your chance to catch unintended behavior.
3. Run `pnpm test:golden` (and once Phase 2 lands, `flutter test
   test/golden/`) to verify both engines produce the captured snapshot.

### Detecting unintended drift
Default CI runs `pnpm test:golden` and `flutter test test/golden/`.
If either fails, the engine produced output that diverged from the
snapshot. Investigate before committing.

### Intentional engine changes
If you intentionally change engine logic (e.g. a clinical correction
to the scaler), the snapshot must update too:
1. Make the engine change.
2. Run `pnpm test:golden:capture` to refresh affected snapshots.
3. Inspect the diff carefully. Each changed snapshot should be a
   conscious clinical decision.
4. Commit code + snapshot together. PR reviewer sees both.

## Supported engine functions

For Phase 1, only `generateSwitchPlan` is wired. As Phase 2 ports more
engine modules, this list grows:

| Engine function | Phase | TS side | Dart side |
|---|---|---|---|
| `generateSwitchPlan` | 1C | ✅ | (placeholder until Phase 2) |
| `scaleSchedule` | 2 | TODO | TODO |
| `assessOverlapIntensity` | 2 | TODO | TODO |
| `computePsychSwitchScore` | 2 | TODO | TODO |
| `predictAeProfile` | 2 | TODO | TODO |
| `generateMonitoringPlan` | 2 | TODO | TODO |

## Fixture-level rules

- **Input must be deterministic.** No timestamps, no random IDs, no
  network calls. Same input → same output, always.
- **Snapshots are committed.** They're the contract.
- **Snapshots are sorted-key JSON.** Use `JSON.stringify(obj, null, 2)`
  with a stable key order — diffs stay legible.
- **No PHI in fixtures.** Patient context fields use generic age bands,
  no names, no MRN.
