# QA checklist — before testers see the build

Run through this once on a real Android device after installing the
.aab. Catches the kind of bugs that don't show up in `pnpm verify`
(layout, native module crashes, dark-theme regressions, missing
assets).

Estimated time: **15-20 min** if everything passes, longer if
something needs fixing.

---

## 0. Install the AAB on your phone (one-time setup)

```bash
# 1. Download the AAB
curl -L -o ~/Downloads/psychswitch-0.4.23.aab \
  https://expo.dev/artifacts/eas/tpqxDaaJjhDFcamBHc6Jdk.aab

# 2. Install bundletool (once)
brew install bundletool

# 3. Plug your Android phone in via USB. Enable USB debugging:
#    Settings → About phone → tap Build number 7 times
#    Settings → System → Developer options → USB debugging ON
#    Accept the RSA-fingerprint prompt on the phone.

# 4. Verify adb sees the device
adb devices         # should list one device with status "device"

# 5. Build APKs from the AAB and install in one shot
bundletool build-apks \
  --bundle=~/Downloads/psychswitch-0.4.23.aab \
  --output=/tmp/psw.apks \
  --connected-device

bundletool install-apks --apks=/tmp/psw.apks
```

App should now appear on your home screen as **PsychSwitch**.

If `bundletool` complains about a missing keystore for AAB signing,
it's because EAS-managed keys aren't local. Use this fallback:

```bash
# Extract universal APK, install directly
bundletool build-apks \
  --bundle=~/Downloads/psychswitch-0.4.23.aab \
  --output=/tmp/psw-universal.apks \
  --mode=universal
unzip -p /tmp/psw-universal.apks universal.apk > /tmp/psw.apk
adb install /tmp/psw.apk
```

---

## 1. Cold-launch sanity (~2 min)

- [ ] App icon shows the **two crossing taper curves** on the dark
      tile (not a generic Expo placeholder)
- [ ] App label below the icon reads **PsychSwitch** (no "ASEAN")
- [ ] First launch shows the **disclaimer modal** (full-screen, dark)
- [ ] Disclaimer says "PsychSwitch" + "Reviewed cross-titration"
      subtitle (not "ASEAN edition")
- [ ] "I am a healthcare professional" button works
- [ ] After dismissing, the **onboarding tour** appears (4 cards,
      swipeable)
- [ ] Last onboarding card has a "Start using PsychSwitch" button that
      lands you on Home

## 2. Home screen (~3 min)

- [ ] Hero shows the brand-mark icon + "PsychSwitch" + "Reviewed
      cross-titration" eyebrow
- [ ] Search bar is reachable and typing "olan" surfaces olanzapine
- [ ] **TodayPulseCard** renders cleanly (or hides if no saved cases)
- [ ] "Start a switch" CTA shows the rule count (~95 reviewed pairs)
- [ ] Clinical modules section shows **Clozapine module only**
      (LAI depot + Mood stabilizers should NOT be visible — they're
      gated)
- [ ] Tools row is a 3-col grid: Equivalents, QTc, AE, Patient
      context, Ramadan, Saved cases
- [ ] Resources row: Glossary, What's new, Review, About
- [ ] Status pill at the bottom mentions "antidepressants and oral
      antipsychotics" (not the old ASEAN copy)
- [ ] **No white flash** when navigating to any screen (pre-v0.4.7
      regression)

## 3. Switch wizard (~3 min)

- [ ] Tap "Start a switch" → step 1 shows drug picker
- [ ] Drug picker has tabs/sections; **mood stabilizers + LAI drugs
      are NOT pickable** (gated)
- [ ] Pick "olanzapine" → step 2 dose picker shows the dose chips
- [ ] Pick a dose → step 3 to-drug picker
- [ ] Pick "aripiprazole" → step 4 dose
- [ ] Pick a dose → "Show schedule" CTA
- [ ] Tap → lands on Result screen

## 4. Result screen (~5 min)

- [ ] Drug pair header: "Olanzapine → Aripiprazole" with Save button
- [ ] Strategy line + duration ("Cross-taper over N days")
- [ ] Evidence badge + citation chips visible
- [ ] **OverlapIntensityChip** shows tier (low / moderate / high /
      severe) + score
- [ ] **PsychSwitch Score card** renders with breakdown
- [ ] Tabs render: **Schedule | Insights | Provenance | Workflow**
- [ ] **Schedule tab** (default): taper-speed segmented control,
      view toggle (Summary / Detailed), Conservative-mode switch,
      then the schedule itself
- [ ] **Insights tab**: Specialty depth (if active), Predicted AE,
      Cost comparison, Alternatives
- [ ] **Provenance tab**: Rule provenance, citations panel, report
      issue
- [ ] **Workflow tab**: Discharge summary, counselling card
- [ ] Tap a **CitationChip** → modal opens with reference + paraphrase
- [ ] Tap **Save** → modal opens, type a label, save → toast confirms
- [ ] Tap **Share** in footer → native share sheet opens
- [ ] Tap **Export PDF** → print sheet opens with formatted plan

## 5. Tools (~2 min)

- [ ] **Clozapine module**: Titration, FBC, ANC checker all reachable
- [ ] **QTc stacker**: pick 2 drugs, see cumulative QTc estimate
- [ ] **Adverse-effect lookup**: pick "weight gain", see culprits +
      candidates as Chips
- [ ] **Patient context**: form fields render (age, weight, eGFR,
      pregnancy)
- [ ] **Ramadan mode**: list of Ramadan-aware drugs + timing chips
- [ ] **Glossary**: search "QTc", definition appears
- [ ] **Saved cases**: the case you saved in step 4 is here

## 6. Settings (~2 min)

- [ ] **Text size** SegmentedControl: Compact / Normal / Large
- [ ] **Language** SegmentedControl: EN / BM / ID
- [ ] **Citation chips toggle**: SwitchRow toggles cleanly
- [ ] **Patient-context prompt toggle**: same
- [ ] **Reminder time** SegmentedControl: 7am / 9am / 12pm / 5pm
- [ ] **Crash reports toggle**: defaults OFF
- [ ] **Privacy policy** link opens the privacy screen
- [ ] **Terms of use** link opens the terms screen
- [ ] **What's new** opens changelog with v0.4.23 at the top
- [ ] **Errata** screen renders the audit feed

## 7. Error & polish (~1 min)

- [ ] Force-quit and reopen — saved case persists
- [ ] Rotate device (if supported) — no layout breaks
- [ ] Background app, return — no state loss on Result screen
- [ ] No console errors / red boxes anywhere
- [ ] Toast confirmations appear for save / share / report-issue

---

## Capturing screenshots for Play Console

While the build is on the device, capture the 6 frames Play wants.
With `adb` connected:

```bash
mkdir -p ~/Desktop/psw-screenshots

# Repeat for each screen — navigate manually on the phone, then run:
adb exec-out screencap -p > ~/Desktop/psw-screenshots/01-home.png
adb exec-out screencap -p > ~/Desktop/psw-screenshots/02-switch-step2.png
adb exec-out screencap -p > ~/Desktop/psw-screenshots/03-result-schedule.png
adb exec-out screencap -p > ~/Desktop/psw-screenshots/04-result-provenance.png
adb exec-out screencap -p > ~/Desktop/psw-screenshots/05-clozapine.png
adb exec-out screencap -p > ~/Desktop/psw-screenshots/06-ae-lookup.png
```

Verify dimensions:

```bash
file ~/Desktop/psw-screenshots/*.png
# Each should be at least 320 px on the shortest side. Phones produce
# ~1080×2400 typically — well within Play Console's range (320–3840).
```

Upload the 6 PNGs in Play Console → Main store listing → Phone screenshots.

---

## If anything fails

- **Crash on launch** → grab the `adb logcat` output:
  ```bash
  adb logcat -d "*:E" | head -50
  ```
  Paste into a GitHub issue or the v0.4.x changelog as a known issue.

- **Wrong app name showing** → confirm `app.json` was rebuilt; v0.4.23
  AAB ID is `tpqxDaaJjhDFcamBHc6Jdk.aab`, not the old
  `7FkWzoNMQimEVqTbhheZX1.aab`.

- **Layout regression** → check the build's runtime version matches
  the local code (`expo-constants` should report 0.4.23 in the About
  screen).

- **Specific bug, can fix locally** → patch, bump to v0.4.24, rebuild
  via `pnpm build:production`. ~15 min cycle.
