// AppDatabase tests — exercise the cases CRUD path against an
// in-memory SQLite instance. Hermetic, no path_provider, no async
// asset loading.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/data/database.dart';
import 'package:psychswitch_engine/case_pulse.dart' show SavedCase;

SavedCase _case({
  String id = 'c1',
  String label = 'JD',
  String fromDrugId = 'olanzapine',
  num fromDoseMg = 20,
  String toDrugId = 'aripiprazole',
  num toDoseMg = 15,
  String? notes,
  bool? favourite,
  String startedISO = '2026-05-09T08:00:00.000Z',
  String updatedISO = '2026-05-09T08:00:00.000Z',
}) =>
    SavedCase(
      id: id,
      label: label,
      fromDrugId: fromDrugId,
      fromDoseMg: fromDoseMg,
      toDrugId: toDrugId,
      toDoseMg: toDoseMg,
      startedISO: startedISO,
      updatedISO: updatedISO,
      notes: notes,
      favourite: favourite,
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() async => db.close());

  group('AppDatabase.cases', () {
    test('starts empty', () async {
      expect(await db.listCases(), isEmpty);
    });

    test('upsert inserts a case', () async {
      await db.upsertCase(_case());
      final all = await db.listCases();
      expect(all, hasLength(1));
      expect(all.first.id, equals('c1'));
      expect(all.first.fromDrugId, equals('olanzapine'));
      expect(all.first.fromDoseMg, equals(20));
    });

    test('upsert is last-write-wins for the same id', () async {
      await db.upsertCase(_case());
      await db.upsertCase(_case(label: 'JD-updated', fromDoseMg: 10));
      final all = await db.listCases();
      expect(all, hasLength(1));
      expect(all.first.label, equals('JD-updated'));
      expect(all.first.fromDoseMg, equals(10));
    });

    test('list is sorted newest-first by updatedISO', () async {
      await db.upsertCase(
        _case(id: 'old', updatedISO: '2026-05-01T00:00:00.000Z'),
      );
      await db.upsertCase(
        _case(id: 'new', updatedISO: '2026-05-09T00:00:00.000Z'),
      );
      await db.upsertCase(
        _case(id: 'mid', updatedISO: '2026-05-05T00:00:00.000Z'),
      );
      final ids = (await db.listCases()).map((c) => c.id).toList();
      expect(ids, equals(<String>['new', 'mid', 'old']));
    });

    test('getCase returns null for unknown id', () async {
      expect(await db.getCase('not-a-case'), isNull);
    });

    test('deleteCase removes the row', () async {
      await db.upsertCase(_case());
      expect(await db.deleteCase('c1'), equals(1));
      expect(await db.listCases(), isEmpty);
    });

    test('deleteAll wipes everything', () async {
      await db.upsertCase(_case(id: 'a'));
      await db.upsertCase(_case(id: 'b'));
      expect(await db.deleteAll(), equals(2));
      expect(await db.listCases(), isEmpty);
    });

    test('nullable fields round-trip (notes set + null, favourite set + null)',
        () async {
      await db.upsertCase(
        _case(id: 'with-notes', notes: 'Counselled re: weight gain'),
      );
      await db.upsertCase(_case(id: 'no-notes'));
      final withNotes = await db.getCase('with-notes');
      final noNotes = await db.getCase('no-notes');
      expect(withNotes?.notes, equals('Counselled re: weight gain'));
      expect(noNotes?.notes, isNull);
      // favourite defaults to false when unset.
      expect(noNotes?.favourite, equals(false));
    });

    test('watchCases emits a fresh snapshot on every change', () async {
      final snapshots = <List<SavedCase>>[];
      final sub = db.watchCases().listen(snapshots.add);
      addTearDown(sub.cancel);

      // Wait for the initial empty snapshot.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(snapshots, isNotEmpty);
      expect(snapshots.first, isEmpty);

      await db.upsertCase(_case(id: 'a'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await db.upsertCase(_case(id: 'b'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Latest snapshot reflects both cases.
      expect(snapshots.last.map((c) => c.id), containsAll(<String>['a', 'b']));
    });
  });
}
