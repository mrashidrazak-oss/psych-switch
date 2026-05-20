// Firebase configuration for PsychSwitch.
//
// The Android block below holds REAL values for the `psychswi` Firebase
// project (written by `flutterfire configure`). iOS is still a
// placeholder — fill it by re-running `flutterfire configure` with the
// iOS platform when/if the app ships on iOS (see store/FIREBASE_SETUP.md).
//
// `AuthConfig.firebaseConfigured` (auth_config.dart) detects the
// `__REPLACE_ME__` sentinel; with Android now real, optional Google
// sign-in is live on Android.

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

  /// Android project configuration — real values for project `psychswi`.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBccgtaVFnOkqSgS70DnmxxR7cxr4mxGQI',
    appId: '1:166044970078:android:d3c3d570489f8940c058cf',
    messagingSenderId: '166044970078',
    projectId: 'psychswi',
    storageBucket: 'psychswi.firebasestorage.app',
  );

  /// iOS project configuration (placeholder — not yet configured).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '__REPLACE_ME__IOS_API_KEY',
    appId: '__REPLACE_ME__IOS_APP_ID',
    messagingSenderId: '__REPLACE_ME__SENDER_ID',
    projectId: '__REPLACE_ME__PROJECT_ID',
    iosBundleId: 'app.psychswitch.app',
  );
}
