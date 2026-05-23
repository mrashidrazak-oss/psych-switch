# PsychSwitch — Closed-beta distribution playbook

This is how PsychSwitch closed-beta builds are shipped to testers
**outside the Play Store**. The medical-app organisation-account gate
on Google Play is blocking Play distribution until a D-U-N-S +
organisation Play Console account is set up (separate task, see
project notes). Until then, Firebase App Distribution is the
distribution channel.

Firebase App Distribution has **no medical-app gate**. Testers get an
install link via email and install the APK directly. Same end result
as a Play closed-test, but live today.

---

## One-time setup (done — keep for reference)

### 1. Firebase CLI

```sh
brew install firebase-cli      # if not already installed
firebase login                  # opens browser; sign in with Google
firebase projects:list          # should show project `psychswi`
```

### 2. Tester group in the Firebase Console

1. Open <https://console.firebase.google.com/project/psychswi/appdistribution>
2. Tab: **Testers & Groups** → **Add group**
3. Group alias: `closed-beta` (the distribute script defaults to this
   alias — match it exactly).
4. Add tester emails. Each tester is sent an invite email.

Alternative: pass tester emails on the command line — see "Ad-hoc
testers" below.

### 3. Tester device prep (one-time, per tester)

The tester gets an email titled "You've been invited to test
PsychSwitch". They need to:

1. **Accept the invite** — opens the App Tester web flow.
2. **Install the Firebase App Tester app** (Android only — link in
   the email).
3. **Sign in to App Tester** with the same email the invite was sent
   to.
4. On the first install, Android prompts them to allow installs from
   App Tester — they tap "Allow".

After that, every new build appears in App Tester within a couple of
minutes of being pushed.

---

## Shipping a new build

From `flutter_app/`:

```sh
bash scripts/distribute-beta.sh "Release notes — what changed since the last build"
```

That's the whole flow. The script:

1. Builds a signed release APK (`flutter build apk --release`).
2. Uploads it to Firebase App Distribution.
3. Notifies the `closed-beta` group — every existing tester gets a
   push notification in App Tester.

Useful flags:

```sh
# Re-distribute the last-built APK without rebuilding (faster):
bash scripts/distribute-beta.sh "Hotfix release notes" --skip-build

# Push to a different group (e.g. an internal-only group):
bash scripts/distribute-beta.sh "Internal smoke build" --group internal
```

---

## Ad-hoc testers (skip the group)

For a one-off tester you don't want to add to the persistent group,
upload via the raw CLI:

```sh
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app 1:166044970078:android:d3c3d570489f8940c058cf \
  --project psychswi \
  --release-notes "Notes" \
  --testers "doctor@example.com"
```

The tester gets the same invite email as group members.

---

## Tester install instructions (copy-paste for tester emails)

> 1. Check your email for the invite — subject line "You've been
>    invited to test PsychSwitch".
> 2. Tap **Accept invitation**. It opens a setup page in your browser.
> 3. Install the **Firebase App Tester** app from the link on that
>    page (Google Play, free).
> 4. Sign in to App Tester with the same Google account that received
>    this invite.
> 5. PsychSwitch will appear in your list of available apps — tap
>    **Download** to install. The first install may ask you to allow
>    installs from App Tester; tap Allow and try again.
> 6. Every time a new build ships, App Tester will notify you. Tap
>    **Update** to install.
>
> If you hit anything weird, screenshot it and message me. The app
> won't transmit any patient data — everything stays on your phone.

---

## What testers get vs. Play Store closed-testing

| Feature | Play closed-test | Firebase App Distribution |
|---|---|---|
| Medical-app org-account gate | Required ✗ | Not required ✓ |
| Install link | Play Store | App Tester app |
| Auto-updates | Yes (Play infra) | Yes (App Tester notifies) |
| Crash reports | Play Console | Firebase Crashlytics (if wired) |
| In-app feedback | Play has a tester feedback channel | None — testers email/Slack you directly |
| Max testers | 100 in closed track | No hard cap (large groups practical) |
| Setup friction (tester) | Low — just Play | One-time App Tester install |

The main thing the tester has to do once is install Firebase App
Tester. After that, updates flow as fast as you push them.

---

## When this stops being the right channel

Switch back to Play Store closed-testing once:

1. The D-U-N-S number arrives (1–4 weeks from D&B).
2. The organisation Play Console account is registered ($25 one-time).
3. The medical-app declaration is signed off in Play Console.

At that point, Firebase App Distribution becomes redundant for
production-track work and can be retired (or kept as an internal
smoke-test channel — both are valid).
