// First-launch onboarding flag — Riverpod state holder backed by
// shared_preferences. Distinct from the disclaimer gate: the
// disclaimer is a legal/safety acknowledgement, the onboarding tour
// is a one-time UX walkthrough showing what the app does.
//
// Storage key: psychswitch.onboarding.complete.v1. Bumped to v2 if
// the tour pages substantively change so returning users see the
// new tour.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psychswitch/src/providers/preferences_provider.dart';

/// Reactive boolean: true once the user has finished the onboarding
/// tour at least once on this install. False on a fresh install AND
/// false if the user hit "Skip" — skipping is treated as completion
/// (we don't want to ambush returning users with the tour).
final onboardingCompleteProvider =
    AsyncNotifierProvider<_OnboardingComplete, bool>(_OnboardingComplete.new);

class _OnboardingComplete extends AsyncNotifier<bool> {
  static const _key = 'psychswitch.onboarding.complete.v1';

  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_key) ?? false;
  }

  /// Persist completion and flip the reactive flag. Called from both
  /// the "Get started" CTA on the final page and the "Skip" link in
  /// the top-right of every page.
  Future<void> markComplete() async {
    state = const AsyncValue.data(true);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, true);
  }

  /// Wipe the completion flag — re-triggers the onboarding tour on
  /// the next time the gate re-evaluates. Used by the Settings
  /// "Replay onboarding tour" affordance.
  Future<void> reset() async {
    state = const AsyncValue.data(false);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, false);
  }
}
