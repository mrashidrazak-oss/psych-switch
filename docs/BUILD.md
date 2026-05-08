# Build & deploy runbook

How to take PsychSwitch from a working dev session to a TestFlight /
Play Store build, and onward to production. Pair with:

- `docs/STORE_LISTING.md` — App Store / Play Store copy
- `docs/ASSET_PIPELINE.md` — icon / splash / screenshot rasterisation
- `docs/BETA_PROGRAM.md` — beta tester recruitment + feedback flow

## TL;DR — typical release flow

```bash
# 1. Make changes, commit. Local sanity-check.
pnpm verify                              # typecheck + jest + MCP smoke

# 2. Bump version + add changelog entry (manual, both files):
#    - app.json:        "version": "0.4.X"
#    - engine/changelog.ts:  prepend new entry

# 3. Push to main → GitHub Actions runs the same `verify` step.

# 4. Build a preview for internal testers (TestFlight / Internal app sharing):
pnpm build:preview                       # runs `eas build --profile preview`

# 5. When the build's good, promote to production:
pnpm build:production                    # runs `pnpm preflight && eas build --profile production`

# 6. Submit to the stores:
pnpm submit:ios                          # uploads latest production build to App Store Connect
pnpm submit:android                      # uploads latest production build to Play Console
```

Nothing here is destructive without explicit confirmation — `eas build`
and `eas submit` both prompt before doing anything that costs money or
ships externally.

## Environments

EAS profiles map to release channels:

| Profile       | Distribution | Channel      | Use for |
|---------------|--------------|--------------|---------|
| `development` | internal     | development  | Custom dev client builds; native debugging |
| `simulator`   | internal     | development  | iOS-Simulator-only builds (no signing) |
| `preview`     | internal     | preview      | TestFlight / Internal app sharing for clinician beta |
| `production`  | store        | production   | App Store / Play Store releases |

Every profile sets `EXPO_PUBLIC_BUILD_ENV` so the JS can branch on it
when needed (e.g. point Sentry at a different DSN per channel, or hide
unfinished features in production).

`appVersionSource: "remote"` (in `eas.json`) means EAS owns the build
number — you only ever bump `version` in `app.json` (semver-ish).

## Secrets

Anything sensitive lives in **EAS secrets** (encrypted, attached to
the project) or **GitHub Actions secrets** (encrypted, scoped to CI).
Never commit a key.

```bash
# Add a build-time env var to EAS (visible in eas.json builds):
eas secret:create --scope project --name SENTRY_DSN --value 'https://…@sentry.io/…'

# List existing secrets:
eas secret:list

# Delete one:
eas secret:delete --id <secret-id>
```

Files in `secrets/` (e.g. the Play Console service-account JSON
referenced by `eas.json`'s submit profile) are gitignored. Generate
them once per machine, never commit.

`.env.example` documents the names of expected env vars. Local dev
copies it to `.env` and fills in values; production reads from EAS
secrets at build time.

## Sentry

Currently a **no-op stub** (`utils/sentry.ts`). The package's
peer-dep graph fights with pnpm's hoisted layout in Expo SDK 54 so we
ship a stub rather than a flaky reporter.

To re-introduce the real Sentry:

1. Move from Expo Go to a custom development build (run
   `pnpm build:dev` once).
2. `pnpm add @sentry/react-native@~8.x`
3. Add the Expo plugin to `app.json`:
   ```json
   "plugins": ["@sentry/react-native/expo"]
   ```
4. Restore `initSentry()` in `utils/sentry.ts` (see git log for the
   pre-stub version).
5. `eas secret:create --scope project --name SENTRY_DSN --value 'https://…'`
6. Build with `pnpm build:preview` — the plugin auto-uploads
   sourcemaps using the DSN.

Until then, ErrorBoundary + the dev console reporter handle local
crash visibility. No DSN is wired.

## Assets

Pipeline lives in `docs/ASSET_PIPELINE.md`. Quick check:

```bash
file assets/*.png
# Should report:
#   icon.png:          1024 x 1024
#   adaptive-icon.png: 1024 x 1024
#   splash.png:        ~1284 x 2778 (iPhone Pro Max)
#   favicon.png:        48 x 48
```

If you re-rasterise from `brand-mark.svg`, follow the recipes in
ASSET_PIPELINE.md — the dimensions matter (Apple/Google reject
anything off-spec) and the background should match `#0b0f14`.

## Pre-flight

`pnpm preflight` (alias for `pnpm verify`) runs:

1. `tsc --noEmit` — strict mode, whole repo
2. `jest` — engine + util tests (currently 302)
3. MCP smoke — 24 handler tests

`build:production` runs preflight automatically. The other build
profiles don't, so you can ship a preview with known minor issues
during exploratory testing.

## Versioning

Two layers:

- **`app.json` `version`** — the public semver, shown in the app
  (`AboutScreen` reads it via `expo-constants`). Bump manually.
- **EAS build number** — opaque, auto-incremented by EAS on every
  production build. Never touch.

When you bump `app.json` `version`, also prepend an entry to
`engine/changelog.ts`. The `What's new` screen reads from there.

Cadence (rough):

- Patch (`0.4.X`) — every meaningful change. We've been shipping
  multiple per week during the polish phase.
- Minor (`0.X.0`) — when a major content arc lands (e.g. mood
  stabilizers ungated, MCP tool count crosses a milestone).
- Major (`X.0.0`) — first paid release / first PMA-cleared release.

## TestFlight / Internal app sharing

```bash
# Build a preview:
pnpm build:preview

# When the build artefact lands (URL in `eas build` output):
#   - iOS: Apple sends it to TestFlight. Add testers in App Store Connect.
#   - Android: Download the .apk and share via Google Drive, or push
#     to Internal testing track in Play Console.
```

Beta tester recruitment + feedback channels: `docs/BETA_PROGRAM.md`.

## Production submission

```bash
pnpm build:production    # preflight + production build, ~25 min
pnpm submit:ios          # uploads to App Store Connect; respond to
                         # email when Apple finishes processing
pnpm submit:android      # uploads to Play Console internal track;
                         # promote to production manually after smoke
```

App-review walkthrough notes (the demo account, the "what to test"
copy) live in `docs/STORE_LISTING.md`.

## Pinned tooling

```
node      ≥ 20
pnpm      ≥ 9
eas-cli   ≥ 18  (npm i -g eas-cli)
expo-cli  built into Expo SDK; use `pnpm dlx expo-cli` if needed
```

The CI workflow pins these versions; if you bump locally, bump the
workflow too (`.github/workflows/verify.yml`).

## Rollback

Two paths:

- **JS-only regression** — push an OTA update with the prior commit:
  ```bash
  git checkout <good-sha>
  pnpm update:production --message 'Rollback to <good-sha>'
  ```
  Users get the fix on next app launch. No store review.

- **Native or store-asset regression** — submit a new production
  build with a higher version. App Store review is ~24h normally.
  Play Store internal-track promotion is minutes.

OTA updates are gated by `runtimeVersion` in `app.json` (currently
`{"policy": "appVersion"}`). That means an OTA can only deploy to
clients running the same `version` it was built against — if a build
has native changes, force users to update.
