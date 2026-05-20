// Riverpod wiring for optional Google sign-in.
//
// Hand-written providers (no codegen) to match the rest of the app —
// see the note in preferences_provider.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psychswitch/src/services/auth_service.dart';

/// The shared [AuthService] singleton.
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService.instance,
);

/// Whether Google sign-in is wired up for this build. When false the
/// UI shows a "coming soon" tile instead of a dead button.
final authAvailableProvider = Provider<bool>(
  (ref) => ref.watch(authServiceProvider).isAvailable,
);

/// Reactive auth state — the signed-in [AuthUser], or null when signed
/// out (or when sign-in is unavailable).
final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authServiceProvider).authState(),
);
