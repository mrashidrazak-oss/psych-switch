// Auth configuration knobs.
//
// Kept separate from the FlutterFire-generated `firebase_options.dart`
// so these values survive a re-run of `flutterfire configure` (which
// overwrites that file wholesale). See store/FIREBASE_SETUP.md.

import 'package:psychswitch/firebase_options.dart';

/// Sentinel embedded in every placeholder value. Its absence is the
/// signal that a real Firebase project has been wired in.
const _sentinel = '__REPLACE_ME__';

/// Static auth wiring — whether Firebase is configured, plus the OAuth
/// web client id Google sign-in needs to mint a verifiable ID token.
abstract final class AuthConfig {
  /// True once [DefaultFirebaseOptions] hold real project values
  /// instead of the shipped placeholders. Every auth surface in the
  /// app is gated off this, so an unconfigured build degrades cleanly
  /// to "sign-in coming soon" rather than a broken button.
  static bool get firebaseConfigured =>
      !DefaultFirebaseOptions.android.apiKey.contains(_sentinel);

  /// OAuth 2.0 **Web** client id (Firebase console → Authentication →
  /// Sign-in method → Google → Web SDK configuration). Google sign-in
  /// on Android needs this as its `serverClientId` so the returned ID
  /// token is one Firebase will accept.
  ///
  /// May be left as the sentinel when `flutterfire configure` was used
  /// AND the Google-services Gradle plugin is applied — google_sign_in
  /// then reads the id from google-services.json automatically.
  static const googleServerClientId = '__REPLACE_ME__WEB_CLIENT_ID';

  /// The [googleServerClientId] when set, else null (so google_sign_in
  /// falls back to its resource-file lookup).
  static String? get serverClientId =>
      googleServerClientId.contains(_sentinel) ? null : googleServerClientId;
}
