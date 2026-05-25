// Drift database — local persistence for saved cases.
//
// One table, `cases`, mirrors the `SavedCase` engine type
// (lib/src/engine/case_pulse.dart). All clinician-supplied data stays
// on-device — no network sync, no telemetry, no patient identifiers
// (the `label` field is intended for free-form clinician initials or
// case codes).
//
// Codegen — run `dart run build_runner build` to generate
// `database.g.dart`. The generator is `drift_dev`.
//
// In production we open a sqlite file under getApplicationDocumentsDirectory()
// (handled by [openConnection]). Tests construct an in-memory instance via
// [AppDatabase.memory] so they're hermetic and fast.

import 'package:drift/drift.dart';
import 'package:psychswitch/src/data/connection/connection.dart';
import 'package:psychswitch_engine/case_pulse.dart' show SavedCase;

part 'database.g.dart';

@DataClassName('CaseRow')
class Cases extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get fromDrugId => text()();
  RealColumn get fromDoseMg => real()();
  TextColumn get toDrugId => text()();
  RealColumn get toDoseMg => real()();
  TextColumn get startedISO => text()();
  TextColumn get updatedISO => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get favourite =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

@DriftDatabase(tables: <Type>[Cases])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.memory() : super(memoryConnection());

  /// Schema version. Bump this and add a `migrationStrategy` step when
  /// the table shape changes.
  @override
  int get schemaVersion => 1;

  // ── Public API ──────────────────────────────────────────────────────

  /// All saved cases, sorted newest-first by `updatedISO`.
  Future<List<SavedCase>> listCases() async {
    final rows = await (select(cases)
          ..orderBy(<OrderClauseGenerator<$CasesTable>>[
            (t) => OrderingTerm.desc(t.updatedISO),
          ]))
        .get();
    return rows.map(_rowToCase).toList();
  }

  /// Stream of saved cases — emits a fresh snapshot whenever the table
  /// changes, suitable for a Riverpod `StreamProvider`.
  Stream<List<SavedCase>> watchCases() {
    return (select(cases)
          ..orderBy(<OrderClauseGenerator<$CasesTable>>[
            (t) => OrderingTerm.desc(t.updatedISO),
          ]))
        .watch()
        .map((rows) => rows.map(_rowToCase).toList());
  }

  Future<SavedCase?> getCase(String id) async {
    final row = await (select(cases)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _rowToCase(row);
  }

  /// Insert or update a case. Existing rows with the same id are
  /// overwritten (last-write-wins).
  Future<void> upsertCase(SavedCase c) async {
    await into(cases).insertOnConflictUpdate(_caseToCompanion(c));
  }

  Future<int> deleteCase(String id) async {
    return (delete(cases)..where((t) => t.id.equals(id))).go();
  }

  /// Wipe everything — used by Settings → Reset all data.
  Future<int> deleteAll() async => delete(cases).go();

  // ── Mapping helpers ─────────────────────────────────────────────────

  SavedCase _rowToCase(CaseRow r) => SavedCase(
        id: r.id,
        label: r.label,
        fromDrugId: r.fromDrugId,
        fromDoseMg: r.fromDoseMg,
        toDrugId: r.toDrugId,
        toDoseMg: r.toDoseMg,
        startedISO: r.startedISO,
        updatedISO: r.updatedISO,
        notes: r.notes,
        favourite: r.favourite,
      );

  CasesCompanion _caseToCompanion(SavedCase c) => CasesCompanion(
        id: Value<String>(c.id),
        label: Value<String>(c.label),
        fromDrugId: Value<String>(c.fromDrugId),
        fromDoseMg: Value<double>(c.fromDoseMg.toDouble()),
        toDrugId: Value<String>(c.toDrugId),
        toDoseMg: Value<double>(c.toDoseMg.toDouble()),
        startedISO: Value<String>(c.startedISO),
        updatedISO: Value<String>(c.updatedISO),
        notes: c.notes == null
            ? const Value<String?>.absent()
            : Value<String?>(c.notes),
        favourite: Value<bool>(c.favourite ?? false),
      );
}

// Connection logic lives in `connection/connection.dart` (the
// conditional-import shim) → `connection_native.dart` (sqlite file
// under getApplicationDocumentsDirectory) or `connection_web.dart`
// (sqlite3 WASM + IndexedDB persistence).
