# Play Store launch — TODAY checklist

Status as of v0.4.23 commit `d172cf3`:

✅ **Build #3 finished successfully** — this is the AAB to upload.
   Renamed from "PsychSwitch ASEAN" → "PsychSwitch" with new package
   `com.psychswitch.app`. Bundle IDs are immutable post-submit, so we
   landed the rename before any store upload.

   - Build ID: `ddebfa2c-ffe8-46a8-840f-bbc690028b8b`
   - Version: **0.4.23** / version code 2
   - Package: **com.psychswitch.app**
   - Duration: ~15 min
   - Status: ✅ finished
   - Dashboard: https://expo.dev/accounts/feistz/projects/psych-switch/builds/ddebfa2c-ffe8-46a8-840f-bbc690028b8b
   - **`.aab` download (USE THIS ONE):** https://expo.dev/artifacts/eas/tpqxDaaJjhDFcamBHc6Jdk.aab

⛔ **Old AAB is DEFUNCT — do NOT upload:**
   `https://expo.dev/artifacts/eas/7FkWzoNMQimEVqTbhheZX1.aab` —
   this is the v0.4.22 build with the old `com.psychswitch.asean`
   package ID. Uploading it would lock the wrong package name forever.

✅ **All assets generated** — icon, adaptive icon, splash, feature graphic, OG card.

✅ **Listing copy written** — see `docs/STORE_LISTING.md`.

✅ **Privacy + terms HTML ready** — `docs/landing/privacy.html` + `terms.html`.

❌ **What ONLY you can do** (account-bound, listed below).

---

## What's blocked on your hands

These steps require your Google account, your credit card, your DNS
panel — there's no way for me to do them on your behalf.

### 1. Play Console account ($25 USD, one-time)

If you don't have one:
1. Go to https://play.google.com/console.
2. Sign in with your Google account.
3. Pay the $25 USD developer registration fee.
4. Verify identity (driver's licence / passport scan).
5. Approval is immediate for individual developers, ~2 days for orgs.

### 2. Google Cloud service account (for `eas submit:android`)

This is the one that lets the `eas submit` command upload builds for you
without manual UI clicks. Without it, you'll upload manually each time
via the Play Console UI — which is fine for the first launch, just
slower for subsequent updates.

If you want to set it up now (recommended for the long run):
1. Play Console → **Setup** → **API access** → **Create new service
   account**. Follow the link to Google Cloud Console.
2. In Google Cloud: create a service account named
   `psychswitch-eas-submit`, grant role **Service Account User**.
3. Generate a JSON key. Download it.
4. Save it locally to `secrets/play-service-account.json` (gitignored,
   already wired in `eas.json`).
5. Back in Play Console: grant the service account **Release manager**
   permissions on the PsychSwitch app.

If you want to skip this for the first launch:
- Manual upload of the `.aab` works fine. Skip to step 4 below.

### 3. Privacy URL — get it live

The Play Store **will not let you publish** without a reachable privacy
URL. You have two paths:

**Path A — quickest, GitHub Pages on the *.github.io subdomain.**
1. Push the local repo to a GitHub remote (any name; private OK):
   ```bash
   gh repo create mrashidrazak-oss/psych-switch --private --source=. --remote=origin --push
   # or your preferred git remote setup
   ```
2. Repo Settings → **Pages** → Source: **GitHub Actions**.
3. The `.github/workflows/publish-landing.yml` workflow will fire on
   the push and deploy `docs/landing/` to
   `https://mrashidrazak-oss.github.io/psych-switch/`. Verify:
   ```bash
   curl -sI https://mrashidrazak-oss.github.io/psych-switch/privacy.html | head -1
   ```
4. Use that URL in Play Console for now. Custom domain can wait.

**Path B — custom domain `psychswitch.health`.**
Same as Path A, then:
5. Repo Settings → Pages → Custom domain: `psychswitch.health`.
6. Configure DNS (whichever registrar you use):
   - 4 × A records to GitHub Pages IPs:
     185.199.108.153, 185.199.109.153, 185.199.110.153, 185.199.111.153
   - OR a CNAME `psychswitch.health → mrashidrazak-oss.github.io`
7. Wait for DNS to propagate (10 min – a few hours).
8. Pages will auto-issue an HTTPS cert. Verify:
   ```bash
   curl -sI https://psychswitch.health/privacy | head -1
   ```

The `docs/landing/CNAME` file is already set to `psychswitch.health`,
so the workflow will configure the custom domain automatically once
DNS is pointed.

### 4. Create the Play Console app entry

1. Play Console → **All apps** → **Create app**.
2. Settings:
   - App name: `PsychSwitch`
   - Default language: English (US)
   - App or game: **App**
   - Free or paid: **Free**
3. Tick the policy declarations.
4. **Create app**.

### 5. Upload the AAB

The build is done. Download:

**https://expo.dev/artifacts/eas/tpqxDaaJjhDFcamBHc6Jdk.aab**

Then:
1. Play Console → your app → **Production** (or **Internal testing**
   for the first run, recommended).
2. **Create new release** → Upload the `.aab`.
3. Add release notes (copy from the v0.4.21 entry in
   `engine/changelog.ts`, or just "Initial release.").
4. **Save** (don't roll out yet).

### 6. Fill in the listing — copy from `docs/STORE_LISTING.md`

Play Console → your app → **Main store listing**:

| Field | Source |
|-------|--------|
| App name | `STORE_LISTING.md` § App name |
| Short description (80 char) | `STORE_LISTING.md` § Subtitle / short description |
| Full description (4000 char) | `STORE_LISTING.md` § Long description |
| App icon (512×512) | `assets/icon.png` (resize to 512 — Play needs exactly this size). One liner: `magick assets/icon.png -resize 512x512 /tmp/playstore-icon.png` |
| Feature graphic (1024×500) | `assets/feature-graphic.png` ✅ already correct size |
| Phone screenshots (≥2) | TODO — capture from Pixel emulator running the build |

For phone screenshots: open the build on a Pixel emulator (or
USB-connected Android device), navigate to:
1. Home screen
2. Switch wizard step 2 (drug picker)
3. Result → Schedule tab
4. Result → Provenance tab
5. Clozapine module
6. Adverse-effect lookup with one expanded

Use Android Studio's emulator screenshot button (or `adb exec-out
screencap -p > screenshot.png`) — must be at least 320 px on the
shortest side, no upscaling allowed.

### 7. Data Safety questionnaire

Play Console → your app → **App content** → **Data safety**.

Every answer is mapped in `docs/PLAY_STORE.md` § Data safety. The TL;DR:
- Does your app collect or share data? **Yes — Crashes (opt-in,
  anonymous) only.**
- Crashes shared with third parties? **No** (would be Yes if Sentry
  is wired with a third-party DSN; currently Sentry is a no-op stub).
- Required or optional? **Optional.**
- Encrypted in transit? **Yes.**
- User can delete? **Yes (uninstall).**

Everything else: **No collection, no sharing.**

### 8. Content rating

Play Console → **App content** → **Content rating** → IARC
questionnaire. Use the answers from `docs/PLAY_STORE.md`:
- Drugs/alcohol/tobacco: **Reference in medical context.**
- Everything else: None.

Expected rating: **Everyone** or **Teen** depending on region.

### 9. Privacy policy URL

Play Console → **App content** → **Privacy policy** → paste your live
URL (from step 3).

### 10. Target audience and content

- Target age: **18+**.
- Designed for children: **No.**
- Ads: **No.**

### 11. Submit for review

Play Console → **Internal testing** track → **Review release** →
**Start rollout**.

Internal testing is **not** reviewed by Play — your build is live
within minutes for the testers you've added (just yourself for now is
fine). Test it on your own device. When you're happy, promote to
Production via the same UI.

Production review takes 1-3 days for first-time apps.

---

## What I've already done

- v0.4.21 committed (commit `142b919`).
- EAS production build queued: build ID `d15cf356-1595-4765-8c35-6e57718c1d05`.
- All assets in place (`assets/` + `docs/landing/og-image.png`).
- All copy written (`docs/STORE_LISTING.md`).
- Workflows ready (`.github/workflows/`).
- Submit profile in `eas.json` is wired with the service-account path.
- Tests green (302 jest, 24 MCP smoke).

When the build finishes, you'll get an email from EAS with the artefact
URL. Or watch:
```bash
eas build:view d15cf356-1595-4765-8c35-6e57718c1d05
```

---

## When you're ready, the one-command path

After steps 1-3 above, every future release is:

```bash
# 1. Bump version + add changelog entry. Commit.
# 2. Build:
pnpm build:production
# 3. Submit (once service account is in secrets/):
pnpm submit:android
```

That's it. The whole pipeline collapses to two commands.
