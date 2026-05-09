# Flutter dependency stack — locked at Phase 0

**Status:** locked · **Date:** at v0.4.23 commit `7904bd1`

This is the dependency stack for the v0.5.0 Flutter migration. Every
choice is opinionated — for a clinical app, "obvious" beats "shiny".
Don't deviate without amending this doc and pinning a new ADR.

---

## Why this matters

Locking the stack now prevents the "well, let's try X" trap that turns
6-week migrations into 14-week ones. If you find a reason to swap a
library, write the reason here, get it reviewed, then swap. Don't
swap mid-port.

---

## SDK versions

| Tool | Version | Why |
|---|---|---|
| Flutter | **stable channel, 3.27+** | Impeller renderer is on by default for Android in 3.27+; that's our perf win |
| Dart | comes with Flutter (3.6+) | Pattern matching + sealed classes mature in Dart 3 |
| Android SDK | **compileSdk 34, minSdk 23, targetSdk 34** | Play requires 34 by Aug 2024; 23 covers Android 6+ (~99% of MY market) |
| iOS deployment target | **13.0** | Future-iOS port; 13.0 is Flutter's current floor |
| Node (MCP server, if Architecture D) | 20+ (LTS) | Matches existing CI |

---

## Performance target devices

Locked at user request.

| Tier | Device | Specs | Role |
|---|---|---|---|
| **Primary** | Samsung Galaxy A14 | 4GB RAM · MediaTek Helio G80 · ~2023 | If we hit budgets here, we hit them everywhere |
| Secondary | Redmi Note 12 | 6GB · Snapdragon 685 | Vendor diversity (Qualcomm vs MediaTek catches vendor-specific issues) |
| Aspirational | Pixel 6a or newer | 8GB · Tensor G1 | Reference device for "premium" feel |

If Galaxy A14 misses any budget, we halt and reconsider before continuing past Phase 0.

---

## Dependencies (pubspec.yaml)

### State management — **flutter_riverpod 2.5+** with `riverpod_generator`
Why over Provider/BLoC:
- Cleanest async/error semantics for AsyncNotifierProvider
- Codegen reduces boilerplate; type-safe family providers
- Best-in-class testability (override providers per test)
- Riverpod's `AsyncValue<T>` shape maps naturally to the patient-context, settings, and saved-cases providers we'll need

### Routing — **go_router 14+**
Why over Navigator 2.0 raw or auto_route:
- Declarative URL-based routing (matches the React Navigation feel we're porting from)
- Deep-link friendly out of the box (matters for "Open this saved case" share intents)
- Plays well with Riverpod (route guards via Riverpod providers)
- Maintained by the Flutter team

### Local storage — **drift** (SQL) + **shared_preferences**
Two-tool approach:
- `drift` for cases + sign-offs + errata reads + monitoring schedules. Anything that benefits from queries.
- `shared_preferences` for settings + onboarding-seen flag + reminder hour. Key-value is the right shape there.

Why drift over hive/isar:
- Real SQL with typed query DSL
- Migration support (we'll need this when content schema evolves)
- The audit-export feature needs to query saved cases — drift makes that trivial; key-value stores require manual indexing

### HTTP — **dio** (when needed)
Currently no network dependencies. Reserved for future telemetry, errata sync, or remote-config.
- Interceptor-friendly (good for adding Sentry tracing)
- Cancellation tokens (good for the search-as-you-type debouncing)

### PDF / Print — **printing** + **pdf**
Replaces expo-print (HTML→PDF via WebView). The Dart approach renders PDFs natively from a structured document, which means:
- Faster
- Pixel-perfect type rendering
- No WebView dependency (smaller AAB)

### SVG — **flutter_svg 2+**
For brand-mark, icons that don't fit Material's icon set. The existing `assets/brand-mark.svg` etc. work as-is.

### Charts — **CustomPaint** (preferred) + **fl_chart** (escape hatch)
The Gantt chart, PK overlay, and receptor occupancy all become CustomPaint widgets — direct-to-canvas, 60fps trivially. fl_chart only if we need a generic chart we don't want to draw ourselves.

### Markdown — **flutter_markdown**
For the changelog screen, errata feed, and any HTML-rendered content from `/content/*.md` files.

### Notifications — **flutter_local_notifications 17+**
Replaces expo-notifications. Same model (local scheduled notifications, no remote push). Mature plugin with active maintenance.

### Haptics — **haptic_feedback**
Replaces expo-haptics. Six feedback levels (selection, light/medium/heavy impact, success, warning, error). Maps to `HapticFeedback.*` in flutter/services for the basic cases.

### Share — **share_plus**
Replaces expo-sharing. Native share sheet on both platforms. Same UX as the current "Share schedule" button.

### Crash reporting — **sentry_flutter 8+** (real DSN this time)
Why Sentry over Crashlytics:
- We already have Sentry account + DSN concept wired in v0.3
- Performance monitoring is included (matters for our budgets)
- `beforeSend` hook for PHI scrubbing
- Sentry's Flutter SDK doesn't have the peer-dep hell that blocked us in RN

### Localization — **intl** + ARB files
Standard Flutter i18n stack. ARB files are Google's translation format. When BM lands post-migration, we add `lib/l10n/app_ms.arb` next to `app_en.arb`.

### MCP (if Architecture C) — **mcp_server**
Community Dart package as of late 2025. To be validated in Phase 0.2 spike. If it fails, we fall back to Architecture D and keep Node MCP.

---

## Codegen tooling

| Tool | Purpose |
|---|---|
| `build_runner` | Driver for all codegen |
| `freezed` | Immutable data classes (replaces our hand-written TS interfaces) |
| `json_serializable` | JSON parsing for `/content/*.json` |
| `riverpod_generator` | Type-safe provider declarations |
| `go_router_builder` | Type-safe route declarations (optional but nice) |

---

## Test stack

| Tool | Layer |
|---|---|
| `package:test` | Pure Dart unit tests (engine modules) |
| `flutter_test` | Widget tests |
| `integration_test` | End-to-end on real device or emulator |
| `mocktail` | Mock dependencies (no codegen, unlike mockito) |
| `golden_toolkit` | Pixel-perfect golden tests for primitives + key screens |
| `patrol` (optional) | Native interactions in integration tests (permission dialogs, etc.) |

---

## Linting

| Tool | Setting |
|---|---|
| `very_good_analysis` 6+ | Stricter than `flutter_lints`. Closer in spirit to our strict TS config. |

Strict null safety enforced everywhere. No `dynamic`, no `as` casts without checks, no implicit ignores.

---

## Asset pipeline

Replaces the rsvg-convert + magick chain.

| Concern | Tool |
|---|---|
| App icon (all sizes) | `flutter_launcher_icons` from a single source |
| Splash screen | `flutter_native_splash` from a single source |
| SVG rendering | `flutter_svg` (runtime, no rasterization) |

---

## Architecture decision (locked at Phase 0.2)

```
ARCHITECTURE: C — full Dart, MCP server reimplemented in Dart
DECIDED: 2026-05-09
SPIKE BINARY SIZE: 5.8 MB (single executable, no runtime needed)
PROTOCOL ROUNDTRIP: verified end-to-end (initialize → tools/list → tools/call)
```

### Rationale

The community Dart `mcp_server` package (v2.0.0) supports the latest
MCP protocol revisions (2024-11-05 / 2025-03-26 / 2025-06-18 /
2025-11-25) with stdio + SSE + Streamable HTTP transports and OAuth
2.1. Active maintenance (last push ~1 week ago). Has its own protocol
compliance test suite and per-version capability gating.

A 1-tool prototype exposing `psychswitch_list_drugs` was built,
compiled to a 5.8 MB single binary, and exercised end-to-end via a
Dart-driven JSON-RPC test:

```
✅ MCP protocol roundtrip OK:
   initialize → 2025-06-18
   tools/list → 1 tool
   tools/call → 3 drugs returned
```

**Caveats acknowledged:**
- 9 GitHub stars, niche package. If a critical bug appears, we may
  have to fork/maintain. Acceptable risk for a small Dart package
  with ~80% test coverage in its own repo.
- Claude Desktop UI integration not directly tested in this spike
  (requires user's hands). Protocol compliance is the substance; if
  Claude Desktop can't talk to a server that correctly speaks
  MCP 2025-06-18, the issue would be on Claude's side, not ours.

### Implication for Phase 6

When Phase 6 rolls around (MCP execution), the existing 18-tool
TypeScript MCP server in `mcp-server/` will be ported to Dart
following the spike's pattern. Each tool becomes a `server.addTool`
call. The 24 smoke tests get equivalent Dart `package:test`
implementations. Distribution via `dart compile exe` gives users a
single binary they install via `dart pub global activate` or a
direct download from GitHub releases.

---

## Update protocol

To swap a dependency:

1. Open this file
2. Strike through the old choice with `~~strikethrough~~`
3. Add the new choice with a one-paragraph "swapped because..." note
4. Bump the doc with a `Last amended: YYYY-MM-DD` line at top
5. Commit with prefix `chore(stack):`

To add a new dependency not listed here:

1. Add to the appropriate section
2. One-paragraph rationale
3. Why-not-existing-alternatives note
4. Same `Last amended` bump + commit

This is a pinning doc. The point is to slow you down before changing the stack mid-migration.
