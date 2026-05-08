# Play Store submission runbook

Step-by-step from "I have a working preview build" to "the app is live
on the Play Store internal track". Pair with `docs/STORE_LISTING.md`
(copy) and `docs/BUILD.md` (build pipeline).

## Prerequisites

- Google Play developer account, registered on
  [play.google.com/console](https://play.google.com/console). One-time
  $25 USD fee. Approval can take a couple of days for individual
  developers.
- Privacy URL **live and reachable** — `https://psychswitch.health/privacy`.
  Hosting is automated via `.github/workflows/publish-landing.yml`; DNS
  is your responsibility.
- A working `pnpm build:preview` artefact (.aab for production,
  .apk for internal sharing). EAS produces both; pass
  `--platform android` if you only want the Android side.
- An app icon, feature graphic and at least 2 phone screenshots
  (Play asks for more — see "Assets" below).

## One-time setup

### 1. Create the app in Play Console

- Open Play Console → **All apps** → **Create app**.
- App name: `PsychSwitch ASEAN`.
- Default language: English (US).
- App or game: App.
- Free or paid: Free.
- Tick the declarations (developer programme policies + US export laws).
- Click **Create app**.

The package name is set when you upload your first build — make sure
it matches `app.json`'s `android.package` (`com.psychswitch.asean`).

### 2. Generate a Play Console service account

`eas submit` needs a service account JSON to upload builds without
manual button-clicking. Once-only:

1. Play Console → **Setup** → **API access** → **Create new service
   account** → follow the link to Google Cloud.
2. In Google Cloud: create service account, role *Service Account User*.
3. Generate a JSON key, download it.
4. Back in Play Console → grant the service account *Release manager*
   permissions (or *Admin* if you want it to also publish).
5. Save the JSON to `secrets/play-service-account.json` (gitignored).

The path is already wired in `eas.json` under `submit.production.android`.

### 3. Wire your privacy URL

Play **requires** a publicly reachable privacy URL before you can
publish — not "promised soon", actually live. Two-step:

1. Push the latest `docs/landing/` to main. The
   `publish-landing.yml` workflow auto-deploys to GitHub Pages.
   Confirm the URL works:
   ```bash
   curl -sI https://feistz.github.io/psych-switch/privacy.html | head -1
   # HTTP/2 200
   ```
2. Set the custom domain in repo Settings → Pages → Custom domain:
   `psychswitch.health`. Configure DNS:
   - A records to GitHub Pages IPs (`185.199.108.153` etc.) or
   - CNAME `psychswitch.health → feistz.github.io`
3. After DNS propagates (minutes to a few hours), confirm:
   ```bash
   curl -sI https://psychswitch.health/privacy | head -1
   # HTTP/2 200
   ```
4. In Play Console → **App content** → **Privacy policy** → paste
   `https://psychswitch.health/privacy`.

Until DNS is configured, paste the GitHub Pages URL — `https://feistz.github.io/psych-switch/privacy.html`. Update later when the custom domain works.

## Per-release flow

```bash
# 1. Confirm version is bumped (app.json + engine/changelog.ts).
git diff app.json engine/changelog.ts

# 2. Run the same checks CI runs.
pnpm verify

# 3. Build the production AAB (signed, store-ready).
pnpm build:production       # builds both platforms; --platform android for Android only

# 4. Wait for the build to finish (~25 min). EAS emails on completion.

# 5. Upload to Play Console internal track.
pnpm submit:android          # uses the service-account key in secrets/
```

After upload, the build is automatically on the **Internal testing**
track. To promote:

- Internal → Closed testing (alpha/beta): Play Console → Internal
  testing → Promote release.
- Closed → Production: same path, Production track.

Each track has its own review (~1-3 days for fresh listings, faster
for updates). Internal testing skips most review steps and is
available within hours.

## App content questionnaires

Play wants three things filled in before any track is publishable:

### Data safety

PsychSwitch's answers (matches `docs/landing/privacy.html`):

| Question | Answer |
|----------|--------|
| Does your app collect or share any of the required data types? | **Yes — Crashes (opt-in, anonymous)** only. Everything else: No. |
| Crashes — collected? | Yes |
| Crashes — shared? | No (would be Yes if Sentry is wired with a third-party DSN; until then No) |
| Crashes — required or optional? | Optional (toggled in Settings → Privacy) |
| Crashes — purpose | App functionality + Analytics |
| Crashes — encrypted in transit? | Yes |
| Crashes — user can request deletion? | Yes (uninstall the app; no data is retained server-side beyond the Sentry default 30 days) |
| Personal info | None collected |
| Financial info | None |
| Health & fitness | None — patient context (age band, eGFR, etc.) is stored *on device only*. Play Store's question is "do you collect or transmit it" — No. |
| Messages | None |
| Photos / videos | None |
| Files / docs | None — exported PDFs go through the OS share sheet, not our servers |
| Location | None |
| Web browsing | None |
| App activity | None |
| Device or other IDs | None |

### Content rating

Use IARC questionnaire (Play walks you through it). Rate:

- Violence: None
- Sexual content: None
- Profanity / crude humour: None
- Drugs, alcohol, tobacco: **References to drugs in a medical context.**
  This is a clinical decision-support tool. The questionnaire has an
  explicit "medical / educational" branch — pick that.
- Gambling: None
- User-generated content: None
- Personal info sharing: None
- Location: None

Expected rating: **Everyone** with a medical/educational descriptor,
or **Teen** in some regions due to mention of drug interactions. Both
are fine for our audience.

### Target audience and content

- Target age: 18+ (clinical professionals).
- Children's policy: Does not target children — answer No to all
  child-related questions.
- Ads: No.

## Listing assets

Required at minimum:

- **App icon**: 512×512 PNG, 32-bit, alpha allowed. Generate from
  `assets/icon.png` (1024×1024) downscaled — see `docs/ASSET_PIPELINE.md`.
- **Feature graphic**: 1024×500 JPG/PNG, no alpha. Currently missing —
  add to `assets/feature-graphic.png`. Brand-mark + tagline on the
  `#0b0f14` background.
- **Phone screenshots**: at least 2, max 8. 320–3840 px on shortest
  side, 16:9 or 9:16 aspect. Capture from a Pixel 5 emulator running
  the preview build.
- **Tablet screenshots**: optional but bumps eligibility for the
  "Tablet picks" surface. Capture from a tablet emulator.

Suggested screenshot frames:
1. Home screen (Start a switch CTA visible)
2. Switch wizard step 2 (drug picker, smart-tier ordering)
3. Result screen — Schedule tab (PsychSwitch score visible)
4. Result screen — Provenance tab (citations + evidence grade)
5. Clozapine module home
6. AdverseEffects screen with a problem expanded

Listing copy is already written in `docs/STORE_LISTING.md` —
copy-paste into Play Console fields.

## Common rejections (and how to avoid)

- **Privacy URL not reachable** — Play crawler couldn't load the page.
  Confirm with `curl -sI` from a non-Google IP first.
- **App description references unverified medical claims** — keep
  STORE_LISTING.md copy as-is; "decision support" not "diagnosis".
- **Missing data-safety declaration** — if you wire Sentry with a real
  DSN later, update the data-safety form to flip Crashes → Shared.
- **Screenshots show a UI that doesn't match the build** — re-capture
  after every minor release that touches the surfaces in the screenshots.
- **Permissions not justified** — we currently only request
  `POST_NOTIFICATIONS` (Android 13+) for monitoring reminders and
  `VIBRATE` via `expo-haptics`. Both are auto-justified by the SDK. If
  Play asks for a manifest review, point to `engine/notifications.ts`
  (only local, scheduled notifications) and `utils/haptics.ts`.

## Internal testing tracks

You can run multiple parallel internal tests by adding testers as
groups:

- **Closed clinician beta** — 5–20 trusted clinicians.
  Recruitment + feedback loops in `docs/BETA_PROGRAM.md`.
- **Open clinician beta** — 100+ via opt-in link.
- **Internal QA** — your own devices.

Each track shares the same build artefact; promotion is a button
click in Play Console.

## Rollback

- **Halt rollout**: Play Console → Production → **Halt rollout** stops
  new users from receiving the broken version. Existing users keep it
  until they update.
- **OTA hotfix**: most fixes are JS-only; push via
  `pnpm update:production --message 'Hotfix <description>'`. Users get
  it on next app launch, no Play review.
- **Native rollback**: build a new release with a higher version code,
  resubmit. Cannot ship a *lower* version code; you can only roll
  forward.
