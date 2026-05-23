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

/// Clinician display name — surfaces on the Home greeting and on
/// exported switch-plan PDFs. Empty string means "not set"; the UI
/// falls back to a generic salutation. Two-letter initials are
/// derived for the avatar bubble.
final clinicianNameProvider =
    AsyncNotifierProvider<_StringPref, String>(_StringPref.new);

class _StringPref extends AsyncNotifier<String> {
  static const _key = 'pref_clinician_name';

  @override
  Future<String> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getString(_key) ?? '';
  }

  Future<void> set(String value) async {
    final trimmed = value.trim();
    state = AsyncValue.data(trimmed);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, trimmed);
  }
}

/// Compute up-to-two-character initials from a clinician name.
/// Returns 'RX' when the name is empty so the avatar never collapses.
String clinicianInitials(String name) {
  final tokens = name
      .replaceAll(RegExp(r'^Dr\.?\s+', caseSensitive: false), '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return 'RX';
  if (tokens.length == 1) {
    final t = tokens.first;
    return t.length >= 2
        ? t.substring(0, 2).toUpperCase()
        : t.substring(0, 1).toUpperCase();
  }
  return (tokens.first.substring(0, 1) + tokens.last.substring(0, 1))
      .toUpperCase();
}

/// Salutation form for the greeting — strips/prefixes "Dr" as needed
/// so the greeting reads naturally regardless of how the user typed
/// their name in. Returns "Doctor" when the name is empty so the
/// greeting reads "Good afternoon, Doctor" — a polished pre-personal-
/// isation default, rather than the truncated-looking "Dr R".
String clinicianSalutation(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Doctor';
  // Already starts with "Dr" / "dr" / "DR" — pass through.
  if (RegExp(r'^Dr\.?\b', caseSensitive: false).hasMatch(trimmed)) {
    return trimmed;
  }
  return 'Dr $trimmed';
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
