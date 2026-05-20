// Authentication service — optional Google sign-in via Firebase Auth.
//
// Design contract: the app is offline-first and account-free. Sign-in
// is a strictly opt-in convenience. Nothing here runs — and no network
// call is ever made — unless the user explicitly taps "Continue with
// Google" in Settings AND a real Firebase project has been wired in
// (see store/FIREBASE_SETUP.md). Until then [isAvailable] is false and
// every method degrades to a safe no-op.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:psychswitch/src/auth_config.dart';

/// Set true by `main()` after a successful `Firebase.initializeApp`.
/// Guards against touching `FirebaseAuth.instance` when the platform
/// init failed (which would throw).
bool firebaseInitialised = false;

/// Immutable snapshot of the signed-in clinician, or null when signed
/// out. Deliberately minimal — only what the UI renders.
class AuthUser {
  /// Creates an [AuthUser].
  const AuthUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  /// Firebase account id — stable for this user.
  final String uid;

  /// Google profile display name, if the account exposes one.
  final String? displayName;

  /// Google account email, if the account exposes one.
  final String? email;

  /// Google profile photo URL, if the account exposes one.
  final String? photoUrl;

  /// Best human label for the UI: name, else email, else a generic.
  String get label {
    final name = displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final mail = email?.trim() ?? '';
    if (mail.isNotEmpty) return mail;
    return 'Signed in';
  }
}

/// Raised for any expected, user-facing auth failure (cancelled flow,
/// unconfigured build, credential rejected). Carries a message safe to
/// surface directly in a SnackBar.
class AuthException implements Exception {
  /// Creates an [AuthException] with a user-facing [message].
  const AuthException(this.message);

  /// Human-readable, SnackBar-safe explanation.
  final String message;

  @override
  String toString() => message;
}

/// Brokers optional Google sign-in. Singleton — one instance per app.
class AuthService {
  AuthService._();

  /// Shared instance.
  static final AuthService instance = AuthService._();

  GoogleSignIn? _google;

  /// Whether sign-in can actually run: a real Firebase project is
  /// wired in AND platform init succeeded.
  bool get isAvailable =>
      AuthConfig.firebaseConfigured && firebaseInitialised;

  /// Reactive auth state. Emits the current [AuthUser] (or null) and
  /// every subsequent change. When sign-in is unavailable it emits a
  /// single null and never touches Firebase.
  Stream<AuthUser?> authState() {
    if (!isAvailable) return Stream<AuthUser?>.value(null);
    return FirebaseAuth.instance.authStateChanges().map(_map);
  }

  /// The currently signed-in user, or null.
  AuthUser? get current =>
      isAvailable ? _map(FirebaseAuth.instance.currentUser) : null;

  static AuthUser? _map(User? u) => u == null
      ? null
      : AuthUser(
          uid: u.uid,
          displayName: u.displayName,
          email: u.email,
          photoUrl: u.photoURL,
        );

  /// Runs the Google sign-in flow and exchanges the credential with
  /// Firebase. Returns the signed-in [AuthUser].
  ///
  /// Throws [AuthException] for every expected failure — unconfigured
  /// build, user cancellation, or a rejected credential.
  Future<AuthUser> signInWithGoogle() async {
    if (!isAvailable) {
      throw const AuthException(
        'Google sign-in is not configured for this build yet.',
      );
    }
    _google ??= GoogleSignIn(
      scopes: const <String>['email'],
      serverClientId: AuthConfig.serverClientId,
    );
    final GoogleSignInAccount? account;
    try {
      account = await _google!.signIn();
    } on Exception catch (_) {
      throw const AuthException('Could not reach Google. Try again.');
    }
    if (account == null) {
      // Null = the user backed out of the Google chooser.
      throw const AuthException('Sign-in cancelled.');
    }
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );
    try {
      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = _map(result.user);
      if (user == null) {
        throw const AuthException('Sign-in failed. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign-in failed. Please try again.');
    }
  }

  /// Signs out of both Google and Firebase. Safe to call when already
  /// signed out or when sign-in is unavailable.
  Future<void> signOut() async {
    if (!isAvailable) return;
    try {
      await _google?.signOut();
    } on Exception catch (_) {
      // Best-effort — a failed Google sign-out must not block the
      // Firebase sign-out below.
    }
    await FirebaseAuth.instance.signOut();
  }
}
