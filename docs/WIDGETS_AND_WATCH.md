# Widgets + Watch app — implementation notes

PsychSwitch's Theme-1 Active Intelligence ships **local push
notifications + a Today's Pulse card** in v0.4.1 — fully working in
Expo Go.

The next two surfaces — **iOS / Android home-screen widgets** and an
**Apple Watch companion** — require a custom development build
(they're native modules / native targets, not JS). This document
captures the design + implementation plan so the work can be picked
up cleanly when you move off Expo Go.

---

## 1. iOS / Android home-screen widget

### Concept

Single-card widget showing today's pulse:
- Number of overdue / today / soon items
- Top 3 individual pulses with case label + entry label

Tap → opens the app to the relevant Result screen.

### iOS (WidgetKit)

WidgetKit needs Swift code in a separate target inside the Xcode
project. Expo SDK 54 supports this via the `expo-build-properties` +
`expo-apple-targets` config plugin ecosystem.

**Steps**:
1. Switch from Expo Go to a custom development build:
   ```
   pnpm add expo-dev-client
   eas build --profile development --platform ios
   ```
2. Add the target via [@bacons/apple-targets](https://github.com/EvanBacon/expo-apple-targets) or manual Xcode setup. Create `targets/PsychSwitchWidget/`:
   - `Widget.swift` — WidgetKit timeline provider
   - `Bundle.swift` — `@main` entry
   - `Info.plist` — bundle identifier `com.psychswitch.app.widget`
3. Share data with the main app via App Groups:
   - Create `group.com.psychswitch.app` in Apple developer portal
   - Main app writes `today-pulse.json` to the shared container
     whenever cases change
   - Widget reads from the same container
4. Timeline provider regenerates every 30 min or on app event.

### Android (Glance / RemoteViews)

Android widgets use Glance (Compose-based) for new widgets or
RemoteViews for older ones. Easier than iOS but still requires a
native build.

**Steps**:
1. Same custom dev build switch as iOS.
2. Add Glance dependencies in `android/app/build.gradle`.
3. Create `android/app/src/main/java/.../widget/PulseWidget.kt`.
4. Share data via `SharedPreferences` (which Expo's AsyncStorage uses
   under the hood — accessible from the widget JVM process).

### What to render (both platforms)

```
┌───────────────────────────────────────┐
│ ⓘ PsychSwitch                          │
│                                        │
│ ◉ 1 overdue   ⊙ 2 today   ⊙ 3 this wk │
│                                        │
│ 🩸 Mr A · D7 Lithium level   today    │
│ 💊 Mrs K · D14 Response check today    │
│ ❤ Mr B · D28 ECG repeat       in 2d   │
└───────────────────────────────────────┘
```

Tappable: each row → opens that case in the main app.

### Data freshness

- Widget reads the shared file on every refresh (~30 min cadence)
- Main app writes the file:
  - After every case save / delete
  - After every notification fires (the OS gives us a callback)
  - On app launch
- Stale-but-readable is better than empty — show last-known data with
  an "as of HH:MM" timestamp.

---

## 2. Apple Watch companion

### Concept

A WatchOS app + complication showing the same Today's Pulse + a
single-tap action: open the case in the iPhone app via Handoff.

### Two surfaces

**Watch app (full-screen)**
- List view: today's pulses, sortable
- Tap → details + "Mark done" + "Open on iPhone" via Handoff
- Pull-to-refresh

**Complication**
- Modular Small: count of overdue + today (`3 / 2`)
- Circular: the next-due item
- Updates via WidgetKit timeline (post-iOS 16 / WatchOS 9)

### Architecture

WatchOS apps in Expo SDK 54:
- Use `expo-apple-targets` to add a Watch app target
- Or eject and configure manually
- **WatchKit + SwiftUI** for the UI
- **WatchConnectivity** for iPhone ↔ Watch data sync

Same App Group as the widget — write today-pulse.json once, render
on Watch.

### Privacy notes

The Watch app sees the case label (clinician-supplied initials/code)
and entry label. **No more PHI than the main app.** Standard local
storage; nothing flies to a server.

---

## 3. When to do this

- **Trigger**: when the app moves from Expo Go to a custom dev build
  for the first store submission (~v0.5)
- **Why it's worth waiting**: building widgets requires native targets,
  Apple Developer enrollment, and EAS Build configuration. These are
  one-time setup costs you'd want to amortise across multiple native
  features (Sentry SDK, Watch app, widgets).
- **Sequence**:
  1. Custom dev build via EAS
  2. Sentry properly installed
  3. iOS widget (WidgetKit)
  4. Watch app
  5. Android widget (Glance)

---

## 4. Stand-in until then

The in-app `<TodayPulseCard />` (engine/casePulse.ts +
components/TodayPulseCard.tsx) gives ~80% of the widget's UX value
inside the existing app. It runs in Expo Go, requires no native code,
and pulls the same data the future widgets will use.

When the widgets ship, both surfaces share the engine output — no
duplicated logic.
