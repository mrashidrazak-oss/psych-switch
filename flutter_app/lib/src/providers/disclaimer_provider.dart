// First-launch disclaimer gate — Riverpod state holder backed by
// shared_preferences. Mirrors the RN AsyncStorage flag exactly so a
// user who acknowledged in the RN build doesn't get re-prompted in
// the Flutter port.
//
// Storage key: psychswitch.disclaimer.ack.v1.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psychswitch/src/providers/preferences_provider.dart';

/// Reactive boolean: true once the user has acknowledged the
/// decision-support disclaimer at least once on this install.
///
/// Watch via:
/// ```dart
/// final asyncAck = ref.watch(disclaimerAcknowledgedProvider);
/// asyncAck.when(
///   loading: () => SplashWidget(),
///   error: (e, st) => SplashWidget(),
///   data: (ack) => ack ? const App() : const DisclaimerScreen(),
/// );
/// ```
final disclaimerAcknowledgedProvider =
    AsyncNotifierProvider<_DisclaimerAck, bool>(_DisclaimerAck.new);

class _DisclaimerAck extends AsyncNotifier<bool> {
  static const _key = 'psychswitch.disclaimer.ack.v1';

  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_key) ?? false;
  }

  /// Persist the acknowledgement and flip the reactive flag.
  Future<void> acknowledge() async {
    state = const AsyncValue.data(true);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, true);
  }
}
