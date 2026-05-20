// Auth tests — the optional-sign-in layer.
//
// Two things under test:
//  1. AuthConfig correctly reports the (now wired-in) Firebase project.
//  2. AuthService stays safe when Firebase has not been initialised in
//     the running process — exactly the case in a unit-test process,
//     since main() (and its Firebase.initializeApp) never runs. So
//     isAvailable is false and every entry point degrades to a safe
//     no-op or a friendly AuthException, never touching Firebase.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/auth_config.dart';
import 'package:psychswitch/src/providers/auth_provider.dart';
import 'package:psychswitch/src/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthUser.label', () {
    test('prefers the display name when present', () {
      const u = AuthUser(
        uid: 'x',
        displayName: 'Dr Rashid Razak',
        email: 'r@example.com',
      );
      expect(u.label, equals('Dr Rashid Razak'));
    });

    test('falls back to email when the name is blank', () {
      const u = AuthUser(uid: 'x', displayName: '   ', email: 'r@x.com');
      expect(u.label, equals('r@x.com'));
    });

    test('falls back to a generic when name and email are absent', () {
      const u = AuthUser(uid: 'x');
      expect(u.label, equals('Signed in'));
    });
  });

  group('AuthException', () {
    test('toString returns the user-facing message', () {
      const e = AuthException('Sign-in cancelled.');
      expect(e.toString(), equals('Sign-in cancelled.'));
    });
  });

  group('AuthConfig (project wired in)', () {
    test('firebaseConfigured is true once real options are present', () {
      expect(AuthConfig.firebaseConfigured, isTrue);
    });

    test('serverClientId returns the configured web client id', () {
      expect(AuthConfig.serverClientId, isNotNull);
      expect(
        AuthConfig.serverClientId,
        endsWith('.apps.googleusercontent.com'),
      );
    });
  });

  group('AuthService when Firebase is not initialised in-process', () {
    final auth = AuthService.instance;

    test('isAvailable is false', () {
      expect(auth.isAvailable, isFalse);
    });

    test('current user is null', () {
      expect(auth.current, isNull);
    });

    test('authState emits a single null without touching Firebase',
        () async {
      expect(await auth.authState().first, isNull);
    });

    test('signInWithGoogle throws a friendly AuthException', () async {
      await expectLater(
        auth.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });

    test('signOut is a safe no-op', () async {
      await expectLater(auth.signOut(), completes);
    });
  });

  group('auth providers', () {
    test('authServiceProvider exposes the shared singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(authServiceProvider),
        same(AuthService.instance),
      );
    });

    test('authAvailableProvider is false when Firebase is not inited', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(authAvailableProvider), isFalse);
    });

    test('authStateProvider resolves to null when signed out', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(await container.read(authStateProvider.future), isNull);
    });
  });
}
