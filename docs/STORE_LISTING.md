# App Store / Play Store listing copy

Drop these strings directly into App Store Connect / Google Play
Console. All copy fits within the platform character limits and is
written for the medical-professional audience the app targets.

---

## App name (30 chars iOS / 50 chars Android)

**`PsychSwitch`**  *(17 chars)*

---

## Subtitle / short description

### iOS subtitle (30 chars)
**`Cross-titration, cited`**  *(22 chars)*

### Android short description (80 chars)
**`Reviewed cross-titration schedules. Privacy-first. For qualified clinicians.`**  *(76 chars)*

---

## Description (long)

```
Reviewed cross-titration schedules, depot protocols, and clozapine
monitoring — built for the bedside.

PsychSwitch is decision-support reference material drawn from the
Maudsley Prescribing Guidelines (15th ed.), BAP, NICE, FDA prescribing
information, and the Malaysian CPGs. Every dose change traces back to
a citation. Every rule has an evidence grade. Every schedule adapts
to your patient's actual doses.

WHAT'S INSIDE
• ~95 reviewed switching rules across antidepressants and oral
  antipsychotics
• Adaptive schedule scaler with formulation-aware rounding
• Citation chips with paraphrased Maudsley / BAP / NICE quotes
• Evidence grading (A → D) on every rule
• PsychSwitch Score — single 0-100 confidence number
• Predicted side-effect profile with likelihood tiers
• Smart drug picker that re-ranks by clinical relevance
• Dose equivalents (chlorpromazine, fluoxetine, diazepam)
• DDI checker for the cross-taper overlap window
• Patient context engine (age, eGFR, hepatic, pregnancy, comorbidities)
• Auto-generated monitoring schedule
• Pharmacokinetic plasma-level overlay
• Receptor-occupancy curves for hyperbolic-taper reasoning
• Discontinuation-syndrome flagger
• Clozapine module — titration, FBC monitoring, ANC checker
• QTc stacker for cumulative cardiac risk
• Ramadan mode for fasting-aware dosing
• Adverse-effect lookup with management notes

Mood stabilizers and LAI / depot antipsychotics are registered in the
engine but currently gated from the cross-titration picker pending
more clinical research. Their dedicated screens will return as the
content is reviewed.

WORKFLOW LOOP
• Discharge summary block ready to paste into the EMR
• Patient counselling card in plain language
• Real PDF export

PRIVACY-FIRST
Patient context, saved cases and sign-offs all stay on this device.
No analytics. No tracking. No PHI ever leaves unless you explicitly
tap Share. The app deliberately does NOT collect patient names, MRN,
NRIC, DOB, or any identifying detail.

NOT MEDICAL ADVICE
PsychSwitch is for use by qualified mental-health prescribers
(psychiatrists, mental-health pharmacists, psychiatry trainees, and
GPs with mental-health experience). It is decision-support reference
content, not medical advice. Always cross-check against the primary
source before acting on any plan.

REVIEWED CLINICAL CONTENT
Every rule carries reviewer attribution + last-reviewed date + a
90-day re-review cadence. The clinical content is open under
CC BY-NC-SA 4.0 — see github.com/mrashidrazak-oss/psych-switch for the full
content repo and a contribution guide.

REPORT AN ISSUE
Tap "Report an issue with this rule" on any Result screen to email
the maintainers a templated report. The report includes rule ID and
app version — never patient data.
```

---

## Keywords (iOS — 100 chars, comma-separated, no spaces)

```
psychiatry,switching,cross,titration,maudsley,bap,clozapine,depot,lai,ssri,snri,antipsychotic
```

---

## Promotional text (iOS — 170 chars, can be updated without review)

```
Adaptive schedules cited to the Maudsley page. Patient-aware. Privacy-first. Built for the bedside.
```

---

## Category

- **Primary**: Medical
- **Secondary**: Reference

---

## Age rating

- **iOS**: 17+ (Frequent/Intense Medical/Treatment Information)
- **Android**: Per IARC questionnaire — typically **Everyone** with a
  medical/educational descriptor, or **Teen** in some regions due to
  mention of drug interactions. Both are appropriate for the
  professional audience. See `docs/PLAY_STORE.md` § Content rating
  for the questionnaire mapping.

---

## Privacy nutrition label (iOS)

### Data Not Collected
- Contact Info (Name, Email, Phone, Physical Address)
- Health & Fitness
- Financial Info
- Location
- Sensitive Info
- Contacts
- User Content
- Browsing History
- Search History
- Identifiers
- Purchases
- Usage Data
- Diagnostics

**The app collects nothing. Verify by inspecting the source —
github.com/mrashidrazak-oss/psych-switch.**

If the user opts in to crash reports (off by default), an anonymized
stack-trace reporter would collect minimal diagnostics. **As of
v0.4.23, the Sentry reporter is a no-op stub** (`utils/sentry.ts`) —
nothing leaves the device until a real DSN is wired. When the
reporter is reactivated, `beforeSend` will scrub any patient input
or clinical context.

---

## Required URLs

| Field | Use today | Future custom domain |
|-------|-----------|----------------------|
| Marketing URL | https://mrashidrazak-oss.github.io/psych-switch/ | https://psychswitch.health |
| Privacy Policy URL | https://mrashidrazak-oss.github.io/psych-switch/privacy.html | https://psychswitch.health/privacy |
| Terms of Use URL | https://mrashidrazak-oss.github.io/psych-switch/terms.html | https://psychswitch.health/terms |
| Errata email | errata@psychswitch.health | (already at psychswitch.health, gmail/forwarder) |

The GitHub Pages URLs are LIVE and store-reviewer ready (HTTP 200,
HTTPS, deployed via `.github/workflows/publish-landing.yml`). The
custom domain `psychswitch.health` is staged in `docs/landing/CNAME`
and will activate when DNS is pointed at GitHub Pages.

The Privacy and Terms screens are also built into the app (see
`PrivacyScreen.tsx` / `TermsScreen.tsx`) — same content, offline
access. The hosted versions exist for store reviewers who need a
public URL.

---

## Review notes (App Store reviewer-facing)

```
PsychSwitch is decision-support reference content for qualified
mental-health prescribers. It does not collect patient data, does not
prescribe medication, and does not replace clinical judgment.

The app is fully functional offline. There is no account, login, or
backend. All data stays on the device.

To test the core flow:
1. Tap "I am a healthcare professional" on the disclaimer screen.
2. Optionally swipe through the 4-card onboarding tour.
3. Tap "Start a switch" on the home screen.
4. Pick a drug (e.g. olanzapine), pick a dose (e.g. 20 mg), pick a
   target drug (e.g. aripiprazole), pick a target dose (e.g. 15 mg).
5. Tap "Show schedule".

The Result screen renders the reviewed schedule, a PsychSwitch Score,
predicted side effects, monitoring plan, citations, and workflow
artifacts.

For any clinical questions about the content, contact
errata@psychswitch.health.
```

---

## Screenshot suggestions

Order them so the App Store carousel tells a story:

1. **Home screen** with the search bar visible. Caption: *"Search any drug or 'X to Y' switch."*
2. **Result screen with PsychSwitch Score** prominent. Caption: *"One number. Patient-aware. Cited to Maudsley."*
3. **Result screen Detailed view** showing PK overlay + receptor occupancy. Caption: *"Plasma-level prediction nobody else surfaces."*
4. **Citation chip modal open** showing paraphrased quote. Caption: *"Tap any step. See the source."*
5. **Discharge summary card expanded**. Caption: *"EMR-paste-ready. One tap to copy."*
6. **Patient counselling card expanded**. Caption: *"Plain language. Reviewable. Shareable."*
7. **Smart drug picker** showing "★ Best fit" / "Reviewed" / "Caution" / "Avoid" tiers. Caption: *"Re-ranked by clinical relevance for THIS patient."*

Sizes:
- iPhone 6.7" (1290×2796): mandatory
- iPhone 6.5" (1242×2688): mandatory
- iPad Pro 12.9" (2048×2732): if you support iPad (we do — `supportsTablet: true`)
- Android phone (1080×1920+): mandatory; submit 5+

Generate via Expo Simulator or device → System Screenshot.

---

## Localizations to add later

- `ms-MY` (Bahasa Malaysia)

The app is currently scoped to Malaysia only (see v0.4.23 changelog).
For v1 launch, ship English (US) only — Malaysian psychiatry is
practised in clinical English. Bahasa Malaysia translation can land
once a native-speaker clinician reviews the i18n strings.
