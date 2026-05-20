# PsychSwitch — Firebase / Google sign-in setup (founder, one-time)

The optional "Continue with Google" sign-in is fully built in the app
but **inert until a real Firebase project is connected**. Until then
the app behaves exactly as before — fully offline, account-free — and
the Settings → ACCOUNT section shows an honest "available in an
upcoming update" tile instead of a dead button.

This is a ~15-minute, one-time task. Nothing here can be done by the
coding assistant: it needs your Google account.

---

## What "configured" means in code

The app keys every auth surface off `AuthConfig.firebaseConfigured`
(`flutter_app/lib/src/auth_config.dart`). That getter returns true the
moment the placeholder values in `lib/firebase_options.dart` are
replaced with a real project's values. No other code change is needed
— the sign-in UI lights up automatically.

---

## Recommended path — FlutterFire CLI (automated)

1. Create a Firebase project at https://console.firebase.google.com
   (free Spark plan is enough).
2. Install the tooling (one-time):
   ```
   dart pub global activate flutterfire_cli
   npm install -g firebase-tools   # or: curl -sL https://firebase.tools | bash
   firebase login
   ```
3. From `flutter_app/`, run:
   ```
   flutterfire configure
   ```
   Select the project and the Android (+ iOS, if shipping iOS) apps.
   Use the existing application id **`app.psychswitch.app`**. This
   overwrites `lib/firebase_options.dart` with real values and adds
   the Android `google-services.json` + Gradle plugin for you.
4. In the Firebase console: **Authentication → Get started → Sign-in
   method → Google → Enable.** Set a support email. Save.
5. Register the app's signing fingerprints so Google sign-in is
   accepted (**Project settings → Your apps → Android app → Add
   fingerprint**). Add the SHA-1 (and SHA-256) of:
   - the **debug** keystore (for `flutter run`), and
   - the **upload/release** keystore from `android/key.properties`.
   Get them with:
   ```
   keytool -list -v -keystore <path-to-keystore> -alias <alias>
   ```
   If you ship via Play App Signing, also add the **App signing key**
   SHA-1 shown in Play Console → Test and release → App integrity.
6. Fill the OAuth **Web client id**: open
   `flutter_app/lib/src/auth_config.dart` and replace
   `googleServerClientId` with the *Web* client id from Firebase
   console → Authentication → Sign-in method → Google → Web SDK
   configuration. (Required so Android sign-in returns an ID token
   Firebase will accept.)
7. Rebuild: `flutter pub get && flutter run`. The Settings → ACCOUNT
   section now shows a working "Continue with Google" button.

## Manual path (no CLI)

If you prefer not to use the CLI: in the Firebase console create the
Android app (`app.psychswitch.app`), then hand-copy the apiKey,
appId, messagingSenderId and projectId into the `android` (and `ios`)
`FirebaseOptions` blocks in `lib/firebase_options.dart`, and the Web
client id into `auth_config.dart`. Then do steps 4–7 above.

---

## Play Store — Data safety form

Connecting sign-in adds one data type you must now declare in the Play
Console **Data safety** form (and it is already reflected in
`store/privacy-policy.md` → "Optional account sign-in"):

- **Data collected:** Name, Email address, and (optionally) a user
  profile photo — via the optional Google sign-in only.
- **Purpose:** App functionality / account management.
- **Collection is optional:** Yes (the user can use the whole app
  without signing in).
- **Encrypted in transit:** Yes.
- **Processor:** Google (Firebase Authentication).
- Still declare: **no** patient/health data is collected or
  transmitted — that remains true and unchanged.

---

## iOS (only if/when you ship iOS)

`flutterfire configure` also writes `GoogleService-Info.plist`. You
must additionally add the reversed-client-id URL scheme to
`ios/Runner/Info.plist` for Google sign-in to return to the app — see
the `google_sign_in` package iOS setup notes.
