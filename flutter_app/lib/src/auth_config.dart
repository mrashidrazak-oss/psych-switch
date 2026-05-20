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
  /// Real value for project `psychswi` — the auto-created Web OAuth
  /// client. Modern Firebase projects no longer carry this in
  /// google-services.json, so it is set explicitly here.
  static const googleServerClientId =
      '166044970078-df0tu631rn0slt50mbh5n0mdu39tmm4u'
      '.apps.googleusercontent.com';

  /// The [googleServerClientId] when set, else null (so google_sign_in
  /// falls back to its resource-file lookup).
  static String? get serverClientId =>
      googleServerClientId.contains(_sentinel) ? null : googleServerClientId;
}
