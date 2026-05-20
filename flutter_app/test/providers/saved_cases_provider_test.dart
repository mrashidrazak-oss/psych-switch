// Saved-cases provider tests — verify the Riverpod wiring with an
// in-memory database override. The actual CRUD semantics live in
// database_test.dart; here we just confirm the providers compose and
// that ProviderScope override + dispose hook work.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/data/database.dart';
import 'package:psychswitch/src/providers/saved_cases_provider.dart';
import 'package:psychswitch_engine/case_pulse.dart' show SavedCase;

SavedCase _case({String id = 'c1'}) => SavedCase(
      id: id,
      label: 'JD',
      fromDrugId: 'olanzapine',
      fromDoseMg: 20,
      toDrugId: 'aripiprazole',
      toDoseMg: 15,
      startedISO: '2026-05-09T08:00:00.000Z',
      updatedISO: '2026-05-09T08:00:00.000Z',
    );

void main() {
  group('saved-cases providers', () {
    late ProviderContainer container;
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
      container = ProviderContainer(
        overrides: <Override>[
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
    });

    tearDown(() async => db.close());

    test('savedCasesProvider starts with an empty stream snapshot',
        () async {
      // First emission is the empty list.
      final firstSnapshot = await container
          .read(savedCasesProvider.future);
      expect(firstSnapshot, isEmpty);
    });

    test(
      'savedCaseRepositoryProvider.save persists, '
      'and savedCasesProvider re-emits',
      () async {
        final repo = container.read(savedCaseRepositoryProvider);
        await repo.save(_case());
        // Pull a fresh snapshot — the StreamProvider sees the change.
        final snap = await container.read(savedCasesProvider.future);
        expect(snap, hasLength(1));
        expect(snap.first.id, equals('c1'));
      },
    );

    test('repository.delete removes the row', () async {
      final repo = container.read(savedCaseRepositoryProvider);
      await repo.save(_case());
      await repo.delete('c1');
      final snap = await container.read(savedCasesProvider.future);
      expect(snap, isEmpty);
    });

    test('repository.get returns null for unknown id', () async {
      final repo = container.read(savedCaseRepositoryProvider);
      expect(await repo.get('not-a-case'), isNull);
    });
  });
}
