# PsychSwitch — Privacy Policy (draft)

_Last updated: TODO_DATE_

PsychSwitch ("the app") is a clinical decision-support and educational
reference tool for healthcare professionals.

## Summary
PsychSwitch is privacy-first. The app works fully offline and does not
require an account — every clinical feature is usable with no sign-in.
It never collects, transmits, or sells patient information. The only
optional, opt-in feature that uses the network is Google sign-in (see
"Optional account sign-in" below); it stays off unless you choose it.

## Information we do NOT collect
- No patient-identifiable information. Any values you enter (e.g. a
  lab result, a dose) are processed only on your device, in memory,
  to compute the on-screen output, and are not stored or transmitted.
- No account is required to use any clinical feature. An optional
  Google sign-in is available — see "Optional account sign-in" below.
- No advertising identifiers; no third-party advertising or analytics
  SDKs.

## Optional account sign-in (Google)
Signing in is entirely optional and off by default. Every clinical
feature works without it. If you choose "Continue with Google" in
Settings:
- We use Google Sign-In and Firebase Authentication (a Google service)
  only to verify your identity.
- The only data processed is your Google account's name, email
  address and profile photo, used solely to label the app on your
  device.
- No patient information is ever associated with your account or
  transmitted. Patient data continues to be processed only on the
  device, exactly as described elsewhere in this policy.
- You can sign out at any time from Settings.
- Authentication is handled by Google/Firebase under Google's own
  privacy policy: https://policies.google.com/privacy

## Information processed on the device
- App preferences (e.g. settings, locale) are stored locally on the
  device only.
- TODO: If optional anonymous crash reporting is enabled, state the
  provider here and confirm it contains no clinical inputs and is
  opt-in / off by default. If no crash reporting ships, delete this
  section.

## Data sharing
We do not sell data and we never share patient information with
anyone. If you use the optional Google sign-in, your authentication is
processed by Google (Firebase Authentication) acting as our service
provider; no patient information is involved. We share nothing else.

## Children
The app is intended for qualified healthcare professionals and is not
directed to children.

## Medical disclaimer
PsychSwitch provides educational decision-support and reference
content only. It does not provide a diagnosis or individualised
medical advice and is not a substitute for professional clinical
judgement, local protocols, or the approved product information. The
prescriber is solely responsible for clinical decisions.

## Changes
We may update this policy; the "last updated" date will change
accordingly.

## Contact
TODO_founder_email

---
NOTE TO FOUNDER: Host this (after filling the TODOs and reconciling the
crash-reporting section with what actually ships) at a stable public
URL and put that URL in the Play Console listing and Data safety form.
The optional Google sign-in adds Name / Email / Profile photo to the
Data safety declaration — see store/FIREBASE_SETUP.md for the exact
form entries. If you decide NOT to ship sign-in for the closed beta,
delete the "Optional account sign-in" section and revert the sign-in
mentions in Summary / Data sharing above.
