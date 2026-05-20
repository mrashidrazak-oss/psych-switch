// Firebase configuration for PsychSwitch.
//
// PLACEHOLDER — the values below are NOT a real Firebase project.
// Optional Google sign-in stays completely inert until a real project
// is wired in. Two ways to do that (see store/FIREBASE_SETUP.md):
//
//   1. Run `flutterfire configure` — it overwrites this whole file
//      with real values. The custom auth knobs the app keys off live
//      in lib/src/auth_config.dart, so they survive that overwrite.
//   2. Hand-fill the constants below with the values from the Firebase
//      console (Project settings → Your apps).
//
// `AuthConfig.firebaseConfigured` (auth_config.dart) detects the
// `__REPLACE_ME__` sentinel and gates every auth surface off it, so an
// unconfigured build never shows a dead "Continue with Google" button.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for the current platform.
///
/// Consumed once, by `Firebase.initializeApp` in `main()`.
class DefaultFirebaseOptions {
  /// The [FirebaseOptions] matching the platform the app is running on.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return android;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return android;
    }
  }

  /// Android project configuration (placeholder).
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '__REPLACE_ME__ANDROID_API_KEY',
    appId: '__REPLACE_ME__ANDROID_APP_ID',
    messagingSenderId: '__REPLACE_ME__SENDER_ID',
    projectId: '__REPLACE_ME__PROJECT_ID',
  );

  /// iOS project configuration (placeholder).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '__REPLACE_ME__IOS_API_KEY',
    appId: '__REPLACE_ME__IOS_APP_ID',
    messagingSenderId: '__REPLACE_ME__SENDER_ID',
    projectId: '__REPLACE_ME__PROJECT_ID',
    iosBundleId: 'app.psychswitch.app',
  );
}
