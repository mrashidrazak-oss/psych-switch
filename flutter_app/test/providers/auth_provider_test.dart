// Auth tests — verify the optional-sign-in layer behaves safely on an
// unconfigured build (the shipped placeholder Firebase config). The
// invariant under test: with no real project wired in, nothing touches
// Firebase, no network call is made, and every entry point degrades to
// a safe no-op or a friendly AuthException.

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

  group('AuthConfig (shipped placeholder)', () {
    test('firebaseConfigured is false until a real project is wired in',
        () {
      expect(AuthConfig.firebaseConfigured, isFalse);
    });

    test('serverClientId is null while the placeholder stands', () {
      expect(AuthConfig.serverClientId, isNull);
    });
  });

  group('AuthService on an unconfigured build', () {
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

    test('authAvailableProvider is false on an unconfigured build', () {
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
