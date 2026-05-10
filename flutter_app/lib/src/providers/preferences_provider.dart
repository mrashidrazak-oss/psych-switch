// User preferences — Riverpod-managed flags backed by
// shared_preferences. Phase 7A only ships two flags
// (showCitationChips, deleteAllConfirmed) but the same pattern
// extends to reminder times, locale, etc. as those features land.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Async singleton — one SharedPreferences instance per app lifetime.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// Whether the Result-screen citation chips render (default: true).
/// Reactive — UI rebuilds on toggle.
final showCitationsProvider =
    AsyncNotifierProvider<_BoolPref, bool>(_BoolPref.new);

class _BoolPref extends AsyncNotifier<bool> {
  static const _key = 'pref_show_citations';

  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_key) ?? true;
  }

  Future<void> set({required bool value}) async {
    state = AsyncValue.data(value);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, value);
  }
}

/// Whether monitoring-reminder notifications fire on saved cases.
/// Default: false — opt-in. Toggling off cancels every pending
/// reminder via `NotificationService.cancelAll`.
final remindersEnabledProvider =
    AsyncNotifierProvider<_RemindersPref, bool>(_RemindersPref.new);

class _RemindersPref extends AsyncNotifier<bool> {
  static const _key = 'pref_reminders_enabled';

  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> set({required bool value}) async {
    state = AsyncValue.data(value);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, value);
  }
}
