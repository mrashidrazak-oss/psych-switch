// Saved-cases Riverpod providers.
//
// Three providers:
//   • databaseProvider     — singleton AppDatabase instance.
//   • savedCasesProvider   — StreamProvider<List<SavedCase>>; emits a
//                            fresh snapshot whenever the cases table
//                            changes. Suitable for History + Home pulse.
//   • savedCaseRepository  — thin wrapper exposing upsert/delete to UI.
//
// The database is held as a Riverpod-scoped singleton rather than a
// global, so widget tests can swap in `AppDatabase.memory()` via
// `ProviderScope(overrides:)` without leaking state across tests.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psychswitch/src/data/database.dart';
import 'package:psychswitch/src/engine/case_pulse.dart' show SavedCase;

/// Application database — overridable in tests via:
///
/// ```dart
/// ProviderScope(
///   overrides: [databaseProvider.overrideWithValue(AppDatabase.memory())],
///   child: ...,
/// );
/// ```
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Live stream of saved cases (newest-first by updatedISO).
final savedCasesProvider = StreamProvider<List<SavedCase>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchCases();
});

/// Thin facade over the database for UI write operations. Screens use
/// `ref.read(savedCaseRepositoryProvider).save(c)` rather than reaching
/// into the AppDatabase directly — keeps the call sites stable if the
/// schema changes.
class SavedCaseRepository {
  const SavedCaseRepository(this._db);

  final AppDatabase _db;

  Future<void> save(SavedCase c) => _db.upsertCase(c);

  Future<void> delete(String id) => _db.deleteCase(id);

  Future<SavedCase?> get(String id) => _db.getCase(id);
}

final savedCaseRepositoryProvider = Provider<SavedCaseRepository>((ref) {
  return SavedCaseRepository(ref.watch(databaseProvider));
});
